
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ============================================================
  // CHECK / REQUEST LOCATION PERMISSION
  // ============================================================

  static Future<bool> ensurePermission() async {
    // Check whether GPS/location services are enabled.
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      debugPrint(
        'RYDEX GPS: Location services are disabled.',
      );
      return false;
    }

    // Check current permission.
    var permission =
        await Geolocator.checkPermission();

    // Request permission if needed.
    if (permission == LocationPermission.denied) {
      debugPrint(
        'RYDEX GPS: Requesting location permission...',
      );

      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      debugPrint(
        'RYDEX GPS: Location permission denied.',
      );
      return false;
    }

    if (permission ==
        LocationPermission.deniedForever) {
      debugPrint(
        'RYDEX GPS: Location permission permanently denied.',
      );
      return false;
    }

    debugPrint(
      'RYDEX GPS: Location permission granted.',
    );

    return true;
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> getCurrentLocation() async {
    final permitted =
        await ensurePermission();

    if (!permitted) {
      debugPrint(
        'RYDEX GPS: Permission/service check failed.',
      );
      return null;
    }

    try {
      debugPrint(
        'RYDEX GPS: Requesting current position...',
      );

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      debugPrint(
        'RYDEX GPS: '
        'latitude=${position.latitude}, '
        'longitude=${position.longitude}',
      );

      return position;
    } catch (e) {
      debugPrint(
        'RYDEX GPS ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // LOCATION STREAM
  // ============================================================

  static Stream<Position> locationStream() {
    const settings =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );

    debugPrint(
      'RYDEX GPS: Starting location stream...',
    );

    return Geolocator.getPositionStream(
      locationSettings: settings,
    );
  }
}
