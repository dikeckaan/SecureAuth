import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final VoidCallback onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
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
  bool _biometricAvailable = false;

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
    if (value && !widget.authService.hasPassword()) {
      _showError('Once sifre belirlemeniz gerekiyor');
      return;
    }
    await widget.authService.enableBiometric(value);
    setState(() => _useBiometric = value);
  }

  Future<void> _toggleRequireAuth(bool value) async {
    if (value && !widget.authService.hasPassword()) {
      _showError('Once sifre belirlemeniz gerekiyor');
      return;
    }
    await _updateSetting((s) => s.requireAuthOnLaunch = value);
    setState(() => _requireAuthOnLaunch = value);
  }

  Future<void> _toggleWipeOnMax(bool value) async {
    if (value) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dikkat'),
          content: Text(
            '$_maxFailedAttempts basarisiz giris denemesinden sonra tum veriler otomatik olarak silinecek. '
            'Bu ozellik geri alinamaz veri kaybina neden olabilir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Iptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Etkinlestir'),
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

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final hasExisting = widget.authService.hasPassword();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasExisting ? 'Sifre Degistir' : 'Sifre Belirle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasExisting)
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mevcut Sifre',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              if (hasExisting) const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Sifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Sifre Tekrar',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () async {
              if (hasExisting) {
                final isValid = await widget.authService
                    .verifyPassword(oldPasswordController.text);
                if (!isValid) {
                  if (context.mounted) _showError('Mevcut sifre yanlis');
                  return;
                }
              }

              if (newPasswordController.text.length <
                  AppConstants.minPasswordLength) {
                _showError(
                    'Sifre en az ${AppConstants.minPasswordLength} karakter olmalidir');
                return;
              }

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                _showError('Sifreler eslesmyor');
                return;
              }

              await widget.authService
                  .setPassword(newPasswordController.text);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == true && mounted) {
      _showSuccess('Sifre basariyla degistirildi');
    }
  }

  Future<void> _exportAccounts() async {
    try {
      final jsonString = await widget.storageService.exportAccountsToJson();
      final fileName =
          'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SecureAuth Yedek',
        text: 'SecureAuth hesap yedekleme dosyasi',
      );

      if (mounted) _showSuccess('Hesaplar disa aktarildi');
    } catch (e) {
      if (mounted) _showError('Disa aktarma hatasi');
    }
  }

  Future<void> _importAccounts() async {
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
        _showSuccess('$imported hesap basariyla ice aktarildi');
      }
    } catch (e) {
      if (mounted) _showError('Ice aktarma hatasi');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tum Verileri Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu islem tum hesaplari ve ayarlari silecektir.',
            ),
            const SizedBox(height: AppConstants.paddingMD),
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingSM),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu islem geri alinamaz!',
                      style: TextStyle(
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
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tum Verileri Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearAllData();
      if (mounted) {
        _showSuccess('Tum veriler silindi');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountCount = widget.storageService.accountCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // --- Appearance ---
          _buildSectionHeader(theme, 'Gorunum', Icons.palette_outlined),
          SwitchListTile(
            title: const Text('Karanlik Mod'),
            subtitle: const Text('Koyu tema kullan'),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: const Icon(Icons.dark_mode_outlined),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Security ---
          _buildSectionHeader(theme, 'Guvenlik', Icons.shield_outlined),
          SwitchListTile(
            title: const Text('Uygulama Kilidi'),
            subtitle: const Text('Acilista sifre iste'),
            value: _requireAuthOnLaunch,
            onChanged: _toggleRequireAuth,
            secondary: const Icon(Icons.lock_outline),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              title: const Text('Biyometrik Dogrulama'),
              subtitle: const Text('Parmak izi / yuz tanima'),
              value: _useBiometric,
              onChanged: _toggleBiometric,
              secondary: const Icon(Icons.fingerprint),
            ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: Text(widget.authService.hasPassword()
                ? 'Sifre Degistir'
                : 'Sifre Belirle'),
            onTap: _changePassword,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Advanced Security ---
          _buildSectionHeader(
              theme, 'Gelismis Guvenlik', Icons.security_outlined),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Otomatik Kilitleme'),
            subtitle: Text(_formatAutoLock(_autoLockSeconds)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoLockPicker(),
          ),
          ListTile(
            leading: const Icon(Icons.content_paste_off_outlined),
            title: const Text('Pano Temizleme'),
            subtitle: Text('$_clipboardClearSeconds saniye sonra'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClipboardClearPicker(),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Max Basarisiz Deneme'),
            subtitle: Text('$_maxFailedAttempts deneme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMaxAttemptsPicker(),
          ),
          SwitchListTile(
            title: const Text('Denemede Veri Silme'),
            subtitle: Text(
              'Max denemede tum verileri sil',
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
          _buildSectionHeader(theme, 'Yedekleme', Icons.backup_outlined),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Hesaplari Disa Aktar'),
            subtitle: Text('$accountCount hesap'),
            onTap: accountCount > 0 ? _exportAccounts : null,
            trailing: const Icon(Icons.chevron_right),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Hesaplari Ice Aktar'),
            subtitle: const Text('JSON dosyasindan yukle'),
            onTap: _importAccounts,
            trailing: const Icon(Icons.chevron_right),
          ),
          const Divider(indent: 16, endIndent: 16),

          // --- Danger Zone ---
          _buildSectionHeader(theme, 'Tehlikeli Bolge', Icons.warning_outlined,
              color: AppColors.error),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Tum Verileri Sil',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Bu islem geri alinamaz'),
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
                  'SecureAuth',
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
                  'PBKDF2-SHA512 | AES-256 | Tamamen Offline',
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
    if (seconds <= 0) return 'Kapali';
    if (seconds < 60) return '$seconds saniye';
    return '${seconds ~/ 60} dakika';
  }

  void _showAutoLockPicker() {
    final options = {
      30: '30 saniye',
      60: '1 dakika',
      120: '2 dakika',
      300: '5 dakika',
      600: '10 dakika',
    };
    _showOptionPicker(
      'Otomatik Kilitleme',
      options,
      _autoLockSeconds,
      (v) => _setAutoLockSeconds(v),
    );
  }

  void _showClipboardClearPicker() {
    final options = {
      10: '10 saniye',
      20: '20 saniye',
      30: '30 saniye',
      60: '1 dakika',
      120: '2 dakika',
    };
    _showOptionPicker(
      'Pano Temizleme Suresi',
      options,
      _clipboardClearSeconds,
      (v) => _setClipboardClearSeconds(v),
    );
  }

  void _showMaxAttemptsPicker() {
    final options = {
      3: '3 deneme',
      5: '5 deneme',
      10: '10 deneme',
      15: '15 deneme',
      20: '20 deneme',
    };
    _showOptionPicker(
      'Max Basarisiz Deneme',
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
