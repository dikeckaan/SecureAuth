import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

/// Authenticated encryption / decryption for SecureAuth backup files.
///
/// Algorithm choices:
///   • Key derivation : PBKDF2-HMAC-SHA256, 200 000 iterations, 16-byte salt
///   • Encryption     : AES-256-GCM — confidentiality + authenticity in one pass
///   • Nonce          : 16 bytes, cryptographically random per export
///   • Auth tag       : 16 bytes (GCM default) — wrong-password → tag mismatch
///
/// Binary file layout (all big-endian):
///   Offset   Len   Field
///      0      5    Magic: ASCII "SAENC"
///      5      1    Format version: 0x01
///      6      4    PBKDF2 iterations (uint32)
///     10     16    Salt
///     26     16    AES-GCM nonce
///     42      *    AES-256-GCM ciphertext ∥ 16-byte GCM authentication tag
///
/// The GCM tag authenticates the ciphertext; any byte flip (wrong password,
/// bit-rot, tampering) produces a tag-mismatch exception before returning data.
class BackupEncryptionService {
  // ── Constants ─────────────────────────────────────────────────────────────
  static const List<int> _magic = [0x53, 0x41, 0x45, 0x4E, 0x43, 0x01];
  static const int _saltLen = 16;
  static const int _nonceLen = 16;
  static const int _tagLen = 16; // GCM authentication-tag length
  static const int _keyLen = 32; // AES-256
  static const int _iterations = 200000; // PBKDF2 rounds
  static const int _headerLen = 6 + 4 + _saltLen + _nonceLen; // 42 bytes
  static const int _minFileLen = _headerLen + _tagLen; // 58 bytes

  /// File extension for encrypted backup files.
  static const String fileExtension = 'saenc';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Encrypts [jsonData] with [password] and returns the binary blob.
  ///
  /// Runs PBKDF2 in a background [Isolate] so the UI stays responsive.
  static Future<Uint8List> encryptBackup(
      String jsonData, String password) async {
    final salt = _secureRandom(_saltLen);
    final nonce = _secureRandom(_nonceLen);

    final keyBytes = await _deriveKey(password, salt, _iterations);

    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(jsonData, iv: enc.IV(nonce));

    final out = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(_be32(_iterations))
      ..add(salt)
      ..add(nonce)
      ..add(encrypted.bytes); // ciphertext ∥ 16-byte GCM tag
    return out.toBytes();
  }

  /// Decrypts an encrypted backup blob and returns the JSON string.
  ///
  /// Throws [FormatException] when:
  ///   • the magic header is wrong (not a SecureAuth encrypted backup)
  ///   • the file is too short / KDF params are out of bounds
  ///   • the GCM tag does not verify (wrong password or corruption)
  static Future<String> decryptBackup(
      Uint8List data, String password) async {
    _validateHeader(data);

    int off = _magic.length;
    final iterations = _rd32(data, off);
    off += 4;

    // Sanity-check iterations to prevent DoS via crafted header.
    if (iterations < 1000 || iterations > 5000000) {
      throw const FormatException('Invalid KDF parameters in backup file');
    }

    final salt = Uint8List.fromList(data.sublist(off, off + _saltLen));
    off += _saltLen;
    final nonce = Uint8List.fromList(data.sublist(off, off + _nonceLen));
    off += _nonceLen;
    final ciphertext = Uint8List.fromList(data.sublist(off));

    if (ciphertext.length < _tagLen) {
      throw const FormatException('Ciphertext too short');
    }

    final keyBytes = await _deriveKey(password, salt, iterations);
    final encrypter =
        enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm));

    try {
      return encrypter.decrypt(enc.Encrypted(ciphertext), iv: enc.IV(nonce));
    } catch (_) {
      // GCM tag mismatch — wrong password or corrupted file.
      throw const FormatException('Wrong password or corrupted backup file');
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

  static void _validateHeader(Uint8List data) {
    if (data.length < _minFileLen) {
      throw const FormatException('File too small to be a valid backup');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (data[i] != _magic[i]) {
        throw const FormatException('Not a SecureAuth encrypted backup');
      }
    }
  }

  /// Derives a 256-bit key in a background [Isolate] using PBKDF2-HMAC-SHA256.
  static Future<Uint8List> _deriveKey(
      String password, Uint8List salt, int iterations) {
    return Isolate.run(() => _pbkdf2(password, salt, iterations, _keyLen));
  }

  /// Pure-Dart PBKDF2-HMAC-SHA256 — safe in any Dart isolate.
  ///
  /// Uses a rolling-XOR accumulator so memory usage is O(32 bytes) per block
  /// regardless of iteration count.
  static Uint8List _pbkdf2(
      String password, Uint8List salt, int iterations, int keyLen) {
    final pw = utf8.encode(password);
    final hmac = Hmac(sha256, pw);
    final blocks = (keyLen / 32).ceil();
    final result = Uint8List(blocks * 32);

    for (var b = 1; b <= blocks; b++) {
      // PRF input for block b: salt ∥ INT(b) in big-endian
      final sb = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (b >> 24) & 0xFF
        ..[salt.length + 1] = (b >> 16) & 0xFF
        ..[salt.length + 2] = (b >> 8) & 0xFF
        ..[salt.length + 3] = b & 0xFF;

      var u = Uint8List.fromList(hmac.convert(sb).bytes); // U_1
      final t = Uint8List.fromList(u); // T_b starts as U_1

      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < u.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.setRange((b - 1) * 32, b * 32, t);
    }
    return result.sublist(0, keyLen);
  }

  static Uint8List _secureRandom(int len) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(len, (_) => rng.nextInt(256)));
  }

  static Uint8List _be32(int v) => Uint8List(4)
    ..[0] = (v >> 24) & 0xFF
    ..[1] = (v >> 16) & 0xFF
    ..[2] = (v >> 8) & 0xFF
    ..[3] = v & 0xFF;

  static int _rd32(Uint8List d, int o) =>
      (d[o] << 24) | (d[o + 1] << 16) | (d[o + 2] << 8) | d[o + 3];
}
