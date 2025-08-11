import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/customer.dart';
import '../../../../shared/utils/responsive_helper.dart';

class CustomerChatView extends StatefulWidget {
  final Customer customer;
  final VoidCallback onBack;

  const CustomerChatView({
    super.key,
    required this.customer,
    required this.onBack,
  });

  @override
  State<CustomerChatView> createState() => _CustomerChatViewState();
}

class _CustomerChatViewState extends State<CustomerChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  
  // デモメッセージ
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      text: 'こんにちは！本日予約したいのですが、空いてますか？',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    ChatMessage(
      id: '2',
      text: 'お問い合わせありがとうございます！本日の14時以降でしたら空きがございます。',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      isRead: true,
    ),
    ChatMessage(
      id: '3',
      text: '14時でお願いします！',
      isMe: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      isRead: true,
    ),
    ChatMessage(
      id: '4',
      text: 'かしこまりました。14時でご予約を承りました。ご来店お待ちしております。',
      isMe: true,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
      isRead: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: _messageController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
      _messageController.clear();
    });
    
    // スクロールを最下部へ
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
    
    ResponsiveHelper.addHapticFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    // モバイルの場合は別画面として表示
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildAppBar(true),
        body: Column(
          children: [
            // メッセージリスト
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _MessageBubble(
                    message: message,
                    showAvatar: index == 0 || 
                        _messages[index - 1].isMe != message.isMe,
                  );
                },
              ),
            ),
            
            // タイピングインジケーター
            if (widget.customer.isTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.customer.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: List.generate(3, (index) => 
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).scale(
                            duration: 600.ms,
                            delay: (index * 100).ms,
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // メッセージ入力エリア
            _buildMessageComposer(),
          ],
        ),
      );
    }
    
    // デスクトップの場合は埋め込み表示
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          _buildAppBar(false),
          Expanded(
            child: Column(
              children: [
                // メッセージリスト
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _MessageBubble(
                        message: message,
                        showAvatar: index == 0 || 
                            _messages[index - 1].isMe != message.isMe,
                      );
                    },
                  ),
                ),
                
                // タイピングインジケーター
                if (widget.customer.isTyping)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.customer.name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: List.generate(3, (index) => 
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.textTertiary,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(
                                onPlay: (controller) => controller.repeat(),
                              ).scale(
                                duration: 600.ms,
                                delay: (index * 100).ms,
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // メッセージ入力エリア
                _buildMessageComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: isMobile
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: widget.onBack,
            )
          : null,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          // アバター
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.customer.isVip
                    ? [Colors.amber.shade300, Colors.amber.shade600]
                    : [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
            ),
            child: Center(
              child: Text(
                widget.customer.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // 名前とステータス
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.name,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                widget.customer.status == CustomerStatus.online
                    ? 'オンライン'
                    : '最終アクセス: ${widget.customer.lastMessageTimeDisplay}',
                style: TextStyle(
                  color: widget.customer.status == CustomerStatus.online
                      ? Colors.green
                      : AppTheme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.phone_outlined, color: AppTheme.textPrimary),
          onPressed: () {
            // 電話
          },
        ),
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: AppTheme.textPrimary),
          onPressed: () {
            // ビデオ通話
          },
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: AppTheme.textPrimary),
          onPressed: () {
            // 顧客情報
          },
        ),
      ],
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 添付ボタン
          IconButton(
            icon: Icon(Icons.attach_file, color: AppTheme.textTertiary),
            onPressed: () {
              // ファイル添付
            },
          ),
          
          // 画像ボタン
          IconButton(
            icon: Icon(Icons.image_outlined, color: AppTheme.textTertiary),
            onPressed: () {
              // 画像添付
            },
          ),
          
          // メッセージ入力フィールド
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              onChanged: (text) {
                setState(() {
                  _isTyping = text.isNotEmpty;
                });
              },
              decoration: InputDecoration(
                hintText: 'メッセージを入力...',
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w200,
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // 送信ボタン
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isTyping ? 48 : 0,
            child: _isTyping
                ? IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _sendMessage,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.isRead,
  });
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const _MessageBubble({
    required this.message,
    required this.showAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: message.isMe ? 48 : 0,
        right: message.isMe ? 0 : 48,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe && showAvatar)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: const Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            )
          else if (!message.isMe)
            const SizedBox(width: 40),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isMe 
                    ? AppTheme.primaryColor 
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isMe ? 20 : 4),
                  bottomRight: Radius.circular(message.isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
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
                      color: message.isMe ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: message.isMe 
                              ? Colors.white.withOpacity(0.7) 
                              : AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      if (message.isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead 
                              ? Icons.done_all 
                              : Icons.done,
                          size: 14,
                          color: message.isRead 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
}