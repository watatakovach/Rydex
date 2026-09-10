class DriverEarnings {
  final double totalEarnings;
  final int totalRides;
  final double todayEarnings;
  final int todayRides;

  DriverEarnings({
    required this.totalEarnings,
    required this.totalRides,
    required this.todayEarnings,
    required this.todayRides,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalRides: (json['total_rides'] as num?)?.toInt() ?? 0,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      todayRides: (json['today_rides'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'total_rides': totalRides,
      'today_earnings': todayEarnings,
      'today_rides': todayRides,
    };
  }
}
