import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<_CustomerData> _customers = List.generate(
    20,
    (index) => _CustomerData(
      id: index + 1,
      name: '顧客 ${index + 1}',
      phone: '090-1234-5678',
      email: 'customer${index + 1}@example.com',
      lastVisit: '2024-03-15',
      totalSpent: '¥125,000',
    ),
  );
  
  List<_CustomerData> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers.where((customer) =>
      customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      customer.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      customer.phone.contains(_searchQuery)
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          if (context.isTouchDevice) {
            ResponsiveHelper.addHapticFeedback();
          }
          // TODO: Refresh customer data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            // Header and Search
            Container(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '顧客管理',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(
                        context,
                        baseFontSize: 24,
                        mobileScale: 0.9,
                      ),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  
                  SizedBox(height: context.responsiveSpacing),
                  
                  // Search and Action Bar
                  _buildSearchAndActions(context, isMobile),
                ],
              ),
            ),
            
            // Customer List
            Expanded(
              child: Container(
                padding: context.responsiveHorizontalPadding,
                child: isMobile 
                  ? _buildMobileCustomerList(context)
                  : _buildDesktopTable(context),
              ),
            ),
          ],
        ),
      ),
      
      // Mobile FAB for adding customers
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () {
                ResponsiveHelper.addHapticFeedbackMedium();
                _showAddCustomerDialog(context);
              },
              backgroundColor: AppTheme.secondaryColor,
              child: const Icon(
                Icons.person_add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
  
  Widget _buildSearchAndActions(BuildContext context, bool isMobile) {
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: '顧客を検索...',
              prefixIcon: Icon(
                Icons.search,
                size: context.responsiveIconSize,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: context.responsiveIconSize,
                      ),
                      onPressed: () {
                        if (context.isTouchDevice) {
                          ResponsiveHelper.addHapticFeedback();
                        }
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        SizedBox(
          width: isMobile ? 0 : 16,
          height: isMobile ? 16 : 0,
        ),
        
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () {
              if (context.isTouchDevice) {
                ResponsiveHelper.addHapticFeedback();
              }
              _showAddCustomerDialog(context);
            },
            icon: Icon(
              Icons.person_add,
              size: context.responsiveIconSize,
            ),
            label: const Text('新規顧客'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(context.responsiveButtonHeight),
            ),
          ),
      ],
    );
  }
  
  Widget _buildMobileCustomerList(BuildContext context) {
    final filteredCustomers = _filteredCustomers;
    
    if (filteredCustomers.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView.separated(
      itemCount: filteredCustomers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = filteredCustomers[index];
        return _buildMobileCustomerCard(context, customer, index);
      },
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildMobileCustomerCard(BuildContext context, _CustomerData customer, int index) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          ResponsiveHelper.addHapticFeedback();
          _showCustomerDetails(context, customer);
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Name and basic info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      ResponsiveHelper.addHapticFeedback();
                      if (value == 'edit') {
                        _editCustomer(context, customer);
                      } else if (value == 'delete') {
                        _deleteCustomer(context, customer);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Details
              Row(
                children: [
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      Icons.email_outlined,
                      customer.email,
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      Icons.access_time,
                      '最終来店: ${customer.lastVisit}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailChip(
                      context,
                      Icons.attach_money,
                      customer.totalSpent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
  }
  
  Widget _buildDetailChip(
    BuildContext context,
    IconData icon,
    String text, {
    bool isExpanded = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopTable(BuildContext context) {
    final filteredCustomers = _filteredCustomers;
    
    if (filteredCustomers.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Card(
      child: DataTable2(
        columnSpacing: 12,
        horizontalMargin: 12,
        minWidth: 600,
        headingRowColor: MaterialStateColor.resolveWith(
          (states) => AppTheme.backgroundColor,
        ),
        columns: const [
          DataColumn2(
            label: Text('顧客名'),
            size: ColumnSize.L,
          ),
          DataColumn(
            label: Text('電話番号'),
          ),
          DataColumn(
            label: Text('メール'),
          ),
          DataColumn(
            label: Text('最終来店'),
          ),
          DataColumn(
            label: Text('累計金額'),
          ),
          DataColumn2(
            label: Text('アクション'),
            size: ColumnSize.S,
            fixedWidth: 120,
          ),
        ],
        rows: filteredCustomers.map((customer) => DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.secondaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(Text(customer.phone)),
            DataCell(
              Text(
                customer.email,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DataCell(Text(customer.lastVisit)),
            DataCell(
              Text(
                customer.totalSpent,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.successColor,
                ),
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      if (context.isTouchDevice) {
                        ResponsiveHelper.addHapticFeedback();
                      }
                      _editCustomer(context, customer);
                    },
                    tooltip: '編集',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      if (context.isTouchDevice) {
                        ResponsiveHelper.addHapticFeedback();
                      }
                      _deleteCustomer(context, customer);
                    },
                    tooltip: '削除',
                  ),
                ],
              ),
            ),
          ],
        )).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildEmptyState(BuildContext context) {
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
            _searchQuery.isEmpty ? '顧客が登録されていません' : '検索結果がありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '新しい顧客を登録してみましょう' : '別のキーワードで検索してみてください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (context.isTouchDevice) {
                  ResponsiveHelper.addHapticFeedback();
                }
                _showAddCustomerDialog(context);
              },
              icon: const Icon(Icons.person_add),
              label: const Text('新規顧客を登録'),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showAddCustomerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規顧客登録'),
        content: const Text('顧客登録機能は実装予定です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  void _showCustomerDetails(BuildContext context, _CustomerData customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('電話: ${customer.phone}'),
            const SizedBox(height: 8),
            Text('メール: ${customer.email}'),
            const SizedBox(height: 8),
            Text('最終来店: ${customer.lastVisit}'),
            const SizedBox(height: 8),
            Text('累計金額: ${customer.totalSpent}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editCustomer(context, customer);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }
  
  void _editCustomer(BuildContext context, _CustomerData customer) {
    ResponsiveHelper.showResponsiveSnackBar(
      context,
      message: '${customer.name}の編集機能は実装予定です',
      backgroundColor: AppTheme.infoColor,
    );
  }
  
  void _deleteCustomer(BuildContext context, _CustomerData customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('顧客を削除'),
        content: Text('${customer.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ResponsiveHelper.showResponsiveSnackBar(
                context,
                message: '${customer.name}を削除しました',
                backgroundColor: AppTheme.errorColor,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CustomerData {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String lastVisit;
  final String totalSpent;
  
  _CustomerData({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.lastVisit,
    required this.totalSpent,
  });
}