import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../core/services/location_service.dart';
import '../core/services/routing_service.dart';
import '../models/place.dart';

class MapWidget extends StatefulWidget {
  final Place? destination;
  final LatLng? pickupLocation;
  final ValueChanged<LatLng>? onPickupSelected;

  const MapWidget({
    super.key,
    this.destination,
    this.pickupLocation,
    this.onPickupSelected,
  });

  @override
  MapWidgetState createState() => MapWidgetState();
}

// IMPORTANT:
// This class is now public so HomeScreen can access
// _mapKey.currentState?.useMyLocation();

class MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();

  // Nairobi CBD fallback location
  static const LatLng _nairobiFallback = LatLng(
    -1.286389,
    36.817223,
  );

  LatLng? _currentLocation;

  List<LatLng> _routePoints = [];

  double? _distanceMeters;

  double? _durationSeconds;

  bool _isLoadingLocation = false;

  bool _isLoadingRoute = false;

  bool _selectingPickup = false;

  @override
  void initState() {
    super.initState();

    // Start with selected pickup if available.
    // Otherwise use Nairobi fallback.
    _currentLocation =
        widget.pickupLocation ?? _nairobiFallback;

    // Try to get the real GPS location.
    _loadLocation();
  }

  @override
  void didUpdateWidget(
    covariant MapWidget oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    // Pickup location changed
    if (widget.pickupLocation !=
        oldWidget.pickupLocation) {
      if (widget.pickupLocation != null) {
        setState(() {
          _currentLocation =
              widget.pickupLocation;
        });

        _moveToLocation(
          widget.pickupLocation!,
        );

        _loadRoute();
      }
    }

    // Destination changed
    if (widget.destination !=
        oldWidget.destination) {
      _loadRoute();
    }
  }

  // ==========================================
  // GET CURRENT LOCATION
  // ==========================================

  Future<void> _loadLocation() async {
    if (_isLoadingLocation) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      debugPrint(
        '====================================',
      );

      debugPrint(
        'Getting current location...',
      );

      final Position position =
          await LocationService
              .getCurrentLocation();

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        'REAL LOCATION:',
      );

      debugPrint(
        'Latitude: ${position.latitude}',
      );

      debugPrint(
        'Longitude: ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = location;
        _isLoadingLocation = false;
      });

      // Move map to real location
      _moveToLocation(location);

      // Tell HomeScreen about the new pickup
      widget.onPickupSelected?.call(location);

      // Recalculate route if destination exists
      await _loadRoute();

      debugPrint(
        'Location successfully updated.',
      );

      debugPrint(
        '====================================',
      );
    } catch (e) {
      debugPrint(
        'GPS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;

        // Keep current pickup if one exists.
        // Otherwise keep Nairobi fallback.
        _currentLocation =
            widget.pickupLocation ??
                _nairobiFallback;
      });

      debugPrint(
        'Using fallback location.',
      );

      _moveToLocation(
        _currentLocation!,
      );

      debugPrint(
        '====================================',
      );
    }
  }

  // ==========================================
  // PUBLIC METHOD
  // HOME SCREEN CAN CALL THIS
  // ==========================================

  Future<void> useMyLocation() async {
    debugPrint(
      'USE MY LOCATION BUTTON PRESSED',
    );

    await _loadLocation();
  }

  // ==========================================
  // ENABLE PICKUP SELECTION
  // ==========================================

  void enablePickupSelection() {
    if (!mounted) return;

    setState(() {
      _selectingPickup = true;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Tap anywhere on the map to set pickup location.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // ==========================================
  // MAP TAP
  // ==========================================

  void _onMapTap(
    TapPosition tapPosition,
    LatLng point,
  ) {
    if (!_selectingPickup) {
      return;
    }

    debugPrint(
      '====================================',
    );

    debugPrint(
      'PICKUP SELECTED ON MAP',
    );

    debugPrint(
      'Latitude: ${point.latitude}',
    );

    debugPrint(
      'Longitude: ${point.longitude}',
    );

    debugPrint(
      '====================================',
    );

    if (!mounted) return;

    setState(() {
      _currentLocation = point;
      _selectingPickup = false;
    });

    // Tell HomeScreen about new pickup
    widget.onPickupSelected?.call(point);

    // Move map
    _moveToLocation(point);

    // Recalculate route
    _loadRoute();
  }

  // ==========================================
  // MOVE MAP TO LOCATION
  // ==========================================

  void _moveToLocation(
    LatLng location,
  ) {
    try {
      _mapController.move(
        location,
        15,
      );
    } catch (e) {
      debugPrint(
        'Could not move map: $e',
      );
    }
  }

  // ==========================================
  // LOAD ROUTE
  // ==========================================

  Future<void> _loadRoute() async {
    final destination =
        widget.destination;

    final pickup =
        _currentLocation;

    if (destination == null ||
        pickup == null) {
      debugPrint(
        'Route waiting for pickup or destination.',
      );

      return;
    }

    final destinationLocation =
        LatLng(
      destination.latitude,
      destination.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      debugPrint(
        '====================================',
      );

      debugPrint(
        'CALCULATING ROUTE',
      );

      debugPrint(
        'PICKUP: '
        '${pickup.latitude}, '
        '${pickup.longitude}',
      );

      debugPrint(
        'DESTINATION: '
        '${destination.latitude}, '
        '${destination.longitude}',
      );

      final RoutingResult result =
          await RoutingService.getRoute(
        start: pickup,
        destination:
            destinationLocation,
      );

      if (!mounted) return;

      setState(() {
        _routePoints =
            result.points;

        _distanceMeters =
            result.distanceMeters;

        _durationSeconds =
            result.durationSeconds;

        _isLoadingRoute = false;
      });

      // Zoom map to show complete route
      _fitRouteOnMap();

      debugPrint(
        'ROUTE SUCCESS',
      );

      debugPrint(
        'Distance: ${result.distanceMeters} meters',
      );

      debugPrint(
        'Duration: ${result.durationSeconds} seconds',
      );

      debugPrint(
        '====================================',
      );
    } catch (e) {
      debugPrint(
        'ROUTE ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoadingRoute = false;
        _routePoints = [];
        _distanceMeters = null;
        _durationSeconds = null;
      });
    }
  }

  // ==========================================
  // FIT ROUTE ON MAP
  // ==========================================

  void _fitRouteOnMap() {
    if (_routePoints.isEmpty ||
        _currentLocation == null) {
      return;
    }

    final points = [
      _currentLocation!,
      ..._routePoints,
    ];

    double minLat =
        points.first.latitude;

    double maxLat =
        points.first.latitude;

    double minLng =
        points.first.longitude;

    double maxLng =
        points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    final bounds = LatLngBounds(
      LatLng(
        minLat,
        minLng,
      ),
      LatLng(
        maxLat,
        maxLng,
      ),
    );

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.all(80),
        ),
      );
    } catch (e) {
      debugPrint(
        'Could not fit route on map: $e',
      );
    }
  }

  // ==========================================
  // FORMAT DISTANCE
  // ==========================================

  String _formatDistance() {
    if (_distanceMeters == null) {
      return '';
    }

    if (_distanceMeters! >= 1000) {
      return '${(_distanceMeters! / 1000).toStringAsFixed(1)} km';
    }

    return '${_distanceMeters!.round()} m';
  }

  // ==========================================
  // FORMAT TIME
  // ==========================================

  String _formatDuration() {
    if (_durationSeconds == null) {
      return '';
    }

    final minutes =
        (_durationSeconds! / 60).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours =
        minutes ~/ 60;

    final remainingMinutes =
        minutes % 60;

    return '${hours}h ${remainingMinutes}min';
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final destination =
        widget.destination;

    final pickup =
        _currentLocation ??
            _nairobiFallback;

    return Stack(
      children: [
        // ======================================
        // MAP
        // ======================================

        ClipRRect(
          borderRadius:
              BorderRadius.circular(20),

          child: FlutterMap(
            mapController:
                _mapController,

            options: MapOptions(
              initialCenter:
                  pickup,

              initialZoom:
                  14,

              onTap:
                  _onMapTap,
            ),

            children: [
              // ==================================
              // MAP TILES
              // ==================================

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName:
                    'com.rydex.passenger',
              ),

              // ==================================
              // ROUTE LINE
              // ==================================

              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points:
                          _routePoints,

                      strokeWidth:
                          5,

                      color:
                          Colors.blue,
                    ),
                  ],
                ),

              // ==================================
              // MARKERS
              // ==================================

              MarkerLayer(
                markers: [
                  // PICKUP MARKER
                  Marker(
                    point:
                        pickup,

                    width:
                        60,

                    height:
                        60,

                    child:
                        const Icon(
                      Icons.my_location,

                      color:
                          Colors.blue,

                      size:
                          38,
                    ),
                  ),

                  // DESTINATION MARKER
                  if (destination != null)
                    Marker(
                      point:
                          LatLng(
                        destination
                            .latitude,

                        destination
                            .longitude,
                      ),

                      width:
                          60,

                      height:
                          60,

                      child:
                          const Icon(
                        Icons.location_pin,

                        color:
                            Colors.red,

                        size:
                            45,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // ======================================
        // PICKUP SELECTION MODE
        // ======================================

        if (_selectingPickup)
          Positioned(
            top:
                20,

            left:
                20,

            right:
                20,

            child:
                Card(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  12,
                ),

                child:
                    Row(
                  children: [
                    const Icon(
                      Icons.touch_app,
                    ),

                    const SizedBox(
                      width:
                          10,
                    ),

                    const Expanded(
                      child:
                          Text(
                        'Tap the map to set your pickup location.',
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectingPickup =
                              false;
                        });
                      },

                      icon:
                          const Icon(
                        Icons.close,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ======================================
        // MAP CONTROLS
        // ======================================

        Positioned(
          right:
              15,

          bottom:
              20,

          child:
              Column(
            children: [
              // USE MY LOCATION
              FloatingActionButton.small(
                heroTag:
                    'myLocation',

                onPressed:
                    _isLoadingLocation
                        ? null
                        : useMyLocation,

                child:
                    _isLoadingLocation
                        ? const SizedBox(
                            width:
                                20,

                            height:
                                20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons.my_location,
                          ),
              ),

              const SizedBox(
                height:
                    10,
              ),

              // SET PICKUP ON MAP
              FloatingActionButton.small(
                heroTag:
                    'setPickup',

                onPressed:
                    enablePickupSelection,

                child:
                    const Icon(
                  Icons.location_on,
                ),
              ),
            ],
          ),
        ),

        // ======================================
        // ROUTE INFORMATION
        // ======================================

        if (destination != null &&
            !_isLoadingRoute &&
            _distanceMeters != null)
          Positioned(
            top:
                20,

            left:
                20,

            right:
                20,

            child:
                Card(
              child:
                  Padding(
                padding:
                    const EdgeInsets.all(
                  15,
                ),

                child:
                    Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,

                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.route,
                        ),

                        const SizedBox(
                          height:
                              5,
                        ),

                        Text(
                          _formatDistance(),

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        const Icon(
                          Icons.access_time,
                        ),

                        const SizedBox(
                          height:
                              5,
                        ),

                        Text(
                          _formatDuration(),

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ======================================
        // ROUTE LOADING
        // ======================================

        if (_isLoadingRoute)
          const Positioned(
            top:
                20,

            right:
                20,

            child:
                Card(
              child:
                  Padding(
                padding:
                    EdgeInsets.all(
                  10,
                ),

                child:
                    SizedBox(
                  width:
                      25,

                  height:
                      25,

                  child:
                      CircularProgressIndicator(
                    strokeWidth:
                        3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}