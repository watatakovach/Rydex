import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/ride.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({
    super.key,
  });

  @override
  State<RideHistoryScreen> createState() =>
      _RideHistoryScreenState();
}

class _RideHistoryScreenState
    extends State<RideHistoryScreen> {
  List<Ride> _rides = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  // ============================================================
  // LOAD RIDE HISTORY
  // ============================================================

  Future<void> _loadRideHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rides =
          await ApiService.getDriverRideHistory();

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride History',
        ),
        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadRideHistory,
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
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (
          context,
          index,
        ) {
          final ride = _rides[index];

          return _RideHistoryCard(
            ride: ride,
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.25,
          ),

          const Icon(
            Icons.history,
            size: 70,
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'No completed rides yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Your completed and cancelled rides will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Failed to load ride history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton.icon(
              onPressed:
                  _loadRideHistory,
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
}

// ================================================================
// RIDE HISTORY CARD
// ================================================================

class _RideHistoryCard
    extends StatelessWidget {
  final Ride ride;

  const _RideHistoryCard({
    required this.ride,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isCompleted =
        ride.status == 'completed';

    final String statusText =
        isCompleted
            ? 'Completed'
            : 'Cancelled';

    final IconData statusIcon =
        isCompleted
            ? Icons.check_circle
            : Icons.cancel;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
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
                Icon(
                  statusIcon,
                  size: 30,
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
                        'Ride #${ride.id}',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        statusText,
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w600,
                          color:
                              isCompleted
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // FARE
                // ==================================================

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${ride.finalFare?.toStringAsFixed(2) ?? ride.estimatedFare?.toStringAsFixed(2) ?? 'N/A'}',
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    const Text(
                      'Fare',
                      style:
                          TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(
              height: 30,
            ),

            // ==================================================
            // PICKUP
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.radio_button_checked,
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
                        'Pickup',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey[600],
                        ),
                      ),

                      const SizedBox(
                        height: 4,
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

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // DESTINATION
            // ==================================================

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
                        'Destination',
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey[600],
                        ),
                      ),

                      const SizedBox(
                        height: 4,
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

            // ==================================================
            // COMPLETION DATE
            // ==================================================

            if (ride.completedAt !=
                null) ...[
              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color:
                        Colors.grey[600],
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Completed: ${_formatDate(ride.completedAt!)}',
                    style:
                        TextStyle(
                      color:
                          Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            if (ride.hasDriverRating &&
                ride.driverRating != null) ...[
              const SizedBox(
                height: 16,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 20,
                    color: Colors.amber,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Passenger rating: ${ride.driverRating} / 5',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (ride.driverRatingComment != null &&
                  ride.driverRatingComment!.isNotEmpty) ...[
                const SizedBox(
                  height: 8,
                ),

                Text(
                  ride.driverRatingComment!,
                  style:
                      TextStyle(
                    color:
                        Colors.grey[700],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final localDate =
        date.toLocal();

    final day =
        localDate.day
            .toString()
            .padLeft(2, '0');

    final month =
        localDate.month
            .toString()
            .padLeft(2, '0');

    final year =
        localDate.year.toString();

    final hour =
        localDate.hour
            .toString()
            .padLeft(2, '0');

    final minute =
        localDate.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
