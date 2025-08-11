import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';

class ChatConversationPage extends StatefulWidget {
  final String chatId;
  
  const ChatConversationPage({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _selectedChannel = 'LINE';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF93AAD4), // LINE風背景色
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leadingWidth: 40,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF00B900),
              child: const Text(
                '田',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '田中 太郎',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00B900),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'オンライン',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('プロフィール'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('検索'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.notifications_off),
                  title: Text('通知OFF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // チャンネル切り替え
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'チャンネル:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                ..._buildChannelChips(themeService),
              ],
            ),
          ),
          // メッセージリスト
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _getDummyMessages().length,
              itemBuilder: (context, index) {
                final message = _getDummyMessages()[index];
                return _buildMessageBubble(message, themeService);
              },
            ),
          ),
          // 入力エリア
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.grey[600],
                  onPressed: () => _showAttachmentOptions(context, themeService),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  color: Colors.grey[600],
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'メッセージを入力',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _isTyping = text.isNotEmpty;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isTyping ? themeService.primaryColor : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isTyping ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _isTyping ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildChannelChips(ThemeService themeService) {
    final channels = ['LINE', 'SMS', 'App', 'WebChat'];
    return channels.map((channel) {
      final isSelected = _selectedChannel == channel;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(channel),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedChannel = channel;
            });
          },
          selectedColor: _getChannelColor(channel).withOpacity(0.2),
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: isSelected ? _getChannelColor(channel) : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ? _getChannelColor(channel) : Colors.grey[300]!,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        ),
      );
    }).toList();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, ThemeService themeService) {
    final isMe = message['isMe'];
    final hasRead = message['hasRead'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00B900),
              child: Text(
                message['sender'][0],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message['type'] == 'text')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF7EC855) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      message['content'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  )
                else if (message['type'] == 'image')
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 200,
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else if (message['type'] == 'sticker')
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions,
                      size: 80,
                      color: Colors.orange,
                    ),
                  )
                else if (message['type'] == 'rich')
                  _buildRichMessage(message['content'], themeService),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message['time'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        hasRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: hasRead ? Colors.blue : Colors.grey,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildRichMessage(Map<String, dynamic> content, ThemeService themeService) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content['image'] != null)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content['buttons'] != null) ...[
                  const SizedBox(height: 8),
                  ...List.generate(
                    content['buttons'].length,
                    (index) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeService.primaryColor,
                          side: BorderSide(color: themeService.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          content['buttons'][index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: '画像',
                  color: Colors.green,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'カメラ',
                  color: Colors.blue,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'ファイル',
                  color: Colors.purple,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: '位置情報',
                  color: Colors.orange,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.contact_phone,
                  label: '連絡先',
                  color: Colors.teal,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.card_giftcard,
                  label: 'クーポン',
                  color: Colors.red,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.calendar_today,
                  label: '予約',
                  color: Colors.indigo,
                  onTap: () {},
                ),
                _buildAttachmentOption(
                  icon: Icons.web,
                  label: 'リッチ',
                  color: themeService.primaryColor,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      // メッセージ送信処理
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
    }
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

  List<Map<String, dynamic>> _getDummyMessages() {
    return [
      {
        'id': '1',
        'sender': '田中太郎',
        'content': 'こんにちは！明日の予約の件ですが、時間変更は可能でしょうか？',
        'time': '14:20',
        'isMe': false,
        'hasRead': true,
        'type': 'text',
      },
      {
        'id': '2',
        'sender': 'Me',
        'content': 'こんにちは田中様！もちろん可能です。何時頃がご希望でしょうか？',
        'time': '14:22',
        'isMe': true,
        'hasRead': true,
        'type': 'text',
      },
      {
        'id': '3',
        'sender': '田中太郎',
        'content': '15時から16時の間でお願いできますか？',
        'time': '14:25',
        'isMe': false,
        'hasRead': true,
        'type': 'text',
      },
      {
        'id': '4',
        'sender': 'Me',
        'content': {
          'title': '予約変更完了',
          'description': '明日15:00からの予約に変更しました',
          'image': true,
          'buttons': ['詳細を見る', '予約をキャンセル'],
        },
        'time': '14:28',
        'isMe': true,
        'hasRead': true,
        'type': 'rich',
      },
      {
        'id': '5',
        'sender': '田中太郎',
        'content': null,
        'time': '14:29',
        'isMe': false,
        'hasRead': true,
        'type': 'sticker',
      },
      {
        'id': '6',
        'sender': '田中太郎',
        'content': 'ありがとうございます！明日楽しみにしています',
        'time': '14:30',
        'isMe': false,
        'hasRead': false,
        'type': 'text',
      },
    ];
  }
}