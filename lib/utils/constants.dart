import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'SecureAuth';
  static const String appVersion = '1.0.0';

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double borderRadius = 12.0;

  static const Duration animationDuration = Duration(milliseconds: 300);
}

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF8B5CF6);

  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
}
