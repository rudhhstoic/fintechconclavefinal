// tax_planner_service.dart — API service for Tax Planner

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tax_planner_model.dart';

class TaxPlannerService {
  // Change this to your backend IP
  static const String _baseUrl = 'http://10.209.192.42:5000';

  Future<TaxResultModel> calculateTax(TaxInputModel input) async {
    final url = Uri.parse('$_baseUrl/calculate_tax');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(input.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaxResultModel.fromJson(data);
      } else {
        throw TaxApiException(
          'Server returned ${response.statusCode}',
          response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw TaxApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is TaxApiException) rethrow;
      throw TaxApiException('Unexpected error: $e');
    }
  }
}

class TaxApiException implements Exception {
  final String message;
  final int? statusCode;

  TaxApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}
