import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  // User authentication status
  bool _isAuthenticated = false;
  int? _serialId;

  int? get serialId => _serialId;

  bool get isAuthenticated => _isAuthenticated;

  void setSerialId(int serialId) {
    _serialId = serialId;
    notifyListeners();
  }

  void login(String token) {
    _isAuthenticated = true;
    // Save token securely
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    // Remove token
    notifyListeners();
  }
}
