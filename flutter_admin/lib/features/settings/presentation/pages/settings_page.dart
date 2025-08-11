import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              '設定',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'アプリケーションの設定を管理します',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Settings Sections
            _buildSettingsSection(
              context,
              title: 'アプリケーション',
              items: [
                _SettingsItem(
                  icon: Icons.palette,
                  iconColor: themeService.primaryColor,
                  title: 'テーマカラー',
                  subtitle: 'アクセントカラーをカスタマイズ',
                  onTap: () => context.go('/settings/theme'),
                ),
                _SettingsItem(
                  icon: Icons.language,
                  iconColor: Colors.blue,
                  title: '言語設定',
                  subtitle: '表示言語の変更',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.notifications,
                  iconColor: Colors.orange,
                  title: '通知設定',
                  subtitle: 'プッシュ通知の管理',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              context,
              title: 'ビジネス設定',
              items: [
                _SettingsItem(
                  icon: Icons.store,
                  iconColor: Colors.green,
                  title: '店舗情報',
                  subtitle: '基本情報の編集',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.schedule,
                  iconColor: Colors.purple,
                  title: '営業時間',
                  subtitle: '営業日・営業時間の設定',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.payment,
                  iconColor: Colors.teal,
                  title: '決済設定',
                  subtitle: '支払い方法の管理',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              context,
              title: '連携サービス',
              items: [
                _SettingsItem(
                  icon: Icons.chat_bubble,
                  iconColor: const Color(0xFF00B900),
                  title: 'LINE設定',
                  subtitle: 'LINE公式アカウントの連携',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.message,
                  iconColor: Colors.blue,
                  title: 'SMS設定',
                  subtitle: 'SMS配信サービスの設定',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.smart_toy,
                  iconColor: Colors.indigo,
                  title: 'AI設定',
                  subtitle: 'AI機能の設定',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildSettingsSection(
              context,
              title: 'システム',
              items: [
                _SettingsItem(
                  icon: Icons.backup,
                  iconColor: Colors.grey[700]!,
                  title: 'バックアップ',
                  subtitle: 'データのバックアップと復元',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.security,
                  iconColor: Colors.red,
                  title: 'セキュリティ',
                  subtitle: 'パスワードと認証設定',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.info,
                  iconColor: Colors.blueGrey,
                  title: 'アプリ情報',
                  subtitle: 'バージョンとライセンス',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.borderColor),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 20,
                      ),
                    ),
                    title: Text(item.title),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.grey,
                    ),
                    onTap: item.onTap,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppTheme.borderColor,
                    ),
                ],
              );
            }).toList(),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}