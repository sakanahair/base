import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final List<String> _channels = ['すべて', 'SAKANA', 'LINE', 'SMS', 'App', 'WebChat'];
  String _selectedChannel = 'すべて';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: Column(
          children: [
            Container(
              height: 48,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'チャット',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.qr_code, size: 20, color: Colors.black54),
                    onPressed: () => context.go('/chat/qr'),
                    tooltip: 'QRコード生成',
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: Icon(Icons.broadcast_on_personal, size: 20, color: Colors.black54),
                    onPressed: () => context.go('/chat/broadcast'),
                    tooltip: '一斉配信',
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, size: 20, color: Colors.black54),
                    onPressed: () => context.go('/settings/chat'),
                    tooltip: 'チャット設定',
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: themeService.primaryColor,
                indicatorWeight: 3,
                labelColor: themeService.primaryColor,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'トーク'),
                  Tab(text: '友だち'),
                  Tab(text: 'グループ'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 検索バーとフィルター
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Column(
              children: [
                // 検索バー
                SizedBox(
                  height: 36,
                  child: TextField(
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '検索',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // チャンネルフィルター
                SizedBox(
                  height: 36,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _channels.map((channel) {
                        final isSelected = _selectedChannel == channel;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedChannel = channel;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected 
                                  ? themeService.primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                    ? themeService.primaryColor 
                                    : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                channel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected 
                                    ? themeService.primaryColor 
                                    : Colors.grey[700],
                                  fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // チャットリスト
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatList(context, themeService),
                _buildFriendsList(context, themeService),
                _buildGroupsList(context, themeService),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/chat/new'),
        backgroundColor: const Color(0xFF8A9A8D), // くすんだ緑グレー
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, ThemeService themeService) {
    final chats = _getDummyChats();
    final filteredChats = chats.where((chat) {
      final matchesSearch = chat['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chat['lastMessage'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesChannel = _selectedChannel == 'すべて' || chat['channel'] == _selectedChannel;
      return matchesSearch && matchesChannel;
    }).toList();

    return ListView.separated(
      itemCount: filteredChats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 80,
        color: AppTheme.borderColor,
      ),
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return ListTile(
          onTap: () => context.go('/chat/conversation/${chat['id']}'),
          leading: InkWell(
            onTap: chat['id'] != 'sakana-ai' ? () => _showCustomerDetails(context, chat) : null,
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: chat['id'] == 'sakana-ai' 
                    ? Colors.white
                    : _getChannelColor(chat['channel']).withOpacity(0.2),
                child: chat['id'] == 'sakana-ai' 
                  ? ClipOval(
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(8),
                        child: Image.network(
                          '/admin/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.catching_pokemon,
                              size: 30,
                              color: _getChannelColor(chat['channel']),
                            );
                          },
                        ),
                      ),
                    )
                  : Text(
                      chat['name'][0],
                      style: TextStyle(color: _getChannelColor(chat['channel']), fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getChannelColor(chat['channel']),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _getChannelIcon(chat['channel']),
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chat['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                chat['time'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (chat['isRead'] == false)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B95A7), // くすんだ青
                    shape: BoxShape.circle,
                  ),
                ),
              Expanded(
                child: Text(
                  chat['lastMessage'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chat['isRead'] ? AppTheme.textSecondary : AppTheme.textPrimary,
                    fontWeight: chat['isRead'] ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ),
              if (chat['unreadCount'] > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67B7B), // くすんだ赤
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    chat['unreadCount'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildFriendsList(BuildContext context, ThemeService themeService) {
    final friends = _getDummyFriends();
    
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return ListTile(
          onTap: () => context.go('/chat/conversation/${friend['id']}'),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: _getChannelColor(friend['channel']).withOpacity(0.2),
            child: Text(
              friend['name'][0],
              style: TextStyle(color: _getChannelColor(friend['channel']), fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          title: Text(friend['name']),
          subtitle: Text(
            '${friend['channel']} • 最終アクティブ: ${friend['lastActive']}',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'chat',
                child: ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('チャットを開始'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block),
                  title: Text('ブロック'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildGroupsList(BuildContext context, ThemeService themeService) {
    final groups = _getDummyGroups();
    
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () => context.go('/chat/group/${group['id']}'),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF9B8B9B).withOpacity(0.15), // くすんだ紫の薄い背景
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.group,
                color: const Color(0xFF9B8B9B), // くすんだ紫
              ),
            ),
            title: Text(
              group['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${group['memberCount']}人のメンバー • ${group['channel']}',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.go('/chat/group/${group['id']}/settings'),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Color _getChannelColor(String channel) {
    // くすんだ色合いのバリエーション
    switch (channel) {
      case 'SAKANA':
        return const Color(0xFF7FA8A1); // くすんだティール
      case 'LINE':
        return const Color(0xFF7C9885); // くすんだ緑
      case 'SMS':
        return const Color(0xFF8B95A7); // くすんだ青
      case 'App':
        return const Color(0xFF9B8B9B); // くすんだ紫
      case 'WebChat':
        return const Color(0xFFA89874); // くすんだオレンジ
      default:
        return const Color(0xFF8B8B8B); // くすんだグレー
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'SAKANA':
        return Icons.catching_pokemon; // 魚アイコン
      case 'LINE':
        return Icons.chat_bubble;
      case 'SMS':
        return Icons.message;
      case 'App':
        return Icons.phone_android;
      case 'WebChat':
        return Icons.web;
      default:
        return Icons.chat;
    }
  }

  List<Map<String, dynamic>> _getDummyChats() {
    return [
      {
        'id': 'sakana-ai',
        'name': 'SAKANA AI',
        'lastMessage': '画像生成、動画生成、着せ替えなど様々な機能をご利用いただけます',
        'time': '常時',
        'channel': 'SAKANA',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'id': '1',
        'name': '田中 太郎',
        'lastMessage': 'ありがとうございます！明日の予約楽しみにしています',
        'time': '14:30',
        'channel': 'LINE',
        'isRead': false,
        'unreadCount': 2,
      },
      {
        'id': '2',
        'name': '佐藤 花子',
        'lastMessage': 'カラーの相談をしたいのですが',
        'time': '13:15',
        'channel': 'WebChat',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'id': '3',
        'name': '山田 美咲',
        'lastMessage': '予約確認のメッセージ届きました',
        'time': '12:00',
        'channel': 'SMS',
        'isRead': false,
        'unreadCount': 1,
      },
      {
        'id': '4',
        'name': '鈴木 健一',
        'lastMessage': 'スタンプ',
        'time': '昨日',
        'channel': 'LINE',
        'isRead': true,
        'unreadCount': 0,
      },
      {
        'id': '5',
        'name': '高橋 めぐみ',
        'lastMessage': 'パーマの持ちはどのくらいですか？',
        'time': '昨日',
        'channel': 'App',
        'isRead': true,
        'unreadCount': 0,
      },
    ];
  }

  List<Map<String, dynamic>> _getDummyFriends() {
    return [
      {
        'id': 'f1',
        'name': '田中 太郎',
        'channel': 'LINE',
        'lastActive': '3分前',
      },
      {
        'id': 'f2',
        'name': '佐藤 花子',
        'channel': 'WebChat',
        'lastActive': '1時間前',
      },
      {
        'id': 'f3',
        'name': '山田 美咲',
        'channel': 'SMS',
        'lastActive': '3時間前',
      },
      {
        'id': 'f4',
        'name': '鈴木 健一',
        'channel': 'LINE',
        'lastActive': '昨日',
      },
      {
        'id': 'f5',
        'name': '高橋 めぐみ',
        'channel': 'App',
        'lastActive': '2日前',
      },
    ];
  }

  void _showCustomerDetails(BuildContext context, Map<String, dynamic> chat) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeService.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        chat['name'][0],
                        style: TextStyle(
                          color: themeService.primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '090-1234-5678',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // アクションボタン
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.chat, 'チャット', () {
                      Navigator.pop(context);
                      context.go('/chat/conversation/${chat['id']}');
                    }),
                    _buildActionButton(Icons.phone, '電話', () {}),
                    _buildActionButton(Icons.calendar_today, '予約', () {}),
                    _buildActionButton(Icons.history, '履歴', () {}),
                  ],
                ),
              ),
              const Divider(height: 1),
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 基本情報
                      _buildSectionTitle('基本情報'),
                      const SizedBox(height: 12),
                      _buildInfoRow('メール', chat['name'].replaceAll(' ', '').toLowerCase() + '@example.com'),
                      _buildInfoRow('誕生日', '1990年1月1日'),
                      _buildInfoRow('性別', '女性'),
                      _buildInfoRow('登録日', '2024年1月15日'),
                      const SizedBox(height: 24),
                      
                      // 利用状況
                      _buildSectionTitle('利用状況'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('累計利用額', '¥125,400', Icons.attach_money, Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('来店回数', '24回', Icons.store, Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('最終来店', '3日前', Icons.access_time, Colors.orange),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard('平均単価', '¥8,500', Icons.receipt, Colors.purple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // コミュニケーション
                      _buildSectionTitle('コミュニケーション'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildCommRow('LINE', '連携済み', true),
                            const Divider(),
                            _buildCommRow('SMS', '連携済み', true),
                            const Divider(),
                            _buildCommRow('最終連絡', '3日前', false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommRow(String label, String value, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              if (isActive)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.green : Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDummyGroups() {
    return [
      {
        'id': 'g1',
        'name': 'VIP顧客グループ',
        'memberCount': 45,
        'channel': 'LINE',
      },
      {
        'id': 'g2',
        'name': '新規顧客グループ',
        'memberCount': 128,
        'channel': 'LINE',
      },
      {
        'id': 'g3',
        'name': 'キャンペーン参加者',
        'memberCount': 89,
        'channel': 'SMS',
      },
      {
        'id': 'g4',
        'name': 'スタッフ連絡',
        'memberCount': 12,
        'channel': 'App',
      },
    ];
  }
}