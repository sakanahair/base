import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  bool _initialized = false;
  
  AuthService._internal() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    try {
      // Wait for Firebase Auth to be ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Firebase Auth state listener
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _firebaseUser = user;
        _isAuthenticated = user != null;
        _userEmail = user?.email;
        _initialized = true;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  User? _firebaseUser;
  bool _isAuthenticated = false;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  User? get currentUser => _firebaseUser;
  bool get initialized => _initialized;

  Future<bool> login(String email, String password) async {
    try {
      // Wait for initialization if needed
      if (!_initialized) {
        await Future.delayed(const Duration(seconds: 1));
      }
      
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = credential.user;
      _isAuthenticated = true;
      _userEmail = credential.user?.email;
      notifyListeners();
      
      debugPrint('Firebase login successful: $_userEmail');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Firebase login error: $e');
      return false;
    }
  }

  Future<bool> loginWithProvider(String provider) async {
    // TODO: Implement social login
    return false;
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _firebaseUser = null;
      _isAuthenticated = false;
      _userEmail = null;
      notifyListeners();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}