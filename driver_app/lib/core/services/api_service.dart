import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/driver.dart';
import '../../models/ride.dart';
import 'auth_service.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Android Emulator:
  // http://10.0.2.2:8000
  //
  // Physical Android phone:
  // Replace with your computer's local network IP.
  // Example:
  // http://192.168.1.100:8000
  //
  // Flutter Web on same computer:
  // http://127.0.0.1:8000

  // static const String baseUrl =
      // 'http://10.0.2.2:8000';

  static const String baseUrl =
    'http://192.168.2.104:8000';

  // ============================================================
  // GET AUTH TOKEN
  // ============================================================

  static Future<String> _getToken() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    return token;
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // JSON AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>> _jsonAuthHeaders() async {
    final token = await _getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // LOGIN DRIVER
  //
  // Backend:
  // POST /auth/login
  //
  // FastAPI uses OAuth2PasswordRequestForm.
  //
  // username can be either:
  // - email
  // - phone number
  // ============================================================

  static Future<String> loginDriver({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type':
            'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {
        'username': username,
        'password': password,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Invalid email/phone number or password',
      );
    }

    final accessToken =
        data['access_token'];

    if (accessToken == null ||
        accessToken.toString().isEmpty) {
      throw Exception(
        'Login succeeded but no access token was returned',
      );
    }

    await AuthService.saveToken(
      accessToken.toString(),
    );

    return accessToken.toString();
  }

  // ============================================================
  // REGISTER DRIVER PROFILE
  //
  // IMPORTANT:
  // The user must already be logged in.
  //
  // Backend:
  // POST /drivers/register
  //
  // Body:
  // {
  //   "license_number": "DL123456"
  // }
  // ============================================================

  static Future<Driver> registerDriver({
    required String licenseNumber,
  }) async {
    final headers =
        await _jsonAuthHeaders();

    final response = await http.post(
      Uri.parse(
        '$baseUrl/drivers/register',
      ),
      headers: headers,
      body: jsonEncode({
        'license_number':
            licenseNumber,
      }),
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        data['detail'] ??
            'Failed to register driver',
      );
    }

    return Driver.fromJson(
      data,
    );
  }

  // ============================================================
  // GET MY DRIVER PROFILE
  //
  // Backend:
  // GET /drivers/me
  // ============================================================

  static Future<Driver>
      getMyDriverProfile() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/drivers/me',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load driver profile',
      );
    }

    return Driver.fromJson(
      data,
    );
  }

  // ============================================================
  // UPDATE DRIVER ONLINE / OFFLINE STATUS
  //
  // Backend:
  // PATCH /drivers/status
  //
  // Body:
  // {
  //   "is_online": true
  // }
  // ============================================================

  static Future<Driver>
      updateDriverStatus({
    required bool isOnline,
  }) async {
    final headers =
        await _jsonAuthHeaders();

    final response =
        await http.patch(
      Uri.parse(
        '$baseUrl/drivers/status',
      ),
      headers: headers,
      body: jsonEncode({
        'is_online': isOnline,
      }),
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to update driver status',
      );
    }

    return Driver.fromJson(
      data,
    );
  }

  // ============================================================
  // UPDATE DRIVER LOCATION
  //
  // Backend:
  // PATCH /drivers/location
  // ============================================================

  static Future<Map<String, dynamic>>
      updateDriverLocation({
    required double latitude,
    required double longitude,
  }) async {
    final headers =
        await _jsonAuthHeaders();

    final response =
        await http.patch(
      Uri.parse(
        '$baseUrl/drivers/location',
      ),
      headers: headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to update driver location',
      );
    }

    return data;
  }

  // ============================================================
  // GET DRIVER LOCATION
  // ============================================================

  static Future<Map<String, dynamic>>
      getDriverLocation({
    required int driverId,
  }) async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/drivers/$driverId/location',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load driver location',
      );
    }

    return data;
  }

  // ============================================================
  // GET AVAILABLE RIDES
  //
  // Backend:
  // GET /rides/available
  // ============================================================

  static Future<List<Ride>>
      getAvailableRides() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/rides/available',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load available rides',
      );
    }

    if (data is! List) {
      throw Exception(
        'Invalid available rides response',
      );
    }

    return data
        .map<Ride>(
          (item) => Ride.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  // ============================================================
  // ACCEPT RIDE
  //
  // Backend:
  // PATCH /rides/{ride_id}/accept
  // ============================================================

  static Future<Ride>
      acceptRide({
    required int rideId,
  }) async {
    final headers =
        await _authHeaders();

    final response =
        await http.patch(
      Uri.parse(
        '$baseUrl/rides/$rideId/accept',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to accept ride',
      );
    }

    return Ride.fromJson(
      data,
    );
  }

  // ============================================================
  // UPDATE RIDE STATUS
  //
  // Backend:
  // PATCH /rides/{ride_id}/status
  //
  // Examples:
  // accepted
  // driver_arriving
  // driver_arrived
  // in_progress
  // completed
  // cancelled
  // ============================================================

  static Future<Ride>
      updateRideStatus({
    required int rideId,
    required String status,
  }) async {
    final headers =
        await _jsonAuthHeaders();

    final response =
        await http.patch(
      Uri.parse(
        '$baseUrl/rides/$rideId/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
      }),
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to update ride status',
      );
    }

    return Ride.fromJson(
      data,
    );
  }

  // ============================================================
  // GET DRIVER CURRENT ACTIVE RIDE
  //
  // Backend:
  // GET /rides/driver/current
  //
  // Returns null when no active ride exists.
  // ============================================================

  static Future<Ride?>
      getDriverCurrentRide() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/rides/driver/current',
      ),
      headers: headers,
    );

    if (response.statusCode == 404) {
      return null;
    }

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load active ride',
      );
    }

    return Ride.fromJson(
      data,
    );
  }

  // ============================================================
  // GET DRIVER RIDE HISTORY
  //
  // Backend:
  // GET /rides/driver/history
  // ============================================================

  static Future<List<Ride>>
      getDriverRideHistory() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/rides/driver/history',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load ride history',
      );
    }

    if (data is! List) {
      throw Exception(
        'Invalid ride history response',
      );
    }

    return data
        .map<Ride>(
          (item) => Ride.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  // ============================================================
  // GET PASSENGER CURRENT RIDE
  // ============================================================

  static Future<Ride?>
      getCurrentRide() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/rides/current',
      ),
      headers: headers,
    );

    if (response.statusCode == 404) {
      return null;
    }

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load current ride',
      );
    }

    return Ride.fromJson(
      data,
    );
  }

  // ============================================================
  // GET PASSENGER RIDE HISTORY
  // ============================================================

  static Future<List<Ride>>
      getMyRides() async {
    final headers =
        await _authHeaders();

    final response =
        await http.get(
      Uri.parse(
        '$baseUrl/rides/my-rides',
      ),
      headers: headers,
    );

    final data =
        _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        data['detail'] ??
            'Failed to load rides',
      );
    }

    if (data is! List) {
      throw Exception(
        'Invalid rides response',
      );
    }

    return data
        .map<Ride>(
          (item) => Ride.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  // ============================================================
  // CANCEL RIDE
  // ============================================================

  static Future<Ride>
      cancelRide({
    required int rideId,
  }) async {
    return updateRideStatus(
      rideId: rideId,
      status: 'cancelled',
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    await AuthService.logout();
  }

  // ============================================================
  // RESPONSE DECODER
  // ============================================================

  static dynamic _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return decoded;
    } catch (_) {
      throw Exception(
        'Invalid response from server',
      );
    }
  }
}