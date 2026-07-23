import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import 'login_screen.dart';

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
  bool _isOnline = false;

  bool _isUpdatingStatus = false;

  bool _isLoadingRides = false;

  List<dynamic> _rides = [];

  @override
  void initState() {
    super.initState();

    _initializeDriver();
  }

  // ============================================================
  // INITIALIZE DRIVER
  // ============================================================

  Future<void> _initializeDriver() async {
    try {
      final online =
          await ApiService
              .getDriverOnlineStatus();

      if (!mounted) return;

      setState(() {
        _isOnline = online;
      });

      if (online) {
        await _loadAvailableRides();
      }
    } catch (e) {
      debugPrint(
        "Could not load driver status: $e",
      );
    }
  }

  // ============================================================
  // UPDATE ONLINE STATUS
  // ============================================================

  Future<void> _toggleOnlineStatus(
    bool value,
  ) async {
    if (_isUpdatingStatus) {
      return;
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final newStatus =
          await ApiService
              .updateDriverOnlineStatus(
        isOnline: value,
      );

      if (!mounted) return;

      setState(() {
        _isOnline = newStatus;
      });

      if (newStatus) {
        await _loadAvailableRides();
      } else {
        setState(() {
          _rides = [];
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? "You are now online"
                : "You are now offline",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  "Exception: ",
                  "",
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
  // LOAD AVAILABLE RIDES
  // ============================================================

  Future<void>
      _loadAvailableRides() async {
    if (!_isOnline) {
      return;
    }

    setState(() {
      _isLoadingRides = true;
    });

    try {
      final rides =
          await ApiService
              .getAvailableRides();

      if (!mounted) return;

      setState(() {
        _rides = rides;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  "Exception: ",
                  "",
                ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRides = false;
        });
      }
    }
  }

  // ============================================================
  // ACCEPT RIDE
  // ============================================================

  Future<void> _acceptRide(
    int rideId,
  ) async {
    try {
      await ApiService.acceptRide(
        rideId: rideId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Ride accepted successfully",
          ),
        ),
      );

      await _loadAvailableRides();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  "Exception: ",
                  "",
                ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      // Set driver offline before logout
      if (_isOnline) {
        await ApiService
            .updateDriverOnlineStatus(
          isOnline: false,
        );
      }
    } catch (e) {
      debugPrint(
        "Could not set driver offline: $e",
      );
    }

    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // RIDE CARD
  // ============================================================

  Widget _buildRideCard(
    Map<String, dynamic> ride,
  ) {
    final rideId =
        ride["id"];

    final fare =
        ride["estimated_fare"];

    final pickupLat =
        ride["pickup_latitude"];

    final pickupLng =
        ride["pickup_longitude"];

    final destinationLat =
        ride["destination_latitude"];

    final destinationLng =
        ride["destination_longitude"];

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                Text(
                  "Ride #$rideId",
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  "KES $fare",
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              "Pickup",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              "$pickupLat, $pickupLng",
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Destination",
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              "$destinationLat, "
              "$destinationLng",
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    () => _acceptRide(
                  rideId as int,
                ),
                child:
                    const Text(
                  "ACCEPT RIDE",
                ),
              ),
            ),
          ],
        ),
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
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          "RydeX Driver",
        ),
        actions: [
          IconButton(
            onPressed:
                _logout,
            icon:
                const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body:
          RefreshIndicator(
        onRefresh:
            _loadAvailableRides,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            // ==================================================
            // ONLINE STATUS
            // ==================================================

            Card(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child:
                    Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          "Driver Status",
                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        Text(
                          _isOnline
                              ? "You are online"
                              : "You are offline",
                        ),
                      ],
                    ),

                    _isUpdatingStatus
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Switch(
                            value:
                                _isOnline,
                            onChanged:
                                _toggleOnlineStatus,
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "Available Rides",
              style:
                  TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // OFFLINE
            // ==================================================

            if (!_isOnline)
              const Card(
                child:
                    Padding(
                  padding:
                      EdgeInsets.all(
                    20,
                  ),
                  child:
                      Center(
                    child:
                        Text(
                      "Go online to receive ride requests.",
                    ),
                  ),
                ),
              ),

            // ==================================================
            // LOADING
            // ==================================================

            if (_isOnline &&
                _isLoadingRides)
              const Center(
                child:
                    Padding(
                  padding:
                      EdgeInsets.all(
                    30,
                  ),
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            // ==================================================
            // NO RIDES
            // ==================================================

            if (_isOnline &&
                !_isLoadingRides &&
                _rides.isEmpty)
              const Card(
                child:
                    Padding(
                  padding:
                      EdgeInsets.all(
                    20,
                  ),
                  child:
                      Center(
                    child:
                        Text(
                      "No rides available.",
                    ),
                  ),
                ),
              ),

            // ==================================================
            // RIDES
            // ==================================================

            if (_isOnline &&
                !_isLoadingRides)
              ..._rides.map(
                (ride) =>
                    _buildRideCard(
                  ride
                      as Map<String,
                          dynamic>,
                ),
              ),
          ],
        ),
      ),
    );
  }
}