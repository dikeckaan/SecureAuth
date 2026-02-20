import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';
import 'package:otp/otp.dart';

import '../models/account_model.dart';

class TOTPService {
  /// Steam Guard uses a custom 26-character alphabet
  static const _steamAlphabet = '23456789BCDFGHJKMNPQRTVWXY';

  // ─── Code generation ───────────────────────────────────────────────────────

  /// Dispatches to the correct generator based on [account.type].
  String generateCode(AccountModel account) {
    switch (account.type) {
      case 'hotp':
        return generateHOTP(account);
      case 'steam':
        return generateSteam(account);
      default:
        return generateTOTP(account);
    }
  }

  String generateTOTP(AccountModel account) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return OTP.generateTOTPCodeString(
      account.secret,
      now,
      length: account.digits,
      interval: account.period,
      algorithm: _getAlgorithm(account.algorithm),
      isGoogle: true,
    );
  }

  String generateHOTP(AccountModel account) {
    return OTP.generateHOTPCodeString(
      account.secret,
      account.counter,
      length: account.digits,
      algorithm: _getAlgorithm(account.algorithm),
      isGoogle: true,
    );
  }

  /// Steam Guard: HMAC-SHA1 TOTP but mapped to a 26-char custom alphabet.
  String generateSteam(AccountModel account) {
    try {
      final keyBytes = base32.decode(account.secret.toUpperCase());
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final counter = now ~/ 30; // Steam always uses 30-second window

      // Build 8-byte big-endian counter
      final msg = Uint8List(8);
      var temp = counter;
      for (int i = 7; i >= 0; i--) {
        msg[i] = temp & 0xFF;
        temp >>= 8;
      }

      final hash = Hmac(sha1, keyBytes).convert(msg).bytes;
      final offset = hash[hash.length - 1] & 0x0F;
      int code = ((hash[offset] & 0x7F) << 24) |
          ((hash[offset + 1] & 0xFF) << 16) |
          ((hash[offset + 2] & 0xFF) << 8) |
          (hash[offset + 3] & 0xFF);

      final result = StringBuffer();
      for (int i = 0; i < 5; i++) {
        result.write(_steamAlphabet[code % _steamAlphabet.length]);
        code ~/= _steamAlphabet.length;
      }
      return result.toString();
    } catch (_) {
      return '-----';
    }
  }

  // ─── Timing helpers ────────────────────────────────────────────────────────

  int getRemainingSeconds(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  double getProgress(int period) {
    return getRemainingSeconds(period) / period;
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  bool validateSecret(String secret) {
    if (secret.isEmpty) return false;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      OTP.generateTOTPCodeString(
        secret,
        now,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── OTP Auth URI parser ───────────────────────────────────────────────────

  /// Parses `otpauth://totp/...`, `otpauth://hotp/...`, and
  /// `otpauth://steam/...` URIs into an [AccountModel].
  AccountModel? parseOtpAuthUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      if (parsedUri.scheme != 'otpauth') return null;

      final type = parsedUri.host.toLowerCase();
      if (type != 'totp' && type != 'hotp' && type != 'steam') return null;

      // Parse label (issuer:account or just account)
      final path = Uri.decodeComponent(parsedUri.path.substring(1));
      final colonIdx = path.indexOf(':');
      String issuer = '';
      String name = '';
      if (colonIdx >= 0) {
        issuer = path.substring(0, colonIdx).trim();
        name = path.substring(colonIdx + 1).trim();
      } else {
        name = path.trim();
      }

      final q = parsedUri.queryParameters;
      final secret = q['secret'];
      if (secret == null || secret.isEmpty) return null;

      // Issuer param overrides label prefix when present
      if (q.containsKey('issuer') && q['issuer']!.isNotEmpty) {
        issuer = q['issuer']!;
      }

      int digits = int.tryParse(q['digits'] ?? '') ?? 6;
      int period = int.tryParse(q['period'] ?? '') ?? 30;
      int counter = int.tryParse(q['counter'] ?? '') ?? 0;
      String algorithm = (q['algorithm'] ?? 'SHA1').toUpperCase();

      // Steam enforces its own parameters
      if (type == 'steam') {
        digits = 5;
        period = 30;
        algorithm = 'SHA1';
      }

      return AccountModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.isEmpty ? name : name,
        issuer: issuer.isEmpty ? 'Unknown' : issuer,
        secret: secret.toUpperCase().replaceAll(' ', ''),
        digits: digits,
        period: period,
        algorithm: algorithm,
        createdAt: DateTime.now(),
        type: type,
        counter: counter,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Formatting ────────────────────────────────────────────────────────────

  /// Splits a numeric OTP code in half (e.g. "123456" → "123 456").
  String formatCode(String code) {
    if (code.length <= 3) return code;
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  Algorithm _getAlgorithm(String name) {
    switch (name.toUpperCase()) {
      case 'SHA256':
        return Algorithm.SHA256;
      case 'SHA512':
        return Algorithm.SHA512;
      default:
        return Algorithm.SHA1;
    }
  }
}
