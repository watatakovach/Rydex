import 'package:flutter/material.dart';

import '../../models/ride.dart';
import 'ride_details_screen.dart';

class AvailableRidesScreen extends StatelessWidget {
  const AvailableRidesScreen({super.key});

  // Temporary sample rides.
  // These are converted into Ride objects before opening details.
  final List<Map<String, dynamic>> rides = const [
    {
      'id': 1001,
      'passenger_id': 1,
      'driver_id': null,
      'pickup_latitude': -0.006,
      'pickup_longitude': 34.601,
      'destination_latitude': -0.0917,
      'destination_longitude': 34.768,
      'status': 'requested',
      'estimated_fare': 850,
      'final_fare': null,
      'requested_at': null,
      'completed_at': null,
    },
    {
      'id': 1002,
      'passenger_id': 2,
      'driver_id': null,
      'pickup_latitude': -0.005,
      'pickup_longitude': 34.601,
      'destination_latitude': -0.108,
      'destination_longitude': 34.756,
      'status': 'requested',
      'estimated_fare': 1200,
      'final_fare': null,
      'requested_at': null,
      'completed_at': null,
    },
    {
      'id': 1003,
      'passenger_id': 3,
      'driver_id': null,
      'pickup_latitude': -0.0917,
      'pickup_longitude': 34.768,
      'destination_latitude': -0.078,
      'destination_longitude': 34.775,
      'status': 'requested',
      'estimated_fare': 350,
      'final_fare': null,
      'requested_at': null,
      'completed_at': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO:
              // Refresh available rides from backend.
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: rides.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async {
                // TODO:
                // Fetch latest rides from API.
                await Future.delayed(
                  const Duration(milliseconds: 500),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rides.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final rideData = rides[index];

                  final Ride ride =
                      Ride.fromJson(rideData);

                  return _RideRequestCard(
                    ride: ride,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RideDetailsScreen(
                            ride: ride,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_taxi_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            const Text(
              'No rides available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New ride requests will appear here when passengers request a ride.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideRequestCard
    extends StatelessWidget {
  final Ride ride;

  final VoidCallback onTap;

  const _RideRequestCard({
    required this.ride,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // HEADER
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Ride #${ride.id}',
                          style: TextStyle(
                            color:
                                Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    'KES ${ride.estimatedFare?.toStringAsFixed(0) ?? 'N/A'}',
                    style: const TextStyle(
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

              // PICKUP
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey[600],
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
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 9,
                ),
                child: SizedBox(
                  height: 20,
                  width: 2,
                  child: ColoredBox(
                    color: Colors.grey,
                  ),
                ),
              ),

              // DESTINATION
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey[600],
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
                                FontWeight.w600,
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

              // RIDE INFORMATION
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
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
                    Icons.arrow_forward_ios,
                    size: 14,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  const Text(
                    'View Details',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
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