import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

  // --- PBKDF2-HMAC-SHA512 ---

  Uint8List generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(AppConstants.saltLength, (_) => random.nextInt(256)),
    );
  }

  String hashPassword(String password, Uint8List salt) {
    final derived = _pbkdf2(
      password: password,
      salt: salt,
      iterations: AppConstants.pbkdf2Iterations,
      keyLength: AppConstants.derivedKeyLength,
    );
    return base64Url.encode(derived);
  }

  bool verifyPassword(String password, String storedHash, Uint8List salt) {
    final computedHash = hashPassword(password, salt);
    return _constantTimeEquals(computedHash, storedHash);
  }

  Uint8List _pbkdf2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = utf8.encode(password);
    const hashLength = 64; // SHA-512 output = 64 bytes
    final numBlocks = (keyLength + hashLength - 1) ~/ hashLength;
    final dk = <int>[];

    for (var blockNum = 1; blockNum <= numBlocks; blockNum++) {
      final blockBytes = ByteData(4)..setUint32(0, blockNum, Endian.big);
      final saltBlock = Uint8List.fromList([
        ...salt,
        ...blockBytes.buffer.asUint8List(),
      ]);

      final hmac = Hmac(sha512, passwordBytes);
      var u = hmac.convert(saltBlock).bytes;
      final t = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = Hmac(sha512, passwordBytes).convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }

      dk.addAll(t);
    }

    return Uint8List.fromList(dk.sublist(0, keyLength));
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

  Future<void> copyToClipboardSecure(String text, int clearAfterSeconds) async {
    await Clipboard.setData(ClipboardData(text: text));

    Future.delayed(Duration(seconds: clearAfterSeconds), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
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
}
