import 'package:flutter_test/flutter_test.dart';
import 'package:secure_auth/utils/result.dart';

void main() {
  group('Result.success', () {
    test('isSuccess returns true', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('value returns wrapped value', () {
      const result = Result<String>.success('hello');
      expect(result.value, 'hello');
    });

    test('when calls success branch', () {
      const result = Result<int>.success(10);
      final output = result.when(
        success: (v) => 'got $v',
        failure: (e) => 'error: ${e.message}',
      );
      expect(output, 'got 10');
    });
  });

  group('Result.failure', () {
    test('isFailure returns true', () {
      const result = Result<int>.failure(
        AppError(category: ErrorCategory.auth, message: 'fail'),
      );
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
    });

    test('error returns AppError', () {
      const err = AppError(category: ErrorCategory.crypto, message: 'bad key');
      const result = Result<String>.failure(err);
      expect(result.error.category, ErrorCategory.crypto);
      expect(result.error.message, 'bad key');
    });

    test('when calls failure branch', () {
      const result = Result<int>.failure(
        AppError(category: ErrorCategory.storage, message: 'disk full'),
      );
      final output = result.when(
        success: (v) => 'value: $v',
        failure: (e) => 'err: ${e.message}',
      );
      expect(output, 'err: disk full');
    });
  });

  group('map', () {
    test('transforms success value', () {
      const result = Result<int>.success(5);
      final mapped = result.map((v) => v * 2);
      expect(mapped.isSuccess, isTrue);
      expect(mapped.value, 10);
    });

    test('passes through failure', () {
      const result = Result<int>.failure(
        AppError(category: ErrorCategory.validation, message: 'invalid'),
      );
      final mapped = result.map((v) => v * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.error.message, 'invalid');
    });
  });

  group('flatMap', () {
    test('chains successful operations', () async {
      const result = Result<int>.success(5);
      final chained = await result.flatMap(
        (v) async => Result<String>.success('value: $v'),
      );
      expect(chained.isSuccess, isTrue);
      expect(chained.value, 'value: 5');
    });

    test('short-circuits on failure', () async {
      const result = Result<int>.failure(
        AppError(category: ErrorCategory.unknown, message: 'oops'),
      );
      var called = false;
      final chained = await result.flatMap((v) async {
        called = true;
        return Result<String>.success('should not reach');
      });
      expect(called, isFalse);
      expect(chained.isFailure, isTrue);
    });
  });

  group('AppError', () {
    test('toString includes category and message', () {
      const err = AppError(
        category: ErrorCategory.backup,
        message: 'wrong password',
        userMessage: 'The backup password is incorrect',
      );
      expect(err.toString(), contains('backup'));
      expect(err.toString(), contains('wrong password'));
    });

    test('preserves original error and stack trace', () {
      final original = FormatException('bad format');
      final trace = StackTrace.current;
      final err = AppError(
        category: ErrorCategory.backup,
        message: 'parse failed',
        originalError: original,
        stackTrace: trace,
      );
      expect(err.originalError, isA<FormatException>());
      expect(err.stackTrace, isNotNull);
    });
  });

  group('ErrorCategory', () {
    test('has all expected categories', () {
      expect(ErrorCategory.values, containsAll([
        ErrorCategory.auth,
        ErrorCategory.crypto,
        ErrorCategory.storage,
        ErrorCategory.validation,
        ErrorCategory.backup,
        ErrorCategory.qr,
        ErrorCategory.biometric,
        ErrorCategory.unknown,
      ]));
    });
  });
}
