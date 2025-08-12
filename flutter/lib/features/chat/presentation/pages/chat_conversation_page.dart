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
  String _selectedAIFunction = 'チャット';
  bool _webSearchEnabled = false;
  
  // AIモデルの定義
  final List<Map<String, String>> _aiModels = [
    {'name': 'mixture', 'displayName': 'Mixture-of-Agents', 'icon': '😊'},
    {'name': 'gpt5', 'displayName': 'GPT-5', 'icon': '🌀'},
    {'name': 'gpt5pro', 'displayName': 'GPT-5 Pro', 'icon': '🌀'},
    {'name': 'o3pro', 'displayName': 'o3-pro', 'icon': '🌀'},
    {'name': 'o4mini', 'displayName': 'o4-mini-high', 'icon': '🌀'},
    {'name': 'claude-sonnet', 'displayName': 'Claude Sonnet 4', 'icon': '✳️'},
    {'name': 'claude-opus', 'displayName': 'Claude Opus 4.1', 'icon': '✳️'},
    {'name': 'gemini-flash', 'displayName': 'Gemini 2.5 Flash', 'icon': '🔷'},
    {'name': 'gemini-pro', 'displayName': 'Gemini 2.5 Pro', 'icon': '🔷'},
    {'name': 'deepseek', 'displayName': 'DeepSeek R1', 'icon': '🔷'},
    {'name': 'grok', 'displayName': 'Grok4 0709', 'icon': '⭕'},
  ];
  
  Map<String, String> _selectedModel = {'name': 'claude-opus', 'displayName': 'Claude Opus 4.1', 'icon': '✳️'};
  
  @override
  void initState() {
    super.initState();
    // chatIdからチャンネルを判定
    if (widget.chatId == 'sakana-ai') {
      _selectedChannel = 'SAKANA';
    } else if (widget.chatId == '2') {
      _selectedChannel = 'WebChat';
    } else if (widget.chatId == '3') {
      _selectedChannel = 'SMS';
    } else if (widget.chatId == '5') {
      _selectedChannel = 'App';
    } else {
      _selectedChannel = 'LINE';
    }
  }

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
      backgroundColor: _selectedChannel == 'LINE' 
        ? const Color(0xFF93AAD4) // LINE風背景色
        : Colors.white, // その他は白背景
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leadingWidth: 40,
        title: Row(
          children: [
            InkWell(
              onTap: widget.chatId != 'sakana-ai' ? () => _showCustomerDetails(context) : null,
              borderRadius: BorderRadius.circular(18),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: widget.chatId == 'sakana-ai' ? Colors.white : _getChannelColor(),
                child: widget.chatId == 'sakana-ai' 
                  ? ClipOval(
                      child: Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(6),
                        child: Image.network(
                          '/admin/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.catching_pokemon,
                              size: 24,
                              color: _getChannelColor(),
                            );
                          },
                        ),
                      ),
                    )
                  : Text(
                      '田',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatId == 'sakana-ai' ? 'SAKANA AI' : '田中 太郎',
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
                        decoration: BoxDecoration(
                          color: _getChannelColor(),
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
        actions: widget.chatId == 'sakana-ai' 
          ? [
              // モデル選択ボタン
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<Map<String, String>>(
                  onSelected: (model) {
                    setState(() {
                      _selectedModel = model;
                    });
                  },
                  itemBuilder: (context) => _aiModels.map((model) {
                    return PopupMenuItem<Map<String, String>>(
                      value: model,
                      child: Row(
                        children: [
                          Text(model['icon']!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(model['displayName']!),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedModel['icon']!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          _selectedModel['displayName']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // ウェブ検索チェックボックス
              IconButton(
                icon: Icon(
                  Icons.search,
                  color: _webSearchEnabled ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _webSearchEnabled = !_webSearchEnabled;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_webSearchEnabled ? 'ウェブ検索を有効にしました' : 'ウェブ検索を無効にしました'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'ウェブ検索',
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('会話をクリア'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('設定'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ]
          : [
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
          // チャンネル切り替え or AI機能切り替え
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  widget.chatId == 'sakana-ai' ? 'AI機能:' : 'チャンネル:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                if (widget.chatId == 'sakana-ai')
                  ..._buildAIFunctionChips(themeService)
                else
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

  List<Widget> _buildAIFunctionChips(ThemeService themeService) {
    final functions = ['チャット', '画像生成', '動画生成', '着せ替え'];
    return functions.map((function) {
      final isSelected = _selectedAIFunction == function;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedAIFunction = function;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                ? const Color(0xFF7FA8A1).withOpacity(0.2)
                : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                  ? const Color(0xFF7FA8A1)
                  : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 14,
                    color: const Color(0xFF7FA8A1),
                  ),
                if (isSelected)
                  const SizedBox(width: 4),
                Text(
                  function,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected 
                      ? const Color(0xFF7FA8A1)
                      : Colors.grey[700],
                    fontWeight: isSelected 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
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
              backgroundColor: widget.chatId == 'sakana-ai' 
                ? themeService.primaryColor 
                : (_selectedChannel == 'LINE' 
                    ? const Color(0xFF00B900)
                    : themeService.primaryColor),
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
                      color: isMe 
                        ? (_selectedChannel == 'LINE' 
                            ? const Color(0xFF7EC855) 
                            : themeService.primaryColor)
                        : Colors.white,
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

  Color _getChannelColor([String? channel]) {
    final targetChannel = channel ?? _selectedChannel;
    // くすんだ色合いのバリエーション
    switch (targetChannel) {
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


  void _showCustomerDetails(BuildContext context) {
    final customerName = widget.chatId == 'sakana-ai' ? 'SAKANA AI' : '田中 太郎';
    final channel = _selectedChannel;
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
                        customerName[0],
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
                            customerName,
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
                    _buildActionButton(Icons.chat, 'チャット', () {}),
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
                      _buildInfoRow('メール', customerName.replaceAll(' ', '').toLowerCase() + '@example.com'),
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
        'sender': widget.chatId == 'sakana-ai' ? 'あなた' : '田中太郎',
        'content': widget.chatId == 'sakana-ai' 
          ? '桜が満開の日本庭園の風景をお願いします' 
          : '15時から16時の間でお願いできますか？',
        'time': '14:25',
        'isMe': widget.chatId == 'sakana-ai' ? true : false,
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
        'sender': widget.chatId == 'sakana-ai' ? 'SAKANA AI' : '田中太郎',
        'content': widget.chatId == 'sakana-ai' 
          ? '他にも何かお手伝いできることがあればお申し付けください！\n\n動画生成、着せ替え、コード生成など様々な機能をご利用いただけます。' 
          : 'ありがとうございます！明日楽しみにしています',
        'time': '14:30',
        'isMe': widget.chatId == 'sakana-ai' ? false : false,
        'hasRead': false,
        'type': 'text',
      },
    ];
  }
}