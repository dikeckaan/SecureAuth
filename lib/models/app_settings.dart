import 'package:hive/hive.dart';

import '../utils/constants.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool useBiometric;

  @HiveField(1)
  bool requireAuthOnLaunch;

  @HiveField(2)
  String? passwordHash;

  /// @deprecated — replaced by [themePreference] (HiveField 10).
  /// Kept for Hive binary compatibility.
  @HiveField(3)
  bool isDarkMode;

  @HiveField(4)
  int autoLockSeconds;

  @HiveField(5)
  int clipboardClearSeconds;

  @HiveField(6)
  int maxFailedAttempts;

  @HiveField(7)
  bool wipeOnMaxAttempts;

  @HiveField(8)
  String? passwordSalt;

  @HiveField(9)
  String? languageCode;

  /// 0 = system, 1 = light, 2 = dark (normal), 3 = pure dark (AMOLED)
  @HiveField(10)
  int themePreference;

  /// 0-7 accent color index (default 0 = Indigo), -1 = custom
  @HiveField(11)
  int accentColorIndex;

  /// Hex string for custom primary color, e.g. "FF4F46E5"
  @HiveField(12)
  String? customPrimaryColor;

  /// Hex string for custom secondary color
  @HiveField(13)
  String? customSecondaryColor;

  /// Whether to auto-clear clipboard after copying a code (default: true)
  @HiveField(14)
  bool clearClipboard;

  /// Ordered list of account IDs (null = alphabetical)
  @HiveField(15)
  List<String>? accountOrder;

  /// Whether Steam Guard token type is visible in Add Account (experimental)
  @HiveField(16)
  bool steamGuardEnabled;

  /// KDF algorithm used for passwordHash.
  /// null or 'pbkdf2' = legacy PBKDF2-SHA512.
  /// 'argon2id' = Argon2id (m=32768, t=3, p=1).
  @HiveField(17)
  String? hashVersion;

  /// Whether to block screenshots and app-switcher preview (Android FLAG_SECURE).
  @HiveField(18)
  bool screenProtection;

  /// Whether security audit logging is enabled (default: true)
  @HiveField(19)
  bool auditLoggingEnabled;

  /// Whether clock tamper detection is enabled (default: true)
  @HiveField(20)
  bool tamperDetectionEnabled;

  /// How many days to retain log entries before automatic cleanup (default: 30)
  @HiveField(21)
  int logRetentionDays;

  AppSettings({
    this.useBiometric = false,
    this.requireAuthOnLaunch = true,
    this.passwordHash,
    this.isDarkMode = false,
    this.autoLockSeconds = AppConstants.defaultAutoLockSeconds,
    this.clipboardClearSeconds = AppConstants.defaultClipboardClearSeconds,
    this.maxFailedAttempts = AppConstants.defaultMaxFailedAttempts,
    this.wipeOnMaxAttempts = false,
    this.passwordSalt,
    this.languageCode,
    this.themePreference = 0,
    this.accentColorIndex = 0,
    this.customPrimaryColor,
    this.customSecondaryColor,
    this.clearClipboard = true,
    this.accountOrder,
    this.steamGuardEnabled = false,
    this.hashVersion,
    this.screenProtection = true,
    this.auditLoggingEnabled = true,
    this.tamperDetectionEnabled = true,
    this.logRetentionDays = 30,
  });
}
