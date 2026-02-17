import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode;
  late bool _useBiometric;
  late bool _requireAuthOnLaunch;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometric();
  }

  void _loadSettings() {
    final settings = widget.storageService.getSettings();
    setState(() {
      _isDarkMode = settings.isDarkMode;
      _useBiometric = settings.useBiometric;
      _requireAuthOnLaunch = settings.requireAuthOnLaunch;
    });
  }

  Future<void> _checkBiometric() async {
    final available = await widget.authService.isBiometricAvailable();
    setState(() => _biometricAvailable = available);
  }

  Future<void> _toggleDarkMode(bool value) async {
    final settings = widget.storageService.getSettings();
    settings.isDarkMode = value;
    await widget.storageService.updateSettings(settings);
    setState(() => _isDarkMode = value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !widget.authService.hasPassword()) {
      _showError('Biyometrik kimlik doğrulamayı etkinleştirmek için önce şifre belirlemelisiniz');
      return;
    }

    await widget.authService.enableBiometric(value);
    setState(() => _useBiometric = value);
  }

  Future<void> _toggleRequireAuth(bool value) async {
    final settings = widget.storageService.getSettings();
    settings.requireAuthOnLaunch = value;
    await widget.storageService.updateSettings(settings);
    setState(() => _requireAuthOnLaunch = value);
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.authService.hasPassword())
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre Tekrar'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              if (widget.authService.hasPassword() &&
                  !widget.authService.verifyPassword(oldPasswordController.text)) {
                _showError('Mevcut şifre yanlış');
                return;
              }

              if (newPasswordController.text.length < 6) {
                _showError('Şifre en az 6 karakter olmalıdır');
                return;
              }

              if (newPasswordController.text != confirmPasswordController.text) {
                _showError('Şifreler eşleşmiyor');
                return;
              }

              await widget.authService.setPassword(newPasswordController.text);
              Navigator.pop(context, true);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _showSuccess('Şifre başarıyla değiştirildi');
    }
  }

  Future<void> _exportAccounts() async {
    try {
      final jsonString = await widget.storageService.exportAccountsToJson();
      final fileName = 'secureauth_backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final directory = Directory.systemTemp;
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SecureAuth Yedek',
        text: 'SecureAuth hesap yedekleme dosyası',
      );

      _showSuccess('Hesaplar dışa aktarıldı');
    } catch (e) {
      _showError('Dışa aktarma hatası: $e');
    }
  }

  Future<void> _importAccounts() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();

      final imported = await widget.storageService.importAccountsFromJson(jsonString);

      if (mounted) {
        _showSuccess('$imported hesap başarıyla içe aktarıldı');
      }
    } catch (e) {
      _showError('İçe aktarma hatası: $e');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Bu işlem tüm hesapları ve ayarları silecektir. Bu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearAllData();
      if (mounted) {
        _showSuccess('Tüm veriler silindi');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              'Görünüm',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Karanlık Mod'),
            subtitle: const Text('Koyu tema kullan'),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Güvenlik',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Uygulama Açılışta Kimlik Doğrula'),
            subtitle: const Text('Uygulamayı açarken şifre iste'),
            value: _requireAuthOnLaunch,
            onChanged: _toggleRequireAuth,
            secondary: const Icon(Icons.lock),
          ),
          if (_biometricAvailable)
            SwitchListTile(
              title: const Text('Biyometrik Kimlik Doğrulama'),
              subtitle: const Text('Parmak izi veya yüz tanıma kullan'),
              value: _useBiometric,
              onChanged: _toggleBiometric,
              secondary: const Icon(Icons.fingerprint),
            ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Şifre Değiştir'),
            onTap: _changePassword,
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Yedekleme',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Hesapları Dışa Aktar'),
            subtitle: const Text('JSON dosyası olarak kaydet'),
            onTap: _exportAccounts,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Hesapları İçe Aktar'),
            subtitle: const Text('JSON dosyasından yükle'),
            onTap: _importAccounts,
          ),
          const Divider(),
          ListTile(
            title: Text(
              'Tehlikeli Bölge',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Tüm Verileri Sil',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Bu işlem geri alınamaz'),
            onTap: _clearAllData,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Text(
                  'SecureAuth',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Versiyon ${AppConstants.appVersion}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Tamamen offline, gizliliğe önem veren 2FA uygulaması',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
