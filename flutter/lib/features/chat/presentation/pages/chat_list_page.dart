import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/tag_service.dart';
import '../../../../shared/widgets/tag_manager_dialog.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _searchQuery = '';
  final List<String> _channels = ['すべて', 'LINE', 'SMS', 'App', 'WebChat'];
  String _selectedChannel = 'すべて';
  String _selectedTag = '';
  bool _isDetailMode = false;
  bool _showTagDropdown = false;
  List<String> _pinnedChats = [];
  List<String> _hiddenChats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    
    // 初期タグを設定（デモ用）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tagService = Provider.of<TagService>(context, listen: false);
      tagService.setUserTags('1', ['VIP', '常連']);
      tagService.setUserTags('2', ['カラー', '新規']);
      tagService.setUserTags('3', ['要フォロー']);
      tagService.setUserTags('4', ['常連']);
      tagService.setUserTags('5', ['パーマ', 'VIP']);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
                    icon: Icon(
                      _isDetailMode ? Icons.view_list : Icons.view_agenda,
                      size: 20,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDetailMode = !_isDetailMode;
                      });
                    },
                    tooltip: _isDetailMode ? 'シンプル表示' : '詳細表示',
                    padding: const EdgeInsets.all(8),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.visibility_off, size: 20, color: Colors.black54),
                        onPressed: () => _showHiddenChatsDialog(context),
                        tooltip: '非表示リスト',
                        padding: const EdgeInsets.all(8),
                      ),
                      if (_hiddenChats.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _hiddenChats.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
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
      body: Stack(
        children: [
          Column(
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
                    controller: _searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '名前、メッセージ、タグで検索',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
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
                // チャンネルフィルターとタグフィルター
                    SizedBox(
                      height: 36,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._channels.map((channel) {
                              final isSelected = _selectedChannel == channel;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedChannel = channel;
                                      _selectedTag = '';
                                      _showTagDropdown = false;
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
                            // タグフィルターボタン
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showTagDropdown = !_showTagDropdown;
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedTag.isNotEmpty 
                                      ? themeService.primaryColor.withOpacity(0.1)
                                      : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _selectedTag.isNotEmpty 
                                        ? themeService.primaryColor 
                                        : Colors.grey[300]!,
                                      width: _selectedTag.isNotEmpty ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.label,
                                        size: 16,
                                        color: _selectedTag.isNotEmpty 
                                          ? themeService.primaryColor 
                                          : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _selectedTag.isEmpty ? 'タグ' : _selectedTag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _selectedTag.isNotEmpty 
                                            ? themeService.primaryColor 
                                            : Colors.grey[700],
                                          fontWeight: _selectedTag.isNotEmpty 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _showTagDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        size: 18,
                                        color: _selectedTag.isNotEmpty 
                                          ? themeService.primaryColor 
                                          : Colors.grey[700],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
          // タグドロップダウンメニュー
          if (_showTagDropdown)
            Positioned(
              top: 90,
              right: 12,
              child: Container(
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Consumer<TagService>(
                    builder: (context, tagService, child) {
                      // 使用されているタグを収集
                      final usedTags = <String>{};
                      for (var chat in _getDummyChats()) {
                        usedTags.addAll(tagService.getUserTags(chat['id']));
                      }
                      
                      if (usedTags.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'タグが登録されていません',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      }
                      
                      return Container(
                        width: 200,
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.label, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '登録済みタグ',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  if (_selectedTag.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedTag = '';
                                          _searchQuery = '';
                                          _searchController.clear();
                                          _showTagDropdown = false;
                                        });
                                      },
                                      child: const Text(
                                        'クリア',
                                        style: TextStyle(fontSize: 12, color: Colors.blue),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: usedTags.map((tag) {
                                    final isSelected = _selectedTag == tag;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedTag = tag;
                                          _searchQuery = tag;
                                          _searchController.text = tag;
                                          _selectedChannel = 'すべて';
                                          _showTagDropdown = false;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                            ? tagService.getTagColor(tag)
                                            : tagService.getTagColor(tag).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: tagService.getTagColor(tag).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                              ? Colors.white
                                              : tagService.getTagColor(tag),
                                            fontWeight: FontWeight.w500,
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
                      );
                    },
                  ),
                ),
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
    final tagService = Provider.of<TagService>(context);
    final chats = _getDummyChats();
    final filteredChats = chats.where((chat) {
      // 名前とメッセージでの検索
      final matchesNameOrMessage = chat['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          chat['lastMessage'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      // タグでの検索
      final userTags = tagService.getUserTags(chat['id']);
      final matchesTags = userTags.any((tag) => 
          tag.toLowerCase().contains(_searchQuery.toLowerCase()));
      
      // いずれかにマッチすれば表示
      final matchesSearch = _searchQuery.isEmpty || matchesNameOrMessage || matchesTags;
      
      final matchesChannel = _selectedChannel == 'すべて' || chat['channel'] == _selectedChannel;
      final isNotHidden = !_hiddenChats.contains(chat['id']);
      return matchesSearch && matchesChannel && isNotHidden;
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
        final isPinned = _pinnedChats.contains(chat['id']);
        final isSakanaAI = chat['id'] == 'sakana-ai';
        final userTags = tagService.getUserTags(chat['id']);
        
        return Dismissible(
          key: Key(chat['id']),
          direction: isSakanaAI ? DismissDirection.none : DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            if (isSakanaAI) return false;
            
            if (direction == DismissDirection.endToStart) {
              // 右から左へのスワイプ（左スワイプ）：ミュート
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${chat['name']}の通知をオフにしました'),
                  action: SnackBarAction(
                    label: '元に戻す',
                    onPressed: () {
                      // ミュート解除の処理
                    },
                  ),
                ),
              );
              return false;
            } else {
              // 左から右へのスワイプ（右スワイプ）：ピン留め
              _togglePin(chat['id']);
              return false;
            }
          },
          background: Container(
            color: Colors.blue.withOpacity(0.2),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.push_pin, color: Colors.blue),
          ),
          secondaryBackground: Container(
            color: Colors.orange.withOpacity(0.2),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.notifications_off, color: Colors.orange),
          ),
          child: GestureDetector(
            onSecondaryTapDown: isSakanaAI ? null : (details) {
              // PCの右クリック
              _showContextMenu(context, details.globalPosition, chat);
            },
            onLongPress: isSakanaAI ? null : () {
              // モバイルの長押し
              _showContextMenu(context, Offset.zero, chat);
            },
            child: Container(
              color: isPinned ? themeService.primaryColor.withOpacity(0.05) : null,
              child: ListTile(
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
                      if (isPinned)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.push_pin,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userTags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ...userTags.map<Widget>((tag) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tagService.getTagColor(tag).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: tagService.getTagColor(tag).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: tagService.getTagColor(tag),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ],
                      ],
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
              if (_isDetailMode) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chat['phone'] ?? '090-1234-5678',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.cake,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chat['birthday'] ?? '1月1日',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.attach_money,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chat['totalSpent'] ?? '¥25,000',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
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
            ),
          ),
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

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'VIP':
        return Colors.amber[700]!;
      case '新規':
        return Colors.green[600]!;
      case '常連':
        return Colors.blue[600]!;
      case '休眠':
        return Colors.grey[600]!;
      case '要フォロー':
        return Colors.red[600]!;
      case 'カラー':
        return Colors.purple[600]!;
      case 'パーマ':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
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
        'tags': null,
        'phone': null,
        'birthday': null,
        'totalSpent': null,
      },
      {
        'id': '1',
        'name': '田中 太郎',
        'lastMessage': 'ありがとうございます！明日の予約楽しみにしています',
        'time': '14:30',
        'channel': 'LINE',
        'isRead': false,
        'unreadCount': 2,
        'tags': ['VIP', '常連'],
        'phone': '090-1234-5678',
        'birthday': '3月15日',
        'totalSpent': '¥125,400',
      },
      {
        'id': '2',
        'name': '佐藤 花子',
        'lastMessage': 'カラーの相談をしたいのですが',
        'time': '13:15',
        'channel': 'WebChat',
        'isRead': true,
        'unreadCount': 0,
        'tags': ['カラー', '新規'],
        'phone': '080-2345-6789',
        'birthday': '7月1日',
        'totalSpent': '¥32,000',
      },
      {
        'id': '3',
        'name': '山田 美咲',
        'lastMessage': '予約確認のメッセージ届きました',
        'time': '12:00',
        'channel': 'SMS',
        'isRead': false,
        'unreadCount': 1,
        'tags': ['要フォロー'],
        'phone': '090-3456-7890',
        'birthday': '11月20日',
        'totalSpent': '¥45,000',
      },
      {
        'id': '4',
        'name': '鈴木 健一',
        'lastMessage': 'スタンプ',
        'time': '昨日',
        'channel': 'LINE',
        'isRead': true,
        'unreadCount': 0,
        'tags': ['常連'],
        'phone': '080-4567-8901',
        'birthday': '5月5日',
        'totalSpent': '¥78,500',
      },
      {
        'id': '5',
        'name': '高橋 めぐみ',
        'lastMessage': 'パーマの持ちはどのくらいですか？',
        'time': '昨日',
        'channel': 'App',
        'isRead': true,
        'unreadCount': 0,
        'tags': ['パーマ', 'VIP'],
        'phone': '090-5678-9012',
        'birthday': '9月10日',
        'totalSpent': '¥210,000',
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

  void _togglePin(String chatId) {
    setState(() {
      if (_pinnedChats.contains(chatId)) {
        _pinnedChats.remove(chatId);
      } else {
        _pinnedChats.add(chatId);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_pinnedChats.contains(chatId) ? 'ピン留めしました' : 'ピン留めを解除しました'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context, Map<String, dynamic> chat) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('${chat['name']}との会話とユーザー情報を完全に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showContextMenu(BuildContext context, Offset position, Map<String, dynamic> chat) {
    final isPinned = _pinnedChats.contains(chat['id']);
    
    showMenu<String>(
      context: context,
      position: position == Offset.zero 
        ? RelativeRect.fromLTRB(100, 200, 100, 200)
        : RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem<String>(
          value: 'preview',
          child: ListTile(
            leading: const Icon(Icons.preview),
            title: const Text('プレビュー'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'mute',
          child: ListTile(
            leading: const Icon(Icons.notifications_off),
            title: const Text('通知オフ'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'hide',
          child: ListTile(
            leading: const Icon(Icons.visibility_off),
            title: const Text('非表示'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'pin',
          child: ListTile(
            leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(isPinned ? 'ピン留め解除' : 'ピン留め'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'tags',
          child: ListTile(
            leading: const Icon(Icons.label),
            title: const Text('タグ管理'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'block',
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: const Text('ブロック', style: TextStyle(color: Colors.orange)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('削除', style: TextStyle(color: Colors.red)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'preview':
            _showCustomerDetails(context, chat);
            break;
          case 'mute':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('通知をオフにしました')),
            );
            break;
          case 'hide':
            setState(() {
              _hiddenChats.add(chat['id']);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${chat['name']}を非表示にしました'),
                action: SnackBarAction(
                  label: '元に戻す',
                  onPressed: () {
                    setState(() {
                      _hiddenChats.remove(chat['id']);
                    });
                  },
                ),
              ),
            );
            break;
          case 'pin':
            _togglePin(chat['id']);
            break;
          case 'tags':
            showDialog(
              context: context,
              builder: (context) => TagManagerDialog(
                userId: chat['id'],
                userName: chat['name'],
              ),
            );
            break;
          case 'block':
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ブロック確認'),
                content: Text('${chat['name']}をブロックしますか？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${chat['name']}をブロックしました')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('ブロック', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            break;
          case 'delete':
            _showDeleteDialog(context, chat).then((shouldDelete) {
              if (shouldDelete) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${chat['name']}を削除しました')),
                );
              }
            });
            break;
        }
      }
    });
  }

  void _showHiddenChatsDialog(BuildContext context) {
    final hiddenChatsList = _getDummyChats().where((chat) => _hiddenChats.contains(chat['id'])).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('非表示リスト'),
            Text(
              '${_hiddenChats.length}件',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        content: _hiddenChats.isEmpty
          ? const Text('非表示にしたチャットはありません')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: hiddenChatsList.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final chat = hiddenChatsList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getChannelColor(chat['channel']).withOpacity(0.2),
                      child: Text(
                        chat['name'][0],
                        style: TextStyle(
                          color: _getChannelColor(chat['channel']),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    title: Text(chat['name']),
                    subtitle: Text(
                      chat['channel'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() {
                          _hiddenChats.remove(chat['id']);
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${chat['name']}を表示に戻しました')),
                        );
                      },
                      child: const Text('表示'),
                    ),
                  );
                },
              ),
            ),
        actions: [
          if (_hiddenChats.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _hiddenChats.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('すべてのチャットを表示に戻しました')),
                );
              },
              child: const Text('すべて表示'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
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