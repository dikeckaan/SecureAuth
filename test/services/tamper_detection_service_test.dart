import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/tamper_detection_service.dart';

import '../helpers/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;
  late TamperDetectionService service;

  setUp(() {
    storage = FakeSecureStorage();
    service = TamperDetectionService(secureStorage: storage);
  });

  group('TamperDetectionService', () {
    group('first launch', () {
      test('records first launch timestamp and returns false', () async {
        final result = await service.checkIntegrity();

        expect(result, isFalse);
        expect(storage.store.containsKey('first_launch_timestamp'), isTrue);
        expect(storage.store.containsKey('last_known_timestamp'), isTrue);
        expect(storage.store['boot_count'], equals('1'));
      });

      test('first launch timestamps are consistent', () async {
        await service.checkIntegrity();

        final firstLaunch = int.parse(storage.store['first_launch_timestamp']!);
        final lastKnown = int.parse(storage.store['last_known_timestamp']!);

        // Both should be set to approximately the same time
        expect((firstLaunch - lastKnown).abs(), lessThan(1000));
      });
    });

    group('normal operation', () {
      test('subsequent checks return false when clock moves forward', () async {
        // First launch
        await service.checkIntegrity();

        // Second check — clock naturally moves forward
        final result = await service.checkIntegrity();

        expect(result, isFalse);
        expect(storage.store['boot_count'], equals('2'));
      });

      test('isTampered returns false when no tampering', () async {
        await service.checkIntegrity();

        final tampered = await service.isTampered();
        expect(tampered, isFalse);
      });

      test('boot count increments on each check', () async {
        await service.checkIntegrity();
        await service.checkIntegrity();
        await service.checkIntegrity();

        expect(storage.store['boot_count'], equals('3'));
      });
    });

    group('tamper detection', () {
      test('detects clock rollback before first launch', () async {
        // Simulate a first launch that happened in the "future"
        final futureTime =
            DateTime.now().millisecondsSinceEpoch + 3600000; // +1 hour
        storage.store['first_launch_timestamp'] = futureTime.toString();
        storage.store['last_known_timestamp'] = futureTime.toString();
        storage.store['boot_count'] = '1';

        final result = await service.checkIntegrity();

        expect(result, isTrue);
        expect(storage.store['tamper_detected'], equals('true'));
      });

      test('detects clock rollback before last known time', () async {
        // Simulate normal first launch
        await service.checkIntegrity();

        // Set last_known_timestamp far in the future to simulate rollback
        final futureTime =
            DateTime.now().millisecondsSinceEpoch + 3600000; // +1 hour
        storage.store['last_known_timestamp'] = futureTime.toString();

        final result = await service.checkIntegrity();

        expect(result, isTrue);
        expect(storage.store['tamper_detected'], equals('true'));
      });

      test('returns true on subsequent checks after tamper detected', () async {
        // Trigger tamper
        final futureTime = DateTime.now().millisecondsSinceEpoch + 3600000;
        storage.store['first_launch_timestamp'] = futureTime.toString();
        storage.store['last_known_timestamp'] = futureTime.toString();
        storage.store['boot_count'] = '1';

        await service.checkIntegrity();
        expect(await service.isTampered(), isTrue);

        // Even after time normalizes, flag persists
        final result = await service.checkIntegrity();
        expect(result, isTrue);
      });

      test('tolerates minor clock drift within 60 seconds', () async {
        await service.checkIntegrity();

        // Set last_known_timestamp only 30s in the future (within tolerance)
        final slightFuture =
            DateTime.now().millisecondsSinceEpoch + 30000; // +30s
        storage.store['last_known_timestamp'] = slightFuture.toString();

        final result = await service.checkIntegrity();

        // Should NOT trigger because 30s < 60s tolerance
        expect(result, isFalse);
      });
    });

    group('clearTamperFlag', () {
      test('clears tamper flag and resets last known timestamp', () async {
        // Set tamper flag
        storage.store['tamper_detected'] = 'true';
        storage.store['first_launch_timestamp'] = DateTime.now()
            .millisecondsSinceEpoch
            .toString();

        expect(await service.isTampered(), isTrue);

        await service.clearTamperFlag();

        expect(await service.isTampered(), isFalse);
        // last_known_timestamp should be updated
        expect(storage.store.containsKey('last_known_timestamp'), isTrue);
      });

      test('subsequent check returns false after clearing', () async {
        // Trigger and clear
        storage.store['tamper_detected'] = 'true';
        storage.store['first_launch_timestamp'] = DateTime.now()
            .millisecondsSinceEpoch
            .toString();
        storage.store['last_known_timestamp'] = DateTime.now()
            .millisecondsSinceEpoch
            .toString();
        storage.store['boot_count'] = '1';

        await service.clearTamperFlag();
        final result = await service.checkIntegrity();

        expect(result, isFalse);
      });
    });

    group('recordTimestamp', () {
      test('updates last known timestamp', () async {
        await service.checkIntegrity();

        final before = int.parse(storage.store['last_known_timestamp']!);
        // Small delay to ensure time advances
        await Future.delayed(const Duration(milliseconds: 10));
        await service.recordTimestamp();
        final after = int.parse(storage.store['last_known_timestamp']!);

        expect(after, greaterThanOrEqualTo(before));
      });
    });

    group('getDiagnostics', () {
      test('returns all diagnostic fields', () async {
        await service.checkIntegrity();

        final diag = await service.getDiagnostics();

        expect(diag.containsKey('firstLaunch'), isTrue);
        expect(diag.containsKey('lastKnownTime'), isTrue);
        expect(diag.containsKey('bootCount'), isTrue);
        expect(diag.containsKey('tamperDetected'), isTrue);
        expect(diag.containsKey('currentTime'), isTrue);
        expect(diag['bootCount'], equals(1));
        expect(diag['tamperDetected'], isFalse);
      });

      test('shows tamperDetected true after tamper', () async {
        storage.store['tamper_detected'] = 'true';
        storage.store['first_launch_timestamp'] = DateTime.now()
            .millisecondsSinceEpoch
            .toString();
        storage.store['boot_count'] = '1';

        final diag = await service.getDiagnostics();

        expect(diag['tamperDetected'], isTrue);
      });
    });

    group('clearAll', () {
      test('removes all tamper detection keys', () async {
        await service.checkIntegrity();

        expect(storage.store.isNotEmpty, isTrue);

        await service.clearAll();

        expect(storage.store.containsKey('first_launch_timestamp'), isFalse);
        expect(storage.store.containsKey('last_known_timestamp'), isFalse);
        expect(storage.store.containsKey('tamper_detected'), isFalse);
        expect(storage.store.containsKey('boot_count'), isFalse);
      });
    });
  });
}
