import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimplifiedAuthService extends ChangeNotifier {
  static final SimplifiedAuthService _instance = SimplifiedAuthService._internal();
  factory SimplifiedAuthService() => _instance;
  
  SimplifiedAuthService._internal() {
    _initializeAuth();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  User? _firebaseUser;
  bool _isAdmin = false;

  bool get initialized => _initialized;
  bool get isAuthenticated => _firebaseUser != null;
  User? get firebaseUser => _firebaseUser;
  User? get currentUser => _firebaseUser; // ServiceServiceで使用
  bool get isAdmin => _isAdmin;

  Future<void> _initializeAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _auth.authStateChanges().listen((User? user) async {
        _firebaseUser = user;
        
        if (user != null) {
          // 管理者判定（メールアドレスベース）
          _isAdmin = user.email == 'admin@sakana.hair';
          
          // ユーザードキュメントを作成/更新
          try {
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'name': _isAdmin ? 'Super Admin' : 'User',
              'role': _isAdmin ? 'super_admin' : 'end_user',
              'lastLogin': FieldValue.serverTimestamp(),
              'isActive': true,
            }, SetOptions(merge: true));
            
            debugPrint('User document created/updated for: ${user.email}');
          } catch (e) {
            debugPrint('Error creating user document: $e');
            // Firestoreエラーは無視（権限がなくても認証は成功）
          }
        } else {
          _isAdmin = false;
        }
        
        _initialized = true;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      if (!_initialized) {
        await Future.delayed(const Duration(seconds: 1));
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        _firebaseUser = credential.user;
        _isAdmin = email == 'admin@sakana.hair';
        
        // ユーザードキュメントを作成/更新
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'email': email,
            'name': _isAdmin ? 'Super Admin' : 'User',
            'role': _isAdmin ? 'super_admin' : 'end_user',
            'lastLogin': FieldValue.serverTimestamp(),
            'isActive': true,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore error (ignored): $e');
        }
        
        notifyListeners();
        debugPrint('Login successful: $email');
        return true;
      }
      
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _firebaseUser = null;
      _isAdmin = false;
      notifyListeners();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}