import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.2.104:8000';

  static Future<void> login(String username, String password) async {
    final r = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Login failed');
    final p = await SharedPreferences.getInstance();
    await p.setString('token', data['access_token']);
  }

  static Future<Map<String, String>> headers() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString('token');
    if (token == null) throw Exception('Not authenticated');
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  static Future<Map<String, dynamic>> requestRide({
    required String pickup,
    required String destination,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/rides'),
      headers: await headers(),
      body: jsonEncode({
        'pickup_address': pickup,
        'destination_address': destination,
      }),
    );
    final data = _decode(r);
    if (r.statusCode != 201) throw Exception(data['detail'] ?? 'Ride request failed');
    return Map<String, dynamic>.from(data);
  }

  static dynamic _decode(http.Response r) {
    if (r.body.isEmpty) return {};
    try { return jsonDecode(r.body); }
    catch (_) { throw Exception('Invalid server response'); }
  }
}
