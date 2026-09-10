class Ride {
  final int id;
  final int passengerId;
  final int? driverId;

  final double pickupLatitude;
  final double pickupLongitude;

  final double destinationLatitude;
  final double destinationLongitude;

  final String status;

  final double? estimatedFare;
  final double? finalFare;

  final DateTime? requestedAt;
  final DateTime? completedAt;
  final int? driverRating;
  final String? driverRatingComment;
  final bool hasDriverRating;

  const Ride({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.status,
    this.estimatedFare,
    this.finalFare,
    this.requestedAt,
    this.completedAt,
    this.driverRating,
    this.driverRatingComment,
    this.hasDriverRating = false,
  });

  factory Ride.fromJson(
    Map<String, dynamic> json,
  ) {
    return Ride(
      id: _parseInt(json['id']),
      passengerId: _parseInt(
        json['passenger_id'],
      ),
      driverId: json['driver_id'] == null
          ? null
          : _parseInt(
              json['driver_id'],
            ),
      pickupLatitude: _parseDouble(
        json['pickup_latitude'],
      ),
      pickupLongitude: _parseDouble(
        json['pickup_longitude'],
      ),
      destinationLatitude: _parseDouble(
        json['destination_latitude'],
      ),
      destinationLongitude: _parseDouble(
        json['destination_longitude'],
      ),
      status: json['status']?.toString() ??
          'unknown',
      estimatedFare:
          json['estimated_fare'] == null
              ? null
              : _parseDouble(
                  json['estimated_fare'],
                ),
      finalFare:
          json['final_fare'] == null
              ? null
              : _parseDouble(
                  json['final_fare'],
                ),
      requestedAt:
          json['requested_at'] == null
              ? null
              : DateTime.tryParse(
                  json['requested_at']
                      .toString(),
                ),
      completedAt:
          json['completed_at'] == null
              ? null
              : DateTime.tryParse(
                  json['completed_at']
                      .toString(),
                ),
      driverRating: json['driver_rating'] == null
          ? null
          : _parseInt(json['driver_rating']),
      driverRatingComment:
          json['driver_rating_comment']?.toString(),
      hasDriverRating:
          json['has_driver_rating'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'driver_id': driverId,
      'pickup_latitude':
          pickupLatitude,
      'pickup_longitude':
          pickupLongitude,
      'destination_latitude':
          destinationLatitude,
      'destination_longitude':
          destinationLongitude,
      'status': status,
      'estimated_fare':
          estimatedFare,
      'final_fare':
          finalFare,
      'requested_at':
          requestedAt?.toIso8601String(),
      'completed_at':
          completedAt?.toIso8601String(),
      'driver_rating': driverRating,
      'driver_rating_comment':
          driverRatingComment,
      'has_driver_rating': hasDriverRating,
    };
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _parseDouble(
    dynamic value,
  ) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}
