import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/backup_encryption_service.dart';

void main() {
  // ─── Round-Trip Encryption/Decryption ──────────────────────────────────────

  group('encrypt / decrypt round-trip', () {
    test('encrypts and decrypts simple JSON', () async {
      const json = '{"accounts":[],"version":"2.0"}';
      const password = 'TestPassword123';

      final encrypted = await BackupEncryptionService.encryptBackup(
        json,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, equals(json));
    });

    test('encrypts and decrypts complex JSON with unicode', () async {
      final jsonData = jsonEncode({
        'accounts': [
          {
            'id': '1',
            'name': 'user@gmail.com',
            'issuer': 'Google',
            'secret': 'JBSWY3DPEHPK3PXP',
            'digits': 6,
            'period': 30,
            'algorithm': 'SHA1',
            'type': 'totp',
          },
          {
            'id': '2',
            'name': 'Türkçe_Hesap',
            'issuer': 'Tëst',
            'secret': 'ABCDEFGHIJKLMNOP',
            'digits': 8,
            'period': 60,
            'algorithm': 'SHA256',
            'type': 'totp',
          },
        ],
        'version': '2.0',
        'exported_at': '2026-01-01T00:00:00.000',
        'count': 2,
      });
      const password = 'Güçlü_Şifre_🔒';

      final encrypted = await BackupEncryptionService.encryptBackup(
        jsonData,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, equals(jsonData));
    });

    test('wrong password throws FormatException', () async {
      const json = '{"test": true}';
      final encrypted = await BackupEncryptionService.encryptBackup(
        json,
        'correct',
      );

      expect(
        () => BackupEncryptionService.decryptBackup(encrypted, 'wrong'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'each encryption produces different output (unique salt/nonce)',
      () async {
        const json = '{"test": true}';
        const password = 'SamePassword';

        final encrypted1 = await BackupEncryptionService.encryptBackup(
          json,
          password,
        );
        final encrypted2 = await BackupEncryptionService.encryptBackup(
          json,
          password,
        );

        // Encrypted outputs should differ due to random salt + nonce
        expect(encrypted1, isNot(equals(encrypted2)));

        // But both should decrypt to the same plaintext
        final decrypted1 = await BackupEncryptionService.decryptBackup(
          encrypted1,
          password,
        );
        final decrypted2 = await BackupEncryptionService.decryptBackup(
          encrypted2,
          password,
        );
        expect(decrypted1, equals(json));
        expect(decrypted2, equals(json));
      },
    );

    test('handles empty JSON string', () async {
      const json = '';
      const password = 'test';

      final encrypted = await BackupEncryptionService.encryptBackup(
        json,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, equals(json));
    });

    test('handles large payload', () async {
      // ~50KB of JSON data
      final accounts = List.generate(
        500,
        (i) => {
          'id': '$i',
          'name': 'user$i@test.com',
          'secret': 'JBSWY3DPEHPK3PXP',
        },
      );
      final json = jsonEncode({'accounts': accounts});
      const password = 'LargePayloadTest';

      final encrypted = await BackupEncryptionService.encryptBackup(
        json,
        password,
      );
      final decrypted = await BackupEncryptionService.decryptBackup(
        encrypted,
        password,
      );

      expect(decrypted, equals(json));
    });
  });

  // ─── V2 Format Validation ──────────────────────────────────────────────────

  group('V2 format structure', () {
    test('encrypted output starts with SAENC magic bytes', () async {
      final encrypted = await BackupEncryptionService.encryptBackup(
        '{"test":true}',
        'pass',
      );

      // "SAENC" = [0x53, 0x41, 0x45, 0x4E, 0x43]
      expect(encrypted[0], 0x53); // S
      expect(encrypted[1], 0x41); // A
      expect(encrypted[2], 0x45); // E
      expect(encrypted[3], 0x4E); // N
      expect(encrypted[4], 0x43); // C
    });

    test('encrypted output has version byte 0x02', () async {
      final encrypted = await BackupEncryptionService.encryptBackup(
        '{"test":true}',
        'pass',
      );
      expect(encrypted[5], 0x02);
    });

    test('encrypted output has minimum expected length', () async {
      final encrypted = await BackupEncryptionService.encryptBackup('', 'pass');
      // Header: 5 magic + 1 version + 32 salt + 12 nonce = 50
      // Minimum ciphertext with GCM tag: at least 16 bytes
      expect(encrypted.length, greaterThanOrEqualTo(66));
    });
  });

  // ─── isEncryptedBackup ─────────────────────────────────────────────────────

  group('isEncryptedBackup', () {
    test('returns true for valid encrypted data', () async {
      final encrypted = await BackupEncryptionService.encryptBackup(
        '{"test":true}',
        'pass',
      );
      expect(BackupEncryptionService.isEncryptedBackup(encrypted), isTrue);
    });

    test('returns false for plain JSON', () {
      final plainJson = Uint8List.fromList(utf8.encode('{"test":true}'));
      expect(BackupEncryptionService.isEncryptedBackup(plainJson), isFalse);
    });

    test('returns false for empty data', () {
      expect(BackupEncryptionService.isEncryptedBackup(Uint8List(0)), isFalse);
    });

    test('returns false for data shorter than magic', () {
      expect(
        BackupEncryptionService.isEncryptedBackup(
          Uint8List.fromList([0x53, 0x41]),
        ),
        isFalse,
      );
    });

    test(
      'returns true for data that starts with SAENC (even if incomplete)',
      () {
        final fakeData = Uint8List.fromList([
          0x53,
          0x41,
          0x45,
          0x4E,
          0x43,
          0x00,
        ]);
        expect(BackupEncryptionService.isEncryptedBackup(fakeData), isTrue);
      },
    );
  });

  // ─── Error Handling ────────────────────────────────────────────────────────

  group('decryptBackup error handling', () {
    test('throws FormatException for data too small', () {
      expect(
        () => BackupEncryptionService.decryptBackup(
          Uint8List.fromList([0x53]),
          'pass',
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('too small'),
          ),
        ),
      );
    });

    test('throws FormatException for wrong magic bytes', () {
      final badMagic = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x02,
        ...List.filled(60, 0),
      ]);
      expect(
        () => BackupEncryptionService.decryptBackup(badMagic, 'pass'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Not a SecureAuth'),
          ),
        ),
      );
    });

    test('throws FormatException for unknown version', () {
      // Valid magic but version 0xFF
      final unknownVersion = Uint8List.fromList([
        0x53,
        0x41,
        0x45,
        0x4E,
        0x43,
        0xFF,
        ...List.filled(60, 0),
      ]);
      expect(
        () => BackupEncryptionService.decryptBackup(unknownVersion, 'pass'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unknown backup format version'),
          ),
        ),
      );
    });

    test('throws FormatException for truncated V2 file', () {
      // Valid magic + version but not enough data
      final truncated = Uint8List.fromList([
        0x53,
        0x41,
        0x45,
        0x4E,
        0x43,
        0x02,
        ...List.filled(10, 0),
      ]);
      expect(
        () => BackupEncryptionService.decryptBackup(truncated, 'pass'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for tampered ciphertext', () async {
      final encrypted = await BackupEncryptionService.encryptBackup(
        '{"test":true}',
        'pass',
      );

      // Tamper with the last byte (part of GCM tag)
      final tampered = Uint8List.fromList(encrypted);
      tampered[tampered.length - 1] ^= 0xFF;

      expect(
        () => BackupEncryptionService.decryptBackup(tampered, 'pass'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── File Extension ────────────────────────────────────────────────────────

  group('constants', () {
    test('fileExtension is saenc', () {
      expect(BackupEncryptionService.fileExtension, 'saenc');
    });
  });
}
