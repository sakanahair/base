import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedQRType = 'friend';
  String _customMessage = '';
  bool _autoReply = true;
  bool _collectInfo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.primaryColor,
        foregroundColor: themeService.onPrimaryColor,
        title: const Text('QRコード生成'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: themeService.onPrimaryColor,
          labelColor: themeService.onPrimaryColor,
          unselectedLabelColor: themeService.onPrimaryColor.withOpacity(0.7),
          tabs: const [
            Tab(text: '友だち追加'),
            Tab(text: 'クーポン'),
            Tab(text: 'イベント'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendQRTab(themeService),
          _buildCouponQRTab(themeService),
          _buildEventQRTab(themeService),
        ],
      ),
    );
  }

  Widget _buildFriendQRTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // QRコード表示エリア
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_2,
                            size: 180,
                            color: Colors.black87,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'QRコード',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(),
                  const SizedBox(height: 20),
                  Text(
                    'SAKANA HAIR 公式LINE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'このQRコードをスキャンして友だち追加',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download),
                        label: const Text('ダウンロード'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.primaryColor,
                          foregroundColor: themeService.onPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text('共有'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeService.primaryColor,
                          side: BorderSide(color: themeService.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 設定エリア
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '友だち追加時の設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // あいさつメッセージ
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'あいさつメッセージ',
                      hintText: '友だち追加ありがとうございます！\n初回限定クーポンをプレゼント中です',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customMessage = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 自動返信
                  SwitchListTile(
                    title: const Text('自動返信を有効にする'),
                    subtitle: Text(
                      '友だち追加時に自動でメッセージを送信',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    value: _autoReply,
                    onChanged: (value) {
                      setState(() {
                        _autoReply = value;
                      });
                    },
                    activeColor: themeService.primaryColor,
                  ),
                  
                  // 情報収集
                  SwitchListTile(
                    title: const Text('プロフィール情報を収集'),
                    subtitle: Text(
                      '名前やメールアドレスを自動収集',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    value: _collectInfo,
                    onChanged: (value) {
                      setState(() {
                        _collectInfo = value;
                      });
                    },
                    activeColor: themeService.primaryColor,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // タグ設定
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'タグ設定',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: const Text('QR経由'),
                            backgroundColor: themeService.primaryColorBackground,
                            labelStyle: TextStyle(
                              color: themeService.primaryColor,
                              fontSize: 12,
                            ),
                          ),
                          Chip(
                            label: const Text('新規顧客'),
                            backgroundColor: Colors.green.withOpacity(0.1),
                            labelStyle: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          ActionChip(
                            label: const Text('+ タグを追加'),
                            onPressed: () {},
                            backgroundColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 統計情報
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QRコード統計',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.qr_code_scanner,
                          label: 'スキャン数',
                          value: '1,234',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.person_add,
                          label: '友だち追加',
                          value: '892',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.trending_up,
                          label: '追加率',
                          value: '72.3%',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.block,
                          label: 'ブロック率',
                          value: '2.1%',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponQRTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'クーポンQRコード',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '特別クーポンを配布できるQRコードを生成',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      foregroundColor: themeService.onPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('クーポンQRを作成'),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildEventQRTab(ThemeService themeService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.event,
                    size: 80,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'イベントQRコード',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'イベント参加者用の特別なQRコードを生成',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeService.primaryColor,
                      foregroundColor: themeService.onPrimaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('イベントQRを作成'),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }
}