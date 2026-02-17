import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/setup_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class _SecureAuthAppState extends State<SecureAuthApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() {
    final settings = widget.storageService.getSettings();
    setState(() {
      _isDarkMode = settings.isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureAuth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _determineInitialScreen(),
    );
  }

  Widget _determineInitialScreen() {
    final hasPassword = widget.authService.hasPassword();
    final settings = widget.storageService.getSettings();

    if (!hasPassword && settings.requireAuthOnLaunch) {
      return SetupScreen(
        storageService: widget.storageService,
        authService: widget.authService,
      );
    } else if (hasPassword && settings.requireAuthOnLaunch) {
      return AuthScreen(
        storageService: widget.storageService,
        authService: widget.authService,
      );
    } else {
      return HomeScreen(
        storageService: widget.storageService,
        authService: widget.authService,
      );
    }
  }
}
