class Place {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;

  const Place({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(
    Map<String, dynamic> json,
  ) {
    return Place(
      name: (json['name'] ?? '').toString().trim().isNotEmpty
          ? json['name'].toString()
          : 'Unknown location',

      displayName:
          (json['display_name'] ?? '').toString(),

      latitude:
          double.parse(
        json['lat'].toString(),
      ),

      longitude:
          double.parse(
        json['lon'].toString(),
      ),
    );
  }

  @override
  String toString() {
    return 'Place('
        'name: $name, '
        'displayName: $displayName, '
        'latitude: $latitude, '
        'longitude: $longitude'
        ')';
  }
}