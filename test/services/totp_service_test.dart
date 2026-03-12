import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/models/account_model.dart';
import 'package:secure_auth/services/totp_service.dart';

void main() {
  late TOTPService service;

  setUp(() {
    service = TOTPService();
  });

  // ─── OTP Auth URI Parsing ───────────────────────────────────────────────────

  group('parseOtpAuthUri', () {
    test('parses standard TOTP URI', () {
      const uri =
          'otpauth://totp/Google:user@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google&digits=6&period=30&algorithm=SHA1';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.type, 'totp');
      expect(account.issuer, 'Google');
      expect(account.name, 'user@gmail.com');
      expect(account.secret, 'JBSWY3DPEHPK3PXP');
      expect(account.digits, 6);
      expect(account.period, 30);
      expect(account.algorithm, 'SHA1');
    });

    test('parses HOTP URI with counter', () {
      const uri =
          'otpauth://hotp/Service:account?secret=JBSWY3DPEHPK3PXP&counter=42';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.type, 'hotp');
      expect(account.counter, 42);
    });

    test('parses Steam URI and enforces parameters', () {
      const uri =
          'otpauth://steam/Steam:user?secret=JBSWY3DPEHPK3PXP&digits=8&period=60';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.type, 'steam');
      // Steam enforces specific parameters regardless of URI
      expect(account.digits, 5);
      expect(account.period, 30);
      expect(account.algorithm, 'SHA1');
    });

    test('handles URI with issuer in query parameter overriding label', () {
      const uri =
          'otpauth://totp/LabelIssuer:user?secret=JBSWY3DPEHPK3PXP&issuer=QueryIssuer';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.issuer, 'QueryIssuer');
    });

    test('handles URI without colon in label', () {
      const uri =
          'otpauth://totp/MyAccount?secret=JBSWY3DPEHPK3PXP&issuer=GitHub';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.name, 'MyAccount');
      expect(account.issuer, 'GitHub');
    });

    test('handles URI with only name (no issuer)', () {
      const uri = 'otpauth://totp/user@test.com?secret=JBSWY3DPEHPK3PXP';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.name, 'user@test.com');
      expect(account.issuer, 'Unknown');
    });

    test('applies defaults for missing parameters', () {
      const uri = 'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.digits, 6);
      expect(account.period, 30);
      expect(account.algorithm, 'SHA1');
      expect(account.counter, 0);
    });

    test('supports SHA256 algorithm', () {
      const uri =
          'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.algorithm, 'SHA256');
    });

    test('supports SHA512 algorithm', () {
      const uri =
          'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.algorithm, 'SHA512');
    });

    test('supports 8-digit codes', () {
      const uri = 'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP&digits=8';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.digits, 8);
    });

    test('returns null for non-otpauth scheme', () {
      expect(service.parseOtpAuthUri('https://example.com'), isNull);
    });

    test('returns null for unknown type', () {
      expect(
        service.parseOtpAuthUri(
          'otpauth://unknown/Test?secret=JBSWY3DPEHPK3PXP',
        ),
        isNull,
      );
    });

    test('returns null for missing secret', () {
      expect(service.parseOtpAuthUri('otpauth://totp/Test'), isNull);
    });

    test('returns null for empty secret', () {
      expect(service.parseOtpAuthUri('otpauth://totp/Test?secret='), isNull);
    });

    test('returns null for malformed URI', () {
      expect(service.parseOtpAuthUri('not a uri at all'), isNull);
    });

    test('handles URL-encoded characters in label', () {
      const uri =
          'otpauth://totp/My%20Service:user%40test.com?secret=JBSWY3DPEHPK3PXP';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.issuer, 'My Service');
      expect(account.name, 'user@test.com');
    });

    test('normalizes secret to uppercase without spaces', () {
      const uri = 'otpauth://totp/Test:user?secret=jbswy3dp ehpk3pxp';
      final account = service.parseOtpAuthUri(uri);

      expect(account, isNotNull);
      expect(account!.secret, 'JBSWY3DPEHPK3PXP');
    });
  });

  // ─── Code Generation (Format Validation) ───────────────────────────────────

  group('generateCode dispatch', () {
    final totpAccount = AccountModel(
      id: '1',
      name: 'test',
      issuer: 'Test',
      secret: 'JBSWY3DPEHPK3PXP',
      createdAt: DateTime.now(),
      type: 'totp',
    );

    final hotpAccount = AccountModel(
      id: '2',
      name: 'test',
      issuer: 'Test',
      secret: 'JBSWY3DPEHPK3PXP',
      createdAt: DateTime.now(),
      type: 'hotp',
      counter: 0,
    );

    final steamAccount = AccountModel(
      id: '3',
      name: 'test',
      issuer: 'Steam',
      secret: 'JBSWY3DPEHPK3PXP',
      createdAt: DateTime.now(),
      type: 'steam',
      digits: 5,
    );

    test('TOTP generates 6-digit code', () {
      final code = service.generateCode(totpAccount);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('HOTP generates 6-digit code', () {
      final code = service.generateCode(hotpAccount);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('Steam generates 5-character alphanumeric code', () {
      final code = service.generateCode(steamAccount);
      expect(code.length, 5);
      // Steam uses custom alphabet: 23456789BCDFGHJKMNPQRTVWXY
      for (final ch in code.split('')) {
        expect(
          '23456789BCDFGHJKMNPQRTVWXY'.contains(ch),
          isTrue,
          reason: 'Character "$ch" not in Steam alphabet',
        );
      }
    });

    test('8-digit TOTP account produces 8-digit code', () {
      final account = AccountModel(
        id: '4',
        name: 'test',
        issuer: 'Test',
        secret: 'JBSWY3DPEHPK3PXP',
        createdAt: DateTime.now(),
        type: 'totp',
        digits: 8,
      );
      final code = service.generateCode(account);
      expect(code.length, 8);
    });
  });

  // ─── TOTP Next Code ────────────────────────────────────────────────────────

  group('generateNextCode', () {
    test('generates a code different from current (most of the time)', () {
      final account = AccountModel(
        id: '1',
        name: 'test',
        issuer: 'Test',
        secret: 'JBSWY3DPEHPK3PXP',
        createdAt: DateTime.now(),
        type: 'totp',
      );
      service.generateTOTP(account);
      final next = service.generateNextCode(account);
      // Note: There's a small chance they could be the same, but very unlikely
      // This test verifies the function doesn't throw and returns valid format
      expect(next.length, 6);
      expect(int.tryParse(next), isNotNull);
    });
  });

  // ─── Timing Helpers ─────────────────────────────────────────────────────────

  group('timing helpers', () {
    test('getRemainingSeconds returns value between 1 and period', () {
      final remaining = service.getRemainingSeconds(30);
      expect(remaining, greaterThan(0));
      expect(remaining, lessThanOrEqualTo(30));
    });

    test('getProgress returns value between 0 and 1', () {
      final progress = service.getProgress(30);
      expect(progress, greaterThan(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });

    test('getProgress matches getRemainingSeconds', () {
      const period = 30;
      final remaining = service.getRemainingSeconds(period);
      final progress = service.getProgress(period);
      expect(progress, closeTo(remaining / period, 0.01));
    });
  });

  // ─── Secret Validation ──────────────────────────────────────────────────────

  group('validateSecret', () {
    test('valid base32 secret returns true', () {
      expect(service.validateSecret('JBSWY3DPEHPK3PXP'), isTrue);
    });

    test('empty string returns false', () {
      expect(service.validateSecret(''), isFalse);
    });

    test('invalid base32 returns false', () {
      expect(service.validateSecret('!!!invalid!!!'), isFalse);
    });
  });

  // ─── Code Formatting ───────────────────────────────────────────────────────

  group('formatCode', () {
    test('splits 6-digit code in half', () {
      expect(service.formatCode('123456'), '123 456');
    });

    test('splits 8-digit code in half', () {
      expect(service.formatCode('12345678'), '1234 5678');
    });

    test('handles 4-digit code', () {
      expect(service.formatCode('1234'), '12 34');
    });

    test('returns short codes as-is', () {
      expect(service.formatCode('12'), '12');
      expect(service.formatCode('1'), '1');
    });

    test('returns 3-char codes as-is', () {
      expect(service.formatCode('123'), '123');
    });
  });
}
