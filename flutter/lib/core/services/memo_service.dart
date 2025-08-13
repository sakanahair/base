import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoService extends ChangeNotifier {
  final Map<String, String> _customerMemos = {};
  String _generalMemo = '';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _storageKey = 'sakana_memos';
  static const String _generalMemoKey = 'sakana_general_memo';
  
  MemoService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadFromLocalStorage();
    _syncWithFirebase();
  }
  
  // LocalStorageから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 顧客メモを読み込み
      final String? memosJson = prefs.getString(_storageKey);
      if (memosJson != null && memosJson.isNotEmpty) {
        final Map<String, dynamic> memosMap = json.decode(memosJson);
        _customerMemos.clear();
        memosMap.forEach((key, value) {
          _customerMemos[key] = value.toString();
        });
      }
      
      // 一般メモを読み込み
      _generalMemo = prefs.getString(_generalMemoKey) ?? '';
      print('Loaded from LocalStorage - General memo length: ${_generalMemo.length}');
      
      notifyListeners();
    } catch (e) {
      print('Error loading memos from LocalStorage: $e');
    }
  }
  
  // LocalStorageに保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 顧客メモを保存
      final String memosJson = json.encode(_customerMemos);
      await prefs.setString(_storageKey, memosJson);
      
      // 一般メモを保存
      await prefs.setString(_generalMemoKey, _generalMemo);
      print('Saved to LocalStorage - General memo length: ${_generalMemo.length}');
    } catch (e) {
      print('Error saving memos to LocalStorage: $e');
    }
  }
  
  // Firebaseと同期
  Future<void> _syncWithFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      // 顧客メモを同期
      _firestore
          .collection('customerMemos')
          .where('tenantId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final customerId = data['customerId'] as String;
          final memo = data['memo'] as String;
          _customerMemos[customerId] = memo;
        }
        _saveToLocalStorage();
        notifyListeners();
      });
      
      // 一般メモを同期
      final generalMemoDoc = await _firestore
          .collection('generalMemos')
          .doc(user.uid)
          .get();
      
      if (generalMemoDoc.exists) {
        _generalMemo = generalMemoDoc.data()?['memo'] ?? '';
        _saveToLocalStorage();
        notifyListeners();
      }
    } catch (e) {
      print('Error syncing memos with Firebase: $e');
    }
  }
  
  // Firebaseに保存
  Future<void> _saveToFirebase(String? customerId, String memo) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      if (customerId != null) {
        // 顧客メモを保存
        await _firestore
            .collection('customerMemos')
            .doc('${user.uid}_$customerId')
            .set({
          'tenantId': user.uid,
          'customerId': customerId,
          'memo': memo,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 一般メモを保存
        await _firestore
            .collection('generalMemos')
            .doc(user.uid)
            .set({
          'tenantId': user.uid,
          'memo': memo,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving memo to Firebase: $e');
    }
  }
  
  // 顧客メモを取得
  String getCustomerMemo(String customerId) {
    return _customerMemos[customerId] ?? '';
  }
  
  // 顧客メモを保存
  Future<void> saveCustomerMemo(String customerId, String memo) async {
    _customerMemos[customerId] = memo;
    await _saveToLocalStorage();
    await _saveToFirebase(customerId, memo);
    notifyListeners();
  }
  
  // 一般メモを取得
  String getGeneralMemo() {
    return _generalMemo;
  }
  
  // 一般メモを保存
  Future<void> saveGeneralMemo(String memo) async {
    print('Saving general memo: ${memo.substring(0, memo.length > 50 ? 50 : memo.length)}...');
    _generalMemo = memo;
    await _saveToLocalStorage();
    await _saveToFirebase(null, memo);
    notifyListeners();
    print('General memo saved successfully');
  }
  
  // メモ履歴を取得（将来の拡張用）
  List<MemoHistory> getMemoHistory(String? customerId) {
    // TODO: 履歴機能の実装
    return [];
  }
  
  // メモを検索
  Map<String, String> searchMemos(String query) {
    final results = <String, String>{};
    
    _customerMemos.forEach((customerId, memo) {
      if (memo.toLowerCase().contains(query.toLowerCase())) {
        results[customerId] = memo;
      }
    });
    
    if (_generalMemo.toLowerCase().contains(query.toLowerCase())) {
      results['general'] = _generalMemo;
    }
    
    return results;
  }
}

class MemoHistory {
  final String memo;
  final DateTime timestamp;
  final String? editedBy;
  
  MemoHistory({
    required this.memo,
    required this.timestamp,
    this.editedBy,
  });
}