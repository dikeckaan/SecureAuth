import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/log_entry_model.dart';

/// Log severity levels, ordered from least to most severe.
enum LogLevel {
  debug,
  info,
  warning,
  error,
  security,
}

/// A single structured log entry (in-memory representation).
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

  /// Create from a persisted Hive model.
  factory LogEntry.fromModel(LogEntryModel model) {
    Map<String, dynamic>? meta;
    if (model.metadataJson != null && model.metadataJson!.isNotEmpty) {
      try {
        meta = jsonDecode(model.metadataJson!) as Map<String, dynamic>;
      } catch (_) {
        // Ignore malformed metadata
      }
    }
    return LogEntry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(model.timestampMs, isUtc: true).toLocal(),
      level: LogLevel.values[model.levelIndex.clamp(0, LogLevel.values.length - 1)],
      category: model.category,
      message: model.message,
      metadata: meta,
    );
  }

  /// Convert to a persistable Hive model.
  LogEntryModel toModel() {
    return LogEntryModel(
      timestampMs: timestamp.toUtc().millisecondsSinceEpoch,
      levelIndex: level.index,
      category: category,
      message: message,
      metadataJson: metadata != null && metadata!.isNotEmpty
          ? jsonEncode(metadata)
          : null,
    );
  }

  @override
  String toString() {
    final meta =
        metadata != null && metadata!.isNotEmpty ? ' | $metadata' : '';
    return '[${timestamp.toIso8601String()}] '
        '${level.name.toUpperCase().padRight(8)} '
        '[$category] $message$meta';
  }
}

/// Application-wide structured logger with encrypted Hive persistence.
///
/// - Maintains an in-memory ring buffer for fast access (max [maxEntries]).
/// - Persists all log entries to an encrypted Hive box for cross-session retention.
/// - Supports TTL-based automatic cleanup (configurable retention days).
/// - In debug mode, also prints to the console via [debugPrint].
///
/// Usage:
///   LoggerService.instance.security('auth', 'Failed login attempt', {'attempt': 3});
///   LoggerService.instance.info('backup', 'Backup exported successfully');
///
/// Initialization:
///   await LoggerService.instance.initPersistence(encryptionKey);
class LoggerService {
  LoggerService._();
  static final LoggerService instance = LoggerService._();

  /// Maximum number of log entries kept in memory.
  static const int maxEntries = 500;

  /// In-memory ring buffer for fast queries.
  final Queue<LogEntry> _buffer = Queue<LogEntry>();

  /// Hive box for persistent storage (null until [initPersistence] is called).
  Box<LogEntryModel>? _logBox;

  /// Whether the persistent store has been initialized.
  bool get isPersistent => _logBox != null && _logBox!.isOpen;

  /// Whether to print logs to the debug console.
  bool printToConsole = kDebugMode;

  /// Whether logging is enabled. When false, _log() skips writing.
  bool loggingEnabled = true;

  // ─── Initialization ─────────────────────────────────────────────────────

  /// Opens the encrypted Hive box for log persistence and loads existing
  /// entries into the in-memory buffer.
  ///
  /// Call this once during app startup, after Hive is initialized.
  /// [encryptionKey] should be a 256-bit key (same approach as other boxes).
  Future<void> initPersistence(List<int> encryptionKey) async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LogEntryModelAdapter());
    }

    _logBox = await Hive.openBox<LogEntryModel>(
      'security_logs',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    // Load persisted entries into memory buffer
    _loadFromDisk();
  }

  /// Loads persisted log entries from Hive into the in-memory buffer,
  /// sorted by timestamp (oldest first).
  void _loadFromDisk() {
    if (_logBox == null) return;

    final models = _logBox!.values.toList()
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    _buffer.clear();
    // Only load the most recent [maxEntries] into memory
    final start = models.length > maxEntries ? models.length - maxEntries : 0;
    for (var i = start; i < models.length; i++) {
      _buffer.addLast(LogEntry.fromModel(models[i]));
    }
  }

  /// Removes log entries older than [retentionDays] from both Hive and memory.
  ///
  /// Call this on app startup after [initPersistence].
  Future<int> purgeExpired(int retentionDays) async {
    if (_logBox == null) return 0;

    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .toUtc()
        .millisecondsSinceEpoch;

    final keysToDelete = <dynamic>[];
    for (final entry in _logBox!.toMap().entries) {
      if (entry.value.timestampMs < cutoff) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _logBox!.deleteAll(keysToDelete);
      // Rebuild in-memory buffer after purge
      _loadFromDisk();
    }

    return keysToDelete.length;
  }

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

  /// Clears all stored log entries (memory and disk).
  Future<void> clear() async {
    _buffer.clear();
    if (_logBox != null && _logBox!.isOpen) {
      await _logBox!.clear();
    }
  }

  /// Total entries currently stored in memory.
  int get length => _buffer.length;

  /// Total entries persisted on disk.
  int get persistedLength => _logBox?.length ?? 0;

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
    buffer.writeln('=== SECUREAUTH LOG EXPORT ===');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_buffer.length}');
    buffer.writeln('Persisted entries: $persistedLength');
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

    // Add to in-memory buffer
    _buffer.addLast(entry);
    while (_buffer.length > maxEntries) {
      _buffer.removeFirst();
    }

    // Persist to Hive (fire-and-forget, non-blocking)
    if (_logBox != null && _logBox!.isOpen) {
      _logBox!.add(entry.toModel());
    }

    if (printToConsole) {
      debugPrint(entry.toString());
    }
  }
}
