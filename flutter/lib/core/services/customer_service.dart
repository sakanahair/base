import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'mock_customer_service.dart';

enum CustomerSortType {
  unread,      // 未読順
  recent,      // 最新順
  vip,         // VIP順
  purchase,    // 購入額順
  reservation, // 予約日順
  name,        // 名前順
  activity,    // アクティビティスコア順（新規追加）
}

enum CustomerFilterType {
  all,
  unread,
  vip,
  online,
  hasReservation,
  birthday,
}

class CustomerService extends ChangeNotifier {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  CustomerSortType _sortType = CustomerSortType.unread; // デフォルトを未読順に戻す
  Set<CustomerFilterType> _activeFilters = {CustomerFilterType.all};
  
  // Getters
  List<Customer> get customers => _filteredCustomers;
  bool get isLoading => _isLoading;
  CustomerSortType get sortType => _sortType;
  Set<CustomerFilterType> get activeFilters => _activeFilters;
  String get searchQuery => _searchQuery;
  
  // 統計情報
  int get totalCustomers => _customers.length;
  int get unreadCount => _customers.where((c) => c.unreadCount > 0).length;
  int get onlineCount => _customers.where((c) => c.status == CustomerStatus.online).length;
  int get vipCount => _customers.where((c) => c.isVip).length;

  // 顧客リストの初期化とリアルタイム監視
  void initializeCustomers() {
    debugPrint('CustomerService: initializeCustomers called');
    if (_customers.isNotEmpty) {
      debugPrint('CustomerService: Already initialized with ${_customers.length} customers');
      return; // 既に初期化済みの場合はスキップ
    }
    
    _isLoading = true;
    notifyListeners();

    // モックデータを使用（開発環境）
    // TODO: 本番環境ではFirestoreを使用
    _customers = MockCustomerService.generateMockCustomers(count: 50);
    debugPrint('CustomerService: Generated ${_customers.length} mock customers');
    _applyFiltersAndSort();
    debugPrint('CustomerService: After filtering, ${_filteredCustomers.length} customers');
    _isLoading = false;
    notifyListeners();
    
    // リアルタイムの更新をシミュレート
    _simulateRealtimeUpdates();

    // Firestore版（本番用・現在はコメントアウト）
    // _firestore
    //     .collection('customers')
    //     .snapshots()
    //     .listen((snapshot) {
    //   _customers = snapshot.docs
    //       .map((doc) => Customer.fromFirestore(doc))
    //       .toList();
    //   
    //   _applyFiltersAndSort();
    //   _isLoading = false;
    //   notifyListeners();
    // });
  }
  
  // リアルタイム更新のシミュレーション
  void _simulateRealtimeUpdates() {
    // 5秒ごとにランダムな顧客のステータスを更新
    Future.delayed(const Duration(seconds: 5), () {
      if (_customers.isNotEmpty) {
        final randomIndex = DateTime.now().millisecond % _customers.length;
        final customer = _customers[randomIndex];
        
        // ランダムにステータスを変更
        final updates = <String, dynamic>{};
        
        // 20%の確率でオンライン状態を切り替え
        if (DateTime.now().millisecond % 5 == 0) {
          final newStatus = customer.status == CustomerStatus.online
              ? CustomerStatus.offline
              : CustomerStatus.online;
          _customers[randomIndex] = customer.copyWith(status: newStatus);
        }
        
        // 10%の確率で新しいメッセージ
        if (DateTime.now().millisecond % 10 == 0) {
          _customers[randomIndex] = customer.copyWith(
            unreadCount: customer.unreadCount + 1,
            lastMessage: '新しいメッセージが届きました',
            lastMessageAt: DateTime.now(),
          );
        }
        
        // 5%の確率でタイピング状態を切り替え
        if (DateTime.now().millisecond % 20 == 0) {
          _customers[randomIndex] = customer.copyWith(
            isTyping: !customer.isTyping,
          );
        }
        
        _applyFiltersAndSort();
        notifyListeners();
      }
      
      // 継続的に更新
      _simulateRealtimeUpdates();
    });
  }

  // 検索
  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  // ソート変更
  void setSortType(CustomerSortType type) {
    _sortType = type;
    _applyFiltersAndSort();
  }

  // フィルター追加/削除
  void toggleFilter(CustomerFilterType filter) {
    if (filter == CustomerFilterType.all) {
      _activeFilters = {CustomerFilterType.all};
    } else {
      _activeFilters.remove(CustomerFilterType.all);
      if (_activeFilters.contains(filter)) {
        _activeFilters.remove(filter);
        if (_activeFilters.isEmpty) {
          _activeFilters.add(CustomerFilterType.all);
        }
      } else {
        _activeFilters.add(filter);
      }
    }
    _applyFiltersAndSort();
  }

  // フィルターとソートを適用
  void _applyFiltersAndSort() {
    var filtered = List<Customer>.from(_customers);

    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(_searchQuery) ||
               (customer.email?.toLowerCase().contains(_searchQuery) ?? false) ||
               (customer.phone?.contains(_searchQuery) ?? false) ||
               customer.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    // タイプフィルター
    if (!_activeFilters.contains(CustomerFilterType.all)) {
      filtered = filtered.where((customer) {
        for (var filter in _activeFilters) {
          switch (filter) {
            case CustomerFilterType.unread:
              if (customer.unreadCount > 0) return true;
              break;
            case CustomerFilterType.vip:
              if (customer.isVip) return true;
              break;
            case CustomerFilterType.online:
              if (customer.status == CustomerStatus.online) return true;
              break;
            case CustomerFilterType.hasReservation:
              if (customer.nextReservationAt != null) return true;
              break;
            case CustomerFilterType.birthday:
              if (customer.isBirthdaySoon) return true;
              break;
            default:
              break;
          }
        }
        return false;
      }).toList();
    }

    // ソート
    switch (_sortType) {
      case CustomerSortType.unread:
        filtered.sort((a, b) {
          // 未読がある顧客を上に
          if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
          if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
          // 未読数が多い順
          if (a.unreadCount != b.unreadCount) {
            return b.unreadCount.compareTo(a.unreadCount);
          }
          // 最新メッセージ順
          if (a.lastMessageAt != null && b.lastMessageAt != null) {
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          }
          return 0;
        });
        break;
      case CustomerSortType.recent:
        filtered.sort((a, b) {
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });
        break;
      case CustomerSortType.vip:
        filtered.sort((a, b) {
          if (a.isVip && !b.isVip) return -1;
          if (!a.isVip && b.isVip) return 1;
          return b.totalPurchaseAmount.compareTo(a.totalPurchaseAmount);
        });
        break;
      case CustomerSortType.purchase:
        filtered.sort((a, b) => b.totalPurchaseAmount.compareTo(a.totalPurchaseAmount));
        break;
      case CustomerSortType.reservation:
        filtered.sort((a, b) {
          if (a.nextReservationAt == null) return 1;
          if (b.nextReservationAt == null) return -1;
          return a.nextReservationAt!.compareTo(b.nextReservationAt!);
        });
        break;
      case CustomerSortType.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case CustomerSortType.activity:
        // 未読を最優先、次にアクティビティスコア
        filtered.sort((a, b) {
          // 未読がある場合は最優先
          if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
          if (a.unreadCount == 0 && b.unreadCount > 0) return 1;
          
          // 両方未読ありの場合は未読数で比較
          if (a.unreadCount > 0 && b.unreadCount > 0) {
            if (a.unreadCount != b.unreadCount) {
              return b.unreadCount.compareTo(a.unreadCount);
            }
          }
          
          // 未読がない場合はアクティビティスコアで比較
          if (a.activityScore != b.activityScore) {
            return b.activityScore.compareTo(a.activityScore);
          }
          
          // 最後に最新メッセージ時間で比較
          if (a.lastMessageAt != null && b.lastMessageAt != null) {
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          }
          return 0;
        });
        break;
    }

    _filteredCustomers = filtered;
    notifyListeners();
  }

  // 顧客を取得
  Customer? getCustomer(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // 顧客を更新
  Future<void> updateCustomer(String id, Map<String, dynamic> updates) async {
    try {
      // モック環境では直接更新
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        final customer = _customers[index];
        Customer updatedCustomer = customer;
        
        // 各フィールドを更新
        if (updates.containsKey('unreadCount')) {
          updatedCustomer = updatedCustomer.copyWith(unreadCount: updates['unreadCount']);
        }
        if (updates.containsKey('priority')) {
          updatedCustomer = updatedCustomer.copyWith(
            priority: updates['priority'] == 'vip' 
                ? CustomerPriority.vip 
                : CustomerPriority.normal,
          );
        }
        if (updates.containsKey('tags')) {
          updatedCustomer = updatedCustomer.copyWith(tags: List<String>.from(updates['tags']));
        }
        if (updates.containsKey('notes')) {
          updatedCustomer = updatedCustomer.copyWith(notes: updates['notes']);
        }
        if (updates.containsKey('isTyping')) {
          updatedCustomer = updatedCustomer.copyWith(isTyping: updates['isTyping']);
        }
        if (updates.containsKey('status')) {
          final status = CustomerStatus.values.firstWhere(
            (s) => s.name == updates['status'],
            orElse: () => CustomerStatus.offline,
          );
          updatedCustomer = updatedCustomer.copyWith(status: status);
        }
        
        _customers[index] = updatedCustomer.copyWith(
          updatedAt: DateTime.now(),
        );
        
        _applyFiltersAndSort();
        notifyListeners();
      }
      
      // Firestore版（本番用・現在はコメントアウト）
      // updates['updatedAt'] = FieldValue.serverTimestamp();
      // await _firestore.collection('customers').doc(id).update(updates);
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  // 未読をクリア
  Future<void> markAsRead(String customerId) async {
    await updateCustomer(customerId, {'unreadCount': 0});
  }

  // VIP設定を切り替え
  Future<void> toggleVip(String customerId) async {
    final customer = getCustomer(customerId);
    if (customer != null) {
      final newPriority = customer.priority == CustomerPriority.vip 
          ? CustomerPriority.normal 
          : CustomerPriority.vip;
      await updateCustomer(customerId, {'priority': newPriority.name});
    }
  }

  // タグを追加
  Future<void> addTag(String customerId, String tag) async {
    final customer = getCustomer(customerId);
    if (customer != null && !customer.tags.contains(tag)) {
      final tags = List<String>.from(customer.tags)..add(tag);
      await updateCustomer(customerId, {'tags': tags});
    }
  }

  // タグを削除
  Future<void> removeTag(String customerId, String tag) async {
    final customer = getCustomer(customerId);
    if (customer != null && customer.tags.contains(tag)) {
      final tags = List<String>.from(customer.tags)..remove(tag);
      await updateCustomer(customerId, {'tags': tags});
    }
  }

  // メモを更新
  Future<void> updateNotes(String customerId, String notes) async {
    await updateCustomer(customerId, {'notes': notes});
  }

  // タイピング状態を更新
  Future<void> setTyping(String customerId, bool isTyping) async {
    await updateCustomer(customerId, {'isTyping': isTyping});
  }

  // オンラインステータスを更新
  Future<void> updateStatus(String customerId, CustomerStatus status) async {
    await updateCustomer(customerId, {'status': status.name});
  }

  // 新規顧客を作成（モック版）
  Future<String> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? lineUserId,
    List<String>? tags,
  }) async {
    try {
      // モック実装：新しい顧客を作成してリストに追加
      final newCustomer = Customer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        lineUserId: lineUserId,
        tags: tags ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _customers.add(newCustomer);
      _applyFiltersAndSort();
      notifyListeners();
      
      return newCustomer.id;
      
      // Firebase版（本番用・現在はコメントアウト）
      // final doc = await _firestore.collection('customers').add({
      //   'name': name,
      //   'email': email,
      //   'phone': phone,
      //   'lineUserId': lineUserId,
      //   'tags': tags ?? [],
      //   'status': CustomerStatus.offline.name,
      //   'priority': CustomerPriority.normal.name,
      //   'unreadCount': 0,
      //   'totalPurchaseAmount': 0,
      //   'purchaseCount': 0,
      //   'createdAt': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });
      // return doc.id;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}