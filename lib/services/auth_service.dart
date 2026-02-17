import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService;

  AuthService(this._storageService);

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Uygulamaya erişmek için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  bool verifyPassword(String password) {
    final settings = _storageService.getSettings();
    if (settings.passwordHash == null) {
      return false;
    }
    return hashPassword(password) == settings.passwordHash;
  }

  Future<void> setPassword(String password) async {
    final settings = _storageService.getSettings();
    settings.passwordHash = hashPassword(password);
    await _storageService.updateSettings(settings);
  }

  Future<void> removePassword() async {
    final settings = _storageService.getSettings();
    settings.passwordHash = null;
    settings.useBiometric = false;
    await _storageService.updateSettings(settings);
  }

  bool hasPassword() {
    final settings = _storageService.getSettings();
    return settings.passwordHash != null;
  }

  Future<void> enableBiometric(bool enable) async {
    final settings = _storageService.getSettings();
    settings.useBiometric = enable;
    await _storageService.updateSettings(settings);
  }

  bool isBiometricEnabled() {
    final settings = _storageService.getSettings();
    return settings.useBiometric;
  }

  Future<bool> authenticate() async {
    final settings = _storageService.getSettings();

    if (!settings.requireAuthOnLaunch) {
      return true;
    }

    if (settings.useBiometric) {
      final canUseBiometric = await isBiometricAvailable();
      if (canUseBiometric) {
        return await authenticateWithBiometric();
      }
    }

    return false;
  }
}
