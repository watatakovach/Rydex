import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/ride.dart';
import 'ride_details_screen.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({
    super.key,
  });

  @override
  State<AvailableRidesScreen> createState() =>
      _AvailableRidesScreenState();
}

class _AvailableRidesScreenState
    extends State<AvailableRidesScreen> {
  List<Ride> _rides = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadAvailableRides();
  }

  // ============================================================
  // LOAD AVAILABLE RIDES
  // ============================================================

  Future<void> _loadAvailableRides() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rides =
          await ApiService.getAvailableRides();

      if (!mounted) return;

      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // OPEN RIDE DETAILS
  // ============================================================

  Future<void> _openRideDetails(
    Ride ride,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RideDetailsScreen(
          ride: ride,
        ),
      ),
    );

    // Refresh rides when returning.
    // This is useful if the driver accepted a ride.
    if (!mounted) return;

    await _loadAvailableRides();
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
        title: const Text(
          'Available Rides',
        ),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadAvailableRides,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAvailableRides,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height:
                  MediaQuery.of(context)
                          .size
                          .height *
                      0.35,
            ),
            _buildEmptyState(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAvailableRides,

      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(16),

        itemCount: _rides.length,

        itemBuilder: (
          context,
          index,
        ) {
          final ride = _rides[index];

          return _RideRequestCard(
            ride: ride,
            onTap: () {
              _openRideDetails(ride);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .cloud_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Unable to load rides',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            ElevatedButton.icon(
              onPressed:
                  _loadAvailableRides,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons
                  .local_taxi_outlined,
              size: 80,
              color: Colors.grey[400],
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'No rides available',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'New ride requests will appear here when passengers request a ride.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            OutlinedButton.icon(
              onPressed:
                  _loadAvailableRides,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'REFRESH',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// RIDE REQUEST CARD
// ================================================================

class _RideRequestCard
    extends StatelessWidget {
  final Ride ride;

  final VoidCallback onTap;

  const _RideRequestCard({
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      elevation: 2,

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(
          12,
        ),

        child: Padding(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(
                      Icons.person,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        const Text(
                          'New Ride Request',
                          style:
                              TextStyle(
                            fontSize:
                                17,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Ride #${ride.id}',
                          style:
                              TextStyle(
                            color:
                                Colors
                                    .grey[600],
                            fontSize:
                                13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    'KES ${ride.estimatedFare?.toStringAsFixed(0) ?? 'N/A'}',

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
                height: 20,
              ),

              // ==================================================
              // PICKUP
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Icon(
                    Icons
                        .radio_button_checked,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          'Pickup Coordinates',
                          style:
                              TextStyle(
                            fontSize:
                                12,
                            color:
                                Colors
                                    .grey[600],
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          '${ride.pickupLatitude}, ${ride.pickupLongitude}',

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets
                        .only(
                  left: 9,
                ),

                child: SizedBox(
                  height: 20,
                  width: 2,

                  child:
                      const ColoredBox(
                    color:
                        Colors.grey,
                  ),
                ),
              ),

              // ==================================================
              // DESTINATION
              // ==================================================

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  const Icon(
                    Icons.location_on,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          'Destination Coordinates',

                          style:
                              TextStyle(
                            fontSize:
                                12,
                            color:
                                Colors
                                    .grey[600],
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          '${ride.destinationLatitude}, ${ride.destinationLongitude}',

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // RIDE INFORMATION
              // ==================================================

              Row(
                children: [
                  const Icon(
                    Icons
                        .route_outlined,
                    size: 20,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Ride #${ride.id}',
                  ),

                  const Spacer(),

                  const Icon(
                    Icons
                        .arrow_forward_ios,
                    size: 14,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  const Text(
                    'View Details',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}