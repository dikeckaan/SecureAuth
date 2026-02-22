import 'dart:io';

import 'package:flutter/services.dart';

import '../models/account_model.dart';
import 'totp_service.dart';

/// Sends real-time OTP codes (never raw secrets) to the Apple Watch via
/// WatchConnectivity on iOS. All calls are no-ops on non-iOS platforms.
class WatchService {
  static const _channel = MethodChannel('com.secureauth/watch');

  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;
  WatchService._internal();

  /// Pushes current OTP codes for all [accounts] to the Watch.
  /// Called periodically from HomeScreen and on account changes.
  Future<void> sendAccounts(
    List<AccountModel> accounts,
    TOTPService totpService, {
    bool isAuthenticated = true,
  }) async {
    if (!Platform.isIOS) return;
    try {
      final accountData = accounts.map((account) {
        final code = totpService.generateCode(account);
        final formattedCode =
            account.isSteam ? code : totpService.formatCode(code);
        final remaining = account.isHotp
            ? 0
            : totpService.getRemainingSeconds(account.period);
        final progress = account.isHotp
            ? 1.0
            : totpService.getProgress(account.period);

        return <String, dynamic>{
          'id': account.id,
          'issuer': account.issuer,
          'name': account.name,
          'code': formattedCode,
          'remainingSeconds': remaining,
          'period': account.period,
          'type': account.type,
          'progress': progress,
        };
      }).toList();

      await _channel.invokeMethod<void>('updateWatchContext', {
        'accounts': accountData,
        'isAuthenticated': isAuthenticated,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      // Watch connectivity errors are non-critical; silently ignore.
    }
  }

  /// Notifies the Watch that the iPhone app is locked or in background.
  /// The Watch will show "Open SecureAuth on iPhone" in response.
  Future<void> sendLocked() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod<void>('updateWatchContext', {
        'accounts': <Map<String, dynamic>>[],
        'isAuthenticated': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }
}
