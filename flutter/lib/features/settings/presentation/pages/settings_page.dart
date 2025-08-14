import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/image_service.dart';

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
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'アプリケーションの設定を管理します',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
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
              title: 'システム',
              items: [
                _SettingsItem(
                  icon: Icons.storage,
                  iconColor: Colors.purple,
                  title: 'ストレージ管理',
                  subtitle: 'キャッシュとデータの管理',
                  onTap: () => _showStorageDialog(context),
                ),
                _SettingsItem(
                  icon: Icons.backup,
                  iconColor: Colors.teal,
                  title: 'バックアップ',
                  subtitle: 'データのバックアップと復元',
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

  // ストレージ管理ダイアログ
  void _showStorageDialog(BuildContext context) async {
    // LocalStorageの使用状況を計算
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int totalSize = 0;
    Map<String, int> breakdown = {};
    
    for (final key in keys) {
      final value = prefs.get(key);
      final size = value.toString().length;
      totalSize += size;
      
      // カテゴリ別に集計
      if (key.startsWith('sakana_images_')) {
        breakdown['画像データ'] = (breakdown['画像データ'] ?? 0) + size;
      } else if (key.startsWith('sakana_customers')) {
        breakdown['顧客データ'] = (breakdown['顧客データ'] ?? 0) + size;
      } else if (key.startsWith('theme_')) {
        breakdown['テーマ設定'] = (breakdown['テーマ設定'] ?? 0) + size;
      } else {
        breakdown['その他'] = (breakdown['その他'] ?? 0) + size;
      }
    }
    
    // ダイアログ表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ストレージ管理'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 使用状況サマリー
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '総使用量',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(totalSize / 1024).toStringAsFixed(1)} KB / 10,000 KB',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalSize / (10 * 1024 * 1024), // 10MBを上限として表示
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        totalSize > 8 * 1024 * 1024 
                          ? Colors.red 
                          : totalSize > 6 * 1024 * 1024 
                            ? Colors.orange 
                            : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // カテゴリ別使用量
              const Text(
                'カテゴリ別使用量',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              ...breakdown.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('${(entry.value / 1024).toStringAsFixed(1)} KB'),
                  ],
                ),
              )).toList(),
              
              const SizedBox(height: 16),
              
              // 警告メッセージ
              if (totalSize > 6 * 1024 * 1024)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ストレージ容量が残り少なくなっています',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (breakdown.containsKey('画像データ'))
            TextButton(
              onPressed: () async {
                // 画像キャッシュをクリア
                final imageService = Provider.of<ImageService>(context, listen: false);
                await imageService.clearCache();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('画像キャッシュをクリアしました')),
                );
              },
              child: const Text('画像キャッシュをクリア'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              // 全データをクリア（設定を除く）
              final keysToRemove = keys.where((key) => 
                !key.startsWith('theme_') && 
                !key.startsWith('is_dark_mode') &&
                !key.startsWith('font_')
              ).toList();
              
              for (final key in keysToRemove) {
                await prefs.remove(key);
              }
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('キャッシュをクリアしました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('全キャッシュをクリア'),
          ),
        ],
      ),
    );
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