import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

class AuthScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final VoidCallback onThemeChanged;
  final VoidCallback onLocaleChanged;

  const AuthScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  Duration? _lockoutRemaining;
  Timer? _lockoutTimer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _checkLockout();
    _tryBiometricAuth();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final remaining = await widget.authService.getRemainingLockout();
    final attempts = await widget.authService.getFailedAttempts();

    if (mounted) {
      setState(() {
        _failedAttempts = attempts;
        _lockoutRemaining = remaining;
      });
    }

    if (remaining != null) {
      _startLockoutTimer();
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final remaining = await widget.authService.getRemainingLockout();
      if (mounted) {
        setState(() => _lockoutRemaining = remaining);
        if (remaining == null) {
          _lockoutTimer?.cancel();
        }
      }
    });
  }

  Future<void> _tryBiometricAuth() async {
    if (widget.authService.isBiometricEnabled()) {
      final authenticated =
          await widget.authService.authenticateWithBiometric();
      if (authenticated && mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _authenticate() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseEnterPassword);
      return;
    }

    // Check lockout
    if (await widget.authService.isLockedOut()) {
      await _checkLockout();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.authService.verifyPassword(password);
      if (isValid) {
        if (mounted) _navigateToHome();
      } else {
        HapticFeedback.heavyImpact();
        _shakeController.forward().then((_) => _shakeController.reset());

        // If verifyPassword wiped all data, hasPassword() is now false.
        // Show the big warning dialog then go to SetupScreen.
        if (!widget.authService.hasPassword()) {
          if (mounted) _showDataWipedDialog(l10n);
          return;
        }

        final attempts = await widget.authService.getFailedAttempts();
        final remaining = await widget.authService.getRemainingLockout();
        final settings = widget.storageService.getSettings();

        if (mounted) {
          setState(() {
            _failedAttempts = attempts;
            _lockoutRemaining = remaining;
            if (remaining != null) {
              _errorMessage = l10n.tooManyAttempts;
              _startLockoutTimer();
            } else {
              _errorMessage = l10n.wrongPasswordWithRemaining(
                  settings.maxFailedAttempts - attempts);
            }
          });
        }

        _passwordController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDataWipedDialog(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    size: 40,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLG),
                Text(
                  l10n.dataWipedTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingMD),
                Text(
                  l10n.dataWipedBody,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppConstants.paddingMD),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      _navigateToSetup();
                    },
                    child: Text(
                      l10n.ok,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSetup() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SetupScreen(
          storageService: widget.storageService,
          authService: widget.authService,
          onThemeChanged: widget.onThemeChanged,
          onLocaleChanged: widget.onLocaleChanged,
        ),
      ),
      (route) => false,
    );
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

  String _formatDuration(Duration d) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) {
      return l10n.minuteShortFormat(minutes, seconds);
    }
    return l10n.secondShortFormat(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = _lockoutRemaining != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.authGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusXL),
                      border: Border.all(
                        color: Colors.white.withAlpha(51),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLG),
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSM),
                  Text(
                    l10n.authSubtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingXXL),
                  // Auth Card
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingLG),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLG),
                      border: Border.all(
                        color: Colors.white.withAlpha(38),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Lockout warning
                        if (isLocked) ...[
                          Container(
                            padding:
                                const EdgeInsets.all(AppConstants.paddingMD),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(38),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD),
                              border: Border.all(
                                color: AppColors.error.withAlpha(77),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_clock,
                                    color: AppColors.error, size: 20),
                                const SizedBox(width: AppConstants.paddingSM),
                                Expanded(
                                  child: Text(
                                    l10n.lockedWithTime(
                                        _formatDuration(_lockoutRemaining!)),
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingMD),
                        ],
                        // Password field
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            final dx = _shakeAnimation.value *
                                10 *
                                ((_shakeController.value * 6).toInt().isEven
                                    ? 1
                                    : -1);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _focusNode,
                            obscureText: _obscurePassword,
                            enabled: !isLocked,
                            onSubmitted: (_) =>
                                isLocked ? null : _authenticate(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              labelStyle: TextStyle(
                                color: Colors.white.withAlpha(153),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.white.withAlpha(153),
                              ),
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
                                  color: Colors.white.withAlpha(51),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                                borderSide: BorderSide(
                                  color: Colors.white.withAlpha(26),
                                ),
                              ),
                              errorText: _errorMessage,
                              errorStyle: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingMD),
                        // Failed attempts indicator
                        if (_failedAttempts > 0 && !isLocked)
                          Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppConstants.paddingSM),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 14,
                                    color: AppColors.warning.withAlpha(204)),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.failedAttemptsCount(_failedAttempts),
                                  style: TextStyle(
                                    color: AppColors.warning.withAlpha(204),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Login button
                        GradientButton(
                          text: l10n.login,
                          onPressed: isLocked ? null : _authenticate,
                          isLoading: _isLoading,
                          icon: Icons.login,
                        ),
                        // Biometric button
                        if (widget.authService.isBiometricEnabled()) ...[
                          const SizedBox(height: AppConstants.paddingMD),
                          OutlinedButton.icon(
                            onPressed: isLocked ? null : _tryBiometricAuth,
                            icon: const Icon(Icons.fingerprint,
                                color: Colors.white),
                            label: Text(
                              l10n.biometricLogin,
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withAlpha(102),
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.paddingMD),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
