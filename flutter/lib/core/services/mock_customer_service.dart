import 'dart:math';
import '../models/customer.dart';

class MockCustomerService {
  static final Random _random = Random();
  
  static final List<String> _lastNames = [
    '田中', '佐藤', '鈴木', '高橋', '渡辺', '伊藤', '山本', '中村', '小林', '加藤',
    '吉田', '山田', '佐々木', '山口', '松本', '井上', '木村', '林', '斎藤', '清水',
    '山崎', '森', '池田', '橋本', '阿部', '石川', '前田', '藤田', '川村', '岡田'
  ];
  
  static final List<String> _firstNamesMale = [
    '太郎', '次郎', '三郎', '健太', '翔太', '大輝', '拓海', '健', '誠', '学',
    '浩', '博', '明', '隆', '和也', '直樹', '雄大', '康平', '真司', '一郎'
  ];
  
  static final List<String> _firstNamesFemale = [
    '花子', '美咲', '愛', '彩', '優子', '真由美', '恵子', '裕子', '陽子', '美穂',
    '千春', '麻衣', '由美', '直美', 'さくら', '葵', '凛', '楓', '美月', '結衣'
  ];
  
  static final List<String> _messages = [
    '今日予約できますか？',
    'カットとカラーをお願いしたいです',
    '次回の予約を変更したいのですが',
    'ありがとうございました！',
    '新しいヘアスタイルとても気に入りました',
    'パーマをかけたいと思っているのですが',
    'トリートメントの料金を教えてください',
    '来週の土曜日は空いていますか？',
    '前回と同じスタイルでお願いします',
    'シャンプーがとても良かったです',
    '写真のような髪型にできますか？',
    '予約の確認をお願いします',
    'キャンセル待ちはできますか？',
    'スタイリングのコツを教えてください',
    '髪質改善について相談したいです',
  ];
  
  static final List<String> _tags = [
    'VIP', '常連', '新規', 'カラー希望', 'パーマ希望', 'トリートメント',
    '要フォロー', '誕生日月', 'キャンセル多', '高単価', '紹介客',
    '学生', '主婦', 'ビジネス', '週末希望', '平日希望', '朝一希望'
  ];
  
  static final List<String> _notes = [
    'とても丁寧な方です。細かい要望があるので注意',
    'カラーのアレルギーがあるため要確認',
    '子供連れで来店されることが多い',
    '仕事の都合で土日しか来れない',
    '髪の傷みを気にされている',
    '最新のトレンドに興味がある',
    'SNSで店舗を知って来店',
    '友人の紹介で来店。とても満足されている',
    '時間に正確。いつも5分前には到着',
    'スタイリング剤の購入率が高い',
  ];

  static List<Customer> generateMockCustomers({int count = 50}) {
    final List<Customer> customers = [];
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
      final isFemale = _random.nextBool();
      final lastName = _lastNames[_random.nextInt(_lastNames.length)];
      final firstName = isFemale 
          ? _firstNamesFemale[_random.nextInt(_firstNamesFemale.length)]
          : _firstNamesMale[_random.nextInt(_firstNamesMale.length)];
      final name = '$lastName $firstName';
      
      // ランダムな属性を生成
      final isVip = _random.nextDouble() < 0.15; // 15%がVIP
      final isOnline = _random.nextDouble() < 0.2; // 20%がオンライン
      final hasUnread = _random.nextDouble() < 0.4; // 40%が未読あり
      final hasReservation = _random.nextDouble() < 0.3; // 30%が予約あり
      final hasBirthday = _random.nextDouble() < 0.1; // 10%が誕生日近い
      
      // 購入履歴
      final purchaseCount = _random.nextInt(20);
      final avgPurchase = 3000 + _random.nextInt(15000);
      final totalPurchase = purchaseCount * avgPurchase.toDouble();
      
      // 最終メッセージ時間（最近の順になるように）
      final minutesAgo = i * 30 + _random.nextInt(30);
      final lastMessageAt = now.subtract(Duration(minutes: minutesAgo));
      
      // 誕生日（今月か来月のランダムな日）
      DateTime? birthday;
      if (hasBirthday) {
        final daysFromNow = _random.nextInt(7);
        birthday = now.add(Duration(days: daysFromNow));
      } else {
        // ランダムな誕生日
        birthday = DateTime(
          1970 + _random.nextInt(40),
          _random.nextInt(12) + 1,
          _random.nextInt(28) + 1,
        );
      }
      
      // 次回予約
      DateTime? nextReservation;
      if (hasReservation) {
        final daysFromNow = _random.nextInt(14);
        final hour = 9 + _random.nextInt(9); // 9時〜17時
        nextReservation = DateTime(
          now.year,
          now.month,
          now.day + daysFromNow,
          hour,
          _random.nextBool() ? 0 : 30, // 00分か30分
        );
      }
      
      // タグをランダムに選択（1〜4個）
      final tagCount = 1 + _random.nextInt(4);
      final selectedTags = <String>[];
      for (int j = 0; j < tagCount; j++) {
        final tag = _tags[_random.nextInt(_tags.length)];
        if (!selectedTags.contains(tag)) {
          selectedTags.add(tag);
        }
      }
      if (isVip && !selectedTags.contains('VIP')) {
        selectedTags.add('VIP');
      }
      
      // アクティビティの生成
      final hasRecentCall = _random.nextDouble() < 0.3; // 30%が最近電話
      final hasRecentPurchase = _random.nextDouble() < 0.25; // 25%が最近購入
      final hasRecentReservation = _random.nextDouble() < 0.35; // 35%が最近予約
      
      DateTime? lastCallAt;
      DateTime? lastReservationAt;
      List<CustomerActivity> recentActivities = [];
      int activityScore = 0;
      
      // 最近の電話
      if (hasRecentCall) {
        lastCallAt = now.subtract(Duration(hours: _random.nextInt(48)));
        recentActivities.add(CustomerActivity(
          type: ActivityType.call,
          timestamp: lastCallAt,
          description: '予約の問い合わせ',
        ));
        activityScore += 30;
      }
      
      // 最近の購入
      if (hasRecentPurchase) {
        final purchaseDate = now.subtract(Duration(days: _random.nextInt(7)));
        recentActivities.add(CustomerActivity(
          type: ActivityType.purchase,
          timestamp: purchaseDate,
          description: 'カット + カラー',
          metadata: {'amount': avgPurchase},
        ));
        activityScore += 40;
      }
      
      // 最近の予約
      if (hasRecentReservation) {
        lastReservationAt = now.subtract(Duration(days: _random.nextInt(3)));
        recentActivities.add(CustomerActivity(
          type: ActivityType.reservation,
          timestamp: lastReservationAt,
          description: '来週の予約確定',
        ));
        activityScore += 25;
      }
      
      // メッセージアクティビティ
      if (hasUnread) {
        recentActivities.add(CustomerActivity(
          type: ActivityType.message,
          timestamp: lastMessageAt,
          description: _messages[_random.nextInt(_messages.length)],
        ));
        activityScore += 15;
      }
      
      // アクティビティをタイムスタンプでソート
      recentActivities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // チャットソースをランダムに設定
      final chatSourceIndex = _random.nextInt(4);
      final primarySource = ChatSource.values[chatSourceIndex];
      final activeSources = <ChatSource>{primarySource};
      
      // 複数のチャットソースを持つ顧客もいる（30%）
      if (_random.nextDouble() < 0.3) {
        final additionalSource = ChatSource.values[_random.nextInt(4)];
        activeSources.add(additionalSource);
      }
      
      customers.add(Customer(
        id: 'customer_${i + 1}',
        name: name,
        email: '${lastName.toLowerCase()}${i + 1}@example.com',
        phone: '090-${_random.nextInt(9000) + 1000}-${_random.nextInt(9000) + 1000}',
        avatarUrl: null, // アバターは名前のイニシャルで表示
        lineUserId: 'LINE_${i + 1}',
        status: isOnline 
            ? CustomerStatus.online 
            : _random.nextDouble() < 0.1 
                ? CustomerStatus.away
                : CustomerStatus.offline,
        priority: isVip 
            ? CustomerPriority.vip 
            : _random.nextDouble() < 0.1
                ? CustomerPriority.premium
                : CustomerPriority.normal,
        lastMessageAt: lastMessageAt,
        lastMessage: _messages[_random.nextInt(_messages.length)],
        unreadCount: hasUnread ? _random.nextInt(10) + 1 : 0,
        tags: selectedTags,
        metadata: {
          'source': _random.nextBool() ? 'LINE' : 'Web',
          'referrer': _random.nextDouble() < 0.3 ? '友人紹介' : null,
        },
        createdAt: now.subtract(Duration(days: _random.nextInt(365))),
        updatedAt: lastMessageAt,
        totalPurchaseAmount: totalPurchase,
        purchaseCount: purchaseCount,
        lastPurchaseAt: purchaseCount > 0 
            ? now.subtract(Duration(days: _random.nextInt(30)))
            : null,
        nextReservationAt: nextReservation,
        notes: _random.nextDouble() < 0.4 
            ? _notes[_random.nextInt(_notes.length)]
            : null,
        isTyping: isOnline && _random.nextDouble() < 0.2, // オンラインの20%が入力中
        birthday: birthday,
        preferences: {
          'preferredTime': _random.nextBool() ? '午前' : '午後',
          'preferredStaff': _random.nextBool() ? '指名あり' : '指名なし',
          'style': _random.nextBool() ? 'ショート' : 'ロング',
        },
        lastCallAt: lastCallAt,
        lastReservationAt: lastReservationAt,
        hasRecentActivity: recentActivities.isNotEmpty,
        activityScore: activityScore.clamp(0, 100),
        recentActivities: recentActivities,
        primaryChatSource: primarySource,
        activeChatSources: activeSources,
      ));
    }
    
    // 最初の数人を特別な状態に設定
    if (customers.isNotEmpty) {
      // 1人目：VIPで未読多数、最近購入あり、LINE経由
      customers[0] = customers[0].copyWith(
        name: '山田 花子',
        priority: CustomerPriority.vip,
        status: CustomerStatus.online,
        unreadCount: 5,
        lastMessage: '今すぐ予約を取りたいのですが可能ですか？緊急でお願いします！',
        lastMessageAt: now.subtract(const Duration(minutes: 2)),
        isTyping: false,
        tags: ['VIP', '常連', '高単価', '最優先対応'],
        totalPurchaseAmount: 580000,
        purchaseCount: 45,
        lastPurchaseAt: now.subtract(const Duration(days: 2)),
        hasRecentActivity: true,
        activityScore: 95,
        primaryChatSource: ChatSource.line,
        activeChatSources: {ChatSource.line, ChatSource.app},
        recentActivities: [
          CustomerActivity(
            type: ActivityType.purchase,
            timestamp: now.subtract(const Duration(days: 2)),
            description: 'フルコース施術 ¥48,000',
            metadata: {'amount': 48000},
          ),
          CustomerActivity(
            type: ActivityType.call,
            timestamp: now.subtract(const Duration(hours: 1)),
            description: '緊急予約の電話',
          ),
        ],
      );
      
      // 2人目：入力中、SMS経由
      customers[1] = customers[1].copyWith(
        name: '佐藤 美咲',
        status: CustomerStatus.online,
        isTyping: true,
        unreadCount: 0,
        lastMessage: 'ありがとうございます！それでは...',
        lastMessageAt: now.subtract(const Duration(minutes: 5)),
        tags: ['新規', 'カラー希望'],
        primaryChatSource: ChatSource.sms,
        activeChatSources: {ChatSource.sms},
      );
      
      // 3人目：誕生日、予約あり
      customers[2] = customers[2].copyWith(
        name: '鈴木 太郎',
        birthday: now.add(const Duration(days: 2)),
        unreadCount: 1,
        lastMessage: '来週の予約について確認したいです',
        lastMessageAt: now.subtract(const Duration(minutes: 30)),
        tags: ['誕生日月', '常連'],
        nextReservationAt: now.add(const Duration(days: 2, hours: 14)),
        hasRecentActivity: true,
        activityScore: 85,
        recentActivities: [
          CustomerActivity(
            type: ActivityType.reservation,
            timestamp: now.subtract(const Duration(hours: 12)),
            description: '誕生日当日の予約',
          ),
        ],
      );
      
      // 4人目：本日予約、電話あり
      customers[3] = customers[3].copyWith(
        name: '高橋 愛',
        nextReservationAt: DateTime(now.year, now.month, now.day, 15, 30),
        unreadCount: 0,
        lastMessage: '本日15:30に伺います',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        tags: ['本日予約', 'パーマ希望'],
        lastCallAt: now.subtract(const Duration(hours: 6)),
        hasRecentActivity: true,
        activityScore: 75,
        recentActivities: [
          CustomerActivity(
            type: ActivityType.call,
            timestamp: now.subtract(const Duration(hours: 6)),
            description: '予約時間の確認電話',
          ),
        ],
      );
      
      // 5人目：高額顧客
      customers[4] = customers[4].copyWith(
        name: '渡辺 健太',
        priority: CustomerPriority.premium,
        totalPurchaseAmount: 320000,
        purchaseCount: 28,
        lastPurchaseAt: now.subtract(const Duration(days: 3)),
        unreadCount: 2,
        lastMessage: '新しいトリートメントについて教えてください',
        tags: ['高単価', 'トリートメント', '月2回来店'],
      );
    }
    
    return customers;
  }
}