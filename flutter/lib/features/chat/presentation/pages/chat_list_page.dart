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
  final List<String> _channels = ['すべて', 'LINE', 'SMS', 'App', 'WebChat'];
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
        child: AppBar(
          backgroundColor: themeService.primaryColor,
          foregroundColor: themeService.onPrimaryColor,
          title: const Text('チャット', style: TextStyle(fontSize: 18)),
          toolbarHeight: 48,
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code, size: 20),
              onPressed: () => context.go('/chat/qr'),
              tooltip: 'QRコード生成',
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.broadcast_on_personal, size: 20),
              onPressed: () => context.go('/chat/broadcast'),
              tooltip: '一斉配信',
              padding: const EdgeInsets.all(8),
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: () => context.go('/settings/chat'),
              tooltip: 'チャット設定',
              padding: const EdgeInsets.all(8),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: SizedBox(
              height: 40,
              child: TabBar(
                controller: _tabController,
                indicatorColor: themeService.onPrimaryColor,
                labelColor: themeService.onPrimaryColor,
                unselectedLabelColor: themeService.onPrimaryColor.withOpacity(0.7),
                labelStyle: const TextStyle(fontSize: 14),
                tabs: const [
                  Tab(text: 'トーク'),
                  Tab(text: '友だち'),
                  Tab(text: 'グループ'),
                ],
              ),
            ),
          ),
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
                  height: 32,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _channels.map((channel) {
                        final isSelected = _selectedChannel == channel;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(channel),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedChannel = channel;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: themeService.primaryColorBackground,
                            checkmarkColor: themeService.primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? themeService.primaryColor : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            side: BorderSide(
                              color: isSelected ? themeService.primaryColor : Colors.grey[300]!,
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
        backgroundColor: themeService.primaryColor,
        foregroundColor: themeService.onPrimaryColor,
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
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: _getChannelColor(chat['channel']),
                child: Text(
                  chat['name'][0],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
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
                    color: themeService.primaryColor,
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
                    color: Colors.red,
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
            backgroundColor: _getChannelColor(friend['channel']),
            child: Text(
              friend['name'][0],
              style: const TextStyle(color: Colors.white, fontSize: 18),
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
                color: themeService.primaryColorBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.group,
                color: themeService.primaryColor,
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
    switch (channel) {
      case 'LINE':
        return const Color(0xFF00B900);
      case 'SMS':
        return Colors.blue;
      case 'App':
        return Colors.purple;
      case 'WebChat':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
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