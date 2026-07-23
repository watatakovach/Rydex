import 'package:flutter/material.dart';

import 'core/services/api_service.dart';
import 'screens/driver_home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    const RydeXDriverApp(),
  );
}

class RydeXDriverApp
    extends StatelessWidget {
  const RydeXDriverApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false,

      title: "RydeX Driver",

      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),

      home:
          const StartupScreen(),
    );
  }
}

// ============================================================
// STARTUP SCREEN
// ============================================================

class StartupScreen
    extends StatefulWidget {
  const StartupScreen({
    super.key,
  });

  @override
  State<StartupScreen> createState() =>
      _StartupScreenState();
}

class _StartupScreenState
    extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();

    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final loggedIn =
        await ApiService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const DriverHomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(),
      ),
    );
  }
}