import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/backup_encryption_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'setup_screen.dart';

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

  // ─── EXPORT ───────────────────────────────────────────────────────────────

  /// Shows a bottom sheet letting the user choose encrypted vs plain export.
  Future<void> _onExportTapped(BuildContext tileCtx) async {
    final l10n = AppLocalizations.of(context)!;

    // Compute iOS share-sheet anchor rect NOW (synchronous, before any await).
    final originRect = _anchorRect(tileCtx);

    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLG)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMD, 12, AppConstants.paddingMD, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outline.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.exportBackup,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              // ── Encrypted option ──────────────────────────────────────────
              _ExportOptionTile(
                icon: Icons.lock_outlined,
                iconColor: AppColors.success,
                title: l10n.encryptedExport,
                subtitle: l10n.encryptedExportDesc,
                onTap: () => Navigator.pop(ctx, _ExportChoice.encrypted),
              ),
              const SizedBox(height: 8),
              // ── Unencrypted option ────────────────────────────────────────
              _ExportOptionTile(
                icon: Icons.lock_open_outlined,
                iconColor: AppColors.warning,
                title: l10n.unencryptedExport,
                subtitle: l10n.unencryptedExportDesc,
                onTap: () => Navigator.pop(ctx, _ExportChoice.plain),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !mounted) return;
    if (choice == _ExportChoice.encrypted) {
      await _exportEncrypted(originRect);
    } else {
      await _exportPlain(originRect);
    }
  }

  /// Encrypted export: shows password dialog → PBKDF2+AES-256-GCM → share.
  Future<void> _exportEncrypted(Rect originRect) async {
    final l10n = AppLocalizations.of(context)!;

    final password = await _showSetPasswordDialog(l10n);
    if (password == null || !mounted) return;

    // Show loading while running PBKDF2 (200 000 iterations in isolate).
    _showLoadingDialog(l10n.encryptingBackup);
    try {
      final jsonString = await widget.storageService.exportAccountsToJson();
      final bytes =
          await BackupEncryptionService.encryptBackup(jsonString, password);

      final fileName =
          'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}'
          '.${BackupEncryptionService.fileExtension}';

      // Close loading dialog.
      if (mounted) Navigator.of(context).pop();

      // Write to Documents dir and share.
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/octet-stream', name: fileName)],
          sharePositionOrigin: originRect,
        );
      } catch (_) {
        // Fallback: share the raw bytes as a temp file.
        final tmp = await getTemporaryDirectory();
        final file = File('${tmp.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, name: fileName)],
          sharePositionOrigin: originRect,
        );
      }

      if (mounted) _showSuccess(l10n.accountsExported);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // close loading if still open
        _showError('${l10n.exportError} ($e)');
      }
    }
  }

  /// Plain JSON export (existing behaviour).
  Future<void> _exportPlain(Rect originRect) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final jsonString = await widget.storageService.exportAccountsToJson();
      final fileName =
          'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(jsonString, flush: true);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/json', name: fileName)],
          sharePositionOrigin: originRect,
        );
      } catch (_) {
        await Share.share(jsonString,
            subject: fileName, sharePositionOrigin: originRect);
      }

      if (mounted) _showSuccess(l10n.accountsExported);
    } catch (e) {
      if (mounted) _showError('${l10n.exportError} ($e)');
    }
  }

  // ─── IMPORT ───────────────────────────────────────────────────────────────

  /// Handles both plain `.json` and encrypted `.saenc` files.
  Future<void> _importAccounts() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // FileType.any instead of FileType.custom: iOS doesn't have a registered
      // UTI for .saenc, so custom-extension filtering would hide those files.
      // We detect the format ourselves via magic bytes after picking.
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true, // required for cloud-backed files (iCloud etc.)
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      final Uint8List bytes;

      if (pickedFile.bytes != null) {
        bytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        bytes = await File(pickedFile.path!).readAsBytes();
      } else {
        if (mounted) _showError(l10n.importError);
        return;
      }

      final String jsonString;

      if (BackupEncryptionService.isEncryptedBackup(bytes)) {
        // ── Encrypted backup ───────────────────────────────────────────────
        final password = await _showDecryptPasswordDialog(l10n);
        if (password == null || !mounted) return;

        _showLoadingDialog(l10n.decryptingBackup);
        try {
          jsonString =
              await BackupEncryptionService.decryptBackup(bytes, password);
          if (mounted) Navigator.of(context).pop(); // close loading
        } on FormatException catch (e) {
          if (mounted) {
            Navigator.of(context).pop();
            _showError(e.message == 'Wrong password or corrupted backup file'
                ? l10n.wrongPasswordOrCorrupted
                : l10n.importError);
          }
          return;
        }
      } else {
        // ── Plain JSON backup ──────────────────────────────────────────────
        jsonString = utf8.decode(bytes);
      }

      final imported =
          await widget.storageService.importAccountsFromJson(jsonString);
      if (mounted) _showSuccess(l10n.nAccountsImported(imported));
    } catch (e) {
      if (mounted) _showError(l10n.importError);
    }
  }

  // ─── Password dialogs ─────────────────────────────────────────────────────

  /// Shows a password + confirm dialog with a strength indicator.
  /// Returns the entered password, or null if cancelled.
  Future<String?> _showSetPasswordDialog(AppLocalizations l10n) async {
    final pwCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool pwVisible = false;
    bool confirmVisible = false;
    String? error;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.setBackupPassword),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Password field
                TextField(
                  controller: pwCtrl,
                  obscureText: !pwVisible,
                  onChanged: (_) => setS(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.backupPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(pwVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setS(() => pwVisible = !pwVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Confirm password field
                TextField(
                  controller: confirmCtrl,
                  obscureText: !confirmVisible,
                  onChanged: (_) => setS(() {}),
                  decoration: InputDecoration(
                    labelText: l10n.confirmBackupPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(confirmVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setS(() => confirmVisible = !confirmVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Strength indicator
                _PasswordStrengthBar(password: pwCtrl.text),
                const SizedBox(height: 12),
                // Warning note
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingSM),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(20),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSM),
                    border: Border.all(color: AppColors.warning.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.backupPasswordWarning,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final pw = pwCtrl.text;
                final confirm = confirmCtrl.text;
                if (pw.length < AppConstants.minPasswordLength) {
                  setS(() => error = l10n
                      .passwordMinLength(AppConstants.minPasswordLength));
                  return;
                }
                if (pw != confirm) {
                  setS(() => error = l10n.passwordsDoNotMatch);
                  return;
                }
                Navigator.pop(ctx, pw);
              },
              child: Text(l10n.exportAccounts),
            ),
          ],
        ),
      ),
    );

    pwCtrl.dispose();
    confirmCtrl.dispose();
    return result;
  }

  /// Shows a single-field password dialog for decryption.
  Future<String?> _showDecryptPasswordDialog(AppLocalizations l10n) async {
    final ctrl = TextEditingController();
    bool visible = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.decryptBackup),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.enterBackupPassword,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withAlpha(153),
                      )),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                obscureText: !visible,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPassword,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(visible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setS(() => visible = !visible),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.isNotEmpty) Navigator.pop(ctx, v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) Navigator.pop(ctx, ctrl.text);
              },
              child: Text(l10n.decryptBackup),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
    return result;
  }

  // ─── Utility helpers ──────────────────────────────────────────────────────

  /// Compute the iOS share-sheet anchor rect from a tile's BuildContext.
  /// Must be called synchronously BEFORE any await.
  Rect _anchorRect(BuildContext tileCtx) {
    final box = tileCtx.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 100),
      width: 1,
      height: 1,
    );
  }

  /// Shows a non-dismissible loading dialog during PBKDF2 / AES operations.
  void _showLoadingDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
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
      // Clear Hive data and reset settings to factory defaults.
      await widget.storageService.clearAllData();
      // Clear brute-force counters / lockout from secure storage.
      await widget.authService.clearSecurityState();

      if (mounted) {
        // Pop the entire navigation stack and replace it with SetupScreen.
        // AppSettings() defaults: requireAuthOnLaunch=true, no passwordHash
        // → SetupScreen is the correct "fresh install" starting point.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SetupScreen(
              storageService: widget.storageService,
              authService: widget.authService,
              onThemeChanged: widget.onThemeChanged,
              onLocaleChanged: widget.onLocaleChanged,
            ),
          ),
          (route) => false, // remove all existing routes
        );
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
                    ? () => _onExportTapped(tileCtx)
                    : null,
              ),
            ),
            _buildInternalDivider(),
            ListTile(
              leading:
                  _buildLeadingIcon(Icons.download_outlined, AppColors.accent),
              title: Text(l10n.importAccounts),
              subtitle: Text(l10n.loadFromFile),
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

// ── Export choice enum ─────────────────────────────────────────────────────

enum _ExportChoice { encrypted, plain }

// ── Export option tile ─────────────────────────────────────────────────────

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: theme.colorScheme.outline.withAlpha(60)),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(22),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withAlpha(128))),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}

// ── Password strength bar ──────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  static ({double value, Color color, String label}) _strength(
      String pw, AppLocalizations l10n) {
    if (pw.isEmpty) {
      return (value: 0, color: Colors.transparent, label: '');
    }
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 12) score++;
    if (pw.length >= 16) score++;
    if (RegExp(r'[A-Z]').hasMatch(pw)) score++;
    if (RegExp(r'[a-z]').hasMatch(pw)) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pw)) score += 2;

    if (score <= 2) {
      return (value: 0.2, color: AppColors.error, label: l10n.strengthWeak);
    } else if (score <= 4) {
      return (
        value: 0.45,
        color: AppColors.warning,
        label: l10n.strengthMedium
      );
    } else if (score <= 6) {
      return (
        value: 0.70,
        color: AppColors.primary,
        label: l10n.strengthGood
      );
    } else if (score <= 7) {
      return (
        value: 0.85,
        color: AppColors.success,
        label: l10n.strengthStrong
      );
    } else {
      return (
        value: 1.0,
        color: AppColors.success,
        label: l10n.strengthVeryStrong
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = _strength(password, l10n);
    if (password.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: s.value,
            minHeight: 6,
            backgroundColor:
                Theme.of(context).colorScheme.outline.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(s.color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: s.color),
        ),
      ],
    );
  }
}

// ── Language option ────────────────────────────────────────────────────────

class _LanguageOption {
  final String code;
  final String name;
  final String flag;

  const _LanguageOption(this.code, this.name, this.flag);
}
