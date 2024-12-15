import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  // User authentication status
  bool _isAuthenticated = false;
  int? _serialId;
  String? _name;

  int? get serialId => _serialId;
  String? get name => _name;

  bool get isAuthenticated => _isAuthenticated;

  void setSerialId(int serialId, String name) {
    _serialId = serialId;
    _name = name;
    notifyListeners();
  }

  void login(String token) {
    _isAuthenticated = true;
    // Save token securely
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    // Remove tokens
    notifyListeners();
  }
}
