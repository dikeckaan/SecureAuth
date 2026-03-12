import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/models/account_model.dart';

void main() {
  // ─── JSON Serialization ────────────────────────────────────────────────────

  group('toJson / fromJson round-trip', () {
    test('round-trips TOTP account correctly', () {
      final original = AccountModel(
        id: 'test-id-123',
        name: 'user@gmail.com',
        issuer: 'Google',
        secret: 'JBSWY3DPEHPK3PXP',
        digits: 6,
        period: 30,
        algorithm: 'SHA1',
        createdAt: DateTime(2026, 1, 15, 10, 30),
        type: 'totp',
        counter: 0,
      );

      final json = original.toJson();
      final restored = AccountModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.issuer, original.issuer);
      expect(restored.secret, original.secret);
      expect(restored.digits, original.digits);
      expect(restored.period, original.period);
      expect(restored.algorithm, original.algorithm);
      expect(restored.createdAt, original.createdAt);
      expect(restored.type, original.type);
      expect(restored.counter, original.counter);
    });

    test('round-trips HOTP account correctly', () {
      final original = AccountModel(
        id: 'hotp-1',
        name: 'hotp-account',
        issuer: 'Service',
        secret: 'ABCDEFGHIJKLMNOP',
        digits: 8,
        period: 0,
        algorithm: 'SHA256',
        createdAt: DateTime(2026, 3, 1),
        type: 'hotp',
        counter: 42,
      );

      final json = original.toJson();
      final restored = AccountModel.fromJson(json);

      expect(restored.type, 'hotp');
      expect(restored.counter, 42);
      expect(restored.digits, 8);
      expect(restored.algorithm, 'SHA256');
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'minimal',
        'name': 'test',
        'issuer': 'Test',
        'secret': 'SECRET',
        'createdAt': '2026-01-01T00:00:00.000',
      };

      final account = AccountModel.fromJson(json);

      expect(account.digits, 6);
      expect(account.period, 30);
      expect(account.algorithm, 'SHA1');
      expect(account.type, 'totp');
      expect(account.counter, 0);
    });
  });

  // ─── OTP Auth URI Generation ───────────────────────────────────────────────

  group('otpAuthUri', () {
    test('generates valid TOTP URI', () {
      final account = AccountModel(
        id: '1',
        name: 'user@test.com',
        issuer: 'GitHub',
        secret: 'JBSWY3DPEHPK3PXP',
        digits: 6,
        period: 30,
        algorithm: 'SHA1',
        createdAt: DateTime.now(),
        type: 'totp',
      );

      final uri = account.otpAuthUri;
      expect(uri, startsWith('otpauth://totp/'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=GitHub'));
      expect(uri, contains('digits=6'));
      expect(uri, contains('period=30'));
      expect(uri, contains('algorithm=SHA1'));
    });

    test('generates valid HOTP URI with counter', () {
      final account = AccountModel(
        id: '1',
        name: 'user',
        issuer: 'Service',
        secret: 'SECRET',
        createdAt: DateTime.now(),
        type: 'hotp',
        counter: 10,
      );

      final uri = account.otpAuthUri;
      expect(uri, startsWith('otpauth://hotp/'));
      expect(uri, contains('counter=10'));
      expect(uri, isNot(contains('period=')));
    });

    test('URL-encodes special characters in issuer and name', () {
      final account = AccountModel(
        id: '1',
        name: 'user name@test',
        issuer: 'My Service',
        secret: 'SECRET',
        createdAt: DateTime.now(),
      );

      final uri = account.otpAuthUri;
      expect(uri, contains('My%20Service'));
      expect(uri, contains('user%20name%40test'));
    });
  });

  // ─── Type Helpers ──────────────────────────────────────────────────────────

  group('type helpers', () {
    test('isTotp returns true for TOTP', () {
      final a = AccountModel(
        id: '1', name: 'a', issuer: 'b', secret: 's',
        createdAt: DateTime.now(), type: 'totp',
      );
      expect(a.isTotp, isTrue);
      expect(a.isHotp, isFalse);
      expect(a.isSteam, isFalse);
    });

    test('isHotp returns true for HOTP', () {
      final a = AccountModel(
        id: '1', name: 'a', issuer: 'b', secret: 's',
        createdAt: DateTime.now(), type: 'hotp',
      );
      expect(a.isTotp, isFalse);
      expect(a.isHotp, isTrue);
      expect(a.isSteam, isFalse);
    });

    test('isSteam returns true for Steam', () {
      final a = AccountModel(
        id: '1', name: 'a', issuer: 'b', secret: 's',
        createdAt: DateTime.now(), type: 'steam',
      );
      expect(a.isTotp, isFalse);
      expect(a.isHotp, isFalse);
      expect(a.isSteam, isTrue);
    });
  });

  // ─── Initials ──────────────────────────────────────────────────────────────

  group('initials', () {
    test('uses first letter of issuer', () {
      final a = AccountModel(
        id: '1', name: 'user', issuer: 'Google', secret: 's',
        createdAt: DateTime.now(),
      );
      expect(a.initials, 'G');
    });

    test('uses first letter of name when issuer is empty', () {
      final a = AccountModel(
        id: '1', name: 'user', issuer: '', secret: 's',
        createdAt: DateTime.now(),
      );
      expect(a.initials, 'U');
    });

    test('returns ? when both are empty', () {
      final a = AccountModel(
        id: '1', name: '', issuer: '', secret: 's',
        createdAt: DateTime.now(),
      );
      expect(a.initials, '?');
    });

    test('uppercases the initial', () {
      final a = AccountModel(
        id: '1', name: 'user', issuer: 'github', secret: 's',
        createdAt: DateTime.now(),
      );
      expect(a.initials, 'G');
    });
  });
}
