import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/global_modal_service.dart';
import '../../core/theme/app_theme.dart';

class ChatModal extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String channel;

  const ChatModal({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.channel,
  });

  @override
  State<ChatModal> createState() => _ChatModalState();
}

class _ChatModalState extends State<ChatModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  String _selectedChannel = '';
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _selectedChannel = widget.channel;
    _loadMockMessages();
    
    // 初期スクロール位置を最下部に
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }
  
  void _loadMockMessages() {
    // モックメッセージデータ
    _messages = [
      ChatMessage(
        id: '1',
        text: 'こんにちは！本日はどのようなご用件でしょうか？',
        isFromCustomer: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        channel: _selectedChannel,
      ),
      ChatMessage(
        id: '2',
        text: '次回の予約を取りたいのですが',
        isFromCustomer: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        channel: _selectedChannel,
      ),
      ChatMessage(
        id: '3',
        text: 'かしこまりました。ご希望の日時はございますか？',
        isFromCustomer: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        channel: _selectedChannel,
      ),
      ChatMessage(
        id: '4',
        text: '来週の土曜日の午後はどうでしょうか？',
        isFromCustomer: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        channel: _selectedChannel,
      ),
      ChatMessage(
        id: '5',
        text: '来週土曜日の14:00からお時間が空いております。いかがでしょうか？',
        isFromCustomer: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        channel: _selectedChannel,
      ),
      ChatMessage(
        id: '6',
        text: 'それでお願いします！',
        isFromCustomer: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        channel: _selectedChannel,
      ),
    ];
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: screenSize.width * 0.9,
        height: screenSize.height * 0.85,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.customerName.isNotEmpty ? widget.customerName[0] : '?',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getChannelLabel(_selectedChannel),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // チャンネル切替
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    onSelected: (value) {
                      setState(() {
                        _selectedChannel = value;
                      });
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'LINE', child: Text('LINE')),
                      const PopupMenuItem(value: 'SMS', child: Text('SMS')),
                      const PopupMenuItem(value: 'App', child: Text('App')),
                      const PopupMenuItem(value: 'WebChat', child: Text('WebChat')),
                    ],
                  ),
                  // 顧客詳細ボタン
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                      GlobalModalService.showCustomerDetail(
                        context,
                        customerId: widget.customerId,
                        customerName: widget.customerName,
                      );
                    },
                    tooltip: '顧客詳細',
                  ),
                  // 閉じるボタン
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '閉じる',
                  ),
                ],
              ),
            ),
            
            // メッセージエリア
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == _messages.length) {
                      return _buildTypingIndicator();
                    }
                    
                    final message = _messages[index];
                    return _buildMessageBubble(message, themeService);
                  },
                ),
              ),
            ),
            
            // クイックアクション
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickActionChip('ご予約はこちら', Icons.calendar_today),
                    const SizedBox(width: 8),
                    _buildQuickActionChip('営業時間', Icons.access_time),
                    const SizedBox(width: 8),
                    _buildQuickActionChip('アクセス', Icons.location_on),
                    const SizedBox(width: 8),
                    _buildQuickActionChip('メニュー', Icons.menu_book),
                  ],
                ),
              ),
            ),
            
            // 入力エリア
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 添付ボタン
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // TODO: ファイル添付処理
                    },
                    tooltip: 'ファイル添付',
                  ),
                  // 絵文字ボタン
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: () {
                      // TODO: 絵文字ピッカー表示
                    },
                    tooltip: '絵文字',
                  ),
                  // テキスト入力
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 送信ボタン
                  Container(
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                      tooltip: '送信',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message, ThemeService themeService) {
    final isFromCustomer = message.isFromCustomer;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isFromCustomer) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                widget.customerName[0],
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromCustomer 
                  ? Colors.white 
                  : themeService.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromCustomer ? 4 : 16),
                  bottomRight: Radius.circular(isFromCustomer ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isFromCustomer ? Colors.black87 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getChannelIcon(message.channel),
                        size: 12,
                        color: isFromCustomer ? Colors.grey : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isFromCustomer ? Colors.grey : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (!isFromCustomer) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: themeService.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.support_agent,
                size: 16,
                color: themeService.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            child: Text(
              widget.customerName[0],
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
  
  Widget _buildQuickActionChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        setState(() {
          _messageController.text = label;
        });
        _focusNode.requestFocus();
      },
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: _messageController.text.trim(),
      isFromCustomer: false,
      timestamp: DateTime.now(),
      channel: _selectedChannel,
    );
    
    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });
    
    // スクロールを最下部へ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // 擬似的な返信を生成
    _simulateReply();
  }
  
  void _simulateReply() {
    setState(() {
      _isTyping = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            text: 'ご連絡ありがとうございます。確認して折り返しご連絡いたします。',
            isFromCustomer: true,
            timestamp: DateTime.now(),
            channel: _selectedChannel,
          ),
        );
      });
      
      // スクロールを最下部へ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }
  
  String _getChannelLabel(String channel) {
    switch (channel) {
      case 'LINE':
        return 'LINE';
      case 'SMS':
        return 'SMS';
      case 'App':
        return 'アプリ';
      case 'WebChat':
        return 'Webチャット';
      default:
        return channel;
    }
  }
  
  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'LINE':
        return Icons.chat_bubble;
      case 'SMS':
        return Icons.sms;
      case 'App':
        return Icons.phone_android;
      case 'WebChat':
        return Icons.web;
      default:
        return Icons.chat;
    }
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isFromCustomer;
  final DateTime timestamp;
  final String channel;
  
  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromCustomer,
    required this.timestamp,
    required this.channel,
  });
}