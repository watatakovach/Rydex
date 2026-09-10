class Driver {
  final int id;
  final int userId;

  final String fullName;
  final String phoneNumber;
  final String email;

  final String licenseNumber;

  final bool isVerified;
  final bool isOnline;

  Driver({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.licenseNumber,
    required this.isVerified,
    required this.isOnline,
  });

  factory Driver.fromJson(
    Map<String, dynamic> json,
  ) {
    return Driver(
      id: json['id'],
      userId: json['user_id'] ?? 0,

      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',

      licenseNumber: json['license_number'],

      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
    );
  }
}