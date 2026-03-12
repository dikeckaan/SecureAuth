import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger_service.dart';

/// Detects clock manipulation and triggers security lockdown.
///
/// Strategy:
/// - Stores `firstLaunchTimestamp` on very first app launch (immutable)
/// - Updates `lastKnownTimestamp` on every app resume/launch
/// - On each check: if current time < lastKnownTimestamp (with 60s tolerance
///   for minor drift), the clock has been rolled back → TAMPER DETECTED
/// - Also checks: if current time < firstLaunchTimestamp → impossible → TAMPER
/// - Once tampered flag is set, it can ONLY be cleared by entering the
///   correct password (not biometric) + a confirmation dialog
class TamperDetectionService {
  static const String _firstLaunchKey = 'first_launch_timestamp';
  static const String _lastKnownTimeKey = 'last_known_timestamp';
  static const String _tamperDetectedKey = 'tamper_detected';
  static const String _bootCountKey = 'boot_count';

  /// Allow 60 seconds of clock drift (NTP sync, DST transition, etc.)
  static const int _toleranceMs = 60 * 1000;

  final FlutterSecureStorage _secureStorage;
  static final _log = LoggerService.instance;

  TamperDetectionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Call on every app launch / resume. Returns true if tamper is detected.
  Future<bool> checkIntegrity() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Initialize first launch timestamp if not set
    final firstLaunchStr = await _secureStorage.read(key: _firstLaunchKey);
    if (firstLaunchStr == null) {
      await _secureStorage.write(key: _firstLaunchKey, value: now.toString());
      await _secureStorage.write(key: _lastKnownTimeKey, value: now.toString());
      await _secureStorage.write(key: _bootCountKey, value: '1');
      _log.security('tamper', 'First launch recorded', {'timestamp': now});
      return false;
    }

    // Check if already flagged
    final tamperFlag = await _secureStorage.read(key: _tamperDetectedKey);
    if (tamperFlag == 'true') {
      _log.security('tamper', 'Previously detected tamper flag still active');
      return true;
    }

    final firstLaunch = int.tryParse(firstLaunchStr) ?? 0;
    final lastKnownStr = await _secureStorage.read(key: _lastKnownTimeKey);
    final lastKnown = int.tryParse(lastKnownStr ?? '0') ?? 0;

    // Increment boot count
    final bootCountStr = await _secureStorage.read(key: _bootCountKey);
    final bootCount = (int.tryParse(bootCountStr ?? '0') ?? 0) + 1;
    await _secureStorage.write(key: _bootCountKey, value: bootCount.toString());

    bool tampered = false;

    // Check 1: Current time before first launch (impossible)
    if (now < firstLaunch - _toleranceMs) {
      _log.security('tamper', 'CLOCK ROLLBACK: current time before first launch', {
        'currentTime': now,
        'firstLaunch': firstLaunch,
        'delta': firstLaunch - now,
      });
      tampered = true;
    }

    // Check 2: Current time before last known time (clock rolled back)
    if (now < lastKnown - _toleranceMs) {
      _log.security('tamper', 'CLOCK ROLLBACK: current time before last known', {
        'currentTime': now,
        'lastKnown': lastKnown,
        'delta': lastKnown - now,
      });
      tampered = true;
    }

    if (tampered) {
      await _secureStorage.write(key: _tamperDetectedKey, value: 'true');
      _log.security('tamper', 'TAMPER LOCKDOWN ACTIVATED', {
        'bootCount': bootCount,
      });
      return true;
    }

    // All good — update last known timestamp
    await _secureStorage.write(key: _lastKnownTimeKey, value: now.toString());
    return false;
  }

  /// Update the last known timestamp. Call this periodically (e.g. every 15s).
  Future<void> recordTimestamp() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _secureStorage.write(key: _lastKnownTimeKey, value: now.toString());
  }

  /// Whether tamper has been previously detected.
  Future<bool> isTampered() async {
    final flag = await _secureStorage.read(key: _tamperDetectedKey);
    return flag == 'true';
  }

  /// Clear the tamper flag. Should ONLY be called after successful
  /// password verification (not biometric).
  Future<void> clearTamperFlag() async {
    await _secureStorage.delete(key: _tamperDetectedKey);
    // Reset the last known timestamp to now
    final now = DateTime.now().millisecondsSinceEpoch;
    await _secureStorage.write(key: _lastKnownTimeKey, value: now.toString());
    _log.security('tamper', 'Tamper flag cleared by authenticated user');
  }

  /// Get diagnostic info for the tamper detection system.
  Future<Map<String, dynamic>> getDiagnostics() async {
    final firstLaunch = await _secureStorage.read(key: _firstLaunchKey);
    final lastKnown = await _secureStorage.read(key: _lastKnownTimeKey);
    final bootCount = await _secureStorage.read(key: _bootCountKey);
    final tampered = await _secureStorage.read(key: _tamperDetectedKey);
    return {
      'firstLaunch': firstLaunch != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(firstLaunch)).toIso8601String()
          : null,
      'lastKnownTime': lastKnown != null
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(lastKnown)).toIso8601String()
          : null,
      'bootCount': int.tryParse(bootCount ?? '0') ?? 0,
      'tamperDetected': tampered == 'true',
      'currentTime': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all tamper detection state. Used during full data wipe.
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _firstLaunchKey);
    await _secureStorage.delete(key: _lastKnownTimeKey);
    await _secureStorage.delete(key: _tamperDetectedKey);
    await _secureStorage.delete(key: _bootCountKey);
  }
}
