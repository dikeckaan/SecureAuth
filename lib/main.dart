import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import 'services/logger_service.dart';
import 'services/screen_protection_service.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/tamper_detection_service.dart';
import 'services/service_locator.dart';
import 'screens/setup_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tamper_lockdown_screen.dart';
import 'utils/constants.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for better security UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await ServiceLocator.instance.init();

  final storageService = ServiceLocator.instance.storageService;
  final authService = ServiceLocator.instance.authService;
  final tamperDetectionService = ServiceLocator.instance.tamperDetectionService;

  final settings = storageService.getSettings();

  // Sync logging enabled state from persisted settings
  LoggerService.instance.loggingEnabled = settings.auditLoggingEnabled;

  try {
    await ScreenProtectionService.setSecure(settings.screenProtection);
  } catch (_) {
    // Non-fatal: screen protection is a best-effort feature
  }

  // Run tamper detection check before showing any UI
  bool isTampered = false;
  if (settings.tamperDetectionEnabled) {
    isTampered = await tamperDetectionService.checkIntegrity();
  }

  runApp(
    SecureAuthApp(
      storageService: storageService,
      authService: authService,
      tamperDetectionService: tamperDetectionService,
      initialTamperState: isTampered,
    ),
  );
}

class SecureAuthApp extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;
  final TamperDetectionService tamperDetectionService;
  final bool initialTamperState;

  const SecureAuthApp({
    super.key,
    required this.storageService,
    required this.authService,
    required this.tamperDetectionService,
    this.initialTamperState = false,
  });

  @override
  State<SecureAuthApp> createState() => _SecureAuthAppState();
}

class _SecureAuthAppState extends State<SecureAuthApp>
    with WidgetsBindingObserver {
  late ThemeMode _themeMode;
  late ThemeData _lightTheme;
  late ThemeData _darkTheme;
  int _accentColorIndex = 0;
  Locale? _locale;
  Timer? _inactivityTimer;
  Timer? _timestampTimer;
  bool _isLocked = false;
  late bool _isTampered;

  @override
  void initState() {
    super.initState();
    _isTampered = widget.initialTamperState;
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _loadLocale();
    _startInactivityTimer();
    _startTimestampRecording();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _timestampTimer?.cancel();
    super.dispose();
  }

  void _loadTheme() {
    final settings = widget.storageService.getSettings();
    _accentColorIndex = settings.accentColorIndex;
    final accent = AccentColorPalette.resolve(
      _accentColorIndex,
      settings.customPrimaryColor,
      settings.customSecondaryColor,
    );
    _themeMode = _themeModeFromPreference(settings.themePreference);
    final pureDark = settings.themePreference == 3;
    _lightTheme = AppTheme.buildLightTheme(accent);
    // System mode → normal dark; explicit pureDark only for preference 3
    _darkTheme = AppTheme.buildDarkTheme(accent, pureDark: pureDark);
  }

  ThemeMode _themeModeFromPreference(int preference) {
    switch (preference) {
      case 1:
        return ThemeMode.light;
      case 2:
      case 3:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _loadLocale() {
    final settings = widget.storageService.getSettings();
    if (settings.languageCode != null) {
      _locale = Locale(settings.languageCode!);
    }
  }

  void _onThemeChanged() {
    final settings = widget.storageService.getSettings();
    _accentColorIndex = settings.accentColorIndex;
    final accent = AccentColorPalette.resolve(
      _accentColorIndex,
      settings.customPrimaryColor,
      settings.customSecondaryColor,
    );
    final pureDark = settings.themePreference == 3;
    setState(() {
      _themeMode = _themeModeFromPreference(settings.themePreference);
      _lightTheme = AppTheme.buildLightTheme(accent);
      _darkTheme = AppTheme.buildDarkTheme(accent, pureDark: pureDark);
    });
  }

  void _onLocaleChanged() {
    final settings = widget.storageService.getSettings();
    setState(() {
      if (settings.languageCode != null) {
        _locale = Locale(settings.languageCode!);
      } else {
        _locale = null;
      }
    });
  }

  /// Periodically record timestamps for tamper detection (every 15 seconds).
  void _startTimestampRecording() {
    _timestampTimer?.cancel();
    final settings = widget.storageService.getSettings();
    if (settings.tamperDetectionEnabled) {
      _timestampTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => widget.tamperDetectionService.recordTimestamp(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Record last activity when going to background
      widget.authService.recordActivity();
      // Record timestamp for tamper detection
      widget.tamperDetectionService.recordTimestamp();
    } else if (state == AppLifecycleState.resumed) {
      // Re-check tamper detection on resume
      _checkTamperOnResume();
      // Check if should lock on resume
      _checkAutoLock();
    }
  }

  Future<void> _checkTamperOnResume() async {
    final settings = widget.storageService.getSettings();
    if (!settings.tamperDetectionEnabled) return;

    final tampered = await widget.tamperDetectionService.checkIntegrity();
    if (tampered && mounted && !_isTampered) {
      setState(() => _isTampered = true);
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    final settings = widget.storageService.getSettings();
    if (settings.autoLockSeconds > 0 && settings.requireAuthOnLaunch) {
      _inactivityTimer = Timer.periodic(
        const Duration(seconds: AppConstants.inactivityCheckIntervalSeconds),
        (_) => _checkAutoLock(),
      );
    }
  }

  Future<void> _checkAutoLock() async {
    final settings = widget.storageService.getSettings();
    if (!settings.requireAuthOnLaunch || !widget.authService.hasPassword()) {
      return;
    }

    final timedOut = await widget.authService.hasTimedOut();
    if (timedOut && mounted && !_isLocked) {
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAuth',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      home: _determineScreen(),
    );
  }

  Widget _determineScreen() {
    // TAMPER CHECK — highest priority, blocks everything
    if (_isTampered) {
      return TamperLockdownScreen(
        storageService: widget.storageService,
        authService: widget.authService,
        tamperDetectionService: widget.tamperDetectionService,
        onCleared: () {
          setState(() => _isTampered = false);
        },
      );
    }

    final hasPassword = widget.authService.hasPassword();
    final settings = widget.storageService.getSettings();

    // If locked by inactivity timer, show auth
    if (_isLocked && hasPassword) {
      // Schedule flag reset for after the current frame to avoid
      // mutating state during build. The flag is consumed once to
      // show the auth screen, then cleared so the next build proceeds
      // normally after successful authentication.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isLocked = false;
      });
      return AuthScreen(
        storageService: widget.storageService,
        authService: widget.authService,
        onThemeChanged: _onThemeChanged,
        onLocaleChanged: _onLocaleChanged,
      );
    }

    // First time setup
    if (!hasPassword && settings.requireAuthOnLaunch) {
      return SetupScreen(
        storageService: widget.storageService,
        authService: widget.authService,
        onThemeChanged: _onThemeChanged,
        onLocaleChanged: _onLocaleChanged,
      );
    }

    // Has password, requires auth
    if (hasPassword && settings.requireAuthOnLaunch) {
      return AuthScreen(
        storageService: widget.storageService,
        authService: widget.authService,
        onThemeChanged: _onThemeChanged,
        onLocaleChanged: _onLocaleChanged,
      );
    }

    // No auth required
    return HomeScreen(
      storageService: widget.storageService,
      authService: widget.authService,
      onThemeChanged: _onThemeChanged,
      onLocaleChanged: _onLocaleChanged,
    );
  }
}
