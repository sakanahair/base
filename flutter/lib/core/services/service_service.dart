import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import 'simplified_auth_service.dart';
import 'hybrid_cache_service.dart';

class ServiceService extends HybridCacheService<ServiceModel> {
  static ServiceService? _instance;
  final SimplifiedAuthService _authService;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  
  ServiceService._internal(this._authService) : super();
  
  factory ServiceService(SimplifiedAuthService authService) {
    _instance ??= ServiceService._internal(authService);
    return _instance!;
  }

  @override
  String get collectionName => 'services';
  
  @override
  String get localStorageKey => 'sakana_services';
  
  // 業種別のサービスリスト
  List<ServiceModel> _services = [];
  String _currentIndustry = 'beauty'; // デフォルトは美容室
  
  List<ServiceModel> get services => _services
      .where((s) => s.industry == _currentIndustry)
      .toList()
    ..sort((a, b) => a.category.compareTo(b.category));
  
  // カテゴリー別にグループ化
  Map<String, List<ServiceModel>> get servicesByCategory {
    final Map<String, List<ServiceModel>> grouped = {};
    for (final service in services) {
      grouped.putIfAbsent(service.category, () => []).add(service);
    }
    return grouped;
  }
  
  // 業種を切り替え
  void setIndustry(String industry) {
    _currentIndustry = industry;
    notifyListeners();
  }
  
  String get currentIndustry => _currentIndustry;

  @override
  ServiceModel fromJson(Map<String, dynamic> json) {
    return ServiceModel.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ServiceModel item) {
    return item.toJson();
  }

  @override
  ServiceModel fromFirestore(String id, Map<String, dynamic> data) {
    return ServiceModel.fromJson({...data, 'id': id});
  }

  @override
  Map<String, dynamic> toFirestore(ServiceModel item) {
    return item.toFirestore();
  }

  @override
  String getId(ServiceModel item) => item.id;
  
  @override
  String getItemId(ServiceModel item) => item.id;

  // 初期化（Firebase優先）
  Future<void> initialize() async {
    if (_authService.currentUser != null) {
      // Firebaseが真実の源 - まずFirebaseから読み込み
      await loadFromFirebase();
      // リアルタイム同期を開始
      _startRealtimeSync();
    } else {
      // 認証されていない場合のみLocalStorageから読み込み（オフライン用）
      await loadFromLocalStorage();
    }
  }

  // LocalStorageから読み込み
  Future<void> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(localStorageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        _services = jsonList.map((json) => ServiceModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading services from LocalStorage: $e');
    }
  }

  // LocalStorageに保存
  Future<void> saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _services.map((service) => service.toJson()).toList();
      await prefs.setString(localStorageKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving services to LocalStorage: $e');
    }
  }

  // Firebaseから読み込み（真実の源）
  Future<void> loadFromFirebase() async {
    if (_authService.currentUser == null) return;
    
    try {
      final tenantId = _authService.currentUser!.uid;
      print('Loading services from Firebase for tenant: $tenantId');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection(collectionName)
          .get();
      
      print('Found ${snapshot.docs.length} services in Firebase');
      
      final firebaseServices = snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
      
      // Firebaseのデータで上書き（Firebaseが真実の源）
      _services = firebaseServices;
      
      print('Services loaded from Firebase: ${_services.length}');
      for (final service in _services) {
        print('  - ${service.id}: ${service.name}');
      }
      
      // LocalStorageにキャッシュとして保存
      await saveToLocalStorage();
      notifyListeners();
    } catch (e) {
      print('Error loading from Firebase: $e');
      // Firebaseから読み込めない場合はLocalStorageを使用
      await loadFromLocalStorage();
    }
  }
  
  // リアルタイム同期を開始
  void _startRealtimeSync() {
    if (_authService.currentUser == null) return;
    
    // 既存のリスナーがあれば停止
    _firestoreSubscription?.cancel();
    
    final tenantId = _authService.currentUser!.uid;
    
    // 新しいリスナーを設定
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('tenants')
        .doc(tenantId)
        .collection(collectionName)
        .snapshots()
        .listen((snapshot) {
      print('Firebase realtime update received: ${snapshot.docChanges.length} changes');
      
      // 変更を適用
      for (final change in snapshot.docChanges) {
        final service = ServiceModel.fromFirestore(change.doc);
        
        switch (change.type) {
          case DocumentChangeType.added:
            // 新規追加（既存でない場合のみ）
            if (!_services.any((s) => s.id == service.id)) {
              _services.add(service);
              print('Service added from Firebase: ${service.id}');
            }
            break;
          case DocumentChangeType.modified:
            // 更新
            final index = _services.indexWhere((s) => s.id == service.id);
            if (index != -1) {
              _services[index] = service;
              print('Service updated from Firebase: ${service.id}');
            }
            break;
          case DocumentChangeType.removed:
            // 削除
            _services.removeWhere((s) => s.id == service.id);
            print('Service removed from Firebase: ${service.id}');
            break;
        }
      }
      
      // LocalStorageを更新
      saveToLocalStorage();
      notifyListeners();
    }, onError: (error) {
      print('Realtime sync error: $error');
    });
  }

  // この関数は削除（LocalStorage → Firebaseの同期は不要）
  // Firebaseが真実の源なので、一方向のみ

  // サービスを追加（Firebase優先）
  Future<ServiceModel> addService({
    required String name,
    required String category,
    required double price,
    required int duration,
    String description = '',
    List<String> options = const [],
    List<String> images = const [],
    required String industry,
  }) async {
    final now = DateTime.now();
    final service = ServiceModel(
      id: 'service_${now.millisecondsSinceEpoch}',
      name: name,
      category: category,
      price: price,
      duration: duration,
      description: description,
      options: options,
      images: images,
      industry: industry,
      createdAt: now,
      updatedAt: now,
    );
    
    // まずFirebaseに保存
    if (_authService.currentUser != null) {
      try {
        await _saveToFirebase(service);
        // リアルタイムリスナーが自動的に追加するので、ここでは追加しない
        // ただし、オフライン時の即座の表示のため、存在しない場合のみ追加
        if (!_services.any((s) => s.id == service.id)) {
          _services.add(service);
          await saveToLocalStorage();
          notifyListeners();
        }
      } catch (e) {
        print('Error adding service to Firebase: $e');
        throw e; // エラーを上位に伝播
      }
    } else {
      // オフラインの場合のみローカルに保存
      _services.add(service);
      await saveToLocalStorage();
      notifyListeners();
    }
    
    return service;
  }

  // サービスを更新（Firebase優先）
  Future<void> updateService(ServiceModel service) async {
    final updatedService = service.copyWith(
      updatedAt: DateTime.now(),
    );
    
    print('Updating service: ${service.id}');
    print('Updated service images: ${updatedService.images}');
    
    // まずFirebaseに保存
    if (_authService.currentUser != null) {
      try {
        await _saveToFirebase(updatedService);
        // リアルタイムリスナーが自動的に更新を反映する
        // ただし、即座の反映のため、ローカルも更新
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = updatedService;
          await saveToLocalStorage();
          notifyListeners();
        }
      } catch (e) {
        print('Error updating service in Firebase: $e');
        throw e; // エラーを上位に伝播
      }
    } else {
      // オフラインの場合のみローカルに保存
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = updatedService;
        await saveToLocalStorage();
        notifyListeners();
      }
    }
  }

  // サービスを削除（Firebase優先）
  Future<void> deleteService(String serviceId) async {
    print('ServiceService.deleteService called with ID: $serviceId');
    
    // 削除前にサービス情報を取得
    final serviceToDelete = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse: () => ServiceModel(
        id: serviceId,
        name: '',
        category: '',
        price: 0,
        duration: 0,
        description: '',
        industry: '',
        options: [],
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    print('Service to delete: ${serviceToDelete.name}, Images: ${serviceToDelete.images.length}');
    
    // まずFirebaseから削除
    if (_authService.currentUser != null) {
      try {
        await _deleteFromFirebase(serviceId);
        // Firebaseからの削除が成功したらローカルから削除
        final beforeCount = _services.length;
        _services.removeWhere((s) => s.id == serviceId);
        final afterCount = _services.length;
        print('Services count: $beforeCount -> $afterCount');
        
        await saveToLocalStorage();
        notifyListeners();
      } catch (e) {
        print('Error deleting service from Firebase: $e');
        throw e; // エラーを上位に伝播
      }
    } else {
      // オフラインの場合のみローカルから削除
      final beforeCount = _services.length;
      _services.removeWhere((s) => s.id == serviceId);
      final afterCount = _services.length;
      print('Services count: $beforeCount -> $afterCount');
      
      await saveToLocalStorage();
      notifyListeners();
    }
  }

  // Firebaseに保存（非同期）
  Future<void> _saveToFirebase(ServiceModel service) async {
    if (_authService.currentUser == null) return;
    
    try {
      final tenantId = _authService.currentUser!.uid;
      print('Saving service to Firebase: ${service.id}');
      print('Service images: ${service.images}');
      
      await FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection(collectionName)
          .doc(service.id)
          .set(service.toFirestore());
      
      print('Service saved to Firebase successfully');
    } catch (e) {
      print('Error saving service to Firebase: $e');
    }
  }

  // Firebaseから削除（非同期）
  Future<void> _deleteFromFirebase(String serviceId) async {
    if (_authService.currentUser == null) {
      print('Cannot delete from Firebase: No authenticated user');
      return;
    }
    
    try {
      final tenantId = _authService.currentUser!.uid;
      print('Deleting service from Firebase: serviceId=$serviceId, tenantId=$tenantId');
      
      final docRef = FirebaseFirestore.instance
          .collection('tenants')
          .doc(tenantId)
          .collection(collectionName)
          .doc(serviceId);
      
      // ドキュメントが存在するか確認
      final doc = await docRef.get();
      if (doc.exists) {
        print('Document exists in Firebase, deleting...');
        await docRef.delete();
        print('Service deleted from Firebase successfully: $serviceId');
      } else {
        print('Document does not exist in Firebase: $serviceId');
      }
    } catch (e) {
      print('Error deleting service from Firebase: $e');
      rethrow; // エラーを再スローして呼び出し元に伝える
    }
  }

  // サービスを検索
  List<ServiceModel> searchServices(String query) {
    if (query.isEmpty) return services;
    
    final lowerQuery = query.toLowerCase();
    return services.where((service) {
      return service.name.toLowerCase().contains(lowerQuery) ||
             service.description.toLowerCase().contains(lowerQuery) ||
             service.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // カテゴリーでフィルター
  List<ServiceModel> filterByCategory(String category) {
    if (category == 'all') return services;
    return services.where((s) => s.category == category).toList();
  }

  // 価格範囲でフィルター
  List<ServiceModel> filterByPriceRange(double minPrice, double maxPrice) {
    return services.where((s) => s.price >= minPrice && s.price <= maxPrice).toList();
  }

  // サービスIDで取得
  ServiceModel? getServiceById(String id) {
    try {
      return _services.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // リソースをクリーンアップ
  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}