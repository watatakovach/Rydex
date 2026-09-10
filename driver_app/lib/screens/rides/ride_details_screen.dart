import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/ride.dart';
import 'active_ride_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final Ride ride;

  const RideDetailsScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RideDetailsScreen> createState() =>
      _RideDetailsScreenState();
}

class _RideDetailsScreenState
    extends State<RideDetailsScreen> {
  bool _isAccepting = false;

  // ============================================================
  // ACCEPT RIDE
  // ============================================================

  Future<void> _acceptRide() async {
    if (_isAccepting) return;

    setState(() {
      _isAccepting = true;
    });

    try {
      final acceptedRide =
          await ApiService.acceptRide(
        rideId: widget.ride.id,
      );

      if (!mounted) return;

      // Go to active ride screen after
      // successful backend acceptance.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ActiveRideScreen(
            ride: acceptedRide,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAccepting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
  // CONFIRM ACCEPTANCE
  // ============================================================

  void _showAcceptConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) {
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

                _acceptRide();
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final ride = widget.ride;

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
            // ==================================================
            // RIDE HEADER
            // ==================================================

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
                            ride.status,

                            style:
                                TextStyle(
                              color:
                                  Colors
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

            // ==================================================
            // RIDE INFORMATION
            // ==================================================

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      'Ride Information',

                      style:
                          TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _InfoRow(
                      icon:
                          Icons.location_on,
                      label:
                          'Pickup',
                      value:
                          '${ride.pickupLatitude}, ${ride.pickupLongitude}',
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.flag,
                      label:
                          'Destination',
                      value:
                          '${ride.destinationLatitude}, ${ride.destinationLongitude}',
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.route,
                      label:
                          'Distance',
                      value:
                          'Ride distance calculated by backend',
                    ),

                    const Divider(
                      height: 24,
                    ),

                    _InfoRow(
                      icon:
                          Icons.payment,
                      label:
                          'Fare',
                      value:
                          'KES ${ride.estimatedFare?.toStringAsFixed(0) ?? 'N/A'}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            // ==================================================
            // ACCEPT BUTTON
            // ==================================================

            SizedBox(
              height: 55,

              child:
                  ElevatedButton.icon(
                onPressed:
                    _isAccepting
                        ? null
                        : _showAcceptConfirmation,

                icon:
                    _isAccepting
                        ? const SizedBox(
                            height: 20,
                            width: 20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .check_circle,
                          ),

                label:
                    Text(
                  _isAccepting
                      ? 'ACCEPTING...'
                      : 'ACCEPT RIDE',

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // DECLINE BUTTON
            // ==================================================

            SizedBox(
              height: 55,

              child:
                  OutlinedButton.icon(
                onPressed:
                    _isAccepting
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },

                icon:
                    const Icon(
                  Icons.close,
                ),

                label:
                    const Text(
                  'DECLINE RIDE',

                  style:
                      TextStyle(
                    fontSize: 16,
                  ),
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
// INFO ROW
// ================================================================

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

            style:
                TextStyle(
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