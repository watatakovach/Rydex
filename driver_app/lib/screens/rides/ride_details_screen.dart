import 'package:flutter/material.dart';

import '../../models/ride.dart';
import 'active_ride_screen.dart';

class RideDetailsScreen
    extends StatelessWidget {
  final Ride ride;

  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final String estimatedFare =
        ride.estimatedFare == null
            ? 'N/A'
            : 'KES ${ride.estimatedFare!.toStringAsFixed(0)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride Details',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [
            // =====================================================
            // RIDE REQUEST HEADER
            // =====================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(
                        Icons.person,
                        size: 30,
                      ),
                    ),

                    const SizedBox(
                      width: 16,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'Ride Request',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Ride #${ride.id}',
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            'Status: ${ride.status}',
                            style:
                                TextStyle(
                              color: Colors
                                  .grey[600],
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

            // =====================================================
            // FARE
            // =====================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      'Estimated Fare',
                      style:
                          TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      estimatedFare,
                      style:
                          const TextStyle(
                        fontSize: 32,
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

            // =====================================================
            // PICKUP AND DESTINATION
            // =====================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Text(
                      'Trip Route',
                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _InfoRow(
                      icon: Icons
                          .radio_button_checked,
                      label:
                          'Pickup Location',
                      value:
                          '${ride.pickupLatitude}, ${ride.pickupLongitude}',
                    ),

                    const Divider(
                      height: 30,
                    ),

                    _InfoRow(
                      icon: Icons
                          .location_on,
                      label:
                          'Destination',
                      value:
                          '${ride.destinationLatitude}, ${ride.destinationLongitude}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =====================================================
            // RIDE INFORMATION
            // =====================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [
                    _InfoRow(
                      icon:
                          Icons.confirmation_number,
                      label:
                          'Ride ID',
                      value:
                          ride.id.toString(),
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.person,
                      label:
                          'Passenger ID',
                      value:
                          ride.passengerId
                              .toString(),
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.info_outline,
                      label:
                          'Status',
                      value:
                          ride.status,
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.payment,
                      label:
                          'Payment',
                      value:
                          'Cash / M-Pesa',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // =====================================================
            // ACCEPT RIDE
            // =====================================================

            SizedBox(
              height: 55,

              child:
                  ElevatedButton.icon(
                onPressed: () {
                  _showAcceptConfirmation(
                    context,
                  );
                },

                icon: const Icon(
                  Icons.check_circle,
                ),

                label: const Text(
                  'ACCEPT RIDE',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // =====================================================
            // DECLINE RIDE
            // =====================================================

            SizedBox(
              height: 55,

              child:
                  OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },

                icon: const Icon(
                  Icons.close,
                ),

                label: const Text(
                  'DECLINE RIDE',
                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ACCEPT CONFIRMATION
  // ===========================================================

  void _showAcceptConfirmation(
    BuildContext context,
  ) {
    showDialog(
      context: context,

      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Accept Ride?',
          ),

          content: const Text(
            'Are you sure you want to accept this ride request?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child: const Text(
                'CANCEL',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Navigator.pushReplacement(
                  context,

                  MaterialPageRoute(
                    builder: (_) =>
                        ActiveRideScreen(
                      ride: ride,
                    ),
                  ),
                );
              },

              child: const Text(
                'ACCEPT',
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================
// INFORMATION ROW
// =============================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;

  final String label;

  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 24,
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  Colors.grey[600],
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.end,

            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}