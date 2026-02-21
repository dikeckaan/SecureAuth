import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
              if (newPasswordController.text != confirmPasswordController.text) {
                _showError(l10n.passwordsDoNotMatch);
                return;
              }
              await widget.authService.setPassword(newPasswordController.text);
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

  // ─── EXPORT: Documents dir primary, plain-text share as fallback ─────────
  // [originContext] is the BuildContext of the tapped tile — used on iOS to
  // compute the sharePositionOrigin rect the share-sheet popover anchors to.
  Future<void> _exportAccounts(BuildContext originContext) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Compute the anchor rect BEFORE any await so context is safe to use.
      Rect originRect = Rect.zero;
      final box = originContext.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        originRect = box.localToGlobal(Offset.zero) & box.size;
      }
      if (originRect.isEmpty) {
        // Sensible default: bottom-centre of screen.
        final size = MediaQuery.sizeOf(context);
        originRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height - 100),
          width: 1,
          height: 1,
        );
      }

      final jsonString = await widget.storageService.exportAccountsToJson();
      final fileName =
          'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      // Primary: write to Documents directory and share as a JSON file.
      // Documents dir is accessible from Files.app on iOS and is stable.
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/json', name: fileName)],
          sharePositionOrigin: originRect,
        );
      } catch (_) {
        // Fallback: share raw JSON text — works everywhere, no file perms needed
        await Share.share(jsonString,
            subject: fileName, sharePositionOrigin: originRect);
      }

      if (mounted) _showSuccess(l10n.accountsExported);
    } catch (e) {
      if (mounted) _showError('${l10n.exportError} ($e)');
    }
  }

  // ─── IMPORT FIX: withData:true + bytes fallback for iCloud / cloud files ───
  Future<void> _importAccounts() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // ensures bytes are populated even for cloud-backed files
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final String jsonString;

      if (pickedFile.path != null) {
        jsonString = await File(pickedFile.path!).readAsString();
      } else if (pickedFile.bytes != null) {
        jsonString = utf8.decode(pickedFile.bytes!);
      } else {
        if (mounted) _showError(l10n.importError);
        return;
      }

      final imported =
          await widget.storageService.importAccountsFromJson(jsonString);

      if (mounted) _showSuccess(l10n.nAccountsImported(imported));
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingSM,
        ),
        children: [
          // ── Language ─────────────────────────────────────────────
          _buildSectionLabel(theme, l10n.language, Icons.language_outlined),
          _buildCard([
            ListTile(
              leading: _buildLeadingIcon(
                  Icons.translate_outlined, theme.colorScheme.primary),
              title: Text(l10n.language),
              subtitle: Text(_getCurrentLanguageName()),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _showLanguagePicker,
            ),
          ]),

          // ── Appearance ────────────────────────────────────────────
          _buildSectionLabel(
              theme, l10n.appearance, Icons.palette_outlined),
          _buildCard([
            SwitchListTile(
              secondary: _buildLeadingIcon(
                  Icons.dark_mode_outlined, theme.colorScheme.primary),
              title: Text(l10n.darkMode),
              subtitle: Text(l10n.useDarkTheme),
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ]),

          // ── Security ──────────────────────────────────────────────
          _buildSectionLabel(theme, l10n.security, Icons.shield_outlined),
          _buildCard([
            SwitchListTile(
              secondary: _buildLeadingIcon(
                  Icons.lock_outline, theme.colorScheme.primary),
              title: Text(l10n.appLock),
              subtitle: Text(l10n.requirePasswordOnLaunch),
              value: _requireAuthOnLaunch,
              onChanged: _toggleRequireAuth,
            ),
            if (_biometricAvailable) ...[
              _buildInternalDivider(),
              SwitchListTile(
                secondary: _buildLeadingIcon(
                    Icons.fingerprint, theme.colorScheme.primary),
                title: Text(l10n.biometricAuth),
                subtitle: Text(l10n.fingerprintFaceId),
                value: _useBiometric,
                onChanged: _toggleBiometric,
              ),
            ],
            _buildInternalDivider(),
            ListTile(
              leading: _buildLeadingIcon(
                  Icons.key_outlined, theme.colorScheme.primary),
              title: Text(widget.authService.hasPassword()
                  ? l10n.changePassword
                  : l10n.setPassword),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _changePassword,
            ),
          ]),

          // ── Advanced Security ─────────────────────────────────────
          _buildSectionLabel(
              theme, l10n.advancedSecurity, Icons.security_outlined),
          _buildCard([
            ListTile(
              leading: _buildLeadingIcon(
                  Icons.timer_outlined, theme.colorScheme.primary),
              title: Text(l10n.autoLock),
              subtitle: Text(_formatAutoLock(_autoLockSeconds)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _showAutoLockPicker,
            ),
            _buildInternalDivider(),
            ListTile(
              leading: _buildLeadingIcon(
                  Icons.content_paste_off_outlined, theme.colorScheme.primary),
              title: Text(l10n.clipboardClear),
              subtitle:
                  Text(l10n.clipboardClearAfterSeconds(_clipboardClearSeconds)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _showClipboardClearPicker,
            ),
            _buildInternalDivider(),
            ListTile(
              leading: _buildLeadingIcon(
                  Icons.pin_outlined, theme.colorScheme.primary),
              title: Text(l10n.maxFailedAttemptsLabel),
              subtitle: Text(l10n.attemptsCount(_maxFailedAttempts)),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _showMaxAttemptsPicker,
            ),
            _buildInternalDivider(),
            SwitchListTile(
              secondary: _buildLeadingIcon(
                Icons.delete_forever_outlined,
                _wipeOnMaxAttempts ? AppColors.error : theme.colorScheme.primary,
              ),
              title: Text(l10n.wipeOnMaxAttemptsLabel),
              subtitle: Text(
                l10n.wipeAllDataOnMax,
                style: TextStyle(
                  color: _wipeOnMaxAttempts ? AppColors.error : null,
                ),
              ),
              value: _wipeOnMaxAttempts,
              onChanged: _toggleWipeOnMax,
            ),
          ]),

          // ── Backup ────────────────────────────────────────────────
          _buildSectionLabel(theme, l10n.backup, Icons.backup_outlined),
          _buildCard([
            Builder(
              builder: (tileCtx) => ListTile(
                leading: _buildLeadingIcon(
                    Icons.upload_outlined, AppColors.success),
                title: Text(l10n.exportAccounts),
                subtitle: Text(l10n.nAccounts(accountCount)),
                trailing: accountCount > 0
                    ? const Icon(Icons.chevron_right, size: 18)
                    : null,
                enabled: accountCount > 0,
                onTap: accountCount > 0
                    ? () => _exportAccounts(tileCtx)
                    : null,
              ),
            ),
            _buildInternalDivider(),
            ListTile(
              leading:
                  _buildLeadingIcon(Icons.download_outlined, AppColors.accent),
              title: Text(l10n.importAccounts),
              subtitle: Text(l10n.loadFromJSON),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: _importAccounts,
            ),
          ]),

          // ── Danger Zone ───────────────────────────────────────────
          _buildSectionLabel(
            theme,
            l10n.dangerZone,
            Icons.warning_outlined,
            color: AppColors.error,
          ),
          _buildCard(
            [
              ListTile(
                leading: _buildLeadingIcon(
                    Icons.delete_forever, AppColors.error),
                title: Text(
                  l10n.deleteAllData,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(l10n.actionIrreversible),
                onTap: _clearAllData,
              ),
            ],
            borderColor: AppColors.error.withAlpha(77),
          ),

          // ── About ─────────────────────────────────────────────────
          const SizedBox(height: AppConstants.paddingLG),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLG),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: const Icon(Icons.shield, size: 24, color: Colors.white),
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingXL),
        ],
      ),
    );
  }

  // ─── UI helpers ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(ThemeData theme, String title, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color ?? theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children, {Color? borderColor}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outline.withAlpha(60),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInternalDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outline.withAlpha(40),
      ),
    );
  }

  Widget _buildLeadingIcon(IconData icon, Color color) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  // ─── Pickers ───────────────────────────────────────────────────────────────

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
    _showOptionPicker(l10n.autoLock, options, _autoLockSeconds,
        _setAutoLockSeconds);
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
    _showOptionPicker(l10n.clipboardClearTime, options, _clipboardClearSeconds,
        _setClipboardClearSeconds);
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
    _showOptionPicker(l10n.maxFailedAttemptsLabel, options, _maxFailedAttempts,
        _setMaxFailedAttempts);
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
