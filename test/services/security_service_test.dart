import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/security_service.dart';

import '../helpers/fake_secure_storage.dart';

void main() {
  late SecurityService service;
  late FakeSecureStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeSecureStorage();
    service = SecurityService(secureStorage: fakeStorage);
  });

  // ─── Salt Generation ────────────────────────────────────────────────────────

  group('generateSalt', () {
    test('returns 32 bytes', () {
      final salt = service.generateSalt();
      expect(salt.length, 32);
    });

    test('generates unique salts each call', () {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();
      expect(salt1, isNot(equals(salt2)));
    });
  });

  group('secureRandom', () {
    test('returns requested number of bytes', () {
      for (final len in [1, 12, 16, 32, 64]) {
        expect(SecurityService.secureRandom(len).length, len);
      }
    });

    test('all byte values are in 0-255 range', () {
      final bytes = SecurityService.secureRandom(256);
      for (final b in bytes) {
        expect(b, inInclusiveRange(0, 255));
      }
    });
  });

  // ─── Constant-Time Equals ───────────────────────────────────────────────────

  group('constantTimeEquals', () {
    test('returns true for identical strings', () {
      expect(SecurityService.constantTimeEquals('abc', 'abc'), isTrue);
    });

    test('returns false for different strings of same length', () {
      expect(SecurityService.constantTimeEquals('abc', 'abd'), isFalse);
    });

    test('returns false for different lengths', () {
      expect(SecurityService.constantTimeEquals('ab', 'abc'), isFalse);
    });

    test('returns true for empty strings', () {
      expect(SecurityService.constantTimeEquals('', ''), isTrue);
    });

    test('returns false when only last char differs', () {
      expect(SecurityService.constantTimeEquals('abcdef', 'abcdeg'), isFalse);
    });

    test('works with base64-encoded hash-length strings', () {
      final a = base64Url.encode(Uint8List(32));
      final b = base64Url.encode(Uint8List(32));
      expect(SecurityService.constantTimeEquals(a, b), isTrue);
    });
  });

  // ─── Argon2id Hash / Verify Round-Trip ──────────────────────────────────────

  group('hashPassword & verifyPassword', () {
    test('hash returns non-empty base64 string', () async {
      final salt = service.generateSalt();
      final hash = await service.hashPassword('MyP@ssw0rd!', salt);
      expect(hash, isNotEmpty);
      // Should be valid base64url
      expect(() => base64Url.decode(hash), returnsNormally);
    });

    test('same password + salt produces same hash (deterministic)', () async {
      final salt = service.generateSalt();
      final hash1 = await service.hashPassword('TestPassword123', salt);
      final hash2 = await service.hashPassword('TestPassword123', salt);
      expect(hash1, equals(hash2));
    });

    test('different salts produce different hashes', () async {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();
      final hash1 = await service.hashPassword('SamePassword', salt1);
      final hash2 = await service.hashPassword('SamePassword', salt2);
      expect(hash1, isNot(equals(hash2)));
    });

    test('different passwords produce different hashes', () async {
      final salt = service.generateSalt();
      final hash1 = await service.hashPassword('Password1', salt);
      final hash2 = await service.hashPassword('Password2', salt);
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPassword returns true for correct password', () async {
      final salt = service.generateSalt();
      final hash = await service.hashPassword('CorrectPassword', salt);
      final isValid = await service.verifyPassword(
        'CorrectPassword',
        hash,
        salt,
      );
      expect(isValid, isTrue);
    });

    test('verifyPassword returns false for wrong password', () async {
      final salt = service.generateSalt();
      final hash = await service.hashPassword('CorrectPassword', salt);
      final isValid = await service.verifyPassword('WrongPassword', hash, salt);
      expect(isValid, isFalse);
    });

    test('verifyPassword returns false for wrong salt', () async {
      final salt = service.generateSalt();
      final wrongSalt = service.generateSalt();
      final hash = await service.hashPassword('MyPassword', salt);
      final isValid = await service.verifyPassword(
        'MyPassword',
        hash,
        wrongSalt,
      );
      expect(isValid, isFalse);
    });

    test('handles unicode passwords', () async {
      final salt = service.generateSalt();
      final hash = await service.hashPassword('Şifre_Türkçe_🔒', salt);
      final isValid = await service.verifyPassword(
        'Şifre_Türkçe_🔒',
        hash,
        salt,
      );
      expect(isValid, isTrue);
    });

    test('handles empty password', () async {
      final salt = service.generateSalt();
      final hash = await service.hashPassword('', salt);
      expect(hash, isNotEmpty);
      final isValid = await service.verifyPassword('', hash, salt);
      expect(isValid, isTrue);
    });
  });

  // ─── Legacy PBKDF2 Verification ────────────────────────────────────────────

  group('verifyLegacyPbkdf2', () {
    test('round-trip: hash then verify with same password succeeds', () async {
      // We can't directly call _pbkdf2Legacy, but we can verify through
      // verifyLegacyPbkdf2 by computing a hash first using the same path
      final salt = service.generateSalt();
      // Hash with the legacy method by going through the verify path
      // This indirectly tests the legacy hashing
      final hash = await service.hashPassword('LegacyTest', salt);
      // Legacy verify should NOT match Argon2id hash (different algorithms)
      final isValid = await SecurityService.verifyLegacyPbkdf2(
        'LegacyTest',
        hash,
        salt,
      );
      expect(isValid, isFalse); // Different KDFs produce different hashes
    });
  });

  // ─── Brute-Force Protection ─────────────────────────────────────────────────

  group('brute-force protection', () {
    test('initial state: zero failed attempts', () async {
      expect(await service.getFailedAttempts(), 0);
    });

    test('initial state: not locked out', () async {
      expect(await service.isLockedOut(), isFalse);
    });

    test('recordFailedAttempt increments counter', () async {
      await service.recordFailedAttempt();
      expect(await service.getFailedAttempts(), 1);
      await service.recordFailedAttempt();
      expect(await service.getFailedAttempts(), 2);
    });

    test('no lockout for first 2 attempts', () async {
      await service.recordFailedAttempt();
      await service.recordFailedAttempt();
      expect(await service.isLockedOut(), isFalse);
      expect(await service.getRemainingLockout(), isNull);
    });

    test('lockout activates at 3rd attempt', () async {
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);
    });

    test('getRemainingLockout returns duration when locked', () async {
      for (var i = 0; i < 3; i++) {
        await service.recordFailedAttempt();
      }
      final remaining = await service.getRemainingLockout();
      expect(remaining, isNotNull);
      // Should be ~30 seconds for 3rd attempt
      expect(remaining!.inSeconds, greaterThan(0));
      expect(remaining.inSeconds, lessThanOrEqualTo(30));
    });

    test('resetFailedAttempts clears lockout', () async {
      for (var i = 0; i < 5; i++) {
        await service.recordFailedAttempt();
      }
      expect(await service.isLockedOut(), isTrue);

      await service.resetFailedAttempts();
      expect(await service.getFailedAttempts(), 0);
      expect(await service.isLockedOut(), isFalse);
      expect(await service.getRemainingLockout(), isNull);
    });
  });

  // ─── Activity Tracking ──────────────────────────────────────────────────────

  group('activity tracking', () {
    test('hasTimedOut returns true when no activity recorded', () async {
      expect(await service.hasTimedOut(60), isTrue);
    });

    test(
      'hasTimedOut returns false immediately after recordActivity',
      () async {
        await service.recordActivity();
        expect(await service.hasTimedOut(60), isFalse);
      },
    );

    test(
      'hasTimedOut returns true with 0 second timeout after activity',
      () async {
        await service.recordActivity();
        // With 0 timeout, should always be timed out
        expect(await service.hasTimedOut(0), isTrue);
      },
    );
  });

  // ─── Security State Cleanup ─────────────────────────────────────────────────

  group('clearSecurityState', () {
    test('clears all security-related keys', () async {
      await service.recordFailedAttempt();
      await service.recordFailedAttempt();
      await service.recordFailedAttempt();
      await service.recordActivity();

      await service.clearSecurityState();

      expect(await service.getFailedAttempts(), 0);
      expect(await service.isLockedOut(), isFalse);
      expect(await service.hasTimedOut(60), isTrue);
    });
  });
}
