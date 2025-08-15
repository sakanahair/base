import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/store_info_model.dart';
import 'simplified_auth_service.dart';

class StoreInfoService extends ChangeNotifier {
  final SimplifiedAuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StoreInfoModel? _storeInfo;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _storeInfoSubscription;

  StoreInfoModel? get storeInfo => _storeInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasStoreInfo => _storeInfo != null;

  StoreInfoService({required SimplifiedAuthService authService})
      : _authService = authService {
    _authService.addListener(_onAuthChange);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_authService.currentUser != null) {
      await loadStoreInfo();
    }
  }

  void _onAuthChange() {
    if (_authService.currentUser == null) {
      _clearData();
    } else {
      _initialize();
    }
  }

  void _clearData() {
    _storeInfoSubscription?.cancel();
    _storeInfoSubscription = null;
    _storeInfo = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadStoreInfo() async {
    if (_authService.currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _authService.currentUser!.uid;
      
      // LocalStorageから読み込み（キャッシュ）
      await _loadFromLocalStorage();
      
      // Firebaseから読み込み
      final doc = await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('settings')
          .doc('storeInfo')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['tenantId'] = tenantId;
        _storeInfo = StoreInfoModel.fromJson(data);
      } else {
        // 初期データを作成
        _storeInfo = _createDefaultStoreInfo(tenantId);
        await saveStoreInfo(_storeInfo!);
      }
      
      await _saveToLocalStorage();
      
      // リアルタイム同期を開始
      _startRealtimeSync();
      
    } catch (e) {
      _error = 'データの読み込みに失敗しました: $e';
      print('Error loading store info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeSync() {
    if (_authService.currentUser == null) return;
    
    _storeInfoSubscription?.cancel();
    
    final tenantId = _authService.currentUser!.uid;
    _storeInfoSubscription = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('storeInfo')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        data['tenantId'] = tenantId;
        _storeInfo = StoreInfoModel.fromJson(data);
        _saveToLocalStorage();
        notifyListeners();
      }
    });
  }

  Future<void> saveStoreInfo(StoreInfoModel storeInfo) async {
    if (_authService.currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _authService.currentUser!.uid;
      final updatedInfo = storeInfo.copyWith(
        tenantId: tenantId,
        updatedAt: DateTime.now(),
      );

      // Firebaseに保存
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('settings')
          .doc('storeInfo')
          .set(updatedInfo.toJson());

      _storeInfo = updatedInfo;
      await _saveToLocalStorage();
      
    } catch (e) {
      _error = '保存に失敗しました: $e';
      print('Error saving store info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStoreInfo(Map<String, dynamic> updates) async {
    if (_storeInfo == null) return;

    final updatedInfo = _storeInfo!.copyWith(
      storeName: updates['storeName'] ?? _storeInfo!.storeName,
      industry: updates['industry'] ?? _storeInfo!.industry,
      description: updates['description'] ?? _storeInfo!.description,
      postalCode: updates['postalCode'] ?? _storeInfo!.postalCode,
      prefecture: updates['prefecture'] ?? _storeInfo!.prefecture,
      city: updates['city'] ?? _storeInfo!.city,
      address: updates['address'] ?? _storeInfo!.address,
      building: updates['building'] ?? _storeInfo!.building,
      phone: updates['phone'] ?? _storeInfo!.phone,
      email: updates['email'] ?? _storeInfo!.email,
      website: updates['website'] ?? _storeInfo!.website,
      establishedYear: updates['establishedYear'] ?? _storeInfo!.establishedYear,
      numberOfSeats: updates['numberOfSeats'] ?? _storeInfo!.numberOfSeats,
      numberOfStaff: updates['numberOfStaff'] ?? _storeInfo!.numberOfStaff,
      parkingSpaces: updates['parkingSpaces'] ?? _storeInfo!.parkingSpaces,
      services: updates['services'] ?? _storeInfo!.services,
      paymentMethods: updates['paymentMethods'] ?? _storeInfo!.paymentMethods,
      features: updates['features'] ?? _storeInfo!.features,
    );

    await saveStoreInfo(updatedInfo);
  }

  StoreInfoModel _createDefaultStoreInfo(String tenantId) {
    return StoreInfoModel(
      id: 'storeInfo',
      tenantId: tenantId,
      storeName: 'SAKANA HAIR',
      industry: '美容室・サロン',
      description: '最新トレンドを取り入れたヘアサロン',
      postalCode: '',
      prefecture: '東京都',
      city: '',
      address: '',
      building: '',
      phone: '',
      email: '',
      website: '',
      establishedYear: DateTime.now().year.toString(),
      numberOfSeats: '',
      numberOfStaff: '',
      parkingSpaces: '',
      services: [],
      paymentMethods: ['現金'],
      features: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveToLocalStorage() async {
    if (_storeInfo == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_storeInfo!.toJson());
      await prefs.setString('sakana_store_info', jsonStr);
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('sakana_store_info');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        _storeInfo = StoreInfoModel.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  @override
  void dispose() {
    _storeInfoSubscription?.cancel();
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }
}