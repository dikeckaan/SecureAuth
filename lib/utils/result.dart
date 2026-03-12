/// A simple Result type for explicit error handling without exceptions.
///
/// Replaces try-catch patterns with a type-safe discriminated union:
///
/// ```dart
/// final result = await someOperation();
/// result.when(
///   success: (data) => showData(data),
///   failure: (error) => showError(error),
/// );
/// ```
///
/// Or using pattern matching:
/// ```dart
/// if (result.isSuccess) {
///   final data = result.value;
/// } else {
///   final error = result.error;
/// }
/// ```
sealed class Result<T> {
  const Result._();

  /// Creates a successful result wrapping [value].
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result wrapping [error].
  const factory Result.failure(AppError error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the success value, or throws if this is a failure.
  T get value => (this as Success<T>)._value;

  /// Returns the error, or throws if this is a success.
  AppError get error => (this as Failure<T>)._error;

  /// Pattern match on the result.
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success<T>(value: final v) => success(v),
      Failure<T>(error: final e) => failure(e),
    };
  }

  /// Maps the success value, leaving failures untouched.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(value: final v) => Result.success(transform(v)),
      Failure<T>(error: final e) => Result.failure(e),
    };
  }

  /// Chains another Result-returning operation on success.
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T value) transform,
  ) async {
    return switch (this) {
      Success<T>(value: final v) => transform(v),
      Failure<T>(error: final e) => Result.failure(e),
    };
  }
}

final class Success<T> extends Result<T> {
  final T _value;
  const Success(this._value) : super._();

  @override
  T get value => _value;
}

final class Failure<T> extends Result<T> {
  final AppError _error;
  const Failure(this._error) : super._();

  @override
  AppError get error => _error;
}

/// Structured application error with category and optional original exception.
class AppError {
  final ErrorCategory category;
  final String message;
  final String? userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.category,
    required this.message,
    this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => '[$category] $message';
}

/// Error categories for structured handling in the UI layer.
enum ErrorCategory {
  /// Authentication or authorization failure.
  auth,

  /// Cryptographic or backup encryption/decryption failure.
  crypto,

  /// Local storage read/write failure.
  storage,

  /// Invalid user input or data format.
  validation,

  /// Backup file format or content error.
  backup,

  /// QR code scanning or generation error.
  qr,

  /// Biometric hardware or permission error.
  biometric,

  /// Generic unexpected error.
  unknown,
}
