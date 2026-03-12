import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:hashlib/hashlib.dart';

import '../utils/constants.dart';
import 'logger_service.dart';
import 'security_service.dart';

/// Authenticated encryption / decryption for SecureAuth backup files.
///
/// V2 format (Argon2id, current):
///   Offset   Len   Field
///      0      5    Magic: ASCII "SAENC"
///      5      1    Format version: 0x02
///      6     32    Salt
///     38     12    AES-GCM nonce (standard 12-byte GCM nonce)
///     50      *    AES-256-GCM ciphertext ∥ 16-byte GCM authentication tag
///
/// V1 format (PBKDF2-SHA256, legacy read-only):
///   Offset   Len   Field
///      0      5    Magic: ASCII "SAENC"
///      5      1    Format version: 0x01
///      6      4    PBKDF2 iterations (uint32 big-endian)
///     10     16    Salt
///     26     16    AES-GCM nonce
///     42      *    AES-256-GCM ciphertext ∥ 16-byte GCM authentication tag
///
/// The GCM tag authenticates the ciphertext; any byte flip (wrong password,
/// bit-rot, tampering) produces a tag-mismatch exception before returning data.
class BackupEncryptionService {
  static final _log = LoggerService.instance;

  // ── Constants ─────────────────────────────────────────────────────────────
  static const List<int> _magic = [0x53, 0x41, 0x45, 0x4E, 0x43]; // "SAENC"
  static const int _versionV1 = 0x01;
  static const int _versionV2 = 0x02;
  static const int _saltLenV1 = 16;
  static const int _saltLenV2 = 32;
  static const int _nonceLenV1 = 16;
  static const int _nonceLenV2 = 12; // standard GCM nonce
  static const int _tagLen = 16;
  static const int _keyLen = 32; // AES-256
  // V2 header: 5 magic + 1 version + 32 salt + 12 nonce = 50 bytes
  static const int _headerLenV2 = 5 + 1 + _saltLenV2 + _nonceLenV2;
  static const int _minFileLenV2 = _headerLenV2 + _tagLen; // 66 bytes

  /// File extension for encrypted backup files.
  static const String fileExtension = 'saenc';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Encrypts [jsonData] with [password] using Argon2id and returns the V2
  /// binary blob.
  ///
  /// Runs Argon2id in a background [Isolate] so the UI stays responsive.
  static Future<Uint8List> encryptBackup(
      String jsonData, String password) async {
    final salt = SecurityService.secureRandom(_saltLenV2);
    final nonce = SecurityService.secureRandom(_nonceLenV2);
    final keyBytes = await Isolate.run(
      () => _argon2idKey(password: password, salt: salt),
    );
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(jsonData, iv: enc.IV(nonce));
    final out = BytesBuilder(copy: false)
      ..add(_magic)
      ..addByte(_versionV2)
      ..add(salt)
      ..add(nonce)
      ..add(encrypted.bytes);
    _log.security('backup', 'Backup encrypted (V2/Argon2id)', {
      'payloadSize': jsonData.length,
      'outputSize': out.length,
    });
    return out.toBytes();
  }

  /// Decrypts an encrypted backup blob and returns the JSON string.
  ///
  /// Supports both V2 (Argon2id) and V1 (PBKDF2-SHA256) formats.
  ///
  /// Throws [FormatException] when:
  ///   • the magic header is wrong (not a SecureAuth encrypted backup)
  ///   • the file is too short / KDF params are out of bounds
  ///   • the format version is unknown
  ///   • the GCM tag does not verify (wrong password or corruption)
  static Future<String> decryptBackup(
      Uint8List data, String password) async {
    if (data.length < _magic.length + 1) {
      throw const FormatException('File too small to be a valid backup');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) {
        throw const FormatException('Not a SecureAuth encrypted backup');
      }
    }
    final version = data[_magic.length];
    if (version == _versionV2) {
      _log.security('backup', 'Decrypting V2 backup', {'size': data.length});
      return _decryptV2(data, password);
    } else if (version == _versionV1) {
      _log.security('backup', 'Decrypting legacy V1 backup', {'size': data.length});
      return _decryptV1(data, password);
    } else {
      _log.error('backup', 'Unknown backup format version', {'version': version});
      throw FormatException('Unknown backup format version: $version');
    }
  }

  /// Returns true if [data] starts with the SecureAuth encrypted backup magic.
  static bool isEncryptedBackup(Uint8List data) {
    if (data.length < _magic.length) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) return false;
    }
    return true;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Future<String> _decryptV2(
      Uint8List data, String password) async {
    if (data.length < _minFileLenV2) {
      throw const FormatException('File too small to be a valid V2 backup');
    }
    int off = _magic.length + 1;
    final salt = Uint8List.fromList(data.sublist(off, off + _saltLenV2));
    off += _saltLenV2;
    final nonce = Uint8List.fromList(data.sublist(off, off + _nonceLenV2));
    off += _nonceLenV2;
    final ciphertext = Uint8List.fromList(data.sublist(off));
    if (ciphertext.length < _tagLen) {
      throw const FormatException('Ciphertext too short');
    }
    final keyBytes = await Isolate.run(
      () => _argon2idKey(password: password, salt: salt),
    );
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
    try {
      return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(nonce));
    } catch (_) {
      throw const FormatException('Wrong password or corrupted backup file');
    }
  }

  static Future<String> _decryptV1(
      Uint8List data, String password) async {
    const v1HeaderLen = 5 + 1 + 4 + 16 + 16; // 42
    if (data.length < v1HeaderLen + _tagLen) {
      throw const FormatException('File too small to be a valid V1 backup');
    }
    int off = _magic.length + 1; // skip magic (5) + version (1)
    final iterations = _rd32(data, off);
    off += 4;
    if (iterations < 1000 || iterations > 5000000) {
      throw const FormatException('Invalid KDF parameters in backup file');
    }
    final salt = Uint8List.fromList(data.sublist(off, off + _saltLenV1));
    off += _saltLenV1;
    final nonce = Uint8List.fromList(data.sublist(off, off + _nonceLenV1));
    off += _nonceLenV1;
    final ciphertext = Uint8List.fromList(data.sublist(off));
    if (ciphertext.length < _tagLen) {
      throw const FormatException('Ciphertext too short');
    }
    final keyBytes = await Isolate.run(
      () => _pbkdf2V1(password: password, salt: salt, iterations: iterations),
    );
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
    try {
      return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(nonce));
    } catch (_) {
      throw const FormatException('Wrong password or corrupted backup file');
    }
  }

  /// Argon2id key derivation for V2 backups.
  static Uint8List _argon2idKey({
    required String password,
    required Uint8List salt,
  }) {
    final hash = Argon2(
      type: Argon2Type.argon2id,
      memorySizeKB: AppConstants.argon2MemoryKB,
      iterations: AppConstants.argon2Iterations,
      parallelism: AppConstants.argon2Parallelism,
      hashLength: _keyLen,
      salt: salt,
    ).convert(utf8.encode(password));
    return Uint8List.fromList(hash.bytes);
  }

  /// Legacy PBKDF2-SHA256 key derivation for V1 backup decryption only.
  static Uint8List _pbkdf2V1({
    required String password,
    required Uint8List salt,
    required int iterations,
  }) {
    final derived = PBKDF2(
      HMAC(sha256),
      iterations,
      salt: salt,
      keyLength: _keyLen,
    ).convert(utf8.encode(password));
    return Uint8List.fromList(derived.bytes);
  }


  static int _rd32(Uint8List d, int o) =>
      (d[o] << 24) | (d[o + 1] << 16) | (d[o + 2] << 8) | d[o + 3];
}
