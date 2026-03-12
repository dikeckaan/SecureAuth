import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/logger_service.dart';

void main() {
  late LoggerService logger;

  setUp(() {
    logger = LoggerService.instance;
    logger.clear();
    logger.printToConsole = false; // suppress output during tests
  });

  group('logging basics', () {
    test('starts empty', () {
      expect(logger.length, 0);
      expect(logger.entries, isEmpty);
    });

    test('logs messages at each level', () {
      logger.debug('test', 'debug message');
      logger.info('test', 'info message');
      logger.warning('test', 'warning message');
      logger.error('test', 'error message');
      logger.security('test', 'security message');

      expect(logger.length, 5);
      expect(logger.entries[0].level, LogLevel.debug);
      expect(logger.entries[1].level, LogLevel.info);
      expect(logger.entries[2].level, LogLevel.warning);
      expect(logger.entries[3].level, LogLevel.error);
      expect(logger.entries[4].level, LogLevel.security);
    });

    test('stores category and message', () {
      logger.info('auth', 'User logged in');
      final entry = logger.entries.first;
      expect(entry.category, 'auth');
      expect(entry.message, 'User logged in');
    });

    test('stores metadata', () {
      logger.error('backup', 'Failed', {'code': 42, 'file': 'test.saenc'});
      final entry = logger.entries.first;
      expect(entry.metadata, {'code': 42, 'file': 'test.saenc'});
    });

    test('stores timestamp', () {
      final before = DateTime.now();
      logger.info('test', 'msg');
      final after = DateTime.now();
      final ts = logger.entries.first.timestamp;
      expect(ts.isAfter(before) || ts.isAtSameMomentAs(before), isTrue);
      expect(ts.isBefore(after) || ts.isAtSameMomentAs(after), isTrue);
    });
  });

  group('ring buffer', () {
    test('respects maxEntries limit', () {
      for (var i = 0; i < LoggerService.maxEntries + 50; i++) {
        logger.info('test', 'message $i');
      }
      expect(logger.length, LoggerService.maxEntries);
      // Oldest entries should have been evicted
      expect(logger.entries.first.message, 'message 50');
    });
  });

  group('query', () {
    setUp(() {
      logger.info('auth', 'login');
      logger.error('auth', 'failed');
      logger.info('backup', 'exported');
      logger.security('auth', 'password changed');
    });

    test('filter by level', () {
      final errors = logger.query(level: LogLevel.error);
      expect(errors.length, 1);
      expect(errors.first.message, 'failed');
    });

    test('filter by category', () {
      final authLogs = logger.query(category: 'auth');
      expect(authLogs.length, 3);
    });

    test('filter by both level and category', () {
      final result =
          logger.query(level: LogLevel.info, category: 'backup');
      expect(result.length, 1);
      expect(result.first.message, 'exported');
    });

    test('securityAuditTrail returns only security entries', () {
      final trail = logger.securityAuditTrail;
      expect(trail.length, 1);
      expect(trail.first.message, 'password changed');
    });
  });

  group('LogEntry toString', () {
    test('formats without metadata', () {
      final entry = LogEntry(
        timestamp: DateTime(2026, 1, 1, 12, 0),
        level: LogLevel.info,
        category: 'test',
        message: 'hello',
      );
      final str = entry.toString();
      expect(str, contains('INFO'));
      expect(str, contains('[test]'));
      expect(str, contains('hello'));
    });

    test('formats with metadata', () {
      final entry = LogEntry(
        timestamp: DateTime(2026, 1, 1, 12, 0),
        level: LogLevel.error,
        category: 'backup',
        message: 'fail',
        metadata: {'code': 1},
      );
      final str = entry.toString();
      expect(str, contains('ERROR'));
      expect(str, contains('{code: 1}'));
    });
  });

  group('clear', () {
    test('removes all entries', () {
      logger.info('test', 'msg1');
      logger.info('test', 'msg2');
      expect(logger.length, 2);

      logger.clear();
      expect(logger.length, 0);
      expect(logger.entries, isEmpty);
    });
  });
}
