import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:secure_auth/l10n/app_localizations.dart';

import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/setup_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for better security UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = StorageService();
  await storageService.init();

  final authService = AuthService(storageService);

  runApp(SecureAuthApp(
    storageService: storageService,
    authService: authService,
  ));
}

class SecureAuthApp extends StatefulWidget {
  final StorageService storageService;
  final AuthService authService;

  const SecureAuthApp({
    super.key,
    required this.storageService,
    required this.authService,
  });

  @override
  State<SecureAuthApp> createState() => _SecureAuthAppState();
}

class _SecureAuthAppState extends State<SecureAuthApp>
    with WidgetsBindingObserver {
  late ThemeMode _themeMode;
  Locale? _locale;
  Timer? _inactivityTimer;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
    _loadLocale();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _loadTheme() {
    final settings = widget.storageService.getSettings();
    _themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void _loadLocale() {
    final settings = widget.storageService.getSettings();
    if (settings.languageCode != null) {
      _locale = Locale(settings.languageCode!);
    }
  }

  void _onThemeChanged() {
    final settings = widget.storageService.getSettings();
    setState(() {
      _themeMode = settings.isDarkMode ? ThemeMode.dark : ThemeMode.light;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Record last activity when going to background
      widget.authService.recordActivity();
    } else if (state == AppLifecycleState.resumed) {
      // Check if should lock on resume
      _checkAutoLock();
    }
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    final settings = widget.storageService.getSettings();
    if (settings.autoLockSeconds > 0 && settings.requireAuthOnLaunch) {
      _inactivityTimer = Timer.periodic(
        const Duration(seconds: 15),
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
      // Force rebuild to show auth screen
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAuth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
    final hasPassword = widget.authService.hasPassword();
    final settings = widget.storageService.getSettings();

    // If locked by inactivity timer, show auth
    if (_isLocked && hasPassword) {
      _isLocked = false;
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
