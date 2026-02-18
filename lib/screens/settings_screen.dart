import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final VoidCallback onThemeChanged;
  final VoidCallback onLocaleChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late bool _useBiometric;
  late bool _requireAuthOnLaunch;
  late int _autoLockSeconds;
  late int _clipboardClearSeconds;
  late int _maxFailedAttempts;
  late bool _wipeOnMaxAttempts;
  late String? _languageCode;
  bool _biometricAvailable = false;

  static const _supportedLanguages = [
    _LanguageOption('tr', 'Turkce', '🇹🇷'),
    _LanguageOption('en', 'English', '🇬🇧'),
    _LanguageOption('es', 'Espanol', '🇪🇸'),
    _LanguageOption('de', 'Deutsch', '🇩🇪'),
    _LanguageOption('az', 'Azerbaycanca', '🇦🇿'),
    _LanguageOption('ru', 'Русский', '🇷🇺'),
    _LanguageOption('fr', 'Francais', '🇫🇷'),
    _LanguageOption('pt', 'Portugues', '🇧🇷'),
    _LanguageOption('ja', '日本語', '🇯🇵'),
    _LanguageOption('ko', '한국어', '🇰🇷'),
    _LanguageOption('zh', '中文', '🇨🇳'),
    _LanguageOption('ar', 'العربية', '🇸🇦'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometric();
  }

  void _loadSettings() {
    final settings = widget.storageService.getSettings();
    _isDarkMode = settings.isDarkMode;
    _useBiometric = settings.useBiometric;
    _requireAuthOnLaunch = settings.requireAuthOnLaunch;
    _autoLockSeconds = settings.autoLockSeconds;
    _clipboardClearSeconds = settings.clipboardClearSeconds;
    _maxFailedAttempts = settings.maxFailedAttempts;
    _wipeOnMaxAttempts = settings.wipeOnMaxAttempts;
    _languageCode = settings.languageCode;
  }

  Future<void> _checkBiometric() async {
    final available = await widget.authService.isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _updateSetting(void Function(dynamic settings) updater) async {
    final settings = widget.storageService.getSettings();
    updater(settings);
    await widget.storageService.updateSettings(settings);
  }

  Future<void> _toggleDarkMode(bool value) async {
    await _updateSetting((s) => s.isDarkMode = value);
    setState(() => _isDarkMode = value);
    widget.onThemeChanged();
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value && !widget.authService.hasPassword()) {
      _showError(l10n.needPasswordFirst);
      return;
    }
    await widget.authService.enableBiometric(value);
    setState(() => _useBiometric = value);
  }

  Future<void> _toggleRequireAuth(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value && !widget.authService.hasPassword()) {
      _showError(l10n.needPasswordFirst);
      return;
    }
    await _updateSetting((s) => s.requireAuthOnLaunch = value);
    setState(() => _requireAuthOnLaunch = value);
  }

  Future<void> _toggleWipeOnMax(bool value) async {
    final l10n = AppLocalizations.of(context)!;
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.warning),
          content: Text(l10n.wipeWarning(_maxFailedAttempts)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l10n.enable),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _updateSetting((s) => s.wipeOnMaxAttempts = value);
    setState(() => _wipeOnMaxAttempts = value);
  }

  Future<void> _setAutoLockSeconds(int value) async {
    await _updateSetting((s) => s.autoLockSeconds = value);
    setState(() => _autoLockSeconds = value);
  }

  Future<void> _setClipboardClearSeconds(int value) async {
    await _updateSetting((s) => s.clipboardClearSeconds = value);
    setState(() => _clipboardClearSeconds = value);
  }

  Future<void> _setMaxFailedAttempts(int value) async {
    await _updateSetting((s) => s.maxFailedAttempts = value);
    setState(() => _maxFailedAttempts = value);
  }

  Future<void> _setLanguage(String? code) async {
    await _updateSetting((s) => s.languageCode = code);
    setState(() => _languageCode = code);
    widget.onLocaleChanged();
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final hasExisting = widget.authService.hasPassword();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasExisting ? l10n.changePassword : l10n.setPassword),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasExisting)
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              if (hasExisting) const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.newPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.confirmNewPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (hasExisting) {
                final isValid = await widget.authService
                    .verifyPassword(oldPasswordController.text);
                if (!isValid) {
                  if (context.mounted) _showError(l10n.currentPasswordWrong);
                  return;
                }
              }

              if (newPasswordController.text.length <
                  AppConstants.minPasswordLength) {
                _showError(
                    l10n.passwordMinLength(AppConstants.minPasswordLength));
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                _showError(l10n.passwordsDoNotMatch);
                return;
              }

              await widget.authService
                  .setPassword(newPasswordController.text);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == true && mounted) {
      _showSuccess(l10n.passwordChangedSuccess);
    }
  }

  Future<void> _exportAccounts() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final jsonString = await widget.storageService.exportAccountsToJson();
      final fileName =
          'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.secureAuthBackup,
        text: l10n.backupFileDescription,
      );

      if (mounted) _showSuccess(l10n.accountsExported);
    } catch (e) {
      if (mounted) _showError(l10n.exportError);
    }
  }

  Future<void> _importAccounts() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonString = await file.readAsString();

      final imported =
          await widget.storageService.importAccountsFromJson(jsonString);

      if (mounted) {
        _showSuccess(l10n.nAccountsImported(imported));
      }
    } catch (e) {
      if (mounted) _showError(l10n.importError);
    }
  }

  Future<void> _clearAllData() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAllDataConfirm),
            const SizedBox(height: AppConstants.paddingMD),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.actionIrreversibleExcl,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deleteAllData),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearAllData();
      if (mounted) {
        _showSuccess(l10n.allDataDeleted);
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  String _getCurrentLanguageName() {
    if (_languageCode == null) return 'System';
    final lang = _supportedLanguages.where((l) => l.code == _languageCode);
    if (lang.isNotEmpty) return lang.first.name;
    return _languageCode!;
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Text(
                l10n.selectLanguage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _supportedLanguages.map((lang) {
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(lang.name),
                    trailing: _languageCode == lang.code
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      _setLanguage(lang.code);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountCount = widget.storageService.accountCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // --- Language ---
          _buildSectionHeader(theme, l10n.language, Icons.language_outlined),
          ListTile(
            leading: const Icon(Icons.translate_outlined),
            title: Text(l10n.language),
            subtitle: Text(_getCurrentLanguageName()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguagePicker,
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Appearance ---
          _buildSectionHeader(theme, l10n.appearance, Icons.palette_outlined),
          SwitchListTile(
            title: Text(l10n.darkMode),
            subtitle: Text(l10n.useDarkTheme),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Security ---
          _buildSectionHeader(theme, l10n.security, Icons.shield_outlined),
          SwitchListTile(
            title: Text(l10n.appLock),
            subtitle: Text(l10n.requirePasswordOnLaunch),
            value: _requireAuthOnLaunch,
            onChanged: _toggleRequireAuth,
            secondary: const Icon(Icons.lock_outline),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              title: Text(l10n.biometricAuth),
              subtitle: Text(l10n.fingerprintFaceId),
              value: _useBiometric,
              onChanged: _toggleBiometric,
              secondary: const Icon(Icons.fingerprint),
            ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(widget.authService.hasPassword()
                ? l10n.changePassword
                : l10n.setPassword),
            onTap: _changePassword,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Advanced Security ---
          _buildSectionHeader(
              theme, l10n.advancedSecurity, Icons.security_outlined),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l10n.autoLock),
            subtitle: Text(_formatAutoLock(_autoLockSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoLockPicker(),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_off_outlined),
            title: Text(l10n.clipboardClear),
            subtitle: Text(l10n.clipboardClearAfterSeconds(_clipboardClearSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClipboardClearPicker(),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(l10n.maxFailedAttemptsLabel),
            subtitle: Text(l10n.attemptsCount(_maxFailedAttempts)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMaxAttemptsPicker(),
          ),
          SwitchListTile(
            title: Text(l10n.wipeOnMaxAttemptsLabel),
            subtitle: Text(
              l10n.wipeAllDataOnMax,
              style: TextStyle(
                color: _wipeOnMaxAttempts ? AppColors.error : null,
              ),
            ),
            value: _wipeOnMaxAttempts,
            onChanged: _toggleWipeOnMax,
            secondary: Icon(
              Icons.delete_forever_outlined,
              color: _wipeOnMaxAttempts ? AppColors.error : null,
            ),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Backup ---
          _buildSectionHeader(theme, l10n.backup, Icons.backup_outlined),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.exportAccounts),
            subtitle: Text(l10n.nAccounts(accountCount)),
            onTap: accountCount > 0 ? _exportAccounts : null,
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.importAccounts),
            subtitle: Text(l10n.loadFromJSON),
            onTap: _importAccounts,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Danger Zone ---
          _buildSectionHeader(theme, l10n.dangerZone, Icons.warning_outlined,
              color: AppColors.error),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text(
              l10n.deleteAllData,
              style: const TextStyle(color: AppColors.error),
            ),
            subtitle: Text(l10n.actionIrreversible),
            onTap: _clearAllData,
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- About ---
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMD),
                  ),
                  child:
                      const Icon(Icons.shield, size: 22, color: Colors.white),
                ),
                const SizedBox(height: AppConstants.paddingSM),
                Text(
                  l10n.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(128),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.aboutEncryption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(102),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAutoLock(int seconds) {
    final l10n = AppLocalizations.of(context)!;
    if (seconds <= 0) return l10n.disabled;
    if (seconds < 60) return l10n.nSeconds(seconds);
    return l10n.nMinutes(seconds ~/ 60);
  }

  void _showAutoLockPicker() {
    final l10n = AppLocalizations.of(context)!;
    final options = {
      30: l10n.nSeconds(30),
      60: l10n.nMinutes(1),
      120: l10n.nMinutes(2),
      300: l10n.nMinutes(5),
      600: l10n.nMinutes(10),
    };
    _showOptionPicker(
      l10n.autoLock,
      options,
      _autoLockSeconds,
      (v) => _setAutoLockSeconds(v),
    );
  }

  void _showClipboardClearPicker() {
    final l10n = AppLocalizations.of(context)!;
    final options = {
      10: l10n.nSeconds(10),
      20: l10n.nSeconds(20),
      30: l10n.nSeconds(30),
      60: l10n.nMinutes(1),
      120: l10n.nMinutes(2),
    };
    _showOptionPicker(
      l10n.clipboardClearTime,
      options,
      _clipboardClearSeconds,
      (v) => _setClipboardClearSeconds(v),
    );
  }

  void _showMaxAttemptsPicker() {
    final l10n = AppLocalizations.of(context)!;
    final options = {
      3: l10n.attemptsCount(3),
      5: l10n.attemptsCount(5),
      10: l10n.attemptsCount(10),
      15: l10n.attemptsCount(15),
      20: l10n.attemptsCount(20),
    };
    _showOptionPicker(
      l10n.maxFailedAttemptsLabel,
      options,
      _maxFailedAttempts,
      (v) => _setMaxFailedAttempts(v),
    );
  }

  void _showOptionPicker(
    String title,
    Map<int, String> options,
    int currentValue,
    void Function(int) onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            ...options.entries.map(
              (entry) => ListTile(
                title: Text(entry.value),
                trailing: currentValue == entry.key
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(entry.key);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: AppConstants.paddingSM),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String name;
  final String flag;

  const _LanguageOption(this.code, this.name, this.flag);
}
