import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/site_model.dart';
import 'multi_tenant_service.dart';

class EnhancedAuthService extends ChangeNotifier {
  static final EnhancedAuthService _instance = EnhancedAuthService._internal();
  factory EnhancedAuthService() => _instance;
  
  EnhancedAuthService._internal() {
    _initializeAuth();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MultiTenantService _multiTenantService = MultiTenantService();

  bool _initialized = false;
  User? _firebaseUser;
  UserModel? _currentUser;
  SiteModel? _currentSite;

  bool get initialized => _initialized;
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null;
  User? get firebaseUser => _firebaseUser;
  UserModel? get currentUser => _currentUser;
  SiteModel? get currentSite => _currentSite;
  
  UserRole? get userRole => _currentUser?.role;
  bool get isSuperAdmin => _currentUser?.role == UserRole.superAdmin;
  bool get isSiteAdmin => _currentUser?.role == UserRole.siteAdmin;
  bool get isEndUser => _currentUser?.role == UserRole.endUser;

  Future<void> _initializeAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      _auth.authStateChanges().listen((User? user) async {
        _firebaseUser = user;
        
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          _currentUser = null;
          _currentSite = null;
          _multiTenantService.clear();
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

  Future<void> _loadUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        
        await _multiTenantService.initializeUser();
        _currentSite = _multiTenantService.currentSite;
        
        debugPrint('User loaded: ${_currentUser!.email} with role: ${_currentUser!.role.value}');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<({bool success, String? error, UserModel? user})> login({
    required String email,
    required String password,
    String? siteId,
  }) async {
    try {
      if (!_initialized) {
        await Future.delayed(const Duration(seconds: 1));
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserData(credential.user!.uid);
        
        if (_currentUser != null) {
          if (siteId != null && _currentUser!.siteId != siteId && !isSuperAdmin) {
            await _auth.signOut();
            return (
              success: false,
              error: 'このサイトへのアクセス権限がありません',
              user: null
            );
          }
          
          return (success: true, error: null, user: _currentUser);
        }
      }
      
      return (success: false, error: 'ユーザー情報の取得に失敗しました', user: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'ユーザーが見つかりません';
          break;
        case 'wrong-password':
          errorMessage = 'パスワードが正しくありません';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        case 'user-disabled':
          errorMessage = 'このアカウントは無効化されています';
          break;
        default:
          errorMessage = 'ログインに失敗しました: ${e.message}';
      }
      return (success: false, error: errorMessage, user: null);
    } catch (e) {
      return (success: false, error: 'ログインエラー: $e', user: null);
    }
  }

  Future<({bool success, String? error})> register({
    required String email,
    required String password,
    required String name,
    String? siteId,
    UserRole role = UserRole.endUser,
  }) async {
    try {
      if (siteId == null && role != UserRole.superAdmin) {
        return (success: false, error: 'サイトIDが必要です');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userData = {
          'email': email,
          'name': name,
          'role': role.value,
          'siteId': siteId,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        };

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData);

        if (siteId != null) {
          await _firestore
              .collection('sites')
              .doc(siteId)
              .update({
            'currentUserCount': FieldValue.increment(1),
          });
        }

        await _loadUserData(credential.user!.uid);
        
        return (success: true, error: null);
      }
      
      return (success: false, error: 'ユーザー登録に失敗しました');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'パスワードが弱すぎます';
          break;
        case 'email-already-in-use':
          errorMessage = 'このメールアドレスは既に使用されています';
          break;
        case 'invalid-email':
          errorMessage = 'メールアドレスの形式が正しくありません';
          break;
        default:
          errorMessage = '登録に失敗しました: ${e.message}';
      }
      return (success: false, error: errorMessage);
    } catch (e) {
      return (success: false, error: '登録エラー: $e');
    }
  }

  Future<void> switchSite(String siteId) async {
    if (!isSuperAdmin && !isSiteAdmin) return;
    
    await _multiTenantService.switchSite(siteId);
    _currentSite = _multiTenantService.currentSite;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _firebaseUser = null;
      _currentUser = null;
      _currentSite = null;
      _multiTenantService.clear();
      notifyListeners();
      debugPrint('User logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  bool hasPermission(String permission) {
    return _multiTenantService.hasPermission(permission);
  }

  Future<void> updateProfile({
    String? name,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentUser == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (metadata != null) updates['metadata'] = metadata;

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updates);

      await _loadUserData(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }
}