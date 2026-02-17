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

  AppSettings({
    this.useBiometric = false,
    this.requireAuthOnLaunch = true,
    this.passwordHash,
    this.isDarkMode = false,
  });
}
