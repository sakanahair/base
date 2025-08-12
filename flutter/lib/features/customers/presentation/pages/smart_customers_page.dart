import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/customer.dart';
import '../../../../core/services/mock_customer_service.dart' as mock;
import '../../../../shared/utils/responsive_helper.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_detail_view.dart';
import '../widgets/customer_filter_bar.dart';
import '../widgets/quick_action_dial.dart';
import '../widgets/customer_chat_view.dart';

class SmartCustomersPage extends StatefulWidget {
  const SmartCustomersPage({super.key});

  @override
  State<SmartCustomersPage> createState() => _SmartCustomersPageState();
}

class _SmartCustomersPageState extends State<SmartCustomersPage>
    with TickerProviderStateMixin {
  Customer? _selectedCustomer;
  bool _showChatView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // 顧客サービスの初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('SmartCustomersPage: Initializing customers...');
      final service = context.read<mock.CustomerService>();
      service.initializeCustomers();
      debugPrint('SmartCustomersPage: Customers count = ${service.customers.length}');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      // 未読メッセージがある場合は直接チャット画面へ
      _showChatView = customer.unreadCount > 0;
    });
    _animationController.forward();
    
    // 未読をクリア
    if (customer.unreadCount > 0) {
      context.read<mock.CustomerService>().markAsRead(customer.id);
    }
    
    // モバイルの場合
    if (context.isMobile) {
      if (customer.unreadCount > 0) {
        // 未読がある場合は直接チャット画面へ
        _navigateToChat(customer);
      } else {
        // 未読がない場合は詳細画面へ
        _navigateToCustomerDetail(customer);
      }
    }
  }

  void _navigateToCustomerDetail(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailView(
          customer: customer,
          onStartChat: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CustomerChatView(
                  customer: customer,
                  onBack: () => Navigator.pop(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToChat(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerChatView(
          customer: customer,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _startChat() {
    setState(() {
      _showChatView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final isMobile = context.isMobile;

    // AdminLayout内で表示されるため、Scaffoldは不要
    return Container(
      color: AppTheme.backgroundColor,
      child: Stack(
        children: [
          if (isDesktop || isTablet)
            _buildDesktopLayout()
          else
            _buildMobileLayout(),
          
          // モバイル用FAB
          if (isMobile)
            Positioned(
              bottom: 16,
              right: 16,
              child: QuickActionDial(
                onNewCustomer: _showNewCustomerDialog,
                onStartChat: _selectedCustomer != null ? _startChat : null,
                onCall: _selectedCustomer != null ? () => _makeCall(_selectedCustomer!) : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左側：顧客リスト
        Container(
          width: context.isTablet ? 350 : 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.5),
              ),
            ),
          ),
          child: Column(
            children: [
              _buildSearchHeader(),
              CustomerFilterBar(
                onFilterChanged: (filters) {
                  // フィルター変更処理
                },
              ),
              Expanded(
                child: _buildCustomerList(),
              ),
            ],
          ),
        ),
        
        // 右側：詳細/チャット
        Expanded(
          child: _selectedCustomer == null
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _showChatView
                      ? CustomerChatView(
                          customer: _selectedCustomer!,
                          onBack: () {
                            setState(() {
                              _showChatView = false;
                            });
                          },
                        )
                      : CustomerDetailView(
                          customer: _selectedCustomer!,
                          onStartChat: _startChat,
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchHeader(),
        CustomerFilterBar(
          onFilterChanged: (filters) {
            // フィルター変更処理
          },
        ),
        Expanded(
          child: _buildCustomerList(),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
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
              focusNode: _searchFocus,
              onChanged: (value) {
                context.read<mock.CustomerService>().search(value);
              },
              decoration: InputDecoration(
                hintText: '顧客を検索...',
                hintStyle: TextStyle(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w200,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.textTertiary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<mock.CustomerService>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // ソートボタン
          PopupMenuButton<mock.CustomerSortType>(
            icon: Icon(
              Icons.sort,
              color: AppTheme.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (type) {
              context.read<mock.CustomerService>().setSortType(type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: mock.CustomerSortType.unread,
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread, size: 20),
                    SizedBox(width: 12),
                    Text('未読順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.recent,
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 20),
                    SizedBox(width: 12),
                    Text('最新順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.vip,
                child: Row(
                  children: [
                    Icon(Icons.star, size: 20),
                    SizedBox(width: 12),
                    Text('VIP順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.purchase,
                child: Row(
                  children: [
                    Icon(Icons.attach_money, size: 20),
                    SizedBox(width: 12),
                    Text('購入額順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.reservation,
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20),
                    SizedBox(width: 12),
                    Text('予約日順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.name,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 12),
                    Text('名前順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: mock.CustomerSortType.activity,
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('アクティビティ順'),
                  ],
                ),
              ),
            ],
          ),
          
          // 新規顧客追加ボタン（デスクトップのみ）
          if (!context.isMobile) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showNewCustomerDialog,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Consumer<mock.CustomerService>(
      builder: (context, service, child) {
        debugPrint('_buildCustomerList: isLoading=${service.isLoading}, customers=${service.customers.length}');
        
        if (service.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (service.customers.isEmpty) {
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
                  '顧客が見つかりません',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    debugPrint('Retry button pressed');
                    service.initializeCustomers();
                  },
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            service.initializeCustomers();
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: service.customers.length,
            itemBuilder: (context, index) {
              final customer = service.customers[index];
              return CustomerCard(
                customer: customer,
                isSelected: _selectedCustomer?.id == customer.id,
                onTap: () => _selectCustomer(customer),
                onLongPress: () => _showCustomerActions(customer),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: AppTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '顧客を選択してください',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '左側のリストから顧客を選択すると\n詳細情報が表示されます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
              fontWeight: FontWeight.w200,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerActions(Customer customer) {
    ResponsiveHelper.addHapticFeedback();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('チャットを開始'),
              onTap: () {
                Navigator.pop(context);
                _selectCustomer(customer);
                _startChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('電話をかける'),
              onTap: () {
                Navigator.pop(context);
                _makeCall(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('ビデオ通話'),
              onTap: () {
                Navigator.pop(context);
                _startVideoCall(customer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('予約を作成'),
              onTap: () {
                Navigator.pop(context);
                _createReservation(customer);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.star,
                color: customer.isVip ? Colors.amber : null,
              ),
              title: Text(customer.isVip ? 'VIPを解除' : 'VIPに設定'),
              onTap: () {
                Navigator.pop(context);
                context.read<mock.CustomerService>().toggleVip(customer.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('顧客情報を編集'),
              onTap: () {
                Navigator.pop(context);
                _editCustomer(customer);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCustomerDialog() {
    // 新規顧客作成ダイアログ
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規顧客作成'),
        content: const Text('新規顧客作成機能は準備中です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _makeCall(Customer customer) {
    // 電話機能
    debugPrint('Calling ${customer.name}');
  }

  void _startVideoCall(Customer customer) {
    // ビデオ通話機能
    debugPrint('Starting video call with ${customer.name}');
  }

  void _createReservation(Customer customer) {
    // 予約作成
    debugPrint('Creating reservation for ${customer.name}');
  }

  void _editCustomer(Customer customer) {
    // 顧客編集
    debugPrint('Editing customer: ${customer.name}');
  }
}