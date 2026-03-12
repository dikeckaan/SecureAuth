import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Log severity levels, ordered from least to most severe.
enum LogLevel {
  debug,
  info,
  warning,
  error,
  security,
}

/// A single structured log entry.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String category;
  final String message;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.category,
    required this.message,
    this.metadata,
  });

  @override
  String toString() {
    final meta =
        metadata != null && metadata!.isNotEmpty ? ' | $metadata' : '';
    return '[${timestamp.toIso8601String()}] '
        '${level.name.toUpperCase().padRight(8)} '
        '[$category] $message$meta';
  }
}

/// Application-wide structured logger.
///
/// - Stores logs in a fixed-size in-memory ring buffer (no disk, no network).
/// - In debug mode, also prints to the console via [debugPrint].
/// - Provides category-based convenience methods for security auditing.
///
/// Usage:
///   LoggerService.instance.security('auth', 'Failed login attempt', {'attempt': 3});
///   LoggerService.instance.info('backup', 'Backup exported successfully');
class LoggerService {
  LoggerService._();
  static final LoggerService instance = LoggerService._();

  /// Maximum number of log entries kept in memory.
  static const int maxEntries = 500;

  final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Whether to print logs to the debug console.
  bool printToConsole = kDebugMode;

  /// Whether logging is enabled. When false, _log() skips writing.
  bool loggingEnabled = true;

  // ─── Public API ──────────────────────────────────────────────────────────

  void debug(String category, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.debug, category, message, meta);

  void info(String category, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.info, category, message, meta);

  void warning(String category, String message,
          [Map<String, dynamic>? meta]) =>
      _log(LogLevel.warning, category, message, meta);

  void error(String category, String message, [Map<String, dynamic>? meta]) =>
      _log(LogLevel.error, category, message, meta);

  /// Security-specific log level for auditable events:
  /// login attempts, password changes, backup operations, data wipes, etc.
  void security(String category, String message,
          [Map<String, dynamic>? meta]) =>
      _log(LogLevel.security, category, message, meta);

  // ─── Query ───────────────────────────────────────────────────────────────

  /// Returns all log entries (oldest first).
  List<LogEntry> get entries => _buffer.toList();

  /// Returns entries filtered by [level] and/or [category].
  List<LogEntry> query({LogLevel? level, String? category}) {
    return _buffer.where((e) {
      if (level != null && e.level != level) return false;
      if (category != null && e.category != category) return false;
      return true;
    }).toList();
  }

  /// Returns only security-level entries (audit trail).
  List<LogEntry> get securityAuditTrail => query(level: LogLevel.security);

  /// Clears all stored log entries.
  void clear() => _buffer.clear();

  /// Total entries currently stored.
  int get length => _buffer.length;

  /// Advanced filtering of log entries by level, category, and time range.
  List<LogEntry> getFilteredEntries({
    LogLevel? minLevel,
    String? category,
    DateTime? from,
    DateTime? to,
  }) {
    final minLevelIndex = minLevel != null ? minLevel.index : -1;
    return _buffer.where((e) {
      if (minLevel != null && e.level.index < minLevelIndex) return false;
      if (category != null && e.category != category) return false;
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }

  /// Exports all log entries as a readable text report.
  String exportAsText() {
    if (_buffer.isEmpty) {
      return 'No log entries.';
    }
    final buffer = StringBuffer();
    buffer.writeln('=== LOG EXPORT ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_buffer.length}');
    buffer.writeln('');
    for (final entry in _buffer) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }

  /// Exports all log entries as a JSON array string.
  String exportAsJson() {
    final jsonList = _buffer.map((entry) {
      return {
        'timestamp': entry.timestamp.toIso8601String(),
        'level': entry.level.name,
        'category': entry.category,
        'message': entry.message,
        'metadata': entry.metadata,
      };
    }).toList();
    return jsonEncode(jsonList);
  }

  // ─── Internal ────────────────────────────────────────────────────────────

  void _log(
    LogLevel level,
    String category,
    String message,
    Map<String, dynamic>? metadata,
  ) {
    if (!loggingEnabled) {
      return;
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      category: category,
      message: message,
      metadata: metadata,
    );

    _buffer.addLast(entry);
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }

    if (printToConsole) {
      debugPrint(entry.toString());
    }
  }
}
