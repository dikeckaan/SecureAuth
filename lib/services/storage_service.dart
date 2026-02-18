import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/account_model.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _accountsBox = 'accounts';
  static const String _settingsBox = 'settings';
  static const String _encryptionKeyName = 'encryption_key';

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

    final encryptionKey = await _getEncryptionKey();
    final encryptionKeyBytes = base64Url.decode(encryptionKey);

    _accountsBoxInstance = await Hive.openBox<AccountModel>(
      _accountsBox,
      encryptionCipher: HiveAesCipher(encryptionKeyBytes),
    );

    _settingsBoxInstance = await Hive.openBox<AppSettings>(_settingsBox);

    if (_settingsBoxInstance!.isEmpty) {
      await _settingsBoxInstance!.put('settings', AppSettings());
    }
  }

  Future<String> _getEncryptionKey() async {
    var encryptionKey = await _secureStorage.read(key: _encryptionKeyName);
    if (encryptionKey == null) {
      final key = Hive.generateSecureKey();
      encryptionKey = base64Url.encode(key);
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: encryptionKey,
      );
    }
    return encryptionKey;
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
  }

  Future<void> updateAccount(AccountModel account) async {
    await account.save();
  }

  Future<void> deleteAccount(String id) async {
    await accountsBox.delete(id);
  }

  List<AccountModel> getAllAccounts() {
    return accountsBox.values.toList()
      ..sort((a, b) => a.issuer.toLowerCase().compareTo(b.issuer.toLowerCase()));
  }

  // --- Settings ---

  AppSettings getSettings() {
    return settingsBox.get('settings', defaultValue: AppSettings())!;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await settingsBox.put('settings', settings);
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
      throw const FormatException('Gecersiz yedek dosyasi: "accounts" alani bulunamadi');
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

    return imported;
  }

  // --- Data Management ---

  Future<void> clearAllData() async {
    await accountsBox.clear();
    await _settingsBoxInstance!.clear();
    await _settingsBoxInstance!.put('settings', AppSettings());
  }

  int get accountCount => accountsBox.length;
}
