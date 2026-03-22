import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class SetuService {
  static const String baseUrl = "http://10.209.192.42:5000";

  // --- Account Aggregator Methods ---

  Future<Map<String, dynamic>> initiateConsent(String userId, String mobileNumber) async {
    final url = Uri.parse("$baseUrl/api/aa/initiate");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "mobile_number": mobileNumber,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        developer.log("InitiateConsent failed: ${response.statusCode} - ${response.body}");
        return {};
      }
    } catch (e) {
      developer.log("Error in initiateConsent: $e");
      return {};
    }
  }

  Future<String> checkStatus(String consentHandle) async {
    final url = Uri.parse("$baseUrl/api/aa/status/$consentHandle");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['consent_status'] ?? "PENDING";
      }
      return "PENDING";
    } catch (e) {
      developer.log("Error in checkStatus: $e");
      return "ERROR";
    }
  }

  Future<Map<String, dynamic>> fetchTransactions(String userId, String consentHandle) async {
    final url = Uri.parse("$baseUrl/api/aa/fetch");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "consent_handle": consentHandle,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      developer.log("Error in fetchTransactions: $e");
      return {};
    }
  }

  // --- FinSense Methods ---

  Future<List<dynamic>> getWarnings(String userId) async {
    final url = Uri.parse("$baseUrl/api/finsense/warnings/$userId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['warnings'] ?? [];
      }
      return [];
    } catch (e) {
      developer.log("Error in getWarnings: $e");
      return [];
    }
  }

  Future<List<dynamic>> getReminders(String userId) async {
    final url = Uri.parse("$baseUrl/api/finsense/reminders/$userId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reminders'] ?? [];
      }
      return [];
    } catch (e) {
      developer.log("Error in getReminders: $e");
      return [];
    }
  }

  Future<bool> saveReminder(String userId, Map<String, dynamic> reminder) async {
    final url = Uri.parse("$baseUrl/api/finsense/reminders/$userId");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reminder),
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log("Error in saveReminder: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> getReport(String userId) async {
    final url = Uri.parse("$baseUrl/api/finsense/report/$userId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      developer.log("Error in getReport: $e");
      return {};
    }
  }

  Future<String> chat(String userId, String message, List<Map<String, String>> history) async {
    final url = Uri.parse("$baseUrl/api/finsense/chat");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "message": message,
          "history": history,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? "I'm sorry, I couldn't process that.";
      }
      return "Error: Could not reach the AI server.";
    } catch (e) {
      developer.log("Error in chat: $e");
      return "Network error: Please check your connection.";
    }
  }
}
