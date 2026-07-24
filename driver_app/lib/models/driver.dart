class Driver {
  final int id;
  final int userId;
  final String licenseNumber;
  final bool isVerified;
  final bool isOnline;

  Driver({
    required this.id,
    required this.userId,
    required this.licenseNumber,
    required this.isVerified,
    required this.isOnline,
  });

  factory Driver.fromJson(
    Map<String, dynamic> json,
  ) {
    return Driver(
      id: json['id'],
      userId: json['user_id'],
      licenseNumber: json['license_number'],
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
    );
  }
}