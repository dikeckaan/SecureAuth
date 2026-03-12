import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/account_model.dart';
import '../models/app_settings.dart';
import '../utils/result.dart';
import 'logger_service.dart';

class StorageService {
  static final _log = LoggerService.instance;
  static const String _accountsBox = 'accounts';
  static const String _settingsBox = 'settings';
  static const String _encryptionKeyName = 'encryption_key';
  static const String _settingsEncryptionKeyName = 'settings_encryption_key';
  static const String _logsEncryptionKeyName = 'logs_encryption_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Box<AccountModel>? _accountsBoxInstance;
  Box<AppSettings>? _settingsBoxInstance;

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AccountModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    final encryptionKey = await _getOrCreateKey(_encryptionKeyName);
    final encryptionKeyBytes = base64Url.decode(encryptionKey);

    _accountsBoxInstance = await Hive.openBox<AccountModel>(
      _accountsBox,
      encryptionCipher: HiveAesCipher(encryptionKeyBytes),
    );

    final settingsKey = await _getOrCreateKey(_settingsEncryptionKeyName);
    final settingsKeyBytes = base64Url.decode(settingsKey);

    try {
      _settingsBoxInstance = await Hive.openBox<AppSettings>(
        _settingsBox,
        encryptionCipher: HiveAesCipher(settingsKeyBytes),
      );
    } catch (e) {
      // Box existed unencrypted (first run after upgrade) — delete and recreate.
      // Password hash/salt will be re-created at next login (transparent migration).
      _log.warning(
        'storage',
        'Settings box migration: recreating encrypted box',
        {'reason': e.toString()},
      );
      await Hive.deleteBoxFromDisk(_settingsBox);
      _settingsBoxInstance = await Hive.openBox<AppSettings>(
        _settingsBox,
        encryptionCipher: HiveAesCipher(settingsKeyBytes),
      );
    }

    if (_settingsBoxInstance!.isEmpty) {
      await _settingsBoxInstance!.put('settings', AppSettings());
    }

    // Initialize encrypted log persistence
    final logsKey = await _getOrCreateKey(_logsEncryptionKeyName);
    final logsKeyBytes = base64Url.decode(logsKey);
    await _log.initPersistence(logsKeyBytes);

    // Purge expired log entries based on retention setting
    final settings = getSettings();
    final purged = await _log.purgeExpired(settings.logRetentionDays);

    _log.info('storage', 'Storage initialized', {
      'accounts': _accountsBoxInstance!.length,
      'persistedLogs': _log.persistedLength,
      if (purged > 0) 'expiredLogsPurged': purged,
    });
  }

  Future<String> _getOrCreateKey(String keyName) async {
    var key = await _secureStorage.read(key: keyName);
    if (key == null) {
      final newKey = Hive.generateSecureKey();
      key = base64Url.encode(newKey);
      await _secureStorage.write(key: keyName, value: key);
    }
    return key;
  }

  Box<AccountModel> get accountsBox {
    if (_accountsBoxInstance == null || !_accountsBoxInstance!.isOpen) {
      throw StateError('Accounts box not initialized. Call init() first.');
    }
    return _accountsBoxInstance!;
  }

  Box<AppSettings> get settingsBox {
    if (_settingsBoxInstance == null || !_settingsBoxInstance!.isOpen) {
      throw StateError('Settings box not initialized. Call init() first.');
    }
    return _settingsBoxInstance!;
  }

  // --- Account Operations ---

  Future<void> addAccount(AccountModel account) async {
    await accountsBox.put(account.id, account);
    _log.info('storage', 'Account added', {
      'issuer': account.issuer,
      'type': account.type,
    });
  }

  Future<void> updateAccount(AccountModel account) async {
    await account.save();
  }

  Future<void> deleteAccount(String id) async {
    await accountsBox.delete(id);
    _log.info('storage', 'Account deleted', {'id': id});
  }

  List<AccountModel> getAllAccounts() {
    final accounts = accountsBox.values.toList();
    final order = getSettings().accountOrder;
    if (order == null || order.isEmpty) {
      return accounts..sort(
        (a, b) => a.issuer.toLowerCase().compareTo(b.issuer.toLowerCase()),
      );
    }
    final orderMap = {for (var i = 0; i < order.length; i++) order[i]: i};
    accounts.sort((a, b) {
      final ia = orderMap[a.id] ?? order.length;
      final ib = orderMap[b.id] ?? order.length;
      return ia.compareTo(ib);
    });
    return accounts;
  }

  /// Persists a custom drag-to-reorder sequence for the home list.
  Future<void> saveAccountOrder(List<String> ids) async {
    final settings = getSettings();
    settings.accountOrder = ids;
    await updateSettings(settings);
  }

  // --- Settings ---

  AppSettings getSettings() {
    return settingsBox.get('settings', defaultValue: AppSettings())!;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await settingsBox.put('settings', settings);
  }

  /// Sets HOTP counter to an arbitrary value and persists.
  Future<void> setHOTPCounter(AccountModel account, int counter) async {
    account.counter = counter;
    await account.save();
  }

  // --- Import / Export ---

  Future<String> exportAccountsToJson() async {
    final accounts = getAllAccounts();
    final jsonList = accounts.map((a) => a.toJson()).toList();
    return json.encode({
      'version': '2.0',
      'app': 'SecureAuth',
      'accounts': jsonList,
      'exported_at': DateTime.now().toIso8601String(),
      'count': jsonList.length,
    });
  }

  Future<int> importAccountsFromJson(String jsonString) async {
    final data = json.decode(jsonString) as Map<String, dynamic>;

    if (!data.containsKey('accounts')) {
      throw const FormatException(
        'Invalid backup file: "accounts" field not found',
      );
    }

    final accountsList = data['accounts'] as List;
    int imported = 0;

    for (final accountJson in accountsList) {
      if (accountJson is! Map<String, dynamic>) continue;

      final account = AccountModel.fromJson(accountJson);

      // Skip duplicates by ID
      if (!accountsBox.containsKey(account.id)) {
        await addAccount(account);
        imported++;
      }
    }

    _log.security('backup', 'Accounts imported', {
      'total': accountsList.length,
      'imported': imported,
      'skippedDuplicates': accountsList.length - imported,
    });
    return imported;
  }

  /// Result-safe version of importAccountsFromJson.
  Future<Result<int>> importAccountsSafe(String jsonString) async {
    try {
      final count = await importAccountsFromJson(jsonString);
      return Result.success(count);
    } on FormatException catch (e, st) {
      return Result.failure(
        AppError(
          category: ErrorCategory.backup,
          message: e.message,
          userMessage: 'Invalid backup file format',
          originalError: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      return Result.failure(
        AppError(
          category: ErrorCategory.storage,
          message: 'Import failed: $e',
          originalError: e,
          stackTrace: st,
        ),
      );
    }
  }

  // --- Data Management ---

  Future<void> clearAllData() async {
    final count = accountsBox.length;
    await accountsBox.clear();
    await _settingsBoxInstance!.clear();
    await _settingsBoxInstance!.put('settings', AppSettings());
    _log.security('storage', 'All data cleared', {'accountsWiped': count});
  }

  int get accountCount => accountsBox.length;
}
