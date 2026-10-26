import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Physical Android phone: use the Fedora/PC LAN IP.
  // Android emulator: http://10.0.2.2:8000
  static const String baseUrl = 'http://192.168.2.104:8000';

  static Future<void> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw Exception(data['detail'] ?? 'Login failed');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['access_token']);
  }

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> profile() async {
    final r = await http.get(Uri.parse('$baseUrl/drivers/profile'), headers: await _headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Failed to load profile');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> status(bool online) async {
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final r = await http.patch(
      Uri.parse('$baseUrl/drivers/status'),
      headers: headers,
      body: jsonEncode({'is_online': online}),
    );
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Failed to update status');
    return Map<String, dynamic>.from(data);
  }

  static dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return {};
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid response from server');
    }
  }
}
