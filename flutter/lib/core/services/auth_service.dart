import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;

  Future<bool> login(String email, String password) async {
    // Check for admin credentials
    if (email == 'admin' && password == 'Pass12345') {
      _isAuthenticated = true;
      _userEmail = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loginWithProvider(String provider) async {
    // Simulate social login
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _userEmail = '$provider@sakana.hair';
    notifyListeners();
    return true;
  }

  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    notifyListeners();
  }
}