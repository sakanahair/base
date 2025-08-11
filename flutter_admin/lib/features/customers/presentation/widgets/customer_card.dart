import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/customer.dart';
import '../../../../shared/utils/responsive_helper.dart';

class CustomerCard extends StatefulWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CustomerCard({
    super.key,
    required this.customer,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<CustomerCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : _isHovered
                    ? AppTheme.backgroundColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // アバターとステータス
                _buildAvatar(),
                const SizedBox(width: 12),
                
                // 顧客情報
                Expanded(
                  child: _buildCustomerInfo(),
                ),
                
                // 右側のアクションとバッジ
                _buildTrailing(),
              ],
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).shimmer(
          duration: widget.customer.isTyping ? 2000.ms : 0.ms,
          color: widget.customer.isTyping 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.customer.isVip
                  ? [Colors.amber.shade300, Colors.amber.shade600]
                  : [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.customer.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    widget.customer.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        
        // オンラインステータス
        if (widget.customer.status == CustomerStatus.online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).scale(
              duration: 1000.ms,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              curve: Curves.easeInOut,
            ),
          ),
          
        // VIPバッジ
        if (widget.customer.isVip)
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // チャットソースに応じた色
  Color _getChatSourceColor(ChatSource source) {
    switch (source) {
      case ChatSource.line:
        return const Color(0xFF00B900); // LINEグリーン
      case ChatSource.sms:
        return Colors.blue;
      case ChatSource.app:
        return Colors.purple;
      case ChatSource.webChat:
        return Colors.orange;
    }
  }
  
  // チャットソースに応じたアイコン
  IconData _getChatSourceIcon(ChatSource source) {
    switch (source) {
      case ChatSource.line:
        return Icons.chat_bubble; // LINE
      case ChatSource.sms:
        return Icons.sms; // SMS
      case ChatSource.app:
        return Icons.phone_iphone; // アプリ
      case ChatSource.webChat:
        return Icons.language; // Webチャット
    }
  }
  
  // アクティビティタイプに応じた色
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.purchase:
        return Colors.green;
      case ActivityType.reservation:
        return Colors.blue;
      case ActivityType.call:
        return Colors.orange;
      case ActivityType.visit:
        return Colors.purple;
      case ActivityType.live:
        return Colors.red;
      case ActivityType.message:
        return Colors.teal;
    }
  }
  
  // アクティビティタイプに応じたアイコン
  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.purchase:
        return Icons.shopping_cart;
      case ActivityType.reservation:
        return Icons.calendar_today;
      case ActivityType.call:
        return Icons.phone;
      case ActivityType.visit:
        return Icons.store;
      case ActivityType.live:
        return Icons.live_tv;
      case ActivityType.message:
        return Icons.chat_bubble;
    }
  }
  
  Widget _buildDefaultAvatar() {
    final initial = widget.customer.name.isNotEmpty
        ? widget.customer.name[0].toUpperCase()
        : '?';
    
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顧客名
        Text(
          widget.customer.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        
        // 最終メッセージまたはタイピング中
        if (widget.customer.isTyping)
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 16,
                child: Stack(
                  children: List.generate(3, (index) => 
                    Positioned(
                      left: index * 12.0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
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
              ),
              const SizedBox(width: 8),
              Text(
                '入力中...',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          )
        else
          Text(
            widget.customer.lastMessage ?? 'メッセージなし',
            style: TextStyle(
              fontSize: 13,
              color: widget.customer.unreadCount > 0
                  ? AppTheme.textPrimary
                  : AppTheme.textTertiary,
              fontWeight: widget.customer.unreadCount > 0
                  ? FontWeight.w400
                  : FontWeight.w200,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        
        // タグ表示（誕生日バッジをここに表示）
        if (widget.customer.tags.isNotEmpty || widget.customer.isBirthdaySoon) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: [
              // 誕生日バッジを先頭に表示
              if (widget.customer.isBirthdaySoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cake,
                        size: 10,
                        color: Colors.pink.shade400,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '誕生日',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.pink.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              // 通常のタグ
              ...widget.customer.tags.take(widget.customer.isBirthdaySoon ? 2 : 3).map((tag) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ).toList(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 時間表示と予約バッジを横並びに
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 予約バッジ
            if (widget.customer.nextReservationAt != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event,
                      size: 12,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '予約',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            // 時間表示
            Text(
              widget.customer.lastMessageTimeDisplay,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.w200,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // チャットソースアイコンと未読バッジ
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // チャットソースアイコン（常に表示）
            ...widget.customer.activeChatSources.map((source) => 
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getChatSourceColor(source).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getChatSourceIcon(source),
                    size: 14,
                    color: _getChatSourceColor(source),
                  ),
                ),
              ),
            ).toList(),
            
            // 未読バッジ（チャットソースアイコン付き、色を対応するチャットソースに合わせる）
            if (widget.customer.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _getChatSourceColor(widget.customer.primaryChatSource),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _getChatSourceColor(widget.customer.primaryChatSource).withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 未読メッセージのソースアイコン
                    Icon(
                      _getChatSourceIcon(widget.customer.primaryChatSource),
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 3),
                    // 未読数
                    Text(
                      widget.customer.unreadCount > 99 
                          ? '99+' 
                          : widget.customer.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}