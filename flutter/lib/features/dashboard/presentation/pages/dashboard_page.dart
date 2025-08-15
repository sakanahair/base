import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../../../core/utils/ios_safe_area_helper.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_appointments_card.dart';
import '../widgets/revenue_chart_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _dateFormat = DateFormat('yyyy年MM月dd日');
  
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IOSSafeAreaHelper.wrapWithSafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (context.isTouchDevice) {
              ResponsiveHelper.addHapticFeedback();
            }
            // TODO: Implement refresh logic
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            padding: isMobile 
              ? const EdgeInsets.all(12.0) // モバイルでは小さめのパディング
              : context.responsivePadding,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context, isMobile, isTablet),
              
                SizedBox(height: context.responsiveSpacing),
                
                // Stats Grid
                _buildStatsGrid(context, isMobile, isTablet, isDesktop),
              
                SizedBox(height: context.responsiveSpacing),
                
                // Charts and Lists
                _buildChartsSection(context, isMobile, isDesktop),
              
                SizedBox(height: context.responsiveSpacing),
                
                // Quick Actions (Desktop only - mobile uses FAB)
                if (isDesktop) _buildQuickActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context, bool isMobile, bool isTablet) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ダッシュボード',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
            const SizedBox(height: 4),
            Text(
              '今日は${_dateFormat.format(DateTime.now())}です',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 100.ms),
          ],
        ),
        
        if (isMobile) const SizedBox(height: 16),
        
        if (!isMobile)
          SizedBox(
            width: 150,
            child: ElevatedButton.icon(
              onPressed: () {
                if (context.isTouchDevice) {
                  ResponsiveHelper.addHapticFeedback();
                }
                // TODO: Export report
              },
              icon: Icon(Icons.download, size: context.responsiveIconSize),
              label: const Text('レポート出力'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 20,
                  vertical: 12,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
          ),
      ],
    );
  }
  
  Widget _buildStatsGrid(BuildContext context, bool isMobile, bool isTablet, bool isDesktop) {
    final crossAxisCount = ResponsiveHelper.getGridColumnCount(
      context,
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
    );
    
    final aspectRatio = ResponsiveHelper.getCardAspectRatio(context);
    
    final stats = [
      _StatData(
        title: '本日の予約',
        value: '12',
        subtitle: '件',
        icon: Icons.calendar_today,
        color: AppTheme.infoColor,
        trend: 20.0,
      ),
      _StatData(
        title: '本日の売上',
        value: '¥125,400',
        subtitle: '',
        icon: Icons.attach_money,
        color: AppTheme.successColor,
        trend: 15.0,
      ),
      _StatData(
        title: '新規顧客',
        value: '8',
        subtitle: '名',
        icon: Icons.person_add,
        color: AppTheme.warningColor,
        trend: -5.0,
      ),
      _StatData(
        title: 'キャンセル率',
        value: '2.3',
        subtitle: '%',
        icon: Icons.cancel,
        color: AppTheme.errorColor,
        trend: -10.0,
      ),
    ];
    
    if (isMobile) {
      // On mobile, show cards in a column with larger touch targets
      return Column(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: StatCard(
              title: stat.title,
              value: stat.value,
              subtitle: stat.subtitle,
              icon: stat.icon,
              color: stat.color,
              trend: stat.trend,
            ).animate()
                .fadeIn(delay: Duration(milliseconds: 100 + index * 100))
                .scale(begin: const Offset(0.9, 0.9))
                .slideX(begin: -0.1, end: 0),
          );
        }).toList(),
      );
    } else {
      // On tablet and desktop, use grid
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: aspectRatio,
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return StatCard(
            title: stat.title,
            value: stat.value,
            subtitle: stat.subtitle,
            icon: stat.icon,
            color: stat.color,
            trend: stat.trend,
          ).animate()
              .fadeIn(delay: Duration(milliseconds: 100 + index * 100))
              .scale(begin: const Offset(0.9, 0.9));
        }).toList(),
      );
    }
  }
  
  Widget _buildChartsSection(BuildContext context, bool isMobile, bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: const RevenueChartCard()
                .animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: const RecentAppointmentsCard()
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.1, end: 0),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          const RevenueChartCard()
              .animate()
              .fadeIn(delay: 500.ms)
              .slideY(begin: 0.1, end: 0),
          SizedBox(height: context.responsiveSpacing),
          const RecentAppointmentsCard()
              .animate()
              .fadeIn(delay: 600.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      );
    }
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'クイックアクション',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ).animate().fadeIn(delay: 700.ms),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildQuickActionChip(
              context: context,
              icon: Icons.add,
              label: '新規予約',
              color: AppTheme.infoColor,
              onTap: () {},
            ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
            _buildQuickActionChip(
              context: context,
              icon: Icons.person_add,
              label: '顧客登録',
              color: AppTheme.successColor,
              onTap: () {},
            ).animate().fadeIn(delay: 850.ms).scale(begin: const Offset(0.9, 0.9)),
            _buildQuickActionChip(
              context: context,
              icon: Icons.message,
              label: 'メッセージ送信',
              color: AppTheme.warningColor,
              onTap: () {},
            ).animate().fadeIn(delay: 900.ms).scale(begin: const Offset(0.9, 0.9)),
            _buildQuickActionChip(
              context: context,
              icon: Icons.campaign,
              label: 'キャンペーン作成',
              color: AppTheme.errorColor,
              onTap: () {},
            ).animate().fadeIn(delay: 950.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildQuickActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
      child: InkWell(
        onTap: () {
          if (context.isTouchDevice) {
            ResponsiveHelper.addHapticFeedback();
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        child: Container(
          constraints: BoxConstraints(
            minHeight: ResponsiveHelper.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: context.responsiveIconSize,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double trend;
  
  _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.trend,
  });
}