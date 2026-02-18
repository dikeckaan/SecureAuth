import 'package:otp/otp.dart';

import '../models/account_model.dart';

class TOTPService {
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

  int getRemainingSeconds(int period) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return period - (now % period);
  }

  double getProgress(int period) {
    final remaining = getRemainingSeconds(period);
    return remaining / period;
  }

  Algorithm _getAlgorithm(String algorithmName) {
    switch (algorithmName.toUpperCase()) {
      case 'SHA256':
        return Algorithm.SHA256;
      case 'SHA512':
        return Algorithm.SHA512;
      case 'SHA1':
      default:
        return Algorithm.SHA1;
    }
  }

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

  AccountModel? parseOtpAuthUri(String uri) {
    try {
      final parsedUri = Uri.parse(uri);

      if (parsedUri.scheme != 'otpauth' || parsedUri.host != 'totp') {
        return null;
      }

      final path = parsedUri.path.substring(1);
      final parts = path.split(':');

      String issuer = '';
      String name = '';

      if (parts.length >= 2) {
        issuer = Uri.decodeComponent(parts[0]);
        name = Uri.decodeComponent(parts.sublist(1).join(':'));
      } else {
        name = Uri.decodeComponent(path);
      }

      final queryParams = parsedUri.queryParameters;
      final secret = queryParams['secret'];

      if (secret == null || secret.isEmpty) {
        return null;
      }

      if (queryParams.containsKey('issuer')) {
        issuer = queryParams['issuer']!;
      }

      return AccountModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        issuer: issuer.isEmpty ? 'Bilinmeyen' : issuer,
        secret: secret.toUpperCase(),
        digits: int.tryParse(queryParams['digits'] ?? '6') ?? 6,
        period: int.tryParse(queryParams['period'] ?? '30') ?? 30,
        algorithm: queryParams['algorithm']?.toUpperCase() ?? 'SHA1',
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  String formatCode(String code) {
    if (code.length <= 3) return code;
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)} ${code.substring(mid)}';
  }
}
