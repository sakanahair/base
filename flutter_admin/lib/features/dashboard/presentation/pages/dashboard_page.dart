import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ダッシュボード',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 4),
                    Text(
                      '今日は${_dateFormat.format(DateTime.now())}です',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text('レポート出力'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 1);
                final aspectRatio = isDesktop ? 1.5 : (isTablet ? 1.8 : 2.5);
                
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                  children: [
                    StatCard(
                      title: '本日の予約',
                      value: '12',
                      subtitle: '件',
                      icon: Icons.calendar_today,
                      color: AppTheme.infoColor,
                      trend: 20,
                    ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9)),
                    StatCard(
                      title: '本日の売上',
                      value: '¥125,400',
                      subtitle: '',
                      icon: Icons.attach_money,
                      color: AppTheme.successColor,
                      trend: 15,
                    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                    StatCard(
                      title: '新規顧客',
                      value: '8',
                      subtitle: '名',
                      icon: Icons.person_add,
                      color: AppTheme.warningColor,
                      trend: -5,
                    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
                    StatCard(
                      title: 'キャンセル率',
                      value: '2.3',
                      subtitle: '%',
                      icon: Icons.cancel,
                      color: AppTheme.errorColor,
                      trend: -10,
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Charts and Lists
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Chart
                Expanded(
                  flex: isDesktop ? 2 : 1,
                  child: const RevenueChartCard()
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
                
                if (isDesktop) ...[
                  const SizedBox(width: 24),
                  // Recent Appointments
                  Expanded(
                    flex: 1,
                    child: const RecentAppointmentsCard()
                        .animate()
                        .fadeIn(delay: 600.ms)
                        .slideY(begin: 0.1, end: 0),
                  ),
                ],
              ],
            ),
            
            if (!isDesktop) ...[
              const SizedBox(height: 24),
              const RecentAppointmentsCard()
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ],
            
            const SizedBox(height: 32),
            
            // Quick Actions
            Text(
              'クイックアクション',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 700.ms),
            
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionChip(
                  icon: Icons.add,
                  label: '新規予約',
                  color: AppTheme.infoColor,
                  onTap: () {},
                ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                _buildQuickActionChip(
                  icon: Icons.person_add,
                  label: '顧客登録',
                  color: AppTheme.successColor,
                  onTap: () {},
                ).animate().fadeIn(delay: 850.ms).scale(begin: const Offset(0.9, 0.9)),
                _buildQuickActionChip(
                  icon: Icons.message,
                  label: 'メッセージ送信',
                  color: AppTheme.warningColor,
                  onTap: () {},
                ).animate().fadeIn(delay: 900.ms).scale(begin: const Offset(0.9, 0.9)),
                _buildQuickActionChip(
                  icon: Icons.campaign,
                  label: 'キャンペーン作成',
                  color: AppTheme.errorColor,
                  onTap: () {},
                ).animate().fadeIn(delay: 950.ms).scale(begin: const Offset(0.9, 0.9)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
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