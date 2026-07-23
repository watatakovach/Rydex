class FareResult {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double totalFare;

  FareResult({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.totalFare,
  });
}

class FareService {
  // RydeX MVP pricing
  static const double baseFare = 100.0;

  // KSh per kilometer
  static const double pricePerKm = 35.0;

  // KSh per minute
  static const double pricePerMinute = 5.0;

  static FareResult calculateFare({
    required double distanceMeters,
    required double durationSeconds,
  }) {
    final distanceKm =
        distanceMeters / 1000;

    final durationMinutes =
        durationSeconds / 60;

    final distanceFare =
        distanceKm * pricePerKm;

    final timeFare =
        durationMinutes * pricePerMinute;

    final totalFare =
        baseFare +
        distanceFare +
        timeFare;

    return FareResult(
      baseFare: baseFare,
      distanceFare: distanceFare,
      timeFare: timeFare,
      totalFare: totalFare,
    );
  }
}