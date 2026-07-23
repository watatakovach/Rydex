import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/place.dart';

class SearchService {
  static Future<List<Place>> searchPlaces(
    String query,
  ) async {
    // ==========================================
    // VALIDATE SEARCH QUERY
    // ==========================================

    if (query.trim().isEmpty) {
      return [];
    }

    // ==========================================
    // BUILD NOMINATIM URL
    // ==========================================

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query.trim(),
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
      },
    );

    debugPrint(
      '====================================',
    );

    debugPrint(
      'Searching OpenStreetMap:',
    );

    debugPrint(
      uri.toString(),
    );

    // ==========================================
    // SEND REQUEST
    // ==========================================

    final response = await http.get(
      uri,
      headers: {
        'User-Agent':
            'RYDEX/1.0 (passenger_app)',
        'Accept':
            'application/json',
      },
    );

    // ==========================================
    // DEBUG RESPONSE
    // ==========================================

    debugPrint(
      'Status code: ${response.statusCode}',
    );

    // ==========================================
    // CHECK RESPONSE
    // ==========================================

    if (response.statusCode != 200) {
      debugPrint(
        'OpenStreetMap request failed.',
      );

      debugPrint(
        'Response: ${response.body}',
      );

      throw Exception(
        'OpenStreetMap search failed: '
        '${response.statusCode}',
      );
    }

    // ==========================================
    // DECODE JSON
    // ==========================================

    final List<dynamic> data =
        jsonDecode(response.body);

    debugPrint(
      'Found ${data.length} locations.',
    );

    // ==========================================
    // CONVERT JSON TO PLACE OBJECTS
    // ==========================================

    final places = data
        .map(
          (item) => Place.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    // ==========================================
    // DEBUG RESULTS
    // ==========================================

    for (final place in places) {
      debugPrint(
        'Place: ${place.name}',
      );

      debugPrint(
        'Address: ${place.displayName}',
      );

      debugPrint(
        'Latitude: ${place.latitude}',
      );

      debugPrint(
        'Longitude: ${place.longitude}',
      );
    }

    debugPrint(
      '====================================',
    );

    return places;
  }
}