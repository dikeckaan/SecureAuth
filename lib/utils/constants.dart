import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'SecureAuth';
  static const String appVersion = '2.0.0';

  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  static const int pbkdf2Iterations = 100000;
  static const int saltLength = 32;
  static const int derivedKeyLength = 64;

  static const int defaultAutoLockSeconds = 60;
  static const int defaultClipboardClearSeconds = 30;
  static const int defaultMaxFailedAttempts = 10;
  static const int minPasswordLength = 6;
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);

  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFF8B5CF6);

  static const Color accent = Color(0xFF06B6D4);

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);

  // Light theme
  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // Dark theme (AMOLED)
  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF0A0A0A);
  static const Color cardDark = Color(0xFF111111);
  static const Color borderDark = Color(0xFF1C1C1C);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient authGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4C1D95)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static List<Color> get serviceColors => [
        const Color(0xFF4F46E5),
        const Color(0xFF7C3AED),
        const Color(0xFF06B6D4),
        const Color(0xFFEC4899),
        const Color(0xFFF59E0B),
        const Color(0xFF10B981),
        const Color(0xFFEF4444),
        const Color(0xFF8B5CF6),
        const Color(0xFF14B8A6),
        const Color(0xFFF97316),
      ];

  static Color getServiceColor(String name) {
    final index = name.isEmpty ? 0 : name.codeUnitAt(0) % serviceColors.length;
    return serviceColors[index];
  }
}
