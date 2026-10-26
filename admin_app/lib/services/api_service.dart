import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  static Future<List<dynamic>> pendingDrivers() async {
    final r = await http.get(Uri.parse('$baseUrl/admin/drivers/pending'), headers: await headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Failed to load drivers');
    return List<dynamic>.from(data);
  }

  static Future<void> verifyDriver(int id) async {
    final r = await http.patch(Uri.parse('$baseUrl/admin/drivers/$id/verify'), headers: await headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Verification failed');
  }

  static String imageUrl(String path) => '$baseUrl$path';

  static Future<List<dynamic>> vehicles() async {
    final r = await http.get(Uri.parse('$baseUrl/admin/vehicles'), headers: await headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Failed to load vehicles');
    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> vehicle(int id) async {
    final r = await http.get(Uri.parse('$baseUrl/admin/vehicles/$id'), headers: await headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Failed to load vehicle');
    return Map<String, dynamic>.from(data);
  }

  static Future<void> uploadVehicleImages(int vehicleId, List<XFile> images) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/admin/vehicles/$vehicleId/images'))
      ..headers.addAll(await headers());
    for (final img in images) {
      req.files.add(http.MultipartFile.fromBytes('files', await img.readAsBytes(), filename: img.name));
    }
    final r = await http.Response.fromStream(await req.send());
    final data = _decode(r);
    if (r.statusCode != 201) throw Exception(data['detail'] ?? 'Upload failed');
  }

  static Future<void> deleteVehicleImage(int vehicleId, int imageId) async {
    final r = await http.delete(Uri.parse('$baseUrl/admin/vehicles/$vehicleId/images/$imageId'), headers: await headers());
    final data = _decode(r);
    if (r.statusCode != 200) throw Exception(data['detail'] ?? 'Delete failed');
  }

  static dynamic _decode(http.Response r) {
    if (r.body.isEmpty) return {};
    try { return jsonDecode(r.body); }
    catch (_) { throw Exception('Invalid server response'); }
  }
}
