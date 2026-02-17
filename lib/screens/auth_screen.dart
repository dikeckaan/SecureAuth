import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;

  const AuthScreen({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricAuth();
  }

  Future<void> _tryBiometricAuth() async {
    if (widget.authService.isBiometricEnabled()) {
      final authenticated = await widget.authService.authenticateWithBiometric();
      if (authenticated && mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_passwordController.text.isEmpty) {
      _showError('Lütfen şifrenizi girin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isValid = widget.authService.verifyPassword(_passwordController.text);
      if (isValid) {
        _navigateToHome();
      } else {
        _showError('Yanlış şifre');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          storageService: widget.storageService,
          authService: widget.authService,
        ),
      ),
    );
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
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'SecureAuth',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Hesaplarınıza erişmek için kimliğinizi doğrulayın',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _authenticate(),
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
              CustomButton(
                text: 'Giriş Yap',
                onPressed: _authenticate,
                isLoading: _isLoading,
                icon: Icons.login,
              ),
              if (widget.authService.isBiometricEnabled()) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                CustomButton(
                  text: 'Biyometrik ile Giriş',
                  onPressed: _tryBiometricAuth,
                  isOutlined: true,
                  icon: Icons.fingerprint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
