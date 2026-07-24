import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/driver_login_screen.dart';
// import 'screens/auth/driver_login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const RydeXDriverApp(),
  );
}

class RydeXDriverApp extends StatelessWidget {
  const RydeXDriverApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RydeX Driver',
      theme: AppTheme.lightTheme,
      home: const DriverLoginScreen(),
    );
  }
}