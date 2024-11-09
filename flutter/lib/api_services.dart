import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://127.0.0.1:5003'; // Make sure this is correct

  // Register method
  Future<Map<String, dynamic>> register(
      String username, String password) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Successful registration
      return {
        'success': true,
        'message': 'Registration successful',
        'serial_id': data['serial_id']
      };
    } else {
      // Failed registration
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Registration failed'
      };
    }
  }

  // Login method (already defined)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return {
        'success': true,
        'token': responseData['token'],
        'message': 'Login successful',
        'serial_id': responseData['serial_id']
      };
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Login failed'
      };
    }
  }
}
