import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/customer_service.dart';
import '../../../../shared/utils/responsive_helper.dart';

class CustomerFilterBar extends StatefulWidget {
  final Function(Set<CustomerFilterType>) onFilterChanged;

  const CustomerFilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<CustomerFilterBar> createState() => _CustomerFilterBarState();
}

class _CustomerFilterBarState extends State<CustomerFilterBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? (isMobile ? 120 : 100) : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // メインバー
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 統計情報
                Consumer<CustomerService>(
                  builder: (context, service, child) {
                    return Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.people,
                          label: '全顧客',
                          value: service.totalCustomers.toString(),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.mark_email_unread,
                          label: '未読',
                          value: service.unreadCount.toString(),
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.circle,
                          label: 'オンライン',
                          value: service.onlineCount.toString(),
                          color: Colors.green,
                        ),
                        if (!isMobile) ...[
                          const SizedBox(width: 12),
                          _buildStatChip(
                            icon: Icons.star,
                            label: 'VIP',
                            value: service.vipCount.toString(),
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    );
                  },
                ),
                
                const Spacer(),
                
                // フィルター展開ボタン
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.expand_more,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // フィルターチップ
          if (_isExpanded)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<CustomerService>(
                  builder: (context, service, child) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: '全て',
                          icon: Icons.all_inclusive,
                          isSelected: service.activeFilters.contains(CustomerFilterType.all),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.all);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                        _FilterChip(
                          label: '未読のみ',
                          icon: Icons.mark_email_unread,
                          isSelected: service.activeFilters.contains(CustomerFilterType.unread),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.unread);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                        _FilterChip(
                          label: 'VIP',
                          icon: Icons.star,
                          isSelected: service.activeFilters.contains(CustomerFilterType.vip),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.vip);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                        _FilterChip(
                          label: 'オンライン',
                          icon: Icons.circle,
                          isSelected: service.activeFilters.contains(CustomerFilterType.online),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.online);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                        _FilterChip(
                          label: '予約あり',
                          icon: Icons.event,
                          isSelected: service.activeFilters.contains(CustomerFilterType.hasReservation),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.hasReservation);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                        _FilterChip(
                          label: '誕生日',
                          icon: Icons.cake,
                          isSelected: service.activeFilters.contains(CustomerFilterType.birthday),
                          onTap: () {
                            service.toggleFilter(CustomerFilterType.birthday);
                            widget.onFilterChanged(service.activeFilters);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textTertiary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ResponsiveHelper.addHapticFeedback();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor 
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected 
                    ? Colors.white 
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}