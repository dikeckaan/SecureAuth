import 'dart:io';

import 'package:flutter/services.dart';

class ScreenProtectionService {
  static const _channel = MethodChannel('com.kaandikec.secureauth/window');

  /// Sets or clears Android FLAG_SECURE. No-op on non-Android platforms.
  static Future<void> setSecure(bool secure) async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('setSecure', {'secure': secure});
  }
}
