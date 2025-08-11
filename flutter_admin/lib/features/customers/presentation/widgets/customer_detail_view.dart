import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/customer.dart';
import '../../../../shared/utils/responsive_helper.dart';

class CustomerDetailView extends StatefulWidget {
  final Customer customer;
  final VoidCallback onStartChat;

  const CustomerDetailView({
    super.key,
    required this.customer,
    required this.onStartChat,
  });

  @override
  State<CustomerDetailView> createState() => _CustomerDetailViewState();
}

class _CustomerDetailViewState extends State<CustomerDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    // モバイルの場合は別画面として表示
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: _buildMobileAppBar(),
        body: Column(
          children: [
            _buildActionButtons(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInsightsTab(),
                  _buildTimelineTab(),
                  _buildPurchaseHistoryTab(),
                  _buildReservationsTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // デスクトップの場合は埋め込み表示
    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          _buildActionButtons(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(),
                _buildTimelineTab(),
                _buildPurchaseHistoryTab(),
                _buildReservationsTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.customer.name,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w300,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.star,
            color: widget.customer.isVip ? Colors.amber : AppTheme.textTertiary,
          ),
          onPressed: () {
            // VIP切り替え
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: AppTheme.textPrimary),
          onPressed: () {
            // その他のアクション
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          // アバター
          Container(
            width: 80,
            height: 80,
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
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
          
          const SizedBox(width: 24),
          
          // 顧客情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.customer.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (widget.customer.isVip) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (widget.customer.email != null) ...[
                      Icon(
                        Icons.email_outlined,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.customer.email!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (widget.customer.phone != null) ...[
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.customer.phone!,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // ステータス
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.customer.displayStatus,
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'チャット',
            color: AppTheme.primaryColor,
            onPressed: widget.onStartChat,
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.phone_outlined,
            label: '電話',
            color: Colors.green,
            onPressed: () {
              // 電話をかける
            },
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.videocam_outlined,
            label: 'ビデオ',
            color: Colors.blue,
            onPressed: () {
              // ビデオ通話
            },
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.shopping_bag_outlined,
            label: 'ショップ',
            color: Colors.orange,
            onPressed: () {
              // ショップへ
            },
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.calendar_today_outlined,
            label: '予約',
            color: Colors.purple,
            onPressed: () {
              // 予約作成
            },
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textTertiary,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'インサイト'),
          Tab(text: 'タイムライン'),
          Tab(text: '購入履歴'),
          Tab(text: '予約'),
          Tab(text: 'メモ'),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 統計カード
          Row(
            children: [
              _StatCard(
                title: '総購入額',
                value: '¥${widget.customer.totalPurchaseAmount.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: '購入回数',
                value: widget.customer.purchaseCount.toString(),
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: '平均単価',
                value: widget.customer.purchaseCount > 0
                    ? '¥${(widget.customer.totalPurchaseAmount / widget.customer.purchaseCount).toStringAsFixed(0)}'
                    : '¥0',
                icon: Icons.trending_up,
                color: Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AIインサイト
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AIインサイト',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'この顧客は火曜日の午後によく連絡してきます。前回の購入から30日経過しているため、フォローアップを推奨します。',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return const Center(
      child: Text('タイムライン機能は準備中です'),
    );
  }

  Widget _buildPurchaseHistoryTab() {
    return const Center(
      child: Text('購入履歴機能は準備中です'),
    );
  }

  Widget _buildReservationsTab() {
    return const Center(
      child: Text('予約機能は準備中です'),
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'スタッフメモ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            maxLines: 10,
            initialValue: widget.customer.notes,
            decoration: InputDecoration(
              hintText: 'この顧客に関するメモを入力...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            onChanged: (value) {
              // メモを保存
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.customer.status) {
      case CustomerStatus.online:
        return Colors.green;
      case CustomerStatus.busy:
        return Colors.orange;
      case CustomerStatus.away:
        return Colors.yellow.shade700;
      case CustomerStatus.offline:
        return Colors.grey;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}