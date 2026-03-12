import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/backup_encryption_service.dart';

/// Integration tests for backup encryption round-trip (encrypt/decrypt).
///
/// All tests are pure unit tests since BackupEncryptionService uses only
/// static methods and standard Dart libraries (no platform channels).
///
/// Run with: `flutter test test/integration/backup_roundtrip_test.dart`
void main() {
  group('Backup Round-Trip Integration', () {
    // ─── Basic Round-Trip ───────────────────────────────────────────────

    test(
      'encrypt → decrypt with same password returns original JSON',
      () async {
        final original = jsonEncode({
          'accounts': [
            {
              'id': 'test-1',
              'issuer': 'GitHub',
              'accountName': 'user@example.com',
              'secret': 'JBSWY3DPEBLW64TMMQ======',
              'type': 'TOTP',
            },
          ],
          'exported_at': '2026-03-12T12:00:00Z',
        });

        const password = 'MyBackupPassword123!';

        final encrypted = await BackupEncryptionService.encryptBackup(
          original,
          password,
        );
        final decrypted = await BackupEncryptionService.decryptBackup(
          encrypted,
          password,
        );

        expect(decrypted, original);
      },
    );

    test('encrypt → decrypt with correct password succeeds', () async {
      final testData = jsonEncode({
        'version': '2.0',
        'accounts': [
          {'id': '1', 'issuer': 'Test', 'accountName': 'test@test.com'},
        ],
      });

      const password = 'CorrectPassword456!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );
      expect(encrypted, isNotEmpty);

      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );
      expect(decrypted, testData);
    });

    test(
      'encrypt → decrypt with wrong password throws FormatException',
      () async {
        final testData = jsonEncode({
          'accounts': [
            {'id': '1', 'issuer': 'Test'},
          ],
        });

        const correctPassword = 'CorrectPassword123!';
        const wrongPassword = 'WrongPassword456!';

        final encrypted = await BackupEncryptionService.encryptBackup(
          testData,
          correctPassword,
        );

        expect(
          () async => await BackupEncryptionService.decryptBackup(
            encrypted,
            wrongPassword,
          ),
          throwsA(isA<FormatException>()),
        );
      },
    );

    // ─── Uniqueness and Randomness ──────────────────────────────────────

    test(
      'two encryptions of same data produce different ciphertexts',
      () async {
        final testData = jsonEncode({'data': 'test content'});
        const password = 'SamePassword123!';

        final encrypted1 = await BackupEncryptionService.encryptBackup(
          testData,
          password,
        );
        final encrypted2 = await BackupEncryptionService.encryptBackup(
          testData,
          password,
        );

        // Different salts and nonces should produce different ciphertexts
        expect(encrypted1, isNot(equals(encrypted2)));
      },
    );

    // ─── Format Structure Verification ──────────────────────────────────

    test('V2 encrypted backup has correct magic bytes and version', () async {
      final testData = jsonEncode({'test': 'data'});
      const password = 'TestPassword123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );

      // V2 magic: 0x53, 0x41, 0x45, 0x4E, 0x43 = "SAENC"
      expect(encrypted[0], 0x53); // S
      expect(encrypted[1], 0x41); // A
      expect(encrypted[2], 0x45); // E
      expect(encrypted[3], 0x4E); // N
      expect(encrypted[4], 0x43); // C

      // Version byte should be 0x02 for V2
      expect(encrypted[5], 0x02);
    });

    test('V2 format structure matches header specification', () async {
      final testData = jsonEncode({'test': 'data'});
      const password = 'StructureTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );

      // V2 header: 5 (magic) + 1 (version) + 32 (salt) + 12 (nonce) = 50 bytes
      expect(
        encrypted.length,
        greaterThanOrEqualTo(50 + 16),
      ); // +16 for GCM tag
    });

    test('isEncryptedBackup detects V2 encrypted backups', () async {
      final testData = jsonEncode({'test': 'data'});
      const password = 'DetectTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );

      expect(BackupEncryptionService.isEncryptedBackup(encrypted), true);
    });

    test('isEncryptedBackup rejects random data', () {
      final randomData = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(BackupEncryptionService.isEncryptedBackup(randomData), false);
    });

    test('isEncryptedBackup rejects truncated magic bytes', () {
      final truncated = Uint8List.fromList([0x53, 0x41, 0x45]); // Incomplete
      expect(BackupEncryptionService.isEncryptedBackup(truncated), false);
    });

    // ─── Tampering Detection ───────────────────────────────────────────

    test('decrypt fails if ciphertext is tampered with', () async {
      final testData = jsonEncode({'accounts': []});
      const password = 'TamperTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );
      final tampered = Uint8List.fromList(encrypted);

      // Flip a bit in the ciphertext (after header)
      tampered[60] ^= 0xFF;

      expect(
        () async =>
            await BackupEncryptionService.decryptBackup(tampered, password),
        throwsA(isA<FormatException>()),
      );
    });

    test('decrypt fails if GCM tag is modified', () async {
      final testData = jsonEncode({'test': 'data'});
      const password = 'TagTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        password,
      );
      final tampered = Uint8List.fromList(encrypted);

      // Flip a bit in the last 16 bytes (GCM tag)
      tampered[tampered.length - 1] ^= 0x01;

      expect(
        () async =>
            await BackupEncryptionService.decryptBackup(tampered, password),
        throwsA(isA<FormatException>()),
      );
    });

    // ─── Large Payload ─────────────────────────────────────────────────

    test('large payload (100KB) encrypt/decrypt round-trip succeeds', () async {
      // Generate 100KB of JSON
      final accounts = List.generate(
        1000,
        (i) => {
          'id': 'acc-$i',
          'issuer': 'Service${i % 100}',
          'accountName': 'user$i@example.com',
          'secret': 'JBSWY3DPEBLW64TMMQ======' * 5,
          'type': i % 2 == 0 ? 'TOTP' : 'HOTP',
        },
      );

      final largeData = jsonEncode({
        'version': '2.0',
        'accounts': accounts,
        'exported_at': '2026-03-12T12:00:00Z',
      });

      const password = 'LargePayloadPassword123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        largeData,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, largeData);
      expect(encrypted.length, greaterThan(100000)); // ~100KB
    });

    // ─── Unicode and Special Characters ─────────────────────────────────

    test('unicode content round-trip preserves characters', () async {
      final unicodeData = jsonEncode({
        'accounts': [
          {
            'issuer': 'GitLab',
            'accountName': 'user@мир.example.com', // Cyrillic
          },
          {
            'issuer': '日本のサービス', // Japanese
            'accountName': '用户@example.com', // Chinese
          },
          {
            'issuer': 'مصر', // Arabic
            'accountName': 'مستخدم@example.com',
          },
          {
            'issuer': '🔐 Secure Bank 🔐', // Emoji
            'accountName': 'user@🏦.example.com',
          },
        ],
      });

      const password = 'UnicodeTest密码123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        unicodeData,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, unicodeData);

      // Verify actual content
      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      final accounts = decoded['accounts'] as List;
      expect(accounts[0]['accountName'], 'user@мир.example.com');
      expect(accounts[1]['issuer'], '日本のサービス');
      expect(accounts[2]['accountName'], 'مستخدم@example.com');
      expect(accounts[3]['issuer'], '🔐 Secure Bank 🔐');
    });

    // ─── Edge Cases ────────────────────────────────────────────────────

    test('empty string encrypt/decrypt round-trip succeeds', () async {
      const emptyData = '';
      const password = 'EmptyTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        emptyData,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, emptyData);
    });

    test('minimal JSON object round-trip succeeds', () async {
      final minimalData = jsonEncode({});
      const password = 'MinimalTest123!';

      final encrypted = await BackupEncryptionService.encryptBackup(
        minimalData,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, minimalData);
      expect(jsonDecode(decrypted), {});
    });

    test('very long password round-trip succeeds', () async {
      final testData = jsonEncode({'test': 'data'});
      final longPassword = 'x' * 500; // 500 character password

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        longPassword,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        longPassword,
      );

      expect(decrypted, testData);
    });

    test('special password characters are preserved correctly', () async {
      final testData = jsonEncode({'test': 'data'});
      const specialPassword = r'!@#$%^&*()_+-=[]{}|;:",.<>?/~`\!@#$%^&*()';

      final encrypted = await BackupEncryptionService.encryptBackup(
        testData,
        specialPassword,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        specialPassword,
      );

      expect(decrypted, testData);
    });

    // ─── Error Cases ───────────────────────────────────────────────────

    test('decrypt throws FormatException for too-small file', () async {
      final tooSmall = Uint8List.fromList([0x53, 0x41]);

      expect(
        () async =>
            await BackupEncryptionService.decryptBackup(tooSmall, 'password'),
        throwsA(isA<FormatException>()),
      );
    });

    test('decrypt throws FormatException for wrong magic bytes', () async {
      final wrongMagic = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);

      expect(
        () async =>
            await BackupEncryptionService.decryptBackup(wrongMagic, 'password'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'decryptBackupSafe returns Result.failure for wrong password',
      () async {
        final testData = jsonEncode({'test': 'data'});
        const correctPassword = 'Correct123!';
        const wrongPassword = 'Wrong456!';

        final encrypted = await BackupEncryptionService.encryptBackup(
          testData,
          correctPassword,
        );

        final result = await BackupEncryptionService.decryptBackupSafe(
          encrypted,
          wrongPassword,
        );

        expect(result.isFailure, true);
        expect(result.error.category.toString(), contains('auth'));
      },
    );

    test('encryptBackupSafe returns Result.success on valid input', () async {
      final testData = jsonEncode({'test': 'data'});
      const password = 'SafeTest123!';

      final result = await BackupEncryptionService.encryptBackupSafe(
        testData,
        password,
      );

      expect(result.isSuccess, true);
      expect(result.value, isA<Uint8List>());
    });

    test(
      'decryptBackupSafe returns Result.success with correct password',
      () async {
        final testData = jsonEncode({'test': 'data'});
        const password = 'SafeTest123!';

        final encrypted = await BackupEncryptionService.encryptBackup(
          testData,
          password,
        );

        final result = await BackupEncryptionService.decryptBackupSafe(
          encrypted,
          password,
        );

        expect(result.isSuccess, true);
        expect(result.value, testData);
      },
    );
  });

  // ─── Notes on V1 Format Testing ─────────────────────────────────────────
  //
  // Legacy V1 format (PBKDF2-SHA256) testing is not included here as it would
  // require constructing valid V1 format binaries. V1 decryption is tested
  // implicitly through the format detection and error handling tests.
  //
  // To add V1 tests, create helper functions that:
  // 1. Generate valid PBKDF2 keys with specific parameters
  // 2. Build proper V1 header: magic + version + iterations + salt + nonce
  // 3. Encrypt with AES-256-GCM
  // 4. Verify decryption produces correct plaintext
  //
  // Example V1 structure:
  //   Offset   Len   Field
  //      0      5    Magic: "SAENC"
  //      5      1    Version: 0x01
  //      6      4    PBKDF2 iterations (big-endian uint32)
  //     10     16    Salt
  //     26     16    AES-GCM nonce
  //     42      *    Ciphertext + GCM tag
}
