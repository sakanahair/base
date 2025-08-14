import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/customer_service.dart';

class EnhancedCustomersPage extends StatefulWidget {
  const EnhancedCustomersPage({super.key});

  @override
  State<EnhancedCustomersPage> createState() => _EnhancedCustomersPageState();
}

class _EnhancedCustomersPageState extends State<EnhancedCustomersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedSegment = 'all';
  String _sortBy = 'recent';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final customerService = Provider.of<CustomerService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // 統計ヘッダー
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeService.primaryColor,
                  themeService.primaryColorDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // タイトルと検索
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '顧客管理',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: themeService.onPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '全${customerService.customers.length}名の顧客',
                              style: TextStyle(
                                color: themeService.onPrimaryColor.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle, 
                          color: themeService.onPrimaryColor,
                          size: 32,
                        ),
                        onPressed: () => _showAddCustomerDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 統計カード
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '新規顧客',
                          '12',
                          '今月',
                          Icons.person_add,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'アクティブ',
                          '89',
                          '過去30日',
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'VIP顧客',
                          '23',
                          '合計',
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // タブバー
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeService.primaryColor,
              labelColor: themeService.primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'すべて'),
                Tab(text: 'VIP'),
                Tab(text: '新規'),
                Tab(text: '休眠'),
              ],
            ),
          ),
          
          // 検索・フィルターバー
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '名前、電話番号、メールで検索',
                        hintStyle: const TextStyle(fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sort, size: 18),
                        SizedBox(width: 4),
                        Text('並び替え', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  onSelected: (value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'recent', child: Text('最近の活動')),
                    const PopupMenuItem(value: 'name', child: Text('名前順')),
                    const PopupMenuItem(value: 'spending', child: Text('利用金額順')),
                    const PopupMenuItem(value: 'visits', child: Text('来店回数順')),
                  ],
                ),
              ],
            ),
          ),
          
          // 顧客リスト
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCustomerList(context, 'all', themeService),
                _buildCustomerList(context, 'vip', themeService),
                _buildCustomerList(context, 'new', themeService),
                _buildCustomerList(context, 'inactive', themeService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildCustomerList(BuildContext context, String segment, ThemeService themeService) {
    final customers = _getFilteredCustomers(segment);
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getCustomerColor(customer['segment']),
                  child: Text(
                    customer['name'][0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (customer['hasUnread'])
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  customer['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                if (customer['segment'] == 'vip')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最終来店: ${customer['lastVisit']} • 累計: ¥${customer['totalSpent']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (customer['channels'].contains('LINE'))
                      _buildChannelChip('LINE', const Color(0xFF00B900)),
                    if (customer['channels'].contains('SMS'))
                      _buildChannelChip('SMS', Colors.blue),
                    if (customer['channels'].contains('App'))
                      _buildChannelChip('App', Colors.purple),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: customer['hasUnread'] ? themeService.primaryColor : Colors.grey,
                  ),
                  onPressed: () {
                    // チャット画面へ遷移
                    context.go('/chat/conversation/${customer['id']}');
                  },
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            onTap: () => _showCustomerDetail(context, customer, themeService),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
      },
    );
  }

  Widget _buildChannelChip(String channel, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        channel,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCustomerDetail(BuildContext context, Map<String, dynamic> customer, ThemeService themeService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          customer['name'][0],
                          style: TextStyle(
                            color: themeService.primaryColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              customer['phone'] ?? '090-0000-0000',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // アクションボタン
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        Icons.chat,
                        'チャット',
                        () {
                          Navigator.pop(context);
                          context.go('/chat/conversation/${customer['id']}');
                        },
                      ),
                      _buildActionButton(
                        Icons.phone,
                        '電話',
                        () {},
                      ),
                      _buildActionButton(
                        Icons.calendar_today,
                        '予約',
                        () {},
                      ),
                      _buildActionButton(
                        Icons.receipt,
                        '履歴',
                        () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 詳細情報
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('基本情報', [
                      _buildInfoRow('メール', customer['email'] ?? 'example@email.com'),
                      _buildInfoRow('誕生日', customer['birthday'] ?? '1990年1月1日'),
                      _buildInfoRow('性別', customer['gender'] ?? '女性'),
                      _buildInfoRow('登録日', customer['registeredDate'] ?? '2024年1月15日'),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('利用状況', [
                      _buildInfoRow('累計利用額', '¥${customer['totalSpent']}'),
                      _buildInfoRow('来店回数', '${customer['visitCount'] ?? 15}回'),
                      _buildInfoRow('最終来店', customer['lastVisit']),
                      _buildInfoRow('平均単価', '¥${customer['averageSpent'] ?? '8,500'}'),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('コミュニケーション', [
                      _buildInfoRow('LINE', customer['channels'].contains('LINE') ? '連携済み' : '未連携'),
                      _buildInfoRow('SMS', customer['channels'].contains('SMS') ? '連携済み' : '未連携'),
                      _buildInfoRow('最終連絡', customer['lastContact'] ?? '3日前'),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規顧客登録'),
        content: const Text('新規顧客を登録しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 顧客登録処理
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  Color _getCustomerColor(String segment) {
    switch (segment) {
      case 'vip':
        return Colors.amber;
      case 'new':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return const Color(0xFF5D9B9B);
    }
  }

  List<Map<String, dynamic>> _getFilteredCustomers(String segment) {
    final allCustomers = [
      {
        'id': '1',
        'name': '田中 美咲',
        'phone': '090-1234-5678',
        'email': 'tanaka@example.com',
        'lastVisit': '3日前',
        'totalSpent': '125,400',
        'segment': 'vip',
        'hasUnread': true,
        'channels': ['LINE', 'SMS'],
        'visitCount': 24,
      },
      {
        'id': '2',
        'name': '佐藤 花子',
        'phone': '080-9876-5432',
        'lastVisit': '1週間前',
        'totalSpent': '45,200',
        'segment': 'regular',
        'hasUnread': false,
        'channels': ['LINE'],
        'visitCount': 8,
      },
      {
        'id': '3',
        'name': '山田 太郎',
        'phone': '070-1111-2222',
        'lastVisit': '今日',
        'totalSpent': '8,500',
        'segment': 'new',
        'hasUnread': true,
        'channels': ['SMS', 'App'],
        'visitCount': 2,
      },
      {
        'id': '4',
        'name': '鈴木 恵子',
        'phone': '090-3333-4444',
        'lastVisit': '2ヶ月前',
        'totalSpent': '67,800',
        'segment': 'inactive',
        'hasUnread': false,
        'channels': ['LINE'],
        'visitCount': 12,
      },
    ];

    if (segment == 'all') return allCustomers;
    return allCustomers.where((c) => c['segment'] == segment).toList();
  }
}