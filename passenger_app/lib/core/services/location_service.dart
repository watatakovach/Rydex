import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    try {
      debugPrint(
        '========================================',
      );
      debugPrint(
        'LOCATION SERVICE: START',
      );
      debugPrint(
        'Running on Web: $kIsWeb',
      );
      debugPrint(
        '========================================',
      );

      // ==========================================
      // 1. CHECK LOCATION SERVICES
      // ==========================================

      debugPrint(
        'Checking if location services are enabled...',
      );

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      debugPrint(
        'Location services enabled: $serviceEnabled',
      );

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled.',
        );
      }

      // ==========================================
      // 2. CHECK PERMISSION
      // ==========================================

      debugPrint(
        'Checking location permission...',
      );

      var permission =
          await Geolocator.checkPermission();

      debugPrint(
        'Current permission: $permission',
      );

      // ==========================================
      // 3. REQUEST PERMISSION
      // ==========================================

      if (permission ==
          LocationPermission.denied) {
        debugPrint(
          'Location permission denied.',
        );

        debugPrint(
          'Requesting location permission...',
        );

        permission =
            await Geolocator.requestPermission();

        debugPrint(
          'Permission after request: '
          '$permission',
        );
      }

      // ==========================================
      // 4. PERMISSION DENIED
      // ==========================================

      if (permission ==
          LocationPermission.denied) {
        throw Exception(
          'Location permission denied by user.',
        );
      }

      // ==========================================
      // 5. PERMISSION PERMANENTLY DENIED
      // ==========================================

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. '
          'Please enable location permission '
          'in your browser settings.',
        );
      }

      // ==========================================
      // 6. REQUEST LOCATION
      // ==========================================

      debugPrint(
        'Permission granted.',
      );

      debugPrint(
        'Requesting browser/device location...',
      );

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(
          seconds: 15,
        ),
        onTimeout: () {
          debugPrint(
            'LOCATION REQUEST TIMED OUT!',
          );

          throw Exception(
            'Location request timed out. '
            'Please allow location access '
            'in Microsoft Edge.',
          );
        },
      );

      // ==========================================
      // 7. LOCATION RECEIVED
      // ==========================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        'LOCATION SUCCESS!',
      );

      debugPrint(
        'Latitude: ${position.latitude}',
      );

      debugPrint(
        'Longitude: ${position.longitude}',
      );

      debugPrint(
        'Accuracy: ${position.accuracy} meters',
      );

      debugPrint(
        '========================================',
      );

      // IMPORTANT:
      // Return the position to MapWidget
      return position;
    } catch (e) {
      // ==========================================
      // ERROR DEBUGGING
      // ==========================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        'LOCATION SERVICE ERROR',
      );

      debugPrint(
        'Error: $e',
      );

      debugPrint(
        'Error type: ${e.runtimeType}',
      );

      debugPrint(
        '========================================',
      );

      // Pass the error back to MapWidget
      rethrow;
    }
  }
}