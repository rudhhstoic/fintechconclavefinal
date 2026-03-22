// tax_planner_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'tax_planner_model.dart';

enum TaxPlannerStatus { idle, loading, success, error }

class TaxPlannerProvider extends ChangeNotifier {
  static const String _baseUrl = 'http://10.209.192.42:5000';

  TaxPlannerStatus _status = TaxPlannerStatus.idle;
  TaxResultModel? _result;
  String _errorMessage = '';

  TaxPlannerStatus get status => _status;
  TaxResultModel? get result => _result;
  String get errorMessage => _errorMessage;
  bool get isLoading => _status == TaxPlannerStatus.loading;
  bool get hasResult => _status == TaxPlannerStatus.success && _result != null;
  bool get hasError => _status == TaxPlannerStatus.error;

  Future<void> calculate(TaxInputModel input) async {
    _status = TaxPlannerStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculate_tax'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(input.toJson()),
      );
      if (response.statusCode == 200) {
        _result = TaxResultModel.fromJson(json.decode(response.body));
        _status = TaxPlannerStatus.success;
      } else {
        final body = json.decode(response.body);
        _errorMessage = body['error'] ?? 'Server error ${response.statusCode}';
        _status = TaxPlannerStatus.error;
      }
    } catch (e) {
      _errorMessage = 'Could not reach server. Check your connection.';
      _status = TaxPlannerStatus.error;
    }
    notifyListeners();
  }

  void reset() {
    _status = TaxPlannerStatus.idle;
    _result = null;
    _errorMessage = '';
    notifyListeners();
  }
}