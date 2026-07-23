import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Flutter Web / Edge
  static const String baseUrl =
      "http://localhost:8000";

  // Android Emulator:
  // static const String baseUrl =
  //     "http://10.0.2.2:8000";

  // Physical Android phone:
  // static const String baseUrl =
  //     "http://192.168.2.104:8000";

  static const String _tokenKey =
      "driver_access_token";

  // ============================================================
  // DRIVER LOGIN
  // ============================================================

  static Future<void> loginDriver({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        "$baseUrl/auth/login",
      ),
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
      throw Exception(
        _getErrorMessage(response),
      );
    }

    final data =
        jsonDecode(response.body);

    final accessToken =
        data["access_token"];

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

    await prefs.remove(
      _tokenKey,
    );
  }

  // ============================================================
  // CHECK LOGIN
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token =
        prefs.getString(
      _tokenKey,
    );

    return token != null &&
        token.isNotEmpty;
  }

  // ============================================================
  // GET TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      _tokenKey,
    );
  }

  // ============================================================
  // AUTH HEADERS
  // ============================================================

  static Future<Map<String, String>>
      authHeaders() async {
    final token =
        await getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        "You are not logged in.",
      );
    }

    return {
      "Content-Type":
          "application/json",
      "Authorization":
          "Bearer $token",
    };
  }

  // ============================================================
  // SET DRIVER ONLINE / OFFLINE
  // ============================================================

  static Future<bool>
      updateDriverOnlineStatus({
    required bool isOnline,
  }) async {
    final headers =
        await authHeaders();

    final response =
        await http.patch(
      Uri.parse(
        "$baseUrl/drivers/status",
      ),
      headers: headers,
      body: jsonEncode({
        "is_online": isOnline,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    final data =
        jsonDecode(response.body);

    return data["is_online"] == true;
  }

  // ============================================================
  // GET DRIVER STATUS
  // ============================================================

  static Future<bool>
      getDriverOnlineStatus() async {
    final headers =
        await authHeaders();

    final response =
        await http.get(
      Uri.parse(
        "$baseUrl/drivers/status",
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    final data =
        jsonDecode(response.body);

    return data["is_online"] == true;
  }

  // ============================================================
  // GET AVAILABLE RIDES
  // ============================================================

  static Future<List<dynamic>>
      getAvailableRides() async {
    final headers =
        await authHeaders();

    final response =
        await http.get(
      Uri.parse(
        "$baseUrl/rides/available",
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    final data =
        jsonDecode(
      response.body,
    );

    return data as List<dynamic>;
  }

  // ============================================================
  // ACCEPT RIDE
  // ============================================================

  static Future<Map<String, dynamic>>
      acceptRide({
    required int rideId,
  }) async {
    final headers =
        await authHeaders();

    final response =
        await http.patch(
      Uri.parse(
        "$baseUrl/rides/$rideId/accept",
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(
      response.body,
    ) as Map<String, dynamic>;
  }

  // ============================================================
  // UPDATE RIDE STATUS
  // ============================================================

  static Future<Map<String, dynamic>>
      updateRideStatus({
    required int rideId,
    required String status,
  }) async {
    final headers =
        await authHeaders();

    final response =
        await http.patch(
      Uri.parse(
        "$baseUrl/rides/$rideId/status",
      ),
      headers: headers,
      body: jsonEncode({
        "status": status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    return jsonDecode(
      response.body,
    ) as Map<String, dynamic>;
  }

  // ============================================================
  // DRIVER RIDE HISTORY
  // ============================================================

  static Future<List<dynamic>>
      getDriverHistory() async {
    final headers =
        await authHeaders();

    final response =
        await http.get(
      Uri.parse(
        "$baseUrl/rides/driver/history",
      ),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _getErrorMessage(response),
      );
    }

    final data =
        jsonDecode(
      response.body,
    );

    return data as List<dynamic>;
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  static String _getErrorMessage(
    http.Response response,
  ) {
    try {
      final data =
          jsonDecode(
        response.body,
      );

      if (data["detail"] != null) {
        return data["detail"]
            .toString();
      }

      return "Request failed with status ${response.statusCode}";
    } catch (_) {
      return "Request failed with status ${response.statusCode}";
    }
  }
}