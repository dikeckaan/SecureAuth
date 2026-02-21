import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData buildLightTheme(AccentColorPalette accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent.primary,
        onPrimary: Colors.white,
        secondary: accent.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: AppColors.bgLight,
        foregroundColor: AppColors.textPrimaryLight,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingSM / 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLG,
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLG,
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          side: BorderSide(color: accent.primary, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: accent.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryLight,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.primary;
          return AppColors.textTertiaryLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.primaryLight.withAlpha(77);
          }
          return AppColors.borderLight;
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        elevation: 8,
      ),
    );
  }

  static ThemeData buildDarkTheme(AccentColorPalette accent,
      {required bool pureDark}) {
    final Color bgColor =
        pureDark ? AppColors.bgDark : AppColors.bgDarkNormal;
    final Color surfaceColor =
        pureDark ? AppColors.surfaceDark : AppColors.surfaceDarkNormal;
    final Color cardColor =
        pureDark ? AppColors.cardDark : AppColors.cardDarkNormal;
    final Color borderColor =
        pureDark ? AppColors.borderDark : AppColors.borderDarkNormal;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent.primaryLight,
        onPrimary: Colors.white,
        secondary: accent.secondaryLight,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: AppColors.textPrimaryDark,
        error: AppColors.error,
        onError: Colors.white,
        outline: borderColor,
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        backgroundColor: bgColor,
        foregroundColor: AppColors.textPrimaryDark,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingSM / 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: accent.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLG,
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingLG,
            vertical: AppConstants.paddingMD,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          ),
          side: BorderSide(color: accent.primaryLight, width: 1.5),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: BorderSide(color: accent.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiaryDark,
          fontSize: 14,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.primaryLight;
          }
          return AppColors.textTertiaryDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.primaryLight.withAlpha(77);
          }
          return borderColor;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        ),
        elevation: 8,
        backgroundColor: surfaceColor,
      ),
    );
  }
}
