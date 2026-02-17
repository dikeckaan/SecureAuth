import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;

  const SetupScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _useBiometric = false;
  bool _biometricAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await widget.authService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _setupSecurity() async {
    if (_passwordController.text.isEmpty) {
      _showError('Lütfen bir şifre belirleyin');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler eşleşmiyor');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.setPassword(_passwordController.text);
      await widget.authService.enableBiometric(_useBiometric);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              storageService: widget.storageService,
              authService: widget.authService,
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Bir hata oluştu: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _skipSetup() async {
    final settings = widget.storageService.getSettings();
    settings.requireAuthOnLaunch = false;
    await widget.storageService.updateSettings(settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            storageService: widget.storageService,
            authService: widget.authService,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.security,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'SecureAuth\'a Hoş Geldiniz',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Hesaplarınızı güvende tutmak için bir şifre belirleyin',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: AppConstants.largePadding),
                Card(
                  child: SwitchListTile(
                    title: const Text('Biyometrik Kimlik Doğrulama'),
                    subtitle: const Text('Parmak izi veya yüz tanıma kullan'),
                    value: _useBiometric,
                    onChanged: (value) => setState(() => _useBiometric = value),
                    secondary: const Icon(Icons.fingerprint),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              CustomButton(
                text: 'Kurulumu Tamamla',
                onPressed: _setupSecurity,
                isLoading: _isLoading,
                icon: Icons.check,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              CustomButton(
                text: 'Şifresiz Devam Et',
                onPressed: _skipSetup,
                isOutlined: true,
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'Not: Şifre belirlemezseniz uygulama açık kalacaktır',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
