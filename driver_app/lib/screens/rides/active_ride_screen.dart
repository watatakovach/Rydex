import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../../models/ride.dart';

class ActiveRideScreen extends StatefulWidget {
  final Ride ride;

  const ActiveRideScreen({super.key, required this.ride});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  late Ride _ride;

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();

    _ride = widget.ride;
  }

  // ============================================================
  // UPDATE RIDE STATUS
  // ============================================================

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedRide = await ApiService.updateRideStatus(
        rideId: _ride.id,
        status: newStatus,
      );

      if (!mounted) return;

      setState(() {
        _ride = updatedRide;
        _isUpdating = false;
      });

      if (newStatus == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed successfully.')),
        );

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        final navigator = Navigator.of(context);
        navigator.pop();

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ride status updated to ${_formatStatus(newStatus)}.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ============================================================
  // GET NEXT STATUS
  // ============================================================

  String? _getNextStatus() {
    switch (_ride.status) {
      case 'assigned':
        return 'accepted';

      case 'accepted':
        return 'driver_arriving';

      case 'driver_arriving':
        return 'driver_arrived';

      case 'driver_arrived':
        return 'in_progress';

      case 'in_progress':
        return 'completed';

      default:
        return null;
    }
  }

  // ============================================================
  // BUTTON LABEL
  // ============================================================

  String _getButtonLabel() {
    switch (_ride.status) {
      case 'assigned':
        return 'ACCEPT RIDE';

      case 'accepted':
        return 'START DRIVING';

      case 'driver_arriving':
        return 'MARK ARRIVED';

      case 'driver_arrived':
        return 'START RIDE';

      case 'in_progress':
        return 'COMPLETE RIDE';

      case 'completed':
        return 'RIDE COMPLETED';

      default:
        return 'NO ACTION AVAILABLE';
    }
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  // ============================================================
  // STATUS DESCRIPTION
  // ============================================================

  String _getStatusDescription() {
    switch (_ride.status) {
      case 'assigned':
        return 'This ride has been assigned to you.';

      case 'accepted':
        return 'You have accepted this ride. Start driving to the passenger.';

      case 'driver_arriving':
        return 'You are on your way to pick up the passenger.';

      case 'driver_arrived':
        return 'You have arrived at the pickup location.';

      case 'in_progress':
        return 'The passenger is currently in your vehicle.';

      case 'completed':
        return 'This ride has been completed.';

      default:
        return 'Current ride status: ${_formatStatus(_ride.status)}';
    }
  }

  // ============================================================
  // CONFIRM COMPLETION
  // ============================================================

  void _confirmCompletion() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Complete Ride?'),
          content: const Text(
            'Are you sure you have dropped off the passenger and want to complete this ride?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _updateStatus('completed');
              },
              child: const Text('COMPLETE'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HANDLE NEXT ACTION
  // ============================================================

  void _handleNextAction() {
    final nextStatus = _getNextStatus();

    if (nextStatus == null) {
      return;
    }

    if (nextStatus == 'completed') {
      _confirmCompletion();

      return;
    }

    _updateStatus(nextStatus);
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  void _confirmCancelRide() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Ride?'),
          content: const Text('Are you sure you want to cancel this ride?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('NO'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _updateStatus('cancelled');
              },
              child: const Text('CANCEL RIDE'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Ride')),

      body: RefreshIndicator(
        onRefresh: () async {
          try {
            final currentRide = await ApiService.getDriverCurrentRide();

            if (!mounted) return;

            if (currentRide != null) {
              setState(() {
                _ride = currentRide;
              });
            }
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(this.context).showSnackBar(
              
              SnackBar(
                content: Text(e.toString().replaceFirst(
                  'Exception: ',''
                )),
              ),
            );
          }
        },

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            // ==================================================
            // STATUS CARD
            // ==================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  children: [
                    Icon(_getStatusIcon(_ride.status), size: 64),

                    const SizedBox(height: 16),

                    Text(
                      _formatStatus(_ride.status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _getStatusDescription(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // RIDE ID
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_taxi),
                title: const Text('Ride ID'),
                subtitle: Text('#${_ride.id}'),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // PICKUP
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.radio_button_checked),
                title: const Text('Pickup Location'),
                subtitle: Text(
                  '${_ride.pickupLatitude}, ${_ride.pickupLongitude}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DESTINATION
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Destination'),
                subtitle: Text(
                  '${_ride.destinationLatitude}, ${_ride.destinationLongitude}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // FARE
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Estimated Fare'),
                subtitle: Text(
                  'KES ${_ride.estimatedFare?.toStringAsFixed(0) ?? 'N/A'}',
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // NEXT ACTION
            // ==================================================
            if (_getNextStatus() != null)
              SizedBox(
                height: 55,

                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _handleNextAction,

                  icon: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _ride.status == 'in_progress'
                              ? Icons.check_circle
                              : Icons.arrow_forward,
                        ),

                  label: Text(
                    _isUpdating ? 'UPDATING...' : _getButtonLabel(),

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ==================================================
            // CANCEL
            // ==================================================
            if (_ride.status != 'completed' &&
                _ride.status != 'cancelled' &&
                _ride.status != 'in_progress')
              SizedBox(
                height: 55,

                child: OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _confirmCancelRide,

                  icon: const Icon(Icons.cancel_outlined),

                  label: const Text('CANCEL RIDE'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned':
        return Icons.assignment;

      case 'accepted':
        return Icons.check_circle;

      case 'driver_arriving':
        return Icons.directions_car;

      case 'driver_arrived':
        return Icons.location_on;

      case 'in_progress':
        return Icons.navigation;

      case 'completed':
        return Icons.done_all;

      case 'cancelled':
        return Icons.cancel;

      default:
        return Icons.local_taxi;
    }
  }
}
