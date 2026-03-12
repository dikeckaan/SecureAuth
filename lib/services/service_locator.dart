import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_service.dart';
import 'logger_service.dart';
import 'security_service.dart';
import 'storage_service.dart';
import 'tamper_detection_service.dart';
import 'totp_service.dart';

/// Lightweight service locator for dependency injection.
///
/// Centralizes service creation and wiring so that:
/// - Services can be swapped for testing (via [overrideForTesting])
/// - Lifecycle is explicit (init → use → dispose)
/// - No external package dependency required
///
/// Usage:
///   await ServiceLocator.instance.init();
///   final auth = ServiceLocator.instance.authService;
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ─── Service instances ───────────────────────────────────────────────────

  late final LoggerService _loggerService;
  late final SecurityService _securityService;
  late final StorageService _storageService;
  late final AuthService _authService;
  late final TOTPService _totpService;
  late final TamperDetectionService _tamperDetectionService;

  LoggerService get loggerService => _loggerService;
  SecurityService get securityService => _securityService;
  StorageService get storageService => _storageService;
  AuthService get authService => _authService;
  TOTPService get totpService => _totpService;
  TamperDetectionService get tamperDetectionService => _tamperDetectionService;

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Initializes all services in dependency order.
  ///
  /// Must be called once at app startup (typically in main.dart).
  Future<void> init({FlutterSecureStorage? secureStorage}) async {
    if (_initialized) return;

    _loggerService = LoggerService.instance;

    _securityService = SecurityService(secureStorage: secureStorage);

    _storageService = StorageService();
    await _storageService.init();

    _authService = AuthService(
      _storageService,
      securityService: _securityService,
    );

    _totpService = TOTPService();

    _tamperDetectionService = TamperDetectionService();

    _initialized = true;
    _loggerService.info('app', 'ServiceLocator initialized');
  }

  // ─── Testing Support ─────────────────────────────────────────────────────

  /// Allows overriding individual services for testing.
  ///
  /// Call this INSTEAD of [init] in test setup:
  /// ```dart
  /// ServiceLocator.instance.overrideForTesting(
  ///   securityService: mockSecurity,
  ///   storageService: mockStorage,
  /// );
  /// ```
  void overrideForTesting({
    LoggerService? loggerService,
    SecurityService? securityService,
    StorageService? storageService,
    AuthService? authService,
    TOTPService? totpService,
    TamperDetectionService? tamperDetectionService,
  }) {
    _loggerService = loggerService ?? LoggerService.instance;
    if (securityService != null) _securityService = securityService;
    if (storageService != null) _storageService = storageService;
    if (authService != null) _authService = authService;
    if (totpService != null) _totpService = totpService;
    if (tamperDetectionService != null)
      _tamperDetectionService = tamperDetectionService;
    _initialized = true;
  }

  /// Resets the locator to uninitialized state. For testing only.
  void reset() {
    _initialized = false;
  }
}
