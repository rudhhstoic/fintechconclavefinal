import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailValidatorService {
  // Using AbstractAPI - 100 free requests per month
  static const String _apiKey = '3f8200dd7e754d0d939518fb70fe02cf'; // We'll get this in next step
  static const String _baseUrl = 'https://emailvalidation.abstractapi.com/v1/';

  static Future<Map<String, dynamic>> validateEmail(String email) async {
    try {
      final url = Uri.parse('$_baseUrl?api_key=$_apiKey&email=$email');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'isValid': data['deliverability'] == 'DELIVERABLE',
          'isDisposable': data['is_disposable_email']['value'] ?? false,
          'message': _getValidationMessage(data),
        };
      } else {
        return {
          'isValid': false,
          'isDisposable': false,
          'message': 'Unable to validate email',
        };
      }
    } catch (e) {
      return {
        'isValid': false,
        'isDisposable': false,
        'message': 'Error validating email',
      };
    }
  }

  static String _getValidationMessage(Map<String, dynamic> data) {
    String deliverability = data['deliverability'] ?? '';
    bool isDisposable = data['is_disposable_email']['value'] ?? false;

    if (deliverability == 'DELIVERABLE') {
      return isDisposable ? 'Disposable email not allowed' : 'Valid email';
    } else if (deliverability == 'UNDELIVERABLE') {
      return 'Email address does not exist';
    } else {
      return 'Unable to verify email';
    }
  }
}