class Vehicle {
  final String? make;
  final String? model;
  final String? color;
  final String? plate;
  final String? photoUrl;

  Vehicle({
    this.make,
    this.model,
    this.color,
    this.plate,
    this.photoUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['vehicle_make'] ?? json['make'],
      model: json['vehicle_model'] ?? json['model'],
      color: json['vehicle_color'] ?? json['color'],
      plate: json['vehicle_plate'] ?? json['plate'],
      photoUrl: json['vehicle_photo'] ?? json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_make': make,
      'vehicle_model': model,
      'vehicle_color': color,
      'vehicle_plate': plate,
      'vehicle_photo': photoUrl,
    };
  }
}
