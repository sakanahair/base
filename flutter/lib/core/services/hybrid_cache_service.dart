import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ハイブリッドキャッシングの基底クラス
/// LocalStorage（高速読み込み）とFirebase（永続化・同期）を組み合わせる
abstract class HybridCacheService<T> extends ChangeNotifier {
  final List<T> _items = [];
  final List<PendingChange> _offlineQueue = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime? _lastSyncTime;
  Timer? _syncTimer;
  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription? _firestoreSubscription;
  
  // サブクラスで実装が必要
  String get collectionName;
  String get localStorageKey;
  String get lastSyncKey => '${localStorageKey}_last_sync';
  
  // アイテムのシリアライズ/デシリアライズ
  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson(T item);
  T fromFirestore(String id, Map<String, dynamic> data);
  Map<String, dynamic> toFirestore(T item);
  String getItemId(T item);
  
  // コンストラクタ
  HybridCacheService() {
    _initialize();
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }
  
  // 初期化処理
  Future<void> _initialize() async {
    // 1. LocalStorageから高速読み込み
    await _loadFromLocalStorage();
    
    // 2. Firebaseとの同期を開始
    _startFirebaseSync();
    
    // 3. 定期同期タイマーを設定（5分ごと）
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncWithFirebase();
    });
  }
  
  // LocalStorageから読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? itemsJson = prefs.getString(localStorageKey);
      
      if (itemsJson != null && itemsJson.isNotEmpty) {
        final List<dynamic> itemsList = json.decode(itemsJson);
        _items.clear();
        _items.addAll(
          itemsList.map((data) => fromJson(data)).toList()
        );
        notifyListeners();
      } else {
        // 初回起動時の処理
        await onFirstLoad();
      }
      
      // 最終同期時刻を読み込み
      final String? lastSyncStr = prefs.getString(lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }
    } catch (e) {
      print('Error loading from LocalStorage: $e');
      await onFirstLoad();
    }
  }
  
  // LocalStorageに保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String itemsJson = json.encode(
        _items.map((item) => toJson(item)).toList()
      );
      await prefs.setString(localStorageKey, itemsJson);
      
      // 最終同期時刻も保存
      if (_lastSyncTime != null) {
        await prefs.setString(lastSyncKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      print('Error saving to LocalStorage: $e');
    }
  }
  
  // Firebaseとの同期を開始
  void _startFirebaseSync() {
    final user = _auth.currentUser;
    if (user == null) {
      print('User not authenticated, skipping Firebase sync');
      return;
    }
    
    // リアルタイムリスナーを設定
    _firestoreSubscription = _firestore
        .collection(collectionName)
        .where('tenantId', isEqualTo: user.uid)
        .snapshots()
        .listen(
      (snapshot) {
        if (!_isSyncing) {
          _handleFirebaseChanges(snapshot);
        }
      },
      onError: (error) {
        print('Firebase listener error: $error');
        _isOnline = false;
      },
    );
  }
  
  // Firebaseの変更を処理
  void _handleFirebaseChanges(QuerySnapshot snapshot) async {
    if (snapshot.docChanges.isEmpty) return;
    
    bool hasChanges = false;
    
    for (final change in snapshot.docChanges) {
      final data = change.doc.data() as Map<String, dynamic>;
      final item = fromFirestore(change.doc.id, data);
      final itemId = getItemId(item);
      
      switch (change.type) {
        case DocumentChangeType.added:
          final existingIndex = _items.indexWhere((i) => getItemId(i) == itemId);
          if (existingIndex == -1) {
            _items.add(item);
            hasChanges = true;
          }
          break;
        case DocumentChangeType.modified:
          final index = _items.indexWhere((i) => getItemId(i) == itemId);
          if (index != -1) {
            _items[index] = item;
            hasChanges = true;
          }
          break;
        case DocumentChangeType.removed:
          _items.removeWhere((i) => getItemId(i) == itemId);
          hasChanges = true;
          break;
      }
    }
    
    if (hasChanges) {
      _lastSyncTime = DateTime.now();
      await _saveToLocalStorage();
      notifyListeners();
    }
  }
  
  // Firebaseと同期（差分同期）
  Future<void> syncWithFirebase() async {
    if (_isSyncing) return;
    
    final user = _auth.currentUser;
    if (user == null) {
      print('User not authenticated, skipping sync');
      return;
    }
    
    _isSyncing = true;
    
    try {
      // オフラインキューを処理
      await _processOfflineQueue();
      
      // 最終同期時刻以降の変更を取得
      Query query = _firestore
          .collection(collectionName)
          .where('tenantId', isEqualTo: user.uid);
      
      if (_lastSyncTime != null) {
        // 差分同期：最終同期時刻以降の変更のみ取得
        query = query.where('updatedAt', isGreaterThan: _lastSyncTime!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final item = fromFirestore(
            doc.id, 
            doc.data() as Map<String, dynamic>
          );
          
          final itemId = getItemId(item);
          final index = _items.indexWhere((i) => getItemId(i) == itemId);
          if (index != -1) {
            _items[index] = item;
          } else {
            _items.add(item);
          }
        }
        
        _lastSyncTime = DateTime.now();
        await _saveToLocalStorage();
        notifyListeners();
      }
      
      _isOnline = true;
    } catch (e) {
      print('Sync error: $e');
      _isOnline = false;
    } finally {
      _isSyncing = false;
    }
  }
  
  // オフラインキューを処理
  Future<void> _processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    final batch = _firestore.batch();
    
    for (final change in _offlineQueue) {
      final docRef = _firestore.collection(collectionName).doc(change.itemId);
      
      switch (change.type) {
        case ChangeType.create:
        case ChangeType.update:
          final itemData = change.itemData!;
          itemData['tenantId'] = user.uid;
          itemData['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, itemData, SetOptions(merge: true));
          break;
        case ChangeType.delete:
          batch.delete(docRef);
          break;
      }
    }
    
    try {
      await batch.commit();
      _offlineQueue.clear();
    } catch (e) {
      print('Failed to process offline queue: $e');
    }
  }
  
  // Firebaseに保存（オンライン/オフライン対応）
  Future<void> _saveToFirebase(T item, ChangeType type) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }
    
    final itemId = getItemId(item);
    
    try {
      final docRef = _firestore.collection(collectionName).doc(itemId);
      
      if (type == ChangeType.delete) {
        await docRef.delete();
      } else {
        final data = toFirestore(item);
        data['tenantId'] = user.uid;
        data['updatedAt'] = FieldValue.serverTimestamp();
        
        await docRef.set(data, SetOptions(merge: true));
      }
      
      _lastSyncTime = DateTime.now();
      await _saveToLocalStorage();
    } catch (e) {
      print('Firebase save error: $e');
      // オフラインの場合はキューに追加
      _offlineQueue.add(PendingChange(
        itemId: itemId,
        type: type,
        itemData: type != ChangeType.delete ? toFirestore(item) : null,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // アイテムを追加
  Future<void> addItem(T item) async {
    _items.add(item);
    await _saveToLocalStorage();
    notifyListeners();
    await _saveToFirebase(item, ChangeType.create);
  }
  
  // アイテムを更新
  Future<void> updateItem(String id, T updatedItem) async {
    final index = _items.indexWhere((item) => getItemId(item) == id);
    if (index != -1) {
      _items[index] = updatedItem;
      await _saveToLocalStorage();
      notifyListeners();
      await _saveToFirebase(updatedItem, ChangeType.update);
    }
  }
  
  // アイテムを削除
  Future<void> deleteItem(String id) async {
    final item = _items.firstWhere((i) => getItemId(i) == id);
    _items.removeWhere((i) => getItemId(i) == id);
    await _saveToLocalStorage();
    notifyListeners();
    await _saveToFirebase(item, ChangeType.delete);
  }
  
  // アイテムを取得
  T? getItemById(String id) {
    try {
      return _items.firstWhere((item) => getItemId(item) == id);
    } catch (e) {
      return null;
    }
  }
  
  // 全アイテムを取得
  List<T> get items => List.unmodifiable(_items);
  
  // オンライン/オフライン状態
  bool get isOnline => _isOnline;
  
  // 同期中かどうか
  bool get isSyncing => _isSyncing;
  
  // 手動同期をトリガー
  Future<void> forceSync() async {
    await syncWithFirebase();
  }
  
  // キャッシュをクリア
  Future<void> clearCache() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(localStorageKey);
    await prefs.remove(lastSyncKey);
    _lastSyncTime = null;
    notifyListeners();
    await syncWithFirebase();
  }
  
  // 初回ロード時の処理（サブクラスでオーバーライド可能）
  Future<void> onFirstLoad() async {
    // デフォルトは何もしない
  }
}

// オフライン変更を追跡するクラス
class PendingChange {
  final String itemId;
  final ChangeType type;
  final Map<String, dynamic>? itemData;
  final DateTime timestamp;
  
  PendingChange({
    required this.itemId,
    required this.type,
    this.itemData,
    required this.timestamp,
  });
}

enum ChangeType {
  create,
  update,
  delete,
}