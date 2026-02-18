import 'dart:convert';

import 'package:local_auth/local_auth.dart';

import 'security_service.dart';
import 'storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService;
  final SecurityService _securityService;

  AuthService(this._storageService, {SecurityService? securityService})
      : _securityService = securityService ?? SecurityService();

  // --- Biometric ---

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Uygulamaya erismek icin kimliginizi dogrulayin',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // --- Password (PBKDF2-HMAC-SHA512) ---

  Future<void> setPassword(String password) async {
    final salt = _securityService.generateSalt();
    final hash = _securityService.hashPassword(password, salt);
    final saltBase64 = base64Url.encode(salt);

    final settings = _storageService.getSettings();
    settings.passwordHash = hash;
    settings.passwordSalt = saltBase64;
    await _storageService.updateSettings(settings);
  }

  Future<bool> verifyPassword(String password) async {
    final settings = _storageService.getSettings();
    if (settings.passwordHash == null || settings.passwordSalt == null) {
      return false;
    }

    // Check lockout first
    if (await _securityService.isLockedOut()) {
      return false;
    }

    final salt = base64Url.decode(settings.passwordSalt!);
    final isValid = _securityService.verifyPassword(
      password,
      settings.passwordHash!,
      salt,
    );

    if (isValid) {
      await _securityService.resetFailedAttempts();
      await _securityService.recordActivity();
    } else {
      await _securityService.recordFailedAttempt();

      // Check if max attempts reached and wipe is enabled
      final failedAttempts = await _securityService.getFailedAttempts();
      if (settings.wipeOnMaxAttempts &&
          failedAttempts >= settings.maxFailedAttempts) {
        await _storageService.clearAllData();
        await _securityService.clearSecurityState();
      }
    }

    return isValid;
  }

  Future<void> removePassword() async {
    final settings = _storageService.getSettings();
    settings.passwordHash = null;
    settings.passwordSalt = null;
    settings.useBiometric = false;
    await _storageService.updateSettings(settings);
  }

  bool hasPassword() {
    final settings = _storageService.getSettings();
    return settings.passwordHash != null && settings.passwordSalt != null;
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

  // --- Lockout Info ---

  Future<bool> isLockedOut() => _securityService.isLockedOut();

  Future<Duration?> getRemainingLockout() =>
      _securityService.getRemainingLockout();

  Future<int> getFailedAttempts() => _securityService.getFailedAttempts();

  // --- Activity ---

  Future<void> recordActivity() => _securityService.recordActivity();

  Future<bool> hasTimedOut() async {
    final settings = _storageService.getSettings();
    return _securityService.hasTimedOut(settings.autoLockSeconds);
  }

  // --- Clipboard ---

  Future<void> secureCopy(String text) async {
    final settings = _storageService.getSettings();
    await _securityService.copyToClipboardSecure(
      text,
      settings.clipboardClearSeconds,
    );
  }

  // --- Full Auth Flow ---

  Future<bool> authenticate() async {
    final settings = _storageService.getSettings();

    if (!settings.requireAuthOnLaunch) {
      return true;
    }

    if (settings.useBiometric) {
      final canUseBiometric = await isBiometricAvailable();
      if (canUseBiometric) {
        final result = await authenticateWithBiometric();
        if (result) {
          await _securityService.recordActivity();
          return true;
        }
      }
    }

    return false;
  }
}
