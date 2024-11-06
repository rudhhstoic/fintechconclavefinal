import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  // User authentication status
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

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
