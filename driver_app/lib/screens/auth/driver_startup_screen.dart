import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../models/driver_profile.dart';

import 'driver_login_screen.dart';
import '../home/driver_home_screen.dart';
import '../verification/driver_registration_screen.dart';
import '../verification/verification_screen.dart';

class DriverStartupScreen extends StatefulWidget {
  const DriverStartupScreen({
    super.key,
  });

  @override
  State<DriverStartupScreen> createState() =>
      _DriverStartupScreenState();
}

class _DriverStartupScreenState
    extends State<DriverStartupScreen> {
  @override
  void initState() {
    super.initState();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final loggedIn =
          await AuthService.isLoggedIn();

      if (!mounted) return;

      if (!loggedIn) {
        _goToLogin();
        return;
      }

      DriverProfile profile;

      try {
        profile =
            await ApiService.getDriverProfile();
      } catch (_) {
        // Token may be expired or invalid.
        await AuthService.logout();

        if (!mounted) return;

        _goToLogin();
        return;
      }

      if (!mounted) return;

      // Driver account doesn't appear to be
      // fully registered.
      if (profile.id == 0 ||
          profile.licenseNumber.isEmpty) {
        _goToRegistration();
        return;
      }

      // Driver exists but has not been verified.
      if (!profile.isVerified) {
        _goToVerification();
        return;
      }

      // Driver is verified.
      _goToHome();
    } catch (_) {
      if (!mounted) return;

      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverLoginScreen(),
      ),
      (route) => false,
    );
  }

  void _goToRegistration() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverRegistrationScreen(),
      ),
      (route) => false,
    );
  }

  void _goToVerification() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const VerificationScreen(),
      ),
      (route) => false,
    );
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_taxi,
              size: 80,
            ),

            const SizedBox(height: 24),

            const Text(
              'RydeX Driver',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Checking your account...',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 28),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}