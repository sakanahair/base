import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../widgets/customer_card.dart';
import '../../../../core/models/customer.dart';
import '../../../../core/services/customer_service.dart';
import '../../../../core/services/mock_customer_service.dart';

enum ViewMode { list, chat, split }

class CustomersSplitPage extends StatefulWidget {
  const CustomersSplitPage({super.key});

  @override
  State<CustomersSplitPage> createState() => _CustomersSplitPageState();
}

class _CustomersSplitPageState extends State<CustomersSplitPage> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  ViewMode _viewMode = ViewMode.split;
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  void _loadCustomers() {
    setState(() {
      _customers = MockCustomerService.generateMockCustomers(count: 20);
      if (_customers.isNotEmpty) {
        _selectedCustomer = _customers.first;
        _loadChatHistory();
      }
    });
  }

  void _loadChatHistory() {
    if (_selectedCustomer == null) return;
    
    setState(() {
      _messages.clear();
      _messages.addAll([
        ChatMessage(
          text: 'こんにちは！前回のご来店ありがとうございました。',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ChatMessage(
          text: '次回の予約をお願いしたいです',
          isUser: true,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ChatMessage(
          text: '承知いたしました。ご希望の日時をお知らせください。',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ]);
    });
  }

  List<Customer> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) =>
      customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      customer.primaryChatSource.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Header with view mode switcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: '顧客を検索...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // View mode toggle
                if (!isMobile)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _ViewModeButton(
                          icon: Icons.list,
                          tooltip: 'リスト表示',
                          isActive: _viewMode == ViewMode.list,
                          onPressed: () {
                            setState(() {
                              _viewMode = ViewMode.list;
                            });
                          },
                        ),
                        Container(width: 1, height: 24, color: AppTheme.borderColor),
                        _ViewModeButton(
                          icon: Icons.chat_bubble_outline,
                          tooltip: 'チャット表示',
                          isActive: _viewMode == ViewMode.chat,
                          onPressed: () {
                            setState(() {
                              _viewMode = ViewMode.chat;
                            });
                          },
                        ),
                        Container(width: 1, height: 24, color: AppTheme.borderColor),
                        _ViewModeButton(
                          icon: Icons.splitscreen,
                          tooltip: '分割表示',
                          isActive: _viewMode == ViewMode.split,
                          onPressed: () {
                            setState(() {
                              _viewMode = ViewMode.split;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: _buildMainContent(isMobile, isTablet, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isTablet, bool isDesktop) {
    if (isMobile) {
      // Mobile: Tab-based navigation
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryColor,
                tabs: [
                  Tab(text: '顧客リスト', icon: Icon(Icons.people, size: 20)),
                  Tab(text: 'チャット', icon: Icon(Icons.chat, size: 20)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCustomerList(isMobile: true),
                  _selectedCustomer != null 
                      ? _buildChatView()
                      : _buildEmptyChat(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Desktop/Tablet: Split or single view based on mode
    switch (_viewMode) {
      case ViewMode.list:
        return _buildCustomerList();
      case ViewMode.chat:
        return _selectedCustomer != null 
            ? _buildChatView()
            : _buildEmptyChat();
      case ViewMode.split:
      default:
        return Row(
          children: [
            // Customer list (left side)
            Container(
              width: isDesktop ? 400 : 320,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: _buildCustomerList(),
            ),
            // Chat view (right side)
            Expanded(
              child: _selectedCustomer != null 
                  ? _buildChatView()
                  : _buildEmptyChat(),
            ),
          ],
        );
    }
  }

  Widget _buildCustomerList({bool isMobile = false}) {
    final filteredCustomers = _filteredCustomers;
    
    if (filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? '顧客がいません' : '検索結果がありません',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          final isSelected = customer.id == _selectedCustomer?.id;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCustomer = customer;
                  _loadChatHistory();
                });
                if (isMobile) {
                  // Switch to chat tab on mobile
                  DefaultTabController.of(context).animateTo(1);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: CustomerCard(
                customer: customer,
                onTap: () {
                  setState(() {
                    _selectedCustomer = customer;
                    _loadChatHistory();
                  });
                  if (isMobile) {
                    DefaultTabController.of(context).animateTo(1);
                  }
                },
              ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms);
        },
      ),
    );
  }

  Widget _buildChatView() {
    if (_selectedCustomer == null) return _buildEmptyChat();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCustomer!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            _getChatSourceIcon(_selectedCustomer!.primaryChatSource),
                            size: 14,
                            color: _getChatSourceColor(_selectedCustomer!.primaryChatSource),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCustomer!.primaryChatSource.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'オンライン',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.videocam),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppTheme.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '顧客を選択してチャットを開始',
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? AppTheme.primaryColor 
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser 
                    ? Colors.white.withOpacity(0.7) 
                    : AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: _messageController.text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
    });

    // Simulate response
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(ChatMessage(
          text: 'ご連絡ありがとうございます。確認して折り返しご連絡いたします。',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  IconData _getChatSourceIcon(ChatSource source) {
    switch (source) {
      case ChatSource.line:
        return Icons.chat_bubble;
      case ChatSource.sms:
        return Icons.message;
      case ChatSource.app:
        return Icons.phone_android;
      case ChatSource.webChat:
        return Icons.computer;
    }
  }

  Color _getChatSourceColor(ChatSource source) {
    switch (source) {
      case ChatSource.line:
        return Colors.green;
      case ChatSource.sms:
        return Colors.blue;
      case ChatSource.app:
        return Colors.purple;
      case ChatSource.webChat:
        return Colors.orange;
    }
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewModeButton({
    required this.icon,
    required this.tooltip,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          child: Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}