import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/payment_settings_model.dart';
import 'simplified_auth_service.dart';

class PaymentSettingsService extends ChangeNotifier {
  final SimplifiedAuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  PaymentSettingsModel? _paymentSettings;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  PaymentSettingsModel? get paymentSettings => _paymentSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPaymentSettings => _paymentSettings != null;

  PaymentSettingsService({required SimplifiedAuthService authService})
      : _authService = authService {
    _authService.addListener(_onAuthChange);
    _initialize();
  }

  Future<void> _initialize() async {
    if (_authService.currentUser != null) {
      await loadPaymentSettings();
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
    _settingsSubscription?.cancel();
    _settingsSubscription = null;
    _paymentSettings = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadPaymentSettings() async {
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
          .doc('paymentSettings')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        data['tenantId'] = tenantId;
        _paymentSettings = PaymentSettingsModel.fromJson(data);
      } else {
        // 初期データを作成
        _paymentSettings = _createDefaultPaymentSettings(tenantId);
        await savePaymentSettings(_paymentSettings!);
      }
      
      await _saveToLocalStorage();
      
      // リアルタイム同期を開始
      _startRealtimeSync();
      
    } catch (e) {
      _error = 'データの読み込みに失敗しました: $e';
      print('Error loading payment settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeSync() {
    if (_authService.currentUser == null) return;
    
    _settingsSubscription?.cancel();
    
    final tenantId = _authService.currentUser!.uid;
    _settingsSubscription = _firestore
        .collection('tenants')
        .doc(tenantId)
        .collection('settings')
        .doc('paymentSettings')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        data['id'] = snapshot.id;
        data['tenantId'] = tenantId;
        _paymentSettings = PaymentSettingsModel.fromJson(data);
        _saveToLocalStorage();
        notifyListeners();
      }
    });
  }

  Future<void> savePaymentSettings(PaymentSettingsModel settings) async {
    if (_authService.currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tenantId = _authService.currentUser!.uid;
      final updatedSettings = settings.copyWith(
        tenantId: tenantId,
        updatedAt: DateTime.now(),
      );

      // Firebaseに保存
      await _firestore
          .collection('tenants')
          .doc(tenantId)
          .collection('settings')
          .doc('paymentSettings')
          .set(updatedSettings.toJson());

      _paymentSettings = updatedSettings;
      await _saveToLocalStorage();
      
    } catch (e) {
      _error = '保存に失敗しました: $e';
      print('Error saving payment settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePaymentMethod(String methodName, bool enabled) async {
    if (_paymentSettings == null) return;

    final updatedPayments = Map<String, PaymentMethod>.from(_paymentSettings!.acceptedPayments);
    if (updatedPayments.containsKey(methodName)) {
      updatedPayments[methodName] = updatedPayments[methodName]!.copyWith(enabled: enabled);
    } else {
      updatedPayments[methodName] = PaymentMethod(enabled: enabled);
    }

    final updatedSettings = _paymentSettings!.copyWith(
      acceptedPayments: updatedPayments,
    );

    await savePaymentSettings(updatedSettings);
  }

  Future<void> updatePolicy(String policyType, String value) async {
    if (_paymentSettings == null) return;

    PaymentSettingsModel updatedSettings;
    switch (policyType) {
      case 'payment':
        updatedSettings = _paymentSettings!.copyWith(paymentPolicy: value);
        break;
      case 'cancellation':
        updatedSettings = _paymentSettings!.copyWith(cancellationPolicy: value);
        break;
      case 'tax':
        updatedSettings = _paymentSettings!.copyWith(taxSettings: value);
        break;
      default:
        return;
    }

    await savePaymentSettings(updatedSettings);
  }

  Future<void> updateDeposit(bool required, String? details) async {
    if (_paymentSettings == null) return;

    final updatedSettings = _paymentSettings!.copyWith(
      depositRequired: required,
      depositDetails: details,
    );

    await savePaymentSettings(updatedSettings);
  }

  PaymentSettingsModel _createDefaultPaymentSettings(String tenantId) {
    final defaultPayments = {
      '現金': PaymentMethod(enabled: true),
      'クレジットカード': PaymentMethod(
        enabled: true,
        brands: ['VISA', 'Mastercard', 'JCB', 'AMEX'],
      ),
      'PayPay': PaymentMethod(enabled: false),
      'LINE Pay': PaymentMethod(enabled: false),
      '交通系IC': PaymentMethod(enabled: false),
    };

    return PaymentSettingsModel(
      id: 'paymentSettings',
      tenantId: tenantId,
      acceptedPayments: defaultPayments,
      paymentPolicy: '前払い制（施術前にお支払い）',
      cancellationPolicy: '予約前日まで無料',
      depositRequired: false,
      depositDetails: null,
      minimumCharge: null,
      serviceCharge: null,
      taxSettings: '内税表示',
      insuranceInfo: null,
      returnPolicy: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _saveToLocalStorage() async {
    if (_paymentSettings == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_paymentSettings!.toJson());
      await prefs.setString('sakana_payment_settings', jsonStr);
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('sakana_payment_settings');
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr);
        _paymentSettings = PaymentSettingsModel.fromJson(json);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading from local storage: $e');
    }
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _authService.removeListener(_onAuthChange);
    super.dispose();
  }
}