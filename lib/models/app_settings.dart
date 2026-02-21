import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool useBiometric;

  @HiveField(1)
  bool requireAuthOnLaunch;

  @HiveField(2)
  String? passwordHash;

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

  /// 0 = system, 1 = light, 2 = dark
  @HiveField(10)
  int themePreference;

  AppSettings({
    this.useBiometric = false,
    this.requireAuthOnLaunch = true,
    this.passwordHash,
    this.isDarkMode = false,
    this.autoLockSeconds = 60,
    this.clipboardClearSeconds = 30,
    this.maxFailedAttempts = 10,
    this.wipeOnMaxAttempts = false,
    this.passwordSalt,
    this.languageCode,
    this.themePreference = 0,
  });
}
