import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/business_hours_model.dart';
import 'simplified_auth_service.dart';

class BusinessHoursService extends ChangeNotifier {
  final SimplifiedAuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  BusinessHoursModel? _businessHours;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _hoursSubscription;

  BusinessHoursModel? get businessHours => _businessHours;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBusinessHours => _businessHours != null;

  BusinessHoursService({required SimplifiedAuthService authService})
      : _authService = authService {
    _authService.addListener(_onAuthChange);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_authService.currentUser != null) {
      await loadBusinessHours();
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
    _hoursSubscription?.cancel();
    _hoursSubscription = null;
    _businessHours = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadBusinessHours() async {
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
          .doc('businessHours')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['tenantId'] = tenantId;
        _businessHours = BusinessHoursModel.fromJson(data);
      } else {
        // 初期データを作成
        _businessHours = _createDefaultBusinessHours(tenantId);
        await saveBusinessHours(_businessHours!);
      }
      
      await _saveToLocalStorage();
      
      // リアルタイム同期を開始
      _startRealtimeSync();
      
    } catch (e) {
      _error = 'データの読み込みに失敗しました: $e';
      print('Error loading business hours: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeSync() {
    if (_authService.currentUser == null) return;
    
    _hoursSubscription?.cancel();
    
    final tenantId = _authService.currentUser!.uid;
    _hoursSubscription = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('businessHours')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        data['tenantId'] = tenantId;
        _businessHours = BusinessHoursModel.fromJson(data);
        _saveToLocalStorage();
        notifyListeners();
      }
    });
  }

  Future<void> saveBusinessHours(BusinessHoursModel hours) async {
    if (_authService.currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _authService.currentUser!.uid;
      final updatedHours = hours.copyWith(
        tenantId: tenantId,
        updatedAt: DateTime.now(),
      );

      // Firebaseに保存
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('settings')
          .doc('businessHours')
          .set(updatedHours.toJson());

      _businessHours = updatedHours;
      await _saveToLocalStorage();
      
    } catch (e) {
      _error = '保存に失敗しました: $e';
      print('Error saving business hours: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDayHours(String day, DayHours hours) async {
    if (_businessHours == null) return;

    final updatedRegularHours = Map<String, DayHours>.from(_businessHours!.regularHours);
    updatedRegularHours[day] = hours;

    final updatedHours = _businessHours!.copyWith(
      regularHours: updatedRegularHours,
    );

    await saveBusinessHours(updatedHours);
  }

  Future<void> updateHolidays(List<String> holidays) async {
    if (_businessHours == null) return;

    final updatedHours = _businessHours!.copyWith(
      holidays: holidays,
    );

    await saveBusinessHours(updatedHours);
  }

  Future<void> updateBreakTime(String? breakTime) async {
    if (_businessHours == null) return;

    final updatedHours = _businessHours!.copyWith(
      breakTime: breakTime,
    );

    await saveBusinessHours(updatedHours);
  }

  Future<void> updateSpecialNotes(String? notes) async {
    if (_businessHours == null) return;

    final updatedHours = _businessHours!.copyWith(
      specialNotes: notes,
    );

    await saveBusinessHours(updatedHours);
  }

  BusinessHoursModel _createDefaultBusinessHours(String tenantId) {
    final defaultHours = {
      '月曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '火曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '水曜日': DayHours(open: '定休日', close: '', isOpen: false, lastOrder: ''),
      '木曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '金曜日': DayHours(open: '10:00', close: '21:00', isOpen: true, lastOrder: '20:00'),
      '土曜日': DayHours(open: '09:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '日曜日': DayHours(open: '09:00', close: '19:00', isOpen: true, lastOrder: '18:00'),
    };

    return BusinessHoursModel(
      id: 'businessHours',
      tenantId: tenantId,
      regularHours: defaultHours,
      holidays: ['年末年始（12/31〜1/3）'],
      breakTime: null,
      specialNotes: '最終受付はカットのみ閉店30分前',
      reservationHours: '24時間オンライン予約可能',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveToLocalStorage() async {
    if (_businessHours == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_businessHours!.toJson());
      await prefs.setString('sakana_business_hours', jsonStr);
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('sakana_business_hours');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        _businessHours = BusinessHoursModel.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  @override
  void dispose() {
    _hoursSubscription?.cancel();
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }
}