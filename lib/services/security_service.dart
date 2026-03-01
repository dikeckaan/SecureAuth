import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data'; // ignore: unnecessary_import

import 'package:hashlib/hashlib.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';

class SecurityService {
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  static const String _lastActivityKey = 'last_activity';

  final FlutterSecureStorage _secureStorage;

  SecurityService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // --- Argon2id Key Derivation ---

  Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(AppConstants.saltLength, (_) => random.nextInt(256)),
    );
  }

  Future<String> hashPassword(String password, Uint8List salt) async {
    final derived = await Isolate.run(
      () => _argon2id(password: password, salt: salt),
    );
    return base64Url.encode(derived);
  }

  Future<bool> verifyPassword(
      String password, String storedHash, Uint8List salt) async {
    final computedHash = await hashPassword(password, salt);
    return _constantTimeEquals(computedHash, storedHash);
  }

  /// Derives a 256-bit key using Argon2id.
  /// Safe to run inside a Dart Isolate (pure Dart via hashlib).
  static Uint8List _argon2id({
    required String password,
    required Uint8List salt,
  }) {
    final hash = Argon2(
      type: Argon2Type.argon2id,
      memorySizeKB: 32768,
      iterations: 3,
      parallelism: 1,
      hashLength: 32,
      salt: salt,
    ).convert(utf8.encode(password));
    return Uint8List.fromList(hash.bytes);
  }

  /// Constant-time string comparison to prevent timing attacks
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  // --- Brute Force Protection ---

  Future<int> getFailedAttempts() async {
    final value = await _secureStorage.read(key: _failedAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  Future<void> recordFailedAttempt() async {
    final current = await getFailedAttempts();
    final newCount = current + 1;
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: newCount.toString(),
    );

    // Exponential backoff lockout: 30s, 1m, 2m, 4m, 8m...
    if (newCount >= 3) {
      final lockoutSeconds = 30 * pow(2, newCount - 3).toInt();
      final lockoutUntil = DateTime.now()
          .add(Duration(seconds: lockoutSeconds))
          .millisecondsSinceEpoch;
      await _secureStorage.write(
        key: _lockoutUntilKey,
        value: lockoutUntil.toString(),
      );
    }
  }

  Future<void> resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutUntilKey);
  }

  Future<bool> isLockedOut() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return false;

    final lockoutUntil = int.tryParse(lockoutStr) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < lockoutUntil) {
      return true;
    }

    await _secureStorage.delete(key: _lockoutUntilKey);
    return false;
  }

  Future<Duration?> getRemainingLockout() async {
    final lockoutStr = await _secureStorage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return null;

    final lockoutUntil = int.tryParse(lockoutStr) ?? 0;
    final remaining = lockoutUntil - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      await _secureStorage.delete(key: _lockoutUntilKey);
      return null;
    }

    return Duration(milliseconds: remaining);
  }

  // --- Clipboard Security ---

  /// Copies [text] to clipboard.  If [clearEnabled] is true, clears it after
  /// [clearAfterSeconds].  On Windows, also marks the entry as excluded from
  /// clipboard history so it never appears in Win+V history.
  Future<void> copyToClipboardSecure(
    String text,
    int clearAfterSeconds, {
    bool clearEnabled = true,
    int? period,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));

    // Exclude from Windows clipboard history immediately after setting data.
    if (Platform.isWindows) {
      _excludeFromWindowsClipboardHistory();
    }

    if (!clearEnabled) return;

    final int delaySeconds;
    if (period != null && period > 0) {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remaining = period - (nowSeconds % period);
      delaySeconds = remaining > 0 ? remaining : period;
    } else {
      delaySeconds = clearAfterSeconds;
    }

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (Platform.isWindows) {
        // Use Win32 EmptyClipboard() so we don't add a blank entry to history.
        _clearWindowsClipboard();
      } else {
        Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  /// Adds the "ExcludeClipboardContentFromMonitorProcessing" format to the
  /// current clipboard content.  Windows reads this flag and omits the entry
  /// from clipboard history (Win+V) — the data is still available for paste.
  ///
  /// Must be called AFTER [Clipboard.setData] so the text is already in the
  /// clipboard; this just appends the exclusion marker in the same session.
  static void _excludeFromWindowsClipboardHistory() {
    try {
      final user32 = DynamicLibrary.open('user32.dll');

      final openClipboard = user32.lookupFunction<
          Int32 Function(IntPtr), int Function(int)>('OpenClipboard');
      final closeClipboard = user32.lookupFunction<
          Int32 Function(), int Function()>('CloseClipboard');
      final registerFormat = user32.lookupFunction<
          Uint32 Function(Pointer<Utf16>),
          int Function(Pointer<Utf16>)>('RegisterClipboardFormatW');
      final setClipboardData = user32.lookupFunction<
          IntPtr Function(Uint32, IntPtr),
          int Function(int, int)>('SetClipboardData');

      if (openClipboard(0) == 0) return;

      // Allocate the format name as a native UTF-16 (wide) string.
      final name =
          'ExcludeClipboardContentFromMonitorProcessing'.toNativeUtf16();
      try {
        final formatId = registerFormat(name);
        if (formatId != 0) {
          // NULL data handle — Windows only needs the format to be present.
          setClipboardData(formatId, 0);
        }
      } finally {
        malloc.free(name);
        closeClipboard();
      }
    } catch (_) {
      // Non-fatal: clipboard still works; history exclusion just won't apply.
    }
  }

  /// Calls Win32 EmptyClipboard() via FFI so the clipboard is cleared without
  /// adding a new (empty) entry to Windows clipboard history.
  static void _clearWindowsClipboard() {
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final openClipboard = user32.lookupFunction<
          Int32 Function(IntPtr), int Function(int)>('OpenClipboard');
      final emptyClipboard = user32.lookupFunction<
          Int32 Function(), int Function()>('EmptyClipboard');
      final closeClipboard = user32.lookupFunction<
          Int32 Function(), int Function()>('CloseClipboard');

      if (openClipboard(0) != 0) {
        emptyClipboard();
        closeClipboard();
      }
    } catch (_) {
      // Fallback: at least overwrite with empty string if FFI fails.
      Clipboard.setData(const ClipboardData(text: ''));
    }
  }

  // --- Activity Tracking ---

  Future<void> recordActivity() async {
    await _secureStorage.write(
      key: _lastActivityKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> hasTimedOut(int timeoutSeconds) async {
    final lastStr = await _secureStorage.read(key: _lastActivityKey);
    if (lastStr == null) return true;

    final lastActivity = int.tryParse(lastStr) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastActivity;
    return elapsed > timeoutSeconds * 1000;
  }

  // --- Data Wipe ---

  Future<void> clearSecurityState() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutUntilKey);
    await _secureStorage.delete(key: _lastActivityKey);
  }

  /// Legacy PBKDF2-SHA512 verifier — used ONLY during one-time migration.
  /// After successful login, the hash is replaced with Argon2id automatically.
  static Future<bool> verifyLegacyPbkdf2(
      String password, String storedHash, Uint8List salt) async {
    final derived = await Isolate.run(
      () => _pbkdf2Legacy(password: password, salt: salt),
    );
    final computed = base64Url.encode(derived);
    if (computed.length != storedHash.length) return false;
    var result = 0;
    for (var i = 0; i < computed.length; i++) {
      result |= computed.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Pure-Dart PBKDF2-HMAC-SHA512 — original algorithm, 100k iterations, 64-byte output.
  /// Used only for migration from legacy hashes.
  static Uint8List _pbkdf2Legacy({
    required String password,
    required Uint8List salt,
  }) {
    final passwordBytes = utf8.encode(password);
    const iterations = 100000;
    const keyLength = 64;
    final digest = PBKDF2(
      HMAC(sha512),
      iterations,
      salt: salt,
      keyLength: keyLength,
    ).convert(passwordBytes);
    return Uint8List.fromList(digest.bytes);
  }
}
