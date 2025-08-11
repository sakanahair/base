// import 'package:cloud_firestore/cloud_firestore.dart';

// チャットソース（会話の経路）
enum ChatSource {
  line,     // LINE
  sms,      // SMS
  app,      // ネイティブアプリ
  webChat,  // Webチャット
}

// アクティビティタイプ
enum ActivityType {
  message,      // メッセージ
  call,         // 電話
  reservation,  // 予約
  purchase,     // 購入
  visit,        // 来店
  live,         // ライブ配信視聴
}

// 顧客アクティビティ
class CustomerActivity {
  final ActivityType type;
  final DateTime timestamp;
  final String? description;
  final Map<String, dynamic>? metadata;

  CustomerActivity({
    required this.type,
    required this.timestamp,
    this.description,
    this.metadata,
  });
  
  // アクティビティの重要度スコア（0-10）
  int get importance {
    switch (type) {
      case ActivityType.purchase:
        return 10;
      case ActivityType.reservation:
        return 8;
      case ActivityType.call:
        return 7;
      case ActivityType.visit:
        return 6;
      case ActivityType.live:
        return 5;
      case ActivityType.message:
        return 3;
    }
  }
  
  // アクティビティのアイコン
  String get icon {
    switch (type) {
      case ActivityType.purchase:
        return '💳';
      case ActivityType.reservation:
        return '📅';
      case ActivityType.call:
        return '📞';
      case ActivityType.visit:
        return '🏪';
      case ActivityType.live:
        return '📺';
      case ActivityType.message:
        return '💬';
    }
  }
}

enum CustomerStatus {
  online,
  offline,
  busy,
  away,
}

enum CustomerPriority {
  normal,
  vip,
  premium,
  blocked,
}

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? lineUserId;
  final CustomerStatus status;
  final CustomerPriority priority;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final int unreadCount;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalPurchaseAmount;
  final int purchaseCount;
  final DateTime? lastPurchaseAt;
  final DateTime? nextReservationAt;
  final String? notes;
  final bool isTyping;
  final DateTime? birthday;
  final Map<String, dynamic>? preferences;
  
  // 新しいアクティビティ関連フィールド
  final DateTime? lastCallAt;        // 最後の電話
  final DateTime? lastReservationAt;  // 最後の予約
  final bool hasRecentActivity;       // 最近のアクティビティ有無
  final int activityScore;            // アクティビティスコア（0-100）
  final List<CustomerActivity> recentActivities; // 最近のアクティビティ履歴
  
  // チャットソース関連
  final ChatSource primaryChatSource; // 主なチャット経路
  final Set<ChatSource> activeChatSources; // アクティブなチャット経路

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.lineUserId,
    this.status = CustomerStatus.offline,
    this.priority = CustomerPriority.normal,
    this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.tags = const [],
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.totalPurchaseAmount = 0,
    this.purchaseCount = 0,
    this.lastPurchaseAt,
    this.nextReservationAt,
    this.notes,
    this.isTyping = false,
    this.birthday,
    this.preferences,
    this.lastCallAt,
    this.lastReservationAt,
    this.hasRecentActivity = false,
    this.activityScore = 0,
    this.recentActivities = const [],
    this.primaryChatSource = ChatSource.line,
    this.activeChatSources = const {ChatSource.line},
  });

  // // Firestoreからのデータ変換（Firebase使用時にコメントアウトを解除）
  // factory Customer.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return Customer(
  //     id: doc.id,
  //     name: data['name'] ?? '',
  //     email: data['email'],
  //     phone: data['phone'],
  //     avatarUrl: data['avatarUrl'],
  //     lineUserId: data['lineUserId'],
  //     status: _parseStatus(data['status']),
  //     priority: _parsePriority(data['priority']),
  //     lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
  //     lastMessage: data['lastMessage'],
  //     unreadCount: data['unreadCount'] ?? 0,
  //     tags: List<String>.from(data['tags'] ?? []),
  //     metadata: data['metadata'],
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  //     totalPurchaseAmount: (data['totalPurchaseAmount'] ?? 0).toDouble(),
  //     purchaseCount: data['purchaseCount'] ?? 0,
  //     lastPurchaseAt: (data['lastPurchaseAt'] as Timestamp?)?.toDate(),
  //     nextReservationAt: (data['nextReservationAt'] as Timestamp?)?.toDate(),
  //     notes: data['notes'],
  //     isTyping: data['isTyping'] ?? false,
  //     birthday: (data['birthday'] as Timestamp?)?.toDate(),
  //     preferences: data['preferences'],
  //   );
  // }

  // // Firestoreへのデータ変換（Firebase使用時にコメントアウトを解除）
  // Map<String, dynamic> toFirestore() {
  //   return {
  //     'name': name,
  //     'email': email,
  //     'phone': phone,
  //     'avatarUrl': avatarUrl,
  //     'lineUserId': lineUserId,
  //     'status': status.name,
  //     'priority': priority.name,
  //     'lastMessageAt': lastMessageAt != null 
  //         ? Timestamp.fromDate(lastMessageAt!) 
  //         : null,
  //     'lastMessage': lastMessage,
  //     'unreadCount': unreadCount,
  //     'tags': tags,
  //     'metadata': metadata,
  //     'createdAt': Timestamp.fromDate(createdAt),
  //     'updatedAt': Timestamp.fromDate(updatedAt),
  //     'totalPurchaseAmount': totalPurchaseAmount,
  //     'purchaseCount': purchaseCount,
  //     'lastPurchaseAt': lastPurchaseAt != null 
  //         ? Timestamp.fromDate(lastPurchaseAt!) 
  //         : null,
  //     'nextReservationAt': nextReservationAt != null 
  //         ? Timestamp.fromDate(nextReservationAt!) 
  //         : null,
  //     'notes': notes,
  //     'isTyping': isTyping,
  //     'birthday': birthday != null 
  //         ? Timestamp.fromDate(birthday!) 
  //         : null,
  //     'preferences': preferences,
  //   };
  // }

  // ステータス変換
  static CustomerStatus _parseStatus(String? status) {
    switch (status) {
      case 'online':
        return CustomerStatus.online;
      case 'busy':
        return CustomerStatus.busy;
      case 'away':
        return CustomerStatus.away;
      default:
        return CustomerStatus.offline;
    }
  }

  // 優先度変換
  static CustomerPriority _parsePriority(String? priority) {
    switch (priority) {
      case 'vip':
        return CustomerPriority.vip;
      case 'premium':
        return CustomerPriority.premium;
      case 'blocked':
        return CustomerPriority.blocked;
      default:
        return CustomerPriority.normal;
    }
  }

  // コピー with メソッド
  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? lineUserId,
    CustomerStatus? status,
    CustomerPriority? priority,
    DateTime? lastMessageAt,
    String? lastMessage,
    int? unreadCount,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? totalPurchaseAmount,
    int? purchaseCount,
    DateTime? lastPurchaseAt,
    DateTime? nextReservationAt,
    String? notes,
    bool? isTyping,
    DateTime? birthday,
    Map<String, dynamic>? preferences,
    DateTime? lastCallAt,
    DateTime? lastReservationAt,
    bool? hasRecentActivity,
    int? activityScore,
    List<CustomerActivity>? recentActivities,
    ChatSource? primaryChatSource,
    Set<ChatSource>? activeChatSources,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lineUserId: lineUserId ?? this.lineUserId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPurchaseAmount: totalPurchaseAmount ?? this.totalPurchaseAmount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      nextReservationAt: nextReservationAt ?? this.nextReservationAt,
      notes: notes ?? this.notes,
      isTyping: isTyping ?? this.isTyping,
      birthday: birthday ?? this.birthday,
      preferences: preferences ?? this.preferences,
      lastCallAt: lastCallAt ?? this.lastCallAt,
      lastReservationAt: lastReservationAt ?? this.lastReservationAt,
      hasRecentActivity: hasRecentActivity ?? this.hasRecentActivity,
      activityScore: activityScore ?? this.activityScore,
      recentActivities: recentActivities ?? this.recentActivities,
      primaryChatSource: primaryChatSource ?? this.primaryChatSource,
      activeChatSources: activeChatSources ?? this.activeChatSources,
    );
  }

  // 表示用のステータステキスト
  String get displayStatus {
    switch (status) {
      case CustomerStatus.online:
        return 'オンライン';
      case CustomerStatus.busy:
        return '取り込み中';
      case CustomerStatus.away:
        return '離席中';
      case CustomerStatus.offline:
        return 'オフライン';
    }
  }

  // VIP判定
  bool get isVip => priority == CustomerPriority.vip || priority == CustomerPriority.premium;

  // 誕生日が近いか判定（7日以内）
  bool get isBirthdaySoon {
    if (birthday == null) return false;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(now.year, birthday!.month, birthday!.day);
    final diff = thisYearBirthday.difference(now).inDays;
    return diff >= 0 && diff <= 7;
  }

  // 最終メッセージの時間表示
  String get lastMessageTimeDisplay {
    if (lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt!);
    
    if (diff.inMinutes < 1) {
      return '今';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}時間前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}日前';
    } else {
      return '${lastMessageAt!.month}/${lastMessageAt!.day}';
    }
  }
}