import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailValidatorService {
  static const String _apiKey = '3f8200dd7e754d0d939518fb70fe02cf'; // Your ZeroBounce key
  static const String _baseUrl = 'https://api.zerobounce.net/v2/validate';

  static Future<Map<String, dynamic>> validateEmail(String email) async {
    print('🔍 Validating email: $email');
    
    try {
      final url = Uri.parse('$_baseUrl?api_key=$_apiKey&email=$email');
      print('🌐 API URL: $url');
      
      final response = await http.get(url);
      print('📡 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📋 Full data: $data');
        
        // ZeroBounce format
        String status = data['status']?.toString() ?? '';
        
        return {
          'isValid': status.toLowerCase() == 'valid',
          'message': _getValidationMessage(status),
        };
      } else {
        return {
          'isValid': false,
          'message': 'API Error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error: $e');
      return {
        'isValid': false,
        'message': 'Network error: $e',
      };
    }
  }

  static String _getValidationMessage(String status) {
    switch (status.toLowerCase()) {
      case 'valid':
        return 'Valid email address';
      case 'invalid':
        return 'Email address does not exist';
      case 'catch-all':
        return 'Email might be valid (catch-all domain)';
      case 'spamtrap':
        return 'Email is a spam trap';
      case 'abuse':
        return 'Email is associated with abuse';
      case 'do_not_mail':
        return 'Email should not be mailed to';
      default:
        return 'Unable to verify email';
    }
  }
}