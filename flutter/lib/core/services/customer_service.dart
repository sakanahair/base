import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerService extends ChangeNotifier {
  final List<Customer> _customers = [];
  static const String _storageKey = 'sakana_customers';
  static const String _lastSyncKey = 'sakana_customers_last_sync';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  DateTime? _lastSyncTime;
  Timer? _syncTimer;
  final List<PendingChange> _offlineQueue = [];
  bool _isOnline = true;
  bool _isSyncing = false;
  
  CustomerService() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    // 1. LocalStorageから高速読み込み
    await _loadFromLocalStorage();
    
    // 2. Firebaseとの同期を開始
    _startFirebaseSync();
    
    // 3. 定期同期タイマーを設定（5分ごと）
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _syncWithFirebase();
    });
  }
  
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
  
  // LocalStorageから顧客データを高速読み込み
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? customersJson = prefs.getString(_storageKey);
      
      if (customersJson != null && customersJson.isNotEmpty) {
        final List<dynamic> customersList = json.decode(customersJson);
        _customers.clear();
        _customers.addAll(
          customersList.map((data) => Customer.fromJson(data)).toList()
        );
        notifyListeners();
      } else {
        // 初回起動時のみデモデータを設定
        _initializeDemoData();
      }
      
      // 最終同期時刻を読み込み
      final String? lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
      }
    } catch (e) {
      print('Error loading customers: $e');
      // エラー時はデモデータを設定
      _initializeDemoData();
    }
  }
  
  // LocalStorageに顧客データを保存
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String customersJson = json.encode(
        _customers.map((c) => c.toJson()).toList()
      );
      await prefs.setString(_storageKey, customersJson);
      
      // 最終同期時刻も保存
      if (_lastSyncTime != null) {
        await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
      }
    } catch (e) {
      print('Error saving customers: $e');
    }
  }
  
  // 初期デモデータを設定
  void _initializeDemoData() {
    _customers.addAll([
      Customer(
        id: 'f1',
        name: '田中 太郎',
        phone: '090-1234-5678',
        email: 'tanaka@example.com',
        memberNumber: 'M00001',
        channel: 'LINE',
        registeredDate: DateTime(2024, 1, 15),
        lastVisit: DateTime.now().subtract(const Duration(days: 3)),
        totalSpent: 125400,
        visitCount: 24,
        birthday: DateTime(1990, 3, 15),
        gender: '男性',
        memo: 'カラーにこだわりがあるお客様。前回はアッシュ系のカラーを希望。',
        tags: ['顧客', 'VIP', '常連'],
      ),
      Customer(
        id: 'f2',
        name: '佐藤 花子',
        phone: '080-2345-6789',
        email: 'sato@example.com',
        memberNumber: 'M00002',
        channel: 'WebChat',
        registeredDate: DateTime(2024, 2, 1),
        lastVisit: DateTime.now().subtract(const Duration(days: 7)),
        totalSpent: 32000,
        visitCount: 5,
        birthday: DateTime(1985, 7, 1),
        gender: '女性',
        memo: 'パーマの持ちを気にされている。',
        tags: ['顧客', 'カラー', '新規'],
      ),
      Customer(
        id: 'f3',
        name: '山田 美咲',
        phone: '090-3456-7890',
        email: 'yamada@example.com',
        memberNumber: 'M00003',
        channel: 'SMS',
        registeredDate: DateTime(2023, 11, 20),
        lastVisit: DateTime.now().subtract(const Duration(days: 14)),
        totalSpent: 45000,
        visitCount: 8,
        birthday: DateTime(1995, 11, 20),
        gender: '女性',
        memo: '',
        tags: ['顧客', '要フォロー'],
      ),
      Customer(
        id: 'f4',
        name: '鈴木 健一',
        phone: '080-4567-8901',
        email: 'suzuki@example.com',
        memberNumber: 'M00004',
        channel: 'LINE',
        registeredDate: DateTime(2023, 5, 5),
        lastVisit: DateTime.now().subtract(const Duration(days: 1)),
        totalSpent: 78500,
        visitCount: 15,
        birthday: DateTime(1988, 5, 5),
        gender: '男性',
        memo: '',
        tags: ['顧客', '常連'],
      ),
      Customer(
        id: 'f5',
        name: '高橋 めぐみ',
        phone: '090-5678-9012',
        email: 'takahashi@example.com',
        channel: 'App',
        registeredDate: DateTime(2023, 9, 10),
        lastVisit: DateTime.now().subtract(const Duration(days: 5)),
        totalSpent: 210000,
        visitCount: 30,
        birthday: DateTime(1992, 9, 10),
        gender: '女性',
        memo: 'VIP顧客。特別対応が必要。',
        tags: ['顧客', 'パーマ', 'VIP'],
      ),
    ]);
    _saveToLocalStorage(); // 初期データをローカルに保存
    _syncWithFirebase(); // Firebaseにも同期
  }
  
  // Firebaseとの同期を開始
  void _startFirebaseSync() {
    final user = _auth.currentUser;
    if (user == null) {
      print('User not authenticated, skipping Firebase sync');
      return;
    }
    
    // リアルタイムリスナーを設定
    _firestore
        .collection('customers')
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
      final customer = Customer.fromFirestore(change.doc.id, data);
      
      switch (change.type) {
        case DocumentChangeType.added:
          final existingIndex = _customers.indexWhere((c) => c.id == customer.id);
          if (existingIndex == -1) {
            _customers.add(customer);
            hasChanges = true;
          }
          break;
        case DocumentChangeType.modified:
          final index = _customers.indexWhere((c) => c.id == customer.id);
          if (index != -1) {
            _customers[index] = customer;
            hasChanges = true;
          }
          break;
        case DocumentChangeType.removed:
          _customers.removeWhere((c) => c.id == customer.id);
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
  Future<void> _syncWithFirebase() async {
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
          .collection('customers')
          .where('tenantId', isEqualTo: user.uid);
      
      if (_lastSyncTime != null) {
        // 差分同期：最終同期時刻以降の変更のみ取得
        query = query.where('updatedAt', isGreaterThan: _lastSyncTime!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        for (final doc in snapshot.docs) {
          final customer = Customer.fromFirestore(
            doc.id, 
            doc.data() as Map<String, dynamic>
          );
          
          final index = _customers.indexWhere((c) => c.id == customer.id);
          if (index != -1) {
            _customers[index] = customer;
          } else {
            _customers.add(customer);
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
      final docRef = _firestore.collection('customers').doc(change.customerId);
      
      switch (change.type) {
        case ChangeType.create:
        case ChangeType.update:
          final customerData = change.customerData!;
          customerData['tenantId'] = user.uid;
          customerData['updatedAt'] = FieldValue.serverTimestamp();
          batch.set(docRef, customerData, SetOptions(merge: true));
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
  
  List<Customer> get customers => List.unmodifiable(_customers);
  
  // 顧客を追加
  Future<void> addCustomer(Customer customer) async {
    // 顧客タグを自動的に追加
    if (!customer.tags.contains('顧客')) {
      customer.tags.insert(0, '顧客');
    }
    _customers.add(customer);
    await _saveToLocalStorage(); // ローカル保存
    notifyListeners();
    
    // Firebaseに保存
    await _saveToFirebase(customer, ChangeType.create);
  }
  
  // 顧客を更新
  Future<void> updateCustomer(String id, Customer updatedCustomer) async {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      // 顧客タグを確保
      if (!updatedCustomer.tags.contains('顧客')) {
        updatedCustomer.tags.insert(0, '顧客');
      }
      _customers[index] = updatedCustomer;
      await _saveToLocalStorage(); // ローカル保存
      notifyListeners();
      
      // Firebaseに保存
      await _saveToFirebase(updatedCustomer, ChangeType.update);
    }
  }
  
  // 顧客を削除
  Future<void> deleteCustomer(String id) async {
    final customer = _customers.firstWhere((c) => c.id == id);
    _customers.removeWhere((c) => c.id == id);
    await _saveToLocalStorage(); // ローカル保存
    notifyListeners();
    
    // Firebaseから削除
    await _saveToFirebase(customer, ChangeType.delete);
  }
  
  // Firebaseに保存（オンライン/オフライン対応）
  Future<void> _saveToFirebase(Customer customer, ChangeType type) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }
    
    try {
      final docRef = _firestore.collection('customers').doc(customer.id);
      
      if (type == ChangeType.delete) {
        await docRef.delete();
      } else {
        final data = customer.toFirestore();
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
        customerId: customer.id,
        type: type,
        customerData: type != ChangeType.delete ? customer.toFirestore() : null,
        timestamp: DateTime.now(),
      ));
    }
  }
  
  // 顧客を検索
  Customer? getCustomerById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // 電話番号で顧客を検索
  Customer? findByPhone(String phone) {
    final normalizedPhone = phone.replaceAll(RegExp(r'[-\s]'), '');
    try {
      return _customers.firstWhere(
        (c) => c.phone.replaceAll(RegExp(r'[-\s]'), '') == normalizedPhone,
      );
    } catch (e) {
      return null;
    }
  }
  
  // 会員番号で顧客を検索
  Customer? findByMemberNumber(String memberNumber) {
    try {
      return _customers.firstWhere(
        (c) => c.memberNumber?.toUpperCase() == memberNumber.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  // 顧客を総合検索（名前、電話番号、会員番号）
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return [];
    
    final normalizedQuery = query.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
    final results = <Customer>[];
    
    for (final customer in _customers) {
      // 名前で検索（部分一致）
      if (customer.name.toLowerCase().contains(normalizedQuery)) {
        results.add(customer);
        continue;
      }
      
      // 電話番号で検索（部分一致）
      final normalizedPhone = customer.phone.replaceAll(RegExp(r'[-\s]'), '');
      if (normalizedPhone.contains(normalizedQuery)) {
        results.add(customer);
        continue;
      }
      
      // 会員番号で検索（前方一致）
      if (customer.memberNumber != null &&
          customer.memberNumber!.toLowerCase().startsWith(normalizedQuery)) {
        results.add(customer);
        continue;
      }
      
      // メールアドレスで検索（部分一致）
      if (customer.email.toLowerCase().contains(normalizedQuery)) {
        results.add(customer);
      }
    }
    
    return results;
  }
  
  // リアルタイムサジェスト用（最大5件）
  List<Customer> getSuggestions(String query, {int limit = 5}) {
    final results = searchCustomers(query);
    return results.take(limit).toList();
  }
  
  // 新規顧客作成
  Future<Customer> createNewCustomer({
    required String name,
    required String phone,
    String? email,
    String? memberNumber,
    String channel = 'なし',
  }) async {
    // 会員番号を自動生成（指定がない場合）
    final generatedMemberNumber = memberNumber ?? _generateMemberNumber();
    
    final newCustomer = Customer(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email ?? '',
      memberNumber: generatedMemberNumber,
      channel: channel,
      registeredDate: DateTime.now(),
      lastVisit: null,
      totalSpent: 0,
      visitCount: 0,
      birthday: null,
      gender: '',
      memo: '',
      tags: ['顧客', '新規'],
    );
    
    await addCustomer(newCustomer);
    return newCustomer;
  }
  
  // 会員番号を自動生成
  String _generateMemberNumber() {
    // 既存の会員番号から最大値を取得
    int maxNumber = 0;
    for (final customer in _customers) {
      if (customer.memberNumber != null && customer.memberNumber!.startsWith('M')) {
        final numberStr = customer.memberNumber!.substring(1);
        final number = int.tryParse(numberStr) ?? 0;
        if (number > maxNumber) {
          maxNumber = number;
        }
      }
    }
    
    // 次の番号を生成
    return 'M${(maxNumber + 1).toString().padLeft(5, '0')}';
  }
  
  // チャンネル別に顧客を取得
  List<Customer> getCustomersByChannel(String channel) {
    if (channel == 'すべて' || channel.isEmpty) {
      return customers;
    }
    return _customers.where((c) => c.channel == channel).toList();
  }
  
  // タグで顧客を検索
  List<Customer> getCustomersByTag(String tag) {
    return _customers.where((c) => c.tags.contains(tag)).toList();
  }
  
  // オンライン/オフライン状態
  bool get isOnline => _isOnline;
  
  // 手動同期をトリガー
  Future<void> forceSync() async {
    await _syncWithFirebase();
  }
}

// オフライン変更を追跡するクラス
class PendingChange {
  final String customerId;
  final ChangeType type;
  final Map<String, dynamic>? customerData;
  final DateTime timestamp;
  
  PendingChange({
    required this.customerId,
    required this.type,
    this.customerData,
    required this.timestamp,
  });
}

enum ChangeType {
  create,
  update,
  delete,
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? memberNumber; // 会員番号（追加）
  final String channel;
  final DateTime registeredDate;
  final DateTime? lastVisit;
  final int totalSpent;
  final int visitCount;
  final DateTime? birthday;
  final String gender;
  final String memo;
  final List<String> tags;
  
  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.memberNumber, // 会員番号（追加）
    required this.channel,
    required this.registeredDate,
    this.lastVisit,
    required this.totalSpent,
    required this.visitCount,
    this.birthday,
    required this.gender,
    required this.memo,
    required this.tags,
  });
  
  // 平均単価を計算
  int get averageSpent {
    if (visitCount == 0) return 0;
    return (totalSpent / visitCount).round();
  }
  
  // 最終来店からの日数
  String get lastVisitText {
    if (lastVisit == null) return '未来店';
    final days = DateTime.now().difference(lastVisit!).inDays;
    if (days == 0) return '今日';
    if (days == 1) return '昨日';
    if (days < 7) return '$days日前';
    if (days < 30) return '${(days / 7).round()}週間前';
    if (days < 365) return '${(days / 30).round()}ヶ月前';
    return '${(days / 365).round()}年前';
  }
  
  // JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'memberNumber': memberNumber,
      'channel': channel,
      'registeredDate': registeredDate.toIso8601String(),
      'lastVisit': lastVisit?.toIso8601String(),
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'birthday': birthday?.toIso8601String(),
      'gender': gender,
      'memo': memo,
      'tags': tags,
    };
  }
  
  // JSONから作成
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      memberNumber: json['memberNumber'],
      channel: json['channel'],
      registeredDate: DateTime.parse(json['registeredDate']),
      lastVisit: json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
      totalSpent: json['totalSpent'],
      visitCount: json['visitCount'],
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      gender: json['gender'] ?? '',
      memo: json['memo'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
  
  // Firestoreから作成
  factory Customer.fromFirestore(String id, Map<String, dynamic> data) {
    return Customer(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      memberNumber: data['memberNumber'],
      channel: data['channel'] ?? 'なし',
      registeredDate: (data['registeredDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastVisit: data['lastVisit'] != null ? (data['lastVisit'] as Timestamp).toDate() : null,
      totalSpent: data['totalSpent'] ?? 0,
      visitCount: data['visitCount'] ?? 0,
      birthday: data['birthday'] != null ? (data['birthday'] as Timestamp).toDate() : null,
      gender: data['gender'] ?? '',
      memo: data['memo'] ?? '',
      tags: List<String>.from(data['tags'] ?? ['顧客']),
    );
  }
  
  // Firestoreに変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'channel': channel,
      'registeredDate': Timestamp.fromDate(registeredDate),
      'lastVisit': lastVisit != null ? Timestamp.fromDate(lastVisit!) : null,
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'birthday': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'gender': gender,
      'memo': memo,
      'tags': tags,
    };
  }
  
  // コピーして更新
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? channel,
    DateTime? registeredDate,
    DateTime? lastVisit,
    int? totalSpent,
    int? visitCount,
    DateTime? birthday,
    String? gender,
    String? memo,
    List<String>? tags,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      channel: channel ?? this.channel,
      registeredDate: registeredDate ?? this.registeredDate,
      lastVisit: lastVisit ?? this.lastVisit,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      memo: memo ?? this.memo,
      tags: tags ?? List.from(this.tags),
    );
  }
}