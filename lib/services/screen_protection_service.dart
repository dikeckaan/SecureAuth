import 'dart:io';

import 'package:flutter/services.dart';

class ScreenProtectionService {
  static const _channel = MethodChannel('com.kaandikec.secureauth/window');

  /// On Android: sets/clears FLAG_SECURE (blocks screenshots, hides in recents).
  /// On iOS: enables/disables blur overlay on app-switch and screenshot detection.
  /// No-op on desktop platforms.
  static Future<void> setSecure(bool secure) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await _channel.invokeMethod<void>('setSecure', {'secure': secure});
  }
}
