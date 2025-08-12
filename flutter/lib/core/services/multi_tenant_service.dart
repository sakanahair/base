import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/site_model.dart';

class MultiTenantService extends ChangeNotifier {
  static final MultiTenantService _instance = MultiTenantService._internal();
  factory MultiTenantService() => _instance;
  MultiTenantService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _currentUser;
  SiteModel? _currentSite;
  List<SiteModel> _managedSites = [];

  UserModel? get currentUser => _currentUser;
  SiteModel? get currentSite => _currentSite;
  List<SiteModel> get managedSites => _managedSites;

  bool get isSuperAdmin => _currentUser?.role == UserRole.superAdmin;
  bool get isSiteAdmin => _currentUser?.role == UserRole.siteAdmin;
  bool get isEndUser => _currentUser?.role == UserRole.endUser;

  Future<void> initializeUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      _currentUser = null;
      _currentSite = null;
      _managedSites = [];
      notifyListeners();
      return;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        
        if (_currentUser!.role == UserRole.superAdmin) {
          await _loadAllSites();
        } else if (_currentUser!.siteId != null) {
          await _loadUserSite(_currentUser!.siteId!);
        }

        await _updateLastLogin();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  Future<void> _loadUserSite(String siteId) async {
    try {
      final siteDoc = await _firestore
          .collection('sites')
          .doc(siteId)
          .get();

      if (siteDoc.exists) {
        _currentSite = SiteModel.fromFirestore(siteDoc);
        
        if (_currentUser!.role == UserRole.siteAdmin) {
          _managedSites = [_currentSite!];
        }
      }
    } catch (e) {
      debugPrint('Error loading site: $e');
    }
  }

  Future<void> _loadAllSites() async {
    try {
      final sitesQuery = await _firestore
          .collection('sites')
          .orderBy('createdAt', descending: true)
          .get();

      _managedSites = sitesQuery.docs
          .map((doc) => SiteModel.fromFirestore(doc))
          .toList();

      if (_managedSites.isNotEmpty) {
        _currentSite = _managedSites.first;
      }
    } catch (e) {
      debugPrint('Error loading sites: $e');
    }
  }

  Future<void> switchSite(String siteId) async {
    if (!isSuperAdmin && !isSiteAdmin) return;

    try {
      final siteDoc = await _firestore
          .collection('sites')
          .doc(siteId)
          .get();

      if (siteDoc.exists) {
        _currentSite = SiteModel.fromFirestore(siteDoc);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error switching site: $e');
    }
  }

  Future<SiteModel?> createSite({
    required String name,
    required String domain,
    String? subdomain,
    required String ownerId,
  }) async {
    if (!isSuperAdmin) return null;

    try {
      final siteData = {
        'name': name,
        'domain': domain,
        'subdomain': subdomain,
        'ownerId': ownerId,
        'status': SiteStatus.trial.value,
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'allowRegistration': true,
          'requireEmailVerification': true,
          'maxUsers': 100,
        },
        'adminIds': [ownerId],
        'currentUserCount': 0,
      };

      final docRef = await _firestore.collection('sites').add(siteData);
      final newSite = await docRef.get();
      
      final siteModel = SiteModel.fromFirestore(newSite);
      _managedSites.add(siteModel);
      notifyListeners();
      
      return siteModel;
    } catch (e) {
      debugPrint('Error creating site: $e');
      return null;
    }
  }

  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? siteId,
  }) async {
    if (!isSuperAdmin && !isSiteAdmin) return null;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'email': email,
        'name': name,
        'role': role.value,
        'siteId': siteId ?? _currentSite?.id,
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

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getSiteUsers(String siteId) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('siteId', isEqualTo: siteId)
          .orderBy('createdAt', descending: true)
          .get();

      return usersQuery.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting site users: $e');
      return [];
    }
  }

  Future<void> updateSiteSettings(String siteId, Map<String, dynamic> settings) async {
    if (!isSuperAdmin && !isSiteAdmin) return;

    try {
      await _firestore
          .collection('sites')
          .doc(siteId)
          .update({'settings': settings});

      if (_currentSite?.id == siteId) {
        _currentSite = _currentSite!.copyWith(settings: settings);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating site settings: $e');
    }
  }

  Future<void> _updateLastLogin() async {
    if (_currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;

    switch (_currentUser!.role) {
      case UserRole.superAdmin:
        return true;
      case UserRole.siteAdmin:
        return _siteAdminPermissions.contains(permission);
      case UserRole.endUser:
        return _endUserPermissions.contains(permission);
    }
  }

  static const List<String> _siteAdminPermissions = [
    'manage_site_users',
    'manage_site_content',
    'view_site_analytics',
    'manage_site_settings',
  ];

  static const List<String> _endUserPermissions = [
    'view_own_content',
    'edit_own_profile',
  ];

  void clear() {
    _currentUser = null;
    _currentSite = null;
    _managedSites = [];
    notifyListeners();
  }
}