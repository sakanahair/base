import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'all';
  late TabController _tabController;
  final _dateFormat = DateFormat('MM月dd日(E)', 'ja_JP');
  final _timeFormat = DateFormat('HH:mm');
  
  final List<_AppointmentData> _appointments = List.generate(
    15,
    (index) {
      final date = DateTime.now().add(Duration(days: index % 7));
      final statuses = ['confirmed', 'pending', 'completed', 'cancelled'];
      return _AppointmentData(
        id: index + 1,
        customerName: '顧客 ${index + 1}',
        serviceName: index % 3 == 0 
            ? 'カット + カラー' 
            : index % 2 == 0 
              ? 'パーマ + トリートメント'
              : 'カット',
        date: date,
        time: TimeOfDay(hour: 9 + (index % 8), minute: index % 2 == 0 ? 0 : 30),
        duration: 60 + (index % 3) * 30,
        status: statuses[index % statuses.length],
        phone: '090-1234-${5678 + index}',
        price: 5000 + (index % 5) * 1000,
      );
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_AppointmentData> get _filteredAppointments {
    var filtered = _appointments.where((appointment) {
      final matchesSearch = _searchQuery.isEmpty ||
          appointment.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          appointment.serviceName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _selectedStatus == 'all' || 
          appointment.status == _selectedStatus;
      
      return matchesSearch && matchesStatus;
    }).toList();
    
    // Sort by date and time
    filtered.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      if (dateComparison != 0) return dateComparison;
      
      final aMinutes = a.time.hour * 60 + a.time.minute;
      final bMinutes = b.time.hour * 60 + b.time.minute;
      return aMinutes.compareTo(bMinutes);
    });
    
    return filtered;
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
          // TODO: Refresh appointment data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            // Header
            Container(
              padding: context.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '予約管理',
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
                  
                  // Search and Filters
                  _buildSearchAndFilters(context, isMobile),
                ],
              ),
            ),
            
            // Status Tabs (Mobile) or Filter Chips (Desktop)
            if (isMobile) 
              _buildMobileStatusTabs(context)
            else 
              _buildDesktopFilterChips(context),
            
            // Appointments List
            Expanded(
              child: Container(
                padding: context.responsiveHorizontalPadding,
                child: _buildAppointmentsList(context, isMobile),
              ),
            ),
          ],
        ),
      ),
      
      // Mobile FAB for adding appointments
      floatingActionButton: isMobile
          ? FloatingActionButton.extended(
              onPressed: () {
                ResponsiveHelper.addHapticFeedbackMedium();
                _showAddAppointmentDialog(context);
              },
              backgroundColor: AppTheme.secondaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                '予約追加',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
  
  Widget _buildSearchAndFilters(BuildContext context, bool isMobile) {
    return Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: '顧客名やサービスで検索...',
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
          ),
        ),
        
        if (!isMobile) ...[
          SizedBox(height: context.responsiveSpacing),
          
          // Desktop Actions Row
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: Icon(Icons.calendar_today, size: context.responsiveIconSize),
                label: Text(_dateFormat.format(_selectedDate)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              
              const SizedBox(width: 16),
              
              ElevatedButton.icon(
                onPressed: () {
                  if (context.isTouchDevice) {
                    ResponsiveHelper.addHapticFeedback();
                  }
                  _showAddAppointmentDialog(context);
                },
                icon: Icon(Icons.add, size: context.responsiveIconSize),
                label: const Text('新規予約'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                ),
              ),
              
              const Spacer(),
              
              // Export button
              OutlinedButton.icon(
                onPressed: () {
                  if (context.isTouchDevice) {
                    ResponsiveHelper.addHapticFeedback();
                  }
                  ResponsiveHelper.showResponsiveSnackBar(
                    context,
                    message: 'エクスポート機能は実装予定です',
                    backgroundColor: AppTheme.infoColor,
                  );
                },
                icon: Icon(Icons.download, size: context.responsiveIconSize),
                label: const Text('エクスポート'),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildMobileStatusTabs(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppTheme.secondaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.secondaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        onTap: (index) {
          ResponsiveHelper.addHapticFeedback();
          setState(() {
            _selectedStatus = ['all', 'confirmed', 'pending', 'completed'][index];
          });
        },
        tabs: const [
          Tab(text: 'すべて'),
          Tab(text: '確定'),
          Tab(text: '保留'),
          Tab(text: '完了'),
        ],
      ),
    );
  }
  
  Widget _buildDesktopFilterChips(BuildContext context) {
    final statuses = [
      {'key': 'all', 'label': 'すべて', 'count': _appointments.length},
      {'key': 'confirmed', 'label': '確定', 'count': _appointments.where((a) => a.status == 'confirmed').length},
      {'key': 'pending', 'label': '保留', 'count': _appointments.where((a) => a.status == 'pending').length},
      {'key': 'completed', 'label': '完了', 'count': _appointments.where((a) => a.status == 'completed').length},
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Wrap(
        spacing: 12,
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status['key'];
          return FilterChip(
            label: Text('${status['label']} (${status['count']})'),
            selected: isSelected,
            onSelected: (selected) {
              if (context.isTouchDevice) {
                ResponsiveHelper.addHapticFeedback();
              }
              setState(() {
                _selectedStatus = status['key'] as String;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: AppTheme.activeBackgroundColor,
            checkmarkColor: AppTheme.secondaryColor,
            side: BorderSide(
              color: isSelected ? AppTheme.secondaryColor : AppTheme.borderColor,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildAppointmentsList(BuildContext context, bool isMobile) {
    final filteredAppointments = _filteredAppointments;
    
    if (filteredAppointments.isEmpty) {
      return _buildEmptyState(context);
    }
    
    if (isMobile) {
      return ListView.separated(
        itemCount: filteredAppointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildMobileAppointmentCard(context, appointment, index);
        },
      ).animate().fadeIn(delay: 200.ms);
    } else {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.getGridColumnCount(
            context,
            mobileColumns: 1,
            tabletColumns: 2,
            desktopColumns: 3,
          ),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildDesktopAppointmentCard(context, appointment, index);
        },
      ).animate().fadeIn(delay: 200.ms);
    }
  }
  
  Widget _buildMobileAppointmentCard(
    BuildContext context, 
    _AppointmentData appointment, 
    int index
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          ResponsiveHelper.addHapticFeedback();
          _showAppointmentDetails(context, appointment);
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and actions
              Row(
                children: [
                  _buildStatusChip(context, appointment.status),
                  const Spacer(),
                  _buildAppointmentActions(context, appointment),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Customer and Service Info
              Row(
                children: [
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
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.serviceName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '¥${appointment.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Date and Time Info
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.calendar_today,
                      _dateFormat.format(appointment.date),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.access_time,
                      '${_timeFormat.format(DateTime(0, 0, 0, appointment.time.hour, appointment.time.minute))} (${appointment.duration}分)',
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
  
  Widget _buildDesktopAppointmentCard(
    BuildContext context, 
    _AppointmentData appointment, 
    int index
  ) {
    return Card(
      child: InkWell(
        onTap: () {
          if (context.isTouchDevice) {
            ResponsiveHelper.addHapticFeedback();
          }
          _showAppointmentDetails(context, appointment);
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  _buildStatusChip(context, appointment.status),
                  const Spacer(),
                  _buildAppointmentActions(context, appointment),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Customer Info
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.customerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.serviceName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Date and Time
              Text(
                _dateFormat.format(appointment.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 4),
              
              Text(
                '${_timeFormat.format(DateTime(0, 0, 0, appointment.time.hour, appointment.time.minute))} (${appointment.duration}分)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '¥${appointment.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.95, 0.95));
  }
  
  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'confirmed':
        color = AppTheme.successColor;
        label = '確定';
        break;
      case 'pending':
        color = AppTheme.warningColor;
        label = '保留';
        break;
      case 'completed':
        color = AppTheme.infoColor;
        label = '完了';
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'キャンセル';
        break;
      default:
        color = AppTheme.textTertiary;
        label = '不明';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
  
  Widget _buildAppointmentActions(BuildContext context, _AppointmentData appointment) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (context.isTouchDevice) {
          ResponsiveHelper.addHapticFeedback();
        }
        
        switch (value) {
          case 'edit':
            _editAppointment(context, appointment);
            break;
          case 'confirm':
            _confirmAppointment(context, appointment);
            break;
          case 'complete':
            _completeAppointment(context, appointment);
            break;
          case 'cancel':
            _cancelAppointment(context, appointment);
            break;
          case 'call':
            _callCustomer(context, appointment);
            break;
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
        if (appointment.status == 'pending')
          const PopupMenuItem(
            value: 'confirm',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: AppTheme.successColor),
                SizedBox(width: 8),
                Text('確定'),
              ],
            ),
          ),
        if (appointment.status == 'confirmed')
          const PopupMenuItem(
            value: 'complete',
            child: Row(
              children: [
                Icon(Icons.done, size: 20, color: AppTheme.infoColor),
                SizedBox(width: 8),
                Text('完了'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'call',
          child: Row(
            children: [
              Icon(Icons.phone, size: 20, color: AppTheme.warningColor),
              SizedBox(width: 8),
              Text('電話'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, size: 20, color: AppTheme.errorColor),
              SizedBox(width: 8),
              Text('キャンセル', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? '予約がありません' : '検索結果がありません',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? '新しい予約を作成してみましょう' : '別のキーワードで検索してみてください',
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
                _showAddAppointmentDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('新規予約を作成'),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ja', 'JP'),
    );
    
    if (picked != null && picked != _selectedDate) {
      if (context.isTouchDevice) {
        ResponsiveHelper.addHapticFeedback();
      }
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _showAddAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新規予約'),
        content: const Text('予約作成機能は実装予定です'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  void _showAppointmentDetails(BuildContext context, _AppointmentData appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('予約詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('顧客: ${appointment.customerName}'),
            const SizedBox(height: 8),
            Text('サービス: ${appointment.serviceName}'),
            const SizedBox(height: 8),
            Text('日付: ${_dateFormat.format(appointment.date)}'),
            const SizedBox(height: 8),
            Text('時間: ${_timeFormat.format(DateTime(0, 0, 0, appointment.time.hour, appointment.time.minute))}'),
            const SizedBox(height: 8),
            Text('料金: ¥${appointment.price.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text('電話: ${appointment.phone}'),
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
              _editAppointment(context, appointment);
            },
            child: const Text('編集'),
          ),
        ],
      ),
    );
  }
  
  void _editAppointment(BuildContext context, _AppointmentData appointment) {
    ResponsiveHelper.showResponsiveSnackBar(
      context,
      message: '${appointment.customerName}の予約編集機能は実装予定です',
      backgroundColor: AppTheme.infoColor,
    );
  }
  
  void _confirmAppointment(BuildContext context, _AppointmentData appointment) {
    ResponsiveHelper.showResponsiveSnackBar(
      context,
      message: '${appointment.customerName}の予約を確定しました',
      backgroundColor: AppTheme.successColor,
    );
  }
  
  void _completeAppointment(BuildContext context, _AppointmentData appointment) {
    ResponsiveHelper.showResponsiveSnackBar(
      context,
      message: '${appointment.customerName}の予約を完了しました',
      backgroundColor: AppTheme.infoColor,
    );
  }
  
  void _cancelAppointment(BuildContext context, _AppointmentData appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約をキャンセル'),
        content: Text('${appointment.customerName}の予約をキャンセルしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ResponsiveHelper.showResponsiveSnackBar(
                context,
                message: '${appointment.customerName}の予約をキャンセルしました',
                backgroundColor: AppTheme.errorColor,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _callCustomer(BuildContext context, _AppointmentData appointment) {
    ResponsiveHelper.showResponsiveSnackBar(
      context,
      message: '${appointment.phone}に電話をかけます',
      backgroundColor: AppTheme.warningColor,
    );
  }
}

class _AppointmentData {
  final int id;
  final String customerName;
  final String serviceName;
  final DateTime date;
  final TimeOfDay time;
  final int duration; // minutes
  final String status; // confirmed, pending, completed, cancelled
  final String phone;
  final double price;
  
  _AppointmentData({
    required this.id,
    required this.customerName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    required this.phone,
    required this.price,
  });
}