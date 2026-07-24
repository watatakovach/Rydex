import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/ride.dart';

class ActiveRideScreen
    extends StatefulWidget {
  final Ride? ride;

  const ActiveRideScreen({
    super.key,
    this.ride,
  });

  @override
  State<ActiveRideScreen> createState() =>
      _ActiveRideScreenState();
}

class _ActiveRideScreenState
    extends State<ActiveRideScreen> {
  Ride? _ride;

  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    if (widget.ride != null) {
      _ride = widget.ride;
      _isLoading = false;
    } else {
      _loadCurrentRide();
    }
  }

  // ============================================================
  // LOAD CURRENT RIDE
  // ============================================================

  Future<void> _loadCurrentRide() async {
    try {
      final ride =
          await ApiService.getDriverCurrentRide();

      if (!mounted) return;

      setState(() {
        _ride = ride;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load active ride: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE RIDE STATUS
  // ============================================================

  Future<void> _updateRideStatus(
    String newStatus,
  ) async {
    if (_ride == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedRide =
          await ApiService.updateRideStatus(
        rideId: _ride!.id,
        status: newStatus,
      );

      if (!mounted) return;

      setState(() {
        _ride = updatedRide;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Ride status updated to $newStatus',
          ),
        ),
      );

      // Ride completed
      if (newStatus == 'completed') {
        await Future.delayed(
          const Duration(
            milliseconds: 500,
          ),
        );

        if (!mounted) return;

        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update ride: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATUS BUTTON
  // ============================================================

  Widget _buildStatusButton() {
    if (_ride == null) {
      return const SizedBox.shrink();
    }

    switch (_ride!.status) {
      case 'assigned':
        return ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  _updateRideStatus(
                    'accepted',
                  );
                },
          icon: const Icon(
            Icons.check_circle,
          ),
          label: const Text(
            'ACCEPT RIDE',
          ),
        );

      case 'accepted':
        return ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  _updateRideStatus(
                    'driver_arriving',
                  );
                },
          icon: const Icon(
            Icons.navigation,
          ),
          label: const Text(
            'I AM ON MY WAY',
          ),
        );

      case 'driver_arriving':
        return ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  _updateRideStatus(
                    'driver_arrived',
                  );
                },
          icon: const Icon(
            Icons.location_on,
          ),
          label: const Text(
            'I HAVE ARRIVED',
          ),
        );

      case 'driver_arrived':
        return ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  _updateRideStatus(
                    'in_progress',
                  );
                },
          icon: const Icon(
            Icons.play_arrow,
          ),
          label: const Text(
            'START RIDE',
          ),
        );

      case 'in_progress':
        return ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () {
                  _updateRideStatus(
                    'completed',
                  );
                },
          icon: const Icon(
            Icons.check_circle,
          ),
          label: const Text(
            'COMPLETE RIDE',
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Active Ride',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_ride == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Active Ride',
          ),
        ),
        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons
                      .directions_car_outlined,
                  size: 70,
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'No active ride',
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
                  'You currently do not have an active ride.',
                  textAlign:
                      TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed:
                      _loadCurrentRide,
                  child: const Text(
                    'REFRESH',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ride = _ride!;

    final fare =
        ride.estimatedFare == null
            ? 'KES 0'
            : 'KES ${ride.estimatedFare!.toStringAsFixed(0)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Active Ride',
        ),
      ),

      body: RefreshIndicator(
        onRefresh:
            _loadCurrentRide,

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),

          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,

            children: [
              // ==================================================
              // STATUS
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Column(
                    children: [
                      Icon(
                        Icons
                            .directions_car,
                        size: 60,
                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .primary,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'Current Ride',
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

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),

                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),

                          color: Colors
                              .green
                              .withValues(
                            alpha: 0.1,
                          ),
                        ),

                        child: Text(
                          ride.status
                              .replaceAll(
                            '_',
                            ' ',
                          )
                              .toUpperCase(),

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // RIDE ID
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      const Text(
                        'Ride ID',
                      ),

                      Text(
                        '#${ride.id}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // ROUTE
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Icon(
                            Icons
                                .my_location,
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
                                  'Pickup',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Lat: ${ride.pickupLatitude}\nLng: ${ride.pickupLongitude}',

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

                      const Padding(
                        padding:
                            EdgeInsets
                                .symmetric(
                          vertical: 16,
                        ),
                        child:
                            Divider(),
                      ),

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [
                          const Icon(
                            Icons
                                .location_on,
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
                                  'Destination',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors
                                            .grey,
                                  ),
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  'Lat: ${ride.destinationLatitude}\nLng: ${ride.destinationLongitude}',

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
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // FARE
              // ==================================================

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [
                      const Text(
                        'Estimated Fare',
                        style:
                            TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        fare,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // STATUS ACTION
              // ==================================================

              SizedBox(
                height: 52,

                child:
                    _buildStatusButton(),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // REPORT
              // ==================================================

              OutlinedButton.icon(
                onPressed:
                    _isUpdating
                        ? null
                        : () {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Problem reporting will be connected soon.',
                                ),
                              ),
                            );
                          },

                icon: const Icon(
                  Icons
                      .report_problem_outlined,
                ),

                label: const Text(
                  'REPORT A PROBLEM',
                ),

                style:
                    OutlinedButton
                        .styleFrom(
                  padding:
                      const EdgeInsets
                          .all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}