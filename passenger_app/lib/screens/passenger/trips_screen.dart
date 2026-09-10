import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({
    super.key,
  });

  @override
  State<TripsScreen> createState() =>
      _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  List<dynamic> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rides = await ApiService.getMyRides();

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
            .replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadRides,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRides,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRides,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 160),
            Icon(Icons.history, size: 72),
            SizedBox(height: 16),
            Text(
              'No trips yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          final ride = Map<String, dynamic>.from(
            _rides[index] as Map,
          );

          return _TripCard(
            ride: ride,
            onRated: _loadRides,
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final Future<void> Function() onRated;

  const _TripCard({
    required this.ride,
    required this.onRated,
  });

  @override
  Widget build(BuildContext context) {
    final status = ride['status']?.toString() ?? '';
    final isCompleted = status == 'completed';
    final hasRating = ride['has_driver_rating'] == true;
    final rating = ride['driver_rating'];

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.route,
                  color: isCompleted
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ride #${ride['id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.green
                        : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Fare: KES ${ride['final_fare'] ?? ride['estimated_fare'] ?? 'N/A'}',
            ),
            const SizedBox(height: 6),
            Text(
              'Pickup: ${ride['pickup_latitude']}, ${ride['pickup_longitude']}',
            ),
            const SizedBox(height: 6),
            Text(
              'Destination: ${ride['destination_latitude']}, ${ride['destination_longitude']}',
            ),
            if (isCompleted) ...[
              const Divider(height: 26),
              if (hasRating)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '$rating / 5',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Driver rated'),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final submitted =
                          await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _RatingSheet(
                          rideId: ride['id'] as int,
                        ),
                      );

                      if (submitted == true) {
                        await onRated();
                      }
                    },
                    icon: const Icon(Icons.star_border),
                    label: const Text('Rate Driver'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingSheet extends StatefulWidget {
  final int rideId;

  const _RatingSheet({
    required this.rideId,
  });

  @override
  State<_RatingSheet> createState() =>
      _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 5;
  bool _isSubmitting = false;
  final TextEditingController _commentController =
      TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.rateDriver(
        rideId: widget.rideId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver rating submitted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your driver',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;

                return IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _rating = value;
                          });
                        },
                  icon: Icon(
                    value <= _rating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 34,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
