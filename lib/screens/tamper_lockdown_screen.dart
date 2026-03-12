import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/tamper_detection_service.dart';
import '../utils/constants.dart';

/// Full-screen lockdown displayed when clock tampering is detected.
///
/// This screen completely blocks the app — not even the normal login screen
/// is shown. The user MUST enter their correct master password (biometrics
/// are explicitly disabled) to clear the tamper flag and regain access.
class TamperLockdownScreen extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final TamperDetectionService tamperDetectionService;
  final VoidCallback onCleared;

  const TamperLockdownScreen({
    super.key,
    required this.storageService,
    required this.authService,
    required this.tamperDetectionService,
    required this.onCleared,
  });

  @override
  State<TamperLockdownScreen> createState() => _TamperLockdownScreenState();
}

class _TamperLockdownScreenState extends State<TamperLockdownScreen>
    with SingleTickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showPasswordField = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndClear() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your master password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.authService.verifyPassword(password);
      if (isValid) {
        await widget.tamperDetectionService.clearTamperFlag();
        if (mounted) {
          widget.onCleared();
        }
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage =
              'Incorrect password. Only the master password '
              'can clear a tamper lockdown.';
        });
        _passwordController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0000), Color(0xFF2D0A0A), Color(0xFF1A0000)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing warning icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.error.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.gpp_bad_rounded,
                        size: 56,
                        color: AppColors.error,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXL),

                  // Title
                  const Text(
                    'SECURITY LOCKDOWN',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingMD),

                  // Description
                  Text(
                    'Clock manipulation has been detected on this device. '
                    'The system clock was rolled back, which could indicate '
                    'an attempt to bypass time-based security codes.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppConstants.paddingMD),

                  // Security notice box
                  Container(
                    padding: const EdgeInsets.all(AppConstants.paddingMD),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      border: Border.all(color: AppColors.error.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.paddingSM),
                        Expanded(
                          child: Text(
                            'All TOTP codes generated during the tampered '
                            'period may be invalid. Biometric unlock is '
                            'disabled during lockdown.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppConstants.paddingXXL),

                  if (!_showPasswordField) ...[
                    // "Resolve" button to show password field
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _showPasswordField = true),
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text('Verify Identity to Unlock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.paddingMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Password entry card
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingLG),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(18),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusLG,
                        ),
                        border: Border.all(
                          color: AppColors.error.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Enter Master Password',
                            style: TextStyle(
                              color: Colors.white.withAlpha(220),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.paddingSM),
                          Text(
                            'Biometric authentication is not accepted '
                            'during a tamper lockdown.',
                            style: TextStyle(
                              color: Colors.white.withAlpha(120),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.paddingMD),
                          TextField(
                            controller: _passwordController,
                            focusNode: _focusNode,
                            obscureText: _obscurePassword,
                            autofocus: true,
                            onSubmitted: (_) => _verifyAndClear(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Master Password',
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
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withAlpha(12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD,
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.error.withAlpha(100),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD,
                                ),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 2,
                                ),
                              ),
                              errorText: _errorMessage,
                              errorStyle: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingMD),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _verifyAndClear,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.error
                                    .withAlpha(100),
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppConstants.paddingMD,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD,
                                  ),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Unlock',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
