import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/websocket_service.dart';

import '../../core/widgets/ride_request_card.dart';

import '../../models/driver_profile.dart';
import '../../models/ride.dart';

import '../auth/driver_login_screen.dart';
import '../auth/driver_registration_screen.dart';

import '../profile/driver_profile_screen.dart';

import '../rides/active_ride_screen.dart';
import '../rides/available_rides_screen.dart';
import '../rides/ride_history_screen.dart';

import '../earnings/earnings_screen.dart';

import '../support/support_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({
    super.key,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  // ============================================================
  // DRIVER
  // ============================================================

  DriverProfile? _driver;

  Ride? _activeRide;

  // ============================================================
  // LOADING / ACTION STATES
  // ============================================================

  bool _isLoading = true;

  bool _isUpdatingStatus = false;

  bool _isAcceptingRide = false;

  bool _isRefreshing = false;

  bool _isGettingLocation = false;

  // ============================================================
  // GPS
  // ============================================================

  Position? _currentPosition;

  StreamSubscription<Position>? _locationSubscription;

  final MapController _mapController = MapController();

  // ============================================================
  // WEBSOCKET
  // ============================================================

  final WebSocketService _webSocketService = WebSocketService();

  // ============================================================
  // RIDE REQUESTS
  // ============================================================

  final List<Ride> _incomingRideRequests = [];

  // ============================================================
  // INIT
  // ============================================================

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
      final driver = await ApiService.getDriverProfile();

      if (!mounted) return;

      setState(() {
        _driver = driver;
        _isLoading = false;
      });

      // ----------------------------------------------------------
      // LOAD ACTIVE RIDE
      // ----------------------------------------------------------

      await _loadActiveRide();

      if (!mounted) return;

      // ----------------------------------------------------------
      // CONNECT IF VERIFIED + ONLINE
      // ----------------------------------------------------------

      if (driver.isVerified && driver.isOnline) {
        _connectWebSocket(driver);

        await _startLocationUpdates();
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceFirst(
            'Exception: ',
            '',
          );

      // ----------------------------------------------------------
      // DRIVER PROFILE DOES NOT EXIST
      // ----------------------------------------------------------

      if (errorMessage.toLowerCase().contains(
            'driver profile not found',
          )) {
        setState(() {
          _isLoading = false;
        });

        _openDriverRegistration();

        return;
      }

      // ----------------------------------------------------------
      // GENERAL ERROR
      // ----------------------------------------------------------

      setState(() {
        _isLoading = false;
      });

      _showError(errorMessage);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDriverProfile();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD ACTIVE RIDE
  // ============================================================

  Future<void> _loadActiveRide() async {
    try {
      final ride = await ApiService.getDriverCurrentRide();

      if (!mounted) return;

      setState(() {
        _activeRide = ride;
      });
    } catch (e) {
      debugPrint(
        'RYDEX failed to load active ride: $e',
      );
    }
  }

  // ============================================================
  // START REAL GPS LOCATION UPDATES
  // ============================================================

  Future<void> _startLocationUpdates() async {
    // ----------------------------------------------------------
    // STOP EXISTING STREAM
    // ----------------------------------------------------------

    await _locationSubscription?.cancel();

    _locationSubscription = null;

    // ----------------------------------------------------------
    // CHECK PERMISSION
    // ----------------------------------------------------------

    final permissionGranted =
        await LocationService.ensurePermission();

    if (!permissionGranted) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required to receive rides.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // GET CURRENT POSITION
    // ----------------------------------------------------------

    try {
      final currentPosition =
          await LocationService.getCurrentLocation();

      if (currentPosition != null) {
        if (mounted) {
          setState(() {
            _currentPosition = currentPosition;
          });
        }

        await _sendDriverLocation(
          currentPosition,
          moveMap: true,
        );
      }
    } catch (e) {
      debugPrint(
        'RYDEX failed to get current location: $e',
      );
    }

    // ----------------------------------------------------------
    // LISTEN FOR GPS CHANGES
    // ----------------------------------------------------------

    _locationSubscription =
        LocationService.locationStream().listen(
      (position) async {
        if (!mounted) return;

        setState(() {
          _currentPosition = position;
        });

        await _sendDriverLocation(
          position,
          moveMap: true,
        );
      },
      onError: (error) {
        debugPrint(
          'RYDEX location stream error: $error',
        );
      },
    );
  }

  // ============================================================
  // SEND DRIVER LOCATION
  // ============================================================

  Future<void> _sendDriverLocation(
    Position position, {
    bool moveMap = false,
  }) async {
    if (!mounted) {
      return;
    }

    if (_driver == null) {
      return;
    }

    // ----------------------------------------------------------
    // VERIFIED CHECK
    // ----------------------------------------------------------

    if (!_driver!.isVerified) {
      return;
    }

    // ----------------------------------------------------------
    // ONLINE CHECK
    // ----------------------------------------------------------

    if (!_driver!.isOnline) {
      return;
    }

    try {
      final result =
          await ApiService.updateDriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint(
        'RYDEX LOCATION UPDATED: '
        '${result['latitude']}, '
        '${result['longitude']}',
      );

      // --------------------------------------------------------
      // MOVE MAP TO DRIVER
      // --------------------------------------------------------

      if (moveMap && mounted) {
        _mapController.move(
          LatLng(
            position.latitude,
            position.longitude,
          ),
          16,
        );
      }
    } catch (e) {
      debugPrint(
        'RYDEX failed to update location: $e',
      );
    }
  }

  // ============================================================
  // STOP GPS LOCATION UPDATES
  // ============================================================

  Future<void> _stopLocationUpdates() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;
  }

  // ============================================================
  // MANUAL GPS REFRESH
  // ============================================================

  Future<void> _refreshCurrentLocation() async {
    if (_isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final permissionGranted =
          await LocationService.ensurePermission();

      if (!permissionGranted) {
        if (mounted) {
          _showError(
            'Location permission is required.',
          );
        }

        return;
      }

      final position =
          await LocationService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          _showError(
            'Unable to determine your current location.',
          );
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
      });

      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        16,
      );

      if (_driver?.isVerified == true &&
          _driver?.isOnline == true) {
        await _sendDriverLocation(
          position,
          moveMap: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
          'Unable to get your location.',
        );
      }

      debugPrint(
        'RYDEX manual location error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // ============================================================
  // WEBSOCKET CONNECTION
  // ============================================================

  void _connectWebSocket(
    DriverProfile driver,
  ) {
    // ----------------------------------------------------------
    // VERIFIED CHECK
    // ----------------------------------------------------------

    if (!driver.isVerified) {
      return;
    }

    // ----------------------------------------------------------
    // ONLINE CHECK
    // ----------------------------------------------------------

    if (!driver.isOnline) {
      return;
    }

    // ----------------------------------------------------------
    // CONNECT
    // ----------------------------------------------------------

    _webSocketService.connect(
      userId: driver.userId,

      // ========================================================
      // RIDE REQUEST
      // ========================================================

      onRideRequest: (ride) {
        if (!mounted) return;

        // ------------------------------------------------------
        // ACTIVE RIDE CHECK
        // ------------------------------------------------------

        if (_activeRide != null) {
          return;
        }

        // ------------------------------------------------------
        // DUPLICATE CHECK
        // ------------------------------------------------------

        final alreadyExists =
            _incomingRideRequests.any(
          (existingRide) =>
              existingRide.id == ride.id,
        );

        if (alreadyExists) {
          return;
        }

        // ------------------------------------------------------
        // ADD REQUEST
        // ------------------------------------------------------

        setState(() {
          _incomingRideRequests.add(
            ride,
          );
        });

        // ------------------------------------------------------
        // NOTIFICATION
        // ------------------------------------------------------

        NotificationService
            .showRideRequestNotification(
          context: context,
          onTap: () {
            _scrollToRideRequest();
          },
        );
      },

      // ========================================================
      // CONNECTION ERROR
      // ========================================================

      onConnectionError: (error) {
        debugPrint(
          'RYDEX WebSocket error: $error',
        );
      },
    );
  }

  // ============================================================
  // RECENTER MAP
  // ============================================================

  void _recenterMap() {
    if (_currentPosition == null) {
      _refreshCurrentLocation();

      return;
    }

    _mapController.move(
      LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ),
      16,
    );
  }

  // ============================================================
  // TOGGLE ONLINE / OFFLINE
  // ============================================================

  Future<void> _toggleOnlineStatus(
    bool value,
  ) async {
    if (_driver == null) {
      return;
    }

    // ----------------------------------------------------------
    // VERIFICATION CHECK
    // ----------------------------------------------------------

    if (!_driver!.isVerified) {
      _showError(
        'Your driver account must be verified before you can go online.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ACTIVE RIDE CHECK
    // ----------------------------------------------------------

    if (!value && _activeRide != null) {
      _showError(
        'You cannot go offline while you have an active ride.',
      );

      return;
    }

    // ----------------------------------------------------------
    // TURNING ONLINE
    // ----------------------------------------------------------

    if (value) {
      final permissionGranted =
          await LocationService.ensurePermission();

      if (!permissionGranted) {
        _showError(
          'Location permission is required before going online.',
        );

        return;
      }
    }

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ApiService.updateDriverStatus(
        isOnline: value,
      );

      final updatedProfile =
          await ApiService.getDriverProfile();

      if (!mounted) return;

      setState(() {
        _driver = updatedProfile;
      });

      // ========================================================
      // DRIVER ONLINE
      // ========================================================

      if (updatedProfile.isOnline) {
        _connectWebSocket(
          updatedProfile,
        );

        await _startLocationUpdates();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are now online and available for rides.',
            ),
          ),
        );
      }

      // ========================================================
      // DRIVER OFFLINE
      // ========================================================

      else {
        _webSocketService.disconnect();

        await _stopLocationUpdates();

        if (!mounted) return;

        setState(() {
          _incomingRideRequests.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are now offline.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
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
  // ACCEPT RIDE
  // ============================================================

  Future<void> _acceptRide(
    Ride ride,
  ) async {
    if (_isAcceptingRide) {
      return;
    }

    if (_driver == null) {
      return;
    }

    // ----------------------------------------------------------
    // VERIFIED CHECK
    // ----------------------------------------------------------

    if (!_driver!.isVerified) {
      _showError(
        'Your driver account is not verified.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ONLINE CHECK
    // ----------------------------------------------------------

    if (!_driver!.isOnline) {
      _showError(
        'You must be online to accept a ride.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ACTIVE RIDE CHECK
    // ----------------------------------------------------------

    if (_activeRide != null) {
      _showError(
        'You already have an active ride.',
      );

      return;
    }

    setState(() {
      _isAcceptingRide = true;
    });

    try {
      // ========================================================
      // ACCEPT RIDE
      // ========================================================

      final acceptedRide =
          await ApiService.acceptRide(
        rideId: ride.id,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // REMOVE REQUEST + SET ACTIVE RIDE
      // --------------------------------------------------------

      setState(() {
        _incomingRideRequests.removeWhere(
          (item) => item.id == ride.id,
        );

        _activeRide = acceptedRide;
      });

      // --------------------------------------------------------
      // OPEN ACTIVE RIDE
      // --------------------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveRideScreen(
            ride: acceptedRide,
          ),
        ),
      );

      // --------------------------------------------------------
      // REFRESH AFTER RETURN
      // --------------------------------------------------------

      if (!mounted) return;

      await _loadActiveRide();

      await _loadDriverProfile();
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingRide = false;
        });
      }
    }
  }

  // ============================================================
  // DECLINE RIDE
  // ============================================================

  void _declineRide(
    Ride ride,
  ) {
    setState(() {
      _incomingRideRequests.removeWhere(
        (item) => item.id == ride.id,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ride request declined.',
        ),
      ),
    );
  }

  // ============================================================
  // OPEN ACTIVE RIDE
  // ============================================================

  Future<void> _openActiveRide() async {
    if (_activeRide == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveRideScreen(
          ride: _activeRide!,
        ),
      ),
    );

    if (!mounted) return;

    await _loadActiveRide();
  }

  // ============================================================
  // SCROLL / NOTIFICATION
  // ============================================================

  void _scrollToRideRequest() {
    if (!mounted) return;

    if (_incomingRideRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No new ride requests.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_incomingRideRequests.length} new ride request(s) waiting.',
        ),
      ),
    );
  }

  // ============================================================
  // OPEN DRIVER REGISTRATION
  // ============================================================

  Future<void> _openDriverRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverRegistrationScreen(),
      ),
    );

    if (!mounted) return;

    if (registered == true) {
      setState(() {
        _isLoading = true;
      });

      await _loadDriverProfile();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    _webSocketService.disconnect();

    await _stopLocationUpdates();

    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverLoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DriverProfileScreen(),
      ),
    );
  }

  // ============================================================
  // AVAILABLE RIDES
  // ============================================================

  void _openAvailableRides() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AvailableRidesScreen(),
      ),
    );
  }

  // ============================================================
  // EARNINGS
  // ============================================================

  void _openEarnings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EarningsScreen(),
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  void _openRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RideHistoryScreen(),
      ),
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupportScreen(),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _webSocketService.disconnect();

    _locationSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildDriverMap() {
    final position = _currentPosition;

    final initialCenter = position != null
        ? LatLng(
            position.latitude,
            position.longitude,
          )
        : const LatLng(
            -1.286389,
            36.817223,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 330,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: position != null ? 16 : 12,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                // ==================================================
                // OPENSTREETMAP
                // ==================================================

                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.rydex.driver_app',
                ),

                // ==================================================
                // DRIVER MARKER
                // ==================================================

                if (position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          position.latitude,
                          position.longitude,
                        ),
                        width: 70,
                        height: 70,
                        child: _DriverMapMarker(
                          isOnline:
                              _driver?.isOnline ?? false,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ======================================================
            // MAP HEADER
            // ======================================================

            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 3),
                      color: Colors.black26,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _driver?.isOnline == true
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _driver?.isOnline == true
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _driver?.isOnline == true
                            ? 'You are online'
                            : 'You are offline',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_currentPosition != null)
                      const Text(
                        'GPS active',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ======================================================
            // RECENTER BUTTON
            // ======================================================

            Positioned(
              right: 14,
              bottom: 14,
              child: FloatingActionButton.small(
                heroTag: 'driver_location_button',
                onPressed: _isGettingLocation
                    ? null
                    : _recenterMap,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                child: _isGettingLocation
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.my_location,
                      ),
              ),
            ),

            // ======================================================
            // NO LOCATION
            // ======================================================

            if (_currentPosition == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Waiting for GPS location...',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // NO DRIVER
    // ==========================================================

    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'RYDEX Driver',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Driver profile not available',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please register as a RYDEX driver to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _openDriverRegistration,
                  child: const Text(
                    'REGISTER AS DRIVER',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
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

    // ==========================================================
    // MAIN DASHBOARD
    // ==========================================================

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RYDEX Driver',
        ),
        actions: [
          // ====================================================
          // NOTIFICATIONS
          // ====================================================

          Stack(
            children: [
              IconButton(
                onPressed: _scrollToRideRequest,
                icon: const Icon(
                  Icons.notifications_outlined,
                ),
              ),
              if (_incomingRideRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.all(4),
                    decoration:
                        const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_incomingRideRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // ====================================================
          // MENU
          // ====================================================

          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _openProfile();
                  break;

                case 'settings':
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Settings coming soon.',
                      ),
                    ),
                  );
                  break;

                case 'logout':
                  _logout();
                  break;
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

      // ========================================================
      // BODY
      // ========================================================

      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // ==================================================
            // DRIVER HEADER
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          Colors.grey.shade200,
                      backgroundImage:
                          driver.profilePhoto != null &&
                                  driver.profilePhoto!
                                      .isNotEmpty
                              ? NetworkImage(
                                  driver.profilePhoto!,
                                )
                              : null,
                      child:
                          driver.profilePhoto ==
                                      null ||
                                  driver.profilePhoto!
                                      .isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 32,
                                )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${driver.fullName}',
                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            driver.phoneNumber,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            driver.email,
                            style: TextStyle(
                              color:
                                  Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
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

            const SizedBox(height: 20),

            // ==================================================
            // MAP
            // ==================================================

            const _SectionTitle(
              title: 'Live Location',
            ),

            const SizedBox(height: 12),

            _buildDriverMap(),

            const SizedBox(height: 20),

            // ==================================================
            // ACTIVE RIDE
            // ==================================================

            if (_activeRide != null) ...[
              const _SectionTitle(
                title: 'Active Ride',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_taxi,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'You currently have an active ride.',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child:
                            ElevatedButton.icon(
                          onPressed:
                              _openActiveRide,
                          icon: const Icon(
                            Icons.arrow_forward,
                          ),
                          label: const Text(
                            'OPEN ACTIVE RIDE',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ==================================================
            // NEW RIDE REQUESTS
            // ==================================================

            if (_incomingRideRequests
                .isNotEmpty) ...[
              const _SectionTitle(
                title: 'New Ride Requests',
              ),
              const SizedBox(height: 12),
              ..._incomingRideRequests.map(
                (ride) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 16,
                  ),
                  child: RideRequestCard(
                    ride: ride,
                    isAccepting:
                        _isAcceptingRide,
                    onAccept: () =>
                        _acceptRide(ride),
                    onDecline: () =>
                        _declineRide(ride),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ==================================================
            // VERIFICATION
            // ==================================================

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
                      color:
                          driver.isVerified
                              ? Colors.green
                              : Colors.orange,
                    ),
                    const SizedBox(width: 16),
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
                          const SizedBox(height: 4),
                          Text(
                            driver.isVerified
                                ? 'Your account is verified and ready to drive.'
                                : 'Your account is awaiting verification.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // ONLINE STATUS
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration:
                          BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            driver.isOnline
                                ? Colors.green
                                : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                          const SizedBox(height: 6),
                          Text(
                            driver.isOnline
                                ? 'You can receive ride requests.'
                                : 'Go online to receive rides.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
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

            const SizedBox(height: 24),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================

            const _SectionTitle(
              title: 'Quick Actions',
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.local_taxi,
                    title:
                        'Available Rides',
                    onTap:
                        _openAvailableRides,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons
                        .account_balance_wallet,
                    title: 'Earnings',
                    onTap: _openEarnings,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.history,
                    title: 'Ride History',
                    onTap:
                        _openRideHistory,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon:
                        Icons.support_agent,
                    title: 'Support',
                    onTap: _openSupport,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ==================================================
            // VERIFICATION WARNING
            // ==================================================

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
                      const SizedBox(height: 10),
                      const Text(
                        'Verification Required',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You will be able to go online and receive rides once your driver account has been verified by RYDEX administration.',
                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // ==================================================
            // MAP ATTRIBUTION
            // ==================================================

            const Text(
              'Map data © OpenStreetMap contributors',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DRIVER MAP MARKER
// ================================================================

class _DriverMapMarker extends StatelessWidget {
  final bool isOnline;

  const _DriverMapMarker({
    required this.isOnline,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isOnline
                ? Colors.green
                : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_taxi,
            color: Colors.white,
            size: 25,
          ),
        ),
        Container(
          width: 3,
          height: 12,
          color: isOnline
              ? Colors.green
              : Colors.grey,
        ),
      ],
    );
  }
}

// ================================================================
// SECTION TITLE
// ================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// ================================================================
// QUICK ACTION CARD
// ================================================================

class _QuickActionCard extends StatelessWidget {
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
              const SizedBox(height: 10),
              Text(
                title,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
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
