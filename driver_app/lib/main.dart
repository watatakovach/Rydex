import 'package:flutter/material.dart';

import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
// import 'screens/auth/driver_login_screen.dart';
import 'screens/home/driver_home_screen.dart';
import 'screens/auth/driver_startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await AuthService.isLoggedIn();

  runApp(
    RydeXDriverApp(
      isLoggedIn: isLoggedIn,
    ),
  );
}

class RydeXDriverApp extends StatelessWidget {
  final bool isLoggedIn;

  const RydeXDriverApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RydeX Driver',
      theme: AppTheme.lightTheme,
      home: isLoggedIn
          ? const DriverHomeScreen()
          : const DriverStartupScreen(),
    );
  }
}