class DriverProfile {
  final int id;
  final int userId;

  final String fullName;
  final String phoneNumber;
  final String email;

  final String licenseNumber;

  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehiclePlate;

  final String? profilePhoto;
  final String? vehiclePhoto;

  final bool isVerified;
  final bool isOnline;
  final double? averageRating;
  final int ratingCount;

  DriverProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.licenseNumber,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.vehiclePlate,
    this.profilePhoto,
    this.vehiclePhoto,
    required this.isVerified,
    required this.isOnline,
    this.averageRating,
    this.ratingCount = 0,
  });

  factory DriverProfile.fromJson(
    Map<String, dynamic> json,
  ) {
    return DriverProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,

      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',

      licenseNumber: json['license_number'] ?? '',

      vehicleMake: json['vehicle_make'],
      vehicleModel: json['vehicle_model'],
      vehicleColor: json['vehicle_color'],
      vehiclePlate: json['vehicle_plate'],

      profilePhoto: json['profile_photo'],
      vehiclePhoto: json['vehicle_photo'],

      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      averageRating:
          json['average_rating'] == null
              ? null
              : _parseDouble(json['average_rating']),
      ratingCount:
          _parseInt(json['rating_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
