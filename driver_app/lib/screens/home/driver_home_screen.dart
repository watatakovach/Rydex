import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/driver.dart';
import '../auth/driver_login_screen.dart';
import '../rides/available_rides_screen.dart';
import '../rides/ride_history_screen.dart';
import '../earnings/earnings_screen.dart';
import '../support/support_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({
    super.key,
  });

  @override
  State<DriverHomeScreen> createState() =>
      _DriverHomeScreenState();
}

class _DriverHomeScreenState
    extends State<DriverHomeScreen> {
  Driver? _driver;

  bool _isLoading = true;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  // ============================================================
  // LOAD DRIVER PROFILE
  // ============================================================

  Future<void> _loadDriverProfile() async {
    try {
      final driver =
          await ApiService.getMyDriverProfile();

      if (!mounted) return;

      setState(() {
        _driver = driver;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE ONLINE / OFFLINE STATUS
  // ============================================================

  Future<void> _toggleOnlineStatus(
    bool value,
  ) async {
    if (_driver == null) {
      return;
    }

    if (!_driver!.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your driver account must be verified before you can go online.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final updatedDriver =
          await ApiService.updateDriverStatus(
        isOnline: value,
      );

      if (!mounted) return;

      setState(() {
        _driver = updatedDriver;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedDriver.isOnline
                ? 'You are now online and available for rides.'
                : 'You are now offline.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DriverLoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // OPEN AVAILABLE RIDES
  // ============================================================

  void _openAvailableRides() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const AvailableRidesScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN EARNINGS
  // ============================================================

  void _openEarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const EarningsScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN RIDE HISTORY
  // ============================================================

  void _openRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const RideHistoryScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN SUPPORT
  // ============================================================

  void _openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const SupportScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'RydeX Driver',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 64,
                ),

                const SizedBox(
                  height: 16,
                ),

                const Text(
                  'Driver profile not found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'You need to register as a RydeX driver before continuing.',
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(
                  height: 24,
                ),

                ElevatedButton(
                  onPressed: _logout,
                  child: const Text(
                    'LOG OUT',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final driver = _driver!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RydeX Driver',
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO:
              // Open notifications screen.
            },
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'profile',
                  child: Text(
                    'Profile',
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Text(
                    'Settings',
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text(
                    'Logout',
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      // ==========================================================
      // MAIN BODY
      // ==========================================================

      body: RefreshIndicator(
        onRefresh: _loadDriverProfile,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            // ======================================================
            // DRIVER HEADER
            // ======================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(
                        Icons.person,
                        size: 32,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Welcome back, Driver',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Driver #${driver.id}',
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'License: ${driver.licenseNumber}',
                            style: TextStyle(
                              color:
                                  Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================================
            // VERIFICATION STATUS
            // ======================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Row(
                  children: [
                    Icon(
                      driver.isVerified
                          ? Icons.verified
                          : Icons.pending,

                      size: 32,

                      color: driver.isVerified
                          ? Colors.green
                          : Colors.orange,
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Verification Status',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            driver.isVerified
                                ? 'Your account is verified'
                                : 'Verification pending',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ======================================================
            // ONLINE STATUS
            // ======================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          driver.isOnline
                              ? 'You are Online'
                              : 'You are Offline',

                          style:
                              const TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          driver.isOnline
                              ? 'You can receive ride requests'
                              : 'Go online to receive rides',
                        ),
                      ],
                    ),

                    _isUpdatingStatus
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child:
                                CircularProgressIndicator(),
                          )
                        : Switch(
                            value:
                                driver.isOnline,

                            onChanged:
                                driver.isVerified
                                    ? _toggleOnlineStatus
                                    : null,
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ======================================================
            // QUICK ACTIONS
            // ======================================================

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // AVAILABLE RIDES + EARNINGS

            Row(
              children: [
                Expanded(
                  child:
                      _QuickActionCard(
                    icon:
                        Icons.local_taxi,

                    title:
                        'Available Rides',

                    onTap:
                        _openAvailableRides,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      _QuickActionCard(
                    icon: Icons
                        .account_balance_wallet,

                    title:
                        'Earnings',

                    onTap:
                        _openEarnings,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // RIDE HISTORY + SUPPORT

            Row(
              children: [
                Expanded(
                  child:
                      _QuickActionCard(
                    icon:
                        Icons.history,

                    title:
                        'Ride History',

                    onTap:
                        _openRideHistory,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                      _QuickActionCard(
                    icon:
                        Icons.support_agent,

                    title:
                        'Support',

                    onTap:
                        _openSupport,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 30,
            ),

            // ======================================================
            // VERIFICATION WARNING
            // ======================================================

            if (!driver.isVerified)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),

                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 32,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'Your driver account is awaiting verification.',
                        textAlign:
                            TextAlign.center,

                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      const Text(
                        'You will be able to go online and receive rides once your account has been verified.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// QUICK ACTION CARD
// ================================================================

class _QuickActionCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(16),

      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                title,
                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}