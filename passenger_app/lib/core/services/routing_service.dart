import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  RoutingResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class RoutingService {
  static Future<RoutingResult> getRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    debugPrint('====================================');
    debugPrint('ROUTING SERVICE');
    debugPrint(
      'START: ${start.latitude}, ${start.longitude}',
    );
    debugPrint(
      'DESTINATION: '
      '${destination.latitude}, '
      '${destination.longitude}',
    );

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full'
      '&geometries=geojson'
      '&alternatives=true'
      '&steps=false',
    );

    debugPrint('OSRM URL: $url');

    final response = await http.get(
      url,
      headers: {
        'User-Agent':
            'RYDEX Passenger App/1.0',
        'Accept':
            'application/json',
      },
    );

    debugPrint(
      'OSRM STATUS: ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get route. '
        'HTTP ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body);

    if (data['code'] != 'Ok') {
      throw Exception(
        'No route found by OSRM.',
      );
    }

    final List<dynamic> routes =
        data['routes'] as List<dynamic>;

    if (routes.isEmpty) {
      throw Exception(
        'OSRM returned no routes.',
      );
    }

    debugPrint(
      'Available routes: ${routes.length}',
    );

    // ==========================================
    // FIND FASTEST ROUTE
    // ==========================================

    Map<String, dynamic> bestRoute =
        routes.first as Map<String, dynamic>;

    for (final routeData in routes) {
      final route =
          routeData as Map<String, dynamic>;

      final currentDuration =
          (route['duration'] as num)
              .toDouble();

      final bestDuration =
          (bestRoute['duration'] as num)
              .toDouble();

      if (currentDuration < bestDuration) {
        bestRoute = route;
      }
    }

    debugPrint(
      'FASTEST ROUTE SELECTED',
    );

    debugPrint(
      'Distance: '
      '${bestRoute['distance']} meters',
    );

    debugPrint(
      'Duration: '
      '${bestRoute['duration']} seconds',
    );

    // ==========================================
    // GET ROUTE GEOMETRY
    // ==========================================

    final geometry =
        bestRoute['geometry']
            as Map<String, dynamic>;

    final coordinates =
        geometry['coordinates']
            as List<dynamic>;

    if (coordinates.isEmpty) {
      throw Exception(
        'Route geometry is empty.',
      );
    }

    // ==========================================
    // CONVERT ROUTE TO LATLNG
    // ==========================================

    final List<LatLng> points =
        coordinates.map((coordinate) {
      final List<dynamic> point =
          coordinate as List<dynamic>;

      final longitude =
          (point[0] as num).toDouble();

      final latitude =
          (point[1] as num).toDouble();

      return LatLng(
        latitude,
        longitude,
      );
    }).toList();

    debugPrint(
      'Route points: ${points.length}',
    );

    debugPrint(
      '====================================',
    );

    return RoutingResult(
      points: points,

      distanceMeters:
          (bestRoute['distance'] as num)
              .toDouble(),

      durationSeconds:
          (bestRoute['duration'] as num)
              .toDouble(),
    );
  }
}