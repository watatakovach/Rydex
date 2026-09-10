import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Flutter Web / Edge
  static const String baseUrl = "http://localhost:8000";

  // Android Emulator:
  // static const String baseUrl = "http://10.0.2.2:8000";

  // Physical Android phone:
  // static const String baseUrl = "http://192.168.2.104:8000";

  static const String _tokenKey = "access_token";

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "full_name": name,
        "email": email,
        "phone_number": phone,
        "password": password,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(_getErrorMessage(response));
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type":
            "application/x-www-form-urlencoded",
      },
      body: {
        "username": email,
        "password": password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }

    final data = jsonDecode(response.body);

    final accessToken = data["access_token"];

    if (accessToken == null ||
        accessToken.toString().isEmpty) {
      throw Exception(
        "Login succeeded but no access token was returned.",
      );
    }

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      accessToken.toString(),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);

    // Verify token was removed
    final remainingToken =
        prefs.getString(_tokenKey);

    if (remainingToken != null) {
      throw Exception(
        "Logout failed. Token could not be removed.",
      );
    }
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(_tokenKey);

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>>
      authHeaders() async {
    final token = await getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        "You are not logged in.",
      );
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ============================================================
  // REQUEST RIDE
  // ============================================================

  static Future<Map<String, dynamic>>
      requestRide({
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final headers =
        await authHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/request"),
      headers: headers,
      body: jsonEncode({
        "pickup_latitude":
            pickupLatitude,
        "pickup_longitude":
            pickupLongitude,
        "destination_latitude":
            destinationLatitude,
        "destination_longitude":
            destinationLongitude,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(response.body)
        as Map<String, dynamic>;
  }

  // ============================================================
  // GET CURRENT RIDE
  // ============================================================

  static Future<Map<String, dynamic>>
      getCurrentRide() async {
    final headers =
        await authHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl/rides/current"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(response.body)
        as Map<String, dynamic>;
  }

  // ============================================================
// CANCEL CURRENT RIDE
// ============================================================

static Future<Map<String, dynamic>> cancelRide(
  int rideId,
) async {
  final headers = await authHeaders();

  final response = await http.patch(
    Uri.parse("$baseUrl/rides/$rideId/status"),
    headers: headers,
    body: jsonEncode({
      "status": "cancelled",
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      _getErrorMessage(response),
    );
  }

  return jsonDecode(response.body)
      as Map<String, dynamic>;
}

  // ============================================================
  // GET MY RIDES
  // ============================================================

  static Future<List<dynamic>>
      getMyRides() async {
    final headers =
        await authHeaders();

    final response = await http.get(
      Uri.parse("$baseUrl/rides/my-rides"),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(response.body)
        as List<dynamic>;
  }

  // ============================================================
  // RATE DRIVER
  // ============================================================

  static Future<Map<String, dynamic>>
      rateDriver({
    required int rideId,
    required int rating,
    String? comment,
  }) async {
    final headers =
        await authHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/rides/$rideId/rating"),
      headers: headers,
      body: jsonEncode({
        "rating": rating,
        "comment": comment,
      }),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(response.body)
        as Map<String, dynamic>;
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  static String _getErrorMessage(
    http.Response response,
  ) {
    try {
      final data =
          jsonDecode(response.body);

      if (data["detail"] != null) {
        return data["detail"].toString();
      }

      return "Request failed with status ${response.statusCode}";
    } catch (_) {
      return "Request failed with status ${response.statusCode}";
    }
  }
}
