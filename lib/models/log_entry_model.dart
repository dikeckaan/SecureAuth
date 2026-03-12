import 'package:hive/hive.dart';

part 'log_entry_model.g.dart';

/// Persistent log entry stored in an encrypted Hive box.
///
/// TypeId 2 — after AccountModel (0) and AppSettings (1).
@HiveType(typeId: 2)
class LogEntryModel extends HiveObject {
  /// Milliseconds since epoch (UTC).
  @HiveField(0)
  int timestampMs;

  /// Log level index matching [LogLevel] enum order:
  /// 0=debug, 1=info, 2=warning, 3=error, 4=security
  @HiveField(1)
  int levelIndex;

  /// Category string (e.g. 'auth', 'backup', 'storage', 'tamper', 'app').
  @HiveField(2)
  String category;

  /// Human-readable log message.
  @HiveField(3)
  String message;

  /// Optional JSON-encoded metadata string (null if no metadata).
  @HiveField(4)
  String? metadataJson;

  LogEntryModel({
    required this.timestampMs,
    required this.levelIndex,
    required this.category,
    required this.message,
    this.metadataJson,
  });
}
