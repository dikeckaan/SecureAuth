import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/services/logger_service.dart';

void main() {
  late LoggerService logger;

  setUp(() async {
    logger = LoggerService.instance;
    await logger.clear();
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

    test('respects loggingEnabled flag', () {
      logger.loggingEnabled = false;
      logger.info('test', 'should not be logged');
      expect(logger.length, 0);

      logger.loggingEnabled = true;
      logger.info('test', 'should be logged');
      expect(logger.length, 1);
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
      final result = logger.query(level: LogLevel.info, category: 'backup');
      expect(result.length, 1);
      expect(result.first.message, 'exported');
    });

    test('securityAuditTrail returns only security entries', () {
      final trail = logger.securityAuditTrail;
      expect(trail.length, 1);
      expect(trail.first.message, 'password changed');
    });
  });

  group('getFilteredEntries', () {
    setUp(() {
      logger.debug('test', 'debug msg');
      logger.info('auth', 'info msg');
      logger.warning('backup', 'warn msg');
      logger.error('auth', 'error msg');
      logger.security('auth', 'sec msg');
    });

    test('filter by minLevel', () {
      final result = logger.getFilteredEntries(minLevel: LogLevel.warning);
      expect(result.length, 3); // warning, error, security
    });

    test('filter by category and minLevel', () {
      final result = logger.getFilteredEntries(
        minLevel: LogLevel.error,
        category: 'auth',
      );
      expect(result.length, 2); // error + security in auth
    });
  });

  group('LogEntry model conversion', () {
    test('round-trip through toModel/fromModel preserves data', () {
      final original = LogEntry(
        timestamp: DateTime(2026, 3, 12, 14, 30, 0),
        level: LogLevel.security,
        category: 'auth',
        message: 'Password changed',
        metadata: {'attempt': 3, 'ip': '192.168.1.1'},
      );

      final model = original.toModel();
      final restored = LogEntry.fromModel(model);

      expect(restored.level, original.level);
      expect(restored.category, original.category);
      expect(restored.message, original.message);
      expect(restored.metadata, original.metadata);
      // Timestamps may differ slightly due to UTC conversion
      expect(
        restored.timestamp.difference(original.timestamp).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('round-trip with null metadata', () {
      final original = LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        category: 'test',
        message: 'No metadata',
      );

      final model = original.toModel();
      final restored = LogEntry.fromModel(model);

      expect(restored.metadata, isNull);
    });
  });

  group('export', () {
    setUp(() {
      logger.info('auth', 'login');
      logger.security('auth', 'password set');
    });

    test('exportAsText contains header and entries', () {
      final text = logger.exportAsText();
      expect(text, contains('SECUREAUTH LOG EXPORT'));
      expect(text, contains('Total entries: 2'));
      expect(text, contains('login'));
      expect(text, contains('password set'));
    });

    test('exportAsJson produces valid JSON array', () {
      final json = logger.exportAsJson();
      expect(json, startsWith('['));
      expect(json, endsWith(']'));
      expect(json, contains('"level":"info"'));
      expect(json, contains('"level":"security"'));
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
    test('removes all entries', () async {
      logger.info('test', 'msg1');
      logger.info('test', 'msg2');
      expect(logger.length, 2);

      await logger.clear();
      expect(logger.length, 0);
      expect(logger.entries, isEmpty);
    });
  });

  group('persistence state', () {
    test('isPersistent returns false before initPersistence', () {
      // Without calling initPersistence, Hive box is not open
      expect(logger.isPersistent, isFalse);
    });

    test('persistedLength returns 0 without persistence', () {
      expect(logger.persistedLength, 0);
    });
  });
}
