import 'package:flutter/material.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final VoidCallback onThemeChanged;
  final VoidCallback onLocaleChanged;

  const SetupScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
    required this.onLocaleChanged,
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
  late int _themePreference;

  @override
  void initState() {
    super.initState();
    _themePreference = widget.storageService.getSettings().themePreference;
    _checkBiometric();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await widget.authService.isBiometricAvailable();
    if (mounted) {
      setState(() => _biometricAvailable = available);
    }
  }

  Future<void> _setThemePreference(int value) async {
    final settings = widget.storageService.getSettings();
    settings.themePreference = value;
    await widget.storageService.updateSettings(settings);
    setState(() => _themePreference = value);
    widget.onThemeChanged();
  }

  void _cycleTheme() {
    // 0 (system) → 1 (light) → 2 (dark) → 3 (pureDark) → 0
    final next = (_themePreference + 1) % 4;
    _setThemePreference(next);
  }

  IconData _themeIcon() {
    switch (_themePreference) {
      case 1:
        return Icons.light_mode;
      case 2:
        return Icons.dark_mode;
      case 3:
        return Icons.nightlight_round;
      default:
        return Icons.brightness_auto;
    }
  }

  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 10) strength += 0.15;
    if (password.length >= 14) strength += 0.15;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.1;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.15;
    return strength.clamp(0.0, 1.0);
  }

  String _getStrengthLabel(double strength) {
    final l10n = AppLocalizations.of(context)!;
    if (strength == 0) return '';
    if (strength < 0.3) return l10n.strengthWeak;
    if (strength < 0.5) return l10n.strengthMedium;
    if (strength < 0.7) return l10n.strengthGood;
    if (strength < 0.9) return l10n.strengthStrong;
    return l10n.strengthVeryStrong;
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return AppColors.error;
    if (strength < 0.5) return AppColors.warning;
    if (strength < 0.7) return AppColors.accent;
    return AppColors.success;
  }

  Future<void> _setupSecurity() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showError(l10n.pleaseSetPassword);
      return;
    }

    if (password.length < AppConstants.minPasswordLength) {
      _showError(l10n.passwordMinLength(AppConstants.minPasswordLength));
      return;
    }

    if (password != confirm) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.setPassword(password);
      await widget.authService.enableBiometric(_useBiometric);

      if (mounted) _navigateToHome();
    } catch (e) {
      if (mounted) _showError(l10n.anErrorOccurred);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skipSetup() async {
    final settings = widget.storageService.getSettings();
    settings.requireAuthOnLaunch = false;
    await widget.storageService.updateSettings(settings);

    if (mounted) _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          storageService: widget.storageService,
          authService: widget.authService,
          onThemeChanged: widget.onThemeChanged,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strength = _getPasswordStrength(_passwordController.text);
    final strengthLabel = _getStrengthLabel(strength);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authGradient),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme toggle — top right
              Positioned(
                top: AppConstants.paddingSM,
                right: AppConstants.paddingSM,
                child: IconButton(
                  onPressed: _cycleTheme,
                  icon: Icon(_themeIcon(), color: Colors.white.withAlpha(179)),
                  tooltip: l10n.themeMode,
                ),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusXL),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLG),
                  Text(
                    l10n.welcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  Text(
                    l10n.setupSubtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingXL),
                  // Setup Card
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLG),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLG),
                      border: Border.all(
                        color: Colors.white.withAlpha(38),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Password field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            labelStyle: TextStyle(
                                color: Colors.white.withAlpha(153)),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.white.withAlpha(153)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white.withAlpha(153),
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha(18),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              borderSide: BorderSide(
                                  color: Colors.white.withAlpha(51)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Password strength indicator
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: AppConstants.paddingSM),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: strength,
                              backgroundColor: Colors.white.withAlpha(26),
                              valueColor: AlwaysStoppedAnimation(
                                  _getStrengthColor(strength)),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strengthLabel,
                            style: TextStyle(
                              color: _getStrengthColor(strength),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppConstants.paddingMD),
                        // Confirm password
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: l10n.confirmPassword,
                            labelStyle: TextStyle(
                                color: Colors.white.withAlpha(153)),
                            prefixIcon: Icon(Icons.lock_outline,
                                color: Colors.white.withAlpha(153)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.white.withAlpha(153),
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha(18),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              borderSide: BorderSide(
                                  color: Colors.white.withAlpha(51)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              borderSide: const BorderSide(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Biometric toggle
                        if (_biometricAvailable) ...[
                          const SizedBox(height: AppConstants.paddingLG),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMD,
                              vertical: AppConstants.paddingSM,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(13),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              border: Border.all(
                                  color: Colors.white.withAlpha(26)),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                l10n.biometricAuth,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              subtitle: Text(
                                l10n.fingerprintOrFace,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 12,
                                ),
                              ),
                              value: _useBiometric,
                              onChanged: (value) =>
                                  setState(() => _useBiometric = value),
                              secondary: Icon(Icons.fingerprint,
                                  color: Colors.white.withAlpha(179)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppConstants.paddingLG),
                        // Setup button
                        GradientButton(
                          text: l10n.completeSetup,
                          onPressed: _setupSecurity,
                          isLoading: _isLoading,
                          icon: Icons.check,
                        ),
                        const SizedBox(height: AppConstants.paddingMD),
                        // Skip button
                        TextButton(
                          onPressed: _skipSetup,
                          child: Text(
                            l10n.continueWithoutPassword,
                            style: TextStyle(
                              color: Colors.white.withAlpha(153),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMD),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: Colors.white.withAlpha(102)),
                      const SizedBox(width: 6),
                      Text(
                        l10n.strongEncryption,
                        style: TextStyle(
                          color: Colors.white.withAlpha(102),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
