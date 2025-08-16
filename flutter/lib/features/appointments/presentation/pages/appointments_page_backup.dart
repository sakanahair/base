import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/global_modal_service.dart';
import '../../../../core/services/customer_service.dart';
import '../../../../core/theme/app_theme.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Google カレンダー連携状態（モック）
  bool _isGoogleCalendarConnected = false;
  
  // 表示モード
  String _viewMode = 'calendar'; // 'calendar', 'list', 'timeline'
  
  // モックの予約データ
  final Map<DateTime, List<Appointment>> _appointments = {};
  
  // 検索関連
  String _searchQuery = '';
  late TextEditingController _searchController;
  String _selectedFilter = 'all'; // 'all', 'customer', 'service', 'staff'
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _searchController = TextEditingController();
    _loadMockAppointments();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadMockAppointments() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // 今日の予約（10時に3つの予約が重複）
    _appointments[normalizedToday] = [
      // 10時開始の予約1
      Appointment(
        id: '1',
        customerId: 'customer_001',
        customerName: '田中 花子',
        serviceName: 'カット + カラー',
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        endTime: DateTime(today.year, today.month, today.day, 12, 0),
        status: AppointmentStatus.confirmed,
        staffName: '山田スタイリスト',
        price: 12000,
        note: '前回と同じカラーリング希望',
        isFromGoogle: true,
      ),
      // 10時開始の予約2
      Appointment(
        id: '2',
        customerId: 'customer_002',
        customerName: '佐藤 次郎',
        serviceName: 'カット',
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        endTime: DateTime(today.year, today.month, today.day, 11, 0),
        status: AppointmentStatus.confirmed,
        staffName: '鈴木スタイリスト',
        price: 4500,
        note: '短めにカット',
      ),
      // 10時開始の予約3
      Appointment(
        id: '3',
        customerId: 'customer_003',
        customerName: '高橋 美穂',
        serviceName: 'パーマ',
        startTime: DateTime(today.year, today.month, today.day, 10, 0),
        endTime: DateTime(today.year, today.month, today.day, 12, 30),
        status: AppointmentStatus.confirmed,
        staffName: '佐藤スタイリスト',
        price: 15000,
        note: 'ゆるめのパーマ希望',
      ),
      // 14時の予約
      Appointment(
        id: '4',
        customerId: 'customer_004',
        customerName: '伊藤 健一',
        serviceName: 'カット',
        startTime: DateTime(today.year, today.month, today.day, 14, 0),
        endTime: DateTime(today.year, today.month, today.day, 15, 0),
        status: AppointmentStatus.confirmed,
        staffName: '山田スタイリスト',
        price: 4500,
      ),
      // 14時の予約2（重複）
      Appointment(
        id: '5',
        customerId: 'customer_005',
        customerName: '鈴木 美咲',
        serviceName: 'トリートメント',
        startTime: DateTime(today.year, today.month, today.day, 14, 0),
        endTime: DateTime(today.year, today.month, today.day, 15, 0),
        status: AppointmentStatus.pending,
        staffName: '鈴木スタイリスト',
        price: 6000,
      ),
      // 16時の予約
      Appointment(
        id: '6',
        customerId: 'customer_006',
        customerName: '渡辺 陽子',
        serviceName: 'カラー',
        startTime: DateTime(today.year, today.month, today.day, 16, 0),
        endTime: DateTime(today.year, today.month, today.day, 17, 30),
        status: AppointmentStatus.confirmed,
        staffName: '山田スタイリスト',
        price: 8000,
      ),
    ];
    
    // 明日の予約
    final tomorrow = normalizedToday.add(const Duration(days: 1));
    _appointments[tomorrow] = [
      Appointment(
        id: '4',
        customerId: 'customer_004',
        customerName: '高橋 健一',
        serviceName: 'パーマ + カット',
        startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 11, 0),
        endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 13, 0),
        status: AppointmentStatus.confirmed,
        staffName: '佐藤スタイリスト',
        price: 15000,
        isFromGoogle: true,
      ),
    ];
    
    // 来週の予約
    final nextWeek = normalizedToday.add(const Duration(days: 7));
    _appointments[nextWeek] = [
      Appointment(
        id: '5',
        customerId: 'customer_005',
        customerName: '伊藤 さゆり',
        serviceName: '縮毛矯正',
        startTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 9, 0),
        endTime: DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 12, 0),
        status: AppointmentStatus.confirmed,
        staffName: '山田スタイリスト',
        price: 18000,
      ),
    ];
  }
  
  List<Appointment> _getAppointmentsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final appointments = _appointments[normalized] ?? [];
    return _filterAppointments(appointments);
  }
  
  List<Appointment> _filterAppointments(List<Appointment> appointments) {
    if (_searchQuery.isEmpty) return appointments;
    
    final query = _searchQuery.toLowerCase();
    return appointments.where((appointment) {
      switch (_selectedFilter) {
        case 'customer':
          return appointment.customerName.toLowerCase().contains(query);
        case 'service':
          return appointment.serviceName.toLowerCase().contains(query);
        case 'staff':
          return appointment.staffName.toLowerCase().contains(query);
        case 'all':
        default:
          return appointment.customerName.toLowerCase().contains(query) ||
                 appointment.serviceName.toLowerCase().contains(query) ||
                 appointment.staffName.toLowerCase().contains(query) ||
                 (appointment.note?.toLowerCase().contains(query) ?? false);
      }
    }).toList();
  }
  
  void _showAppointmentDetails(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentDetailModal(appointment: appointment),
    );
  }
  
  void _showNewAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => const _NewAppointmentDialog(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー（ダッシュボードと同じスタイル）
            Container(
              color: AppTheme.backgroundColor,
              padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 20, isMobile ? 16 : 20, 12),
              child: Column(
                children: [
                  // タイトル行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '予約管理',
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy年MM月dd日').format(DateTime.now()),
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: AppTheme.textSecondary,
                              ),
                            ).animate().fadeIn(delay: 100.ms),
                          ],
                        ),
                      ),
                      // メニューボタン（モバイルのみ）
                      if (isMobile)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                _showViewModeMenu();
                                break;
                              case 'google':
                                _showGoogleCalendarSettings();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.view_module, size: 20),
                                  SizedBox(width: 8),
                                  Text('表示切替'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'google',
                              child: Row(
                                children: [
                                  Icon(Icons.settings, size: 20),
                                  SizedBox(width: 8),
                                  Text('設定'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 検索バーとアクション行
                  Row(
                    children: [
                      // 検索バー
                      Expanded(
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: isMobile ? '検索' : '顧客、サービス、スタッフで検索',
                              hintStyle: const TextStyle(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: themeService.primaryColor),
                              ),
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
                      // デスクトップ用アクションボタン
                      if (!isMobile) ...[
            // Google カレンダー連携状態
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isGoogleCalendarConnected 
                ? Colors.green.shade50 
                : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isGoogleCalendarConnected 
                  ? Colors.green.shade300 
                  : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: _isGoogleCalendarConnected 
                    ? Colors.green.shade700 
                    : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _isGoogleCalendarConnected ? 'Google 連携中' : 'Google 未連携',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isGoogleCalendarConnected 
                      ? Colors.green.shade700 
                      : Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            ),
            // 表示切り替え
            PopupMenuButton<String>(
            icon: const Icon(Icons.view_module),
            onSelected: (value) {
              setState(() {
                _viewMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month, size: 20),
                    SizedBox(width: 8),
                    Text('カレンダー'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'list',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 8),
                    Text('リスト'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'timeline',
                child: Row(
                  children: [
                    Icon(Icons.timeline, size: 20),
                    SizedBox(width: 8),
                    Text('タイムライン'),
                  ],
                ),
              ),
            ],
          ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _showGoogleCalendarSettings();
              },
            ),
          ],
        ],
      ),
    ],
  ),
),
            
            // コンテンツ
            Expanded(
              child: _viewMode == 'calendar' 
        ? _buildCalendarView(themeService, isMobile)
        : _viewMode == 'list'
          ? _buildListView(themeService)
          : _buildTimelineView(themeService),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewAppointmentDialog,
        backgroundColor: themeService.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCalendarView(ThemeService themeService, bool isMobile) {
    return Card(
      margin: EdgeInsets.all(isMobile ? 8 : 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          locale: 'ja_JP',
          rowHeight: isMobile ? 60 : 80,
          daysOfWeekHeight: 40,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          eventLoader: _getAppointmentsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(4),
            selectedDecoration: BoxDecoration(
              color: themeService.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Colors.blue.shade400,
              shape: BoxShape.circle,
            ),
            markersAlignment: Alignment.bottomCenter,
            defaultTextStyle: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
            weekendTextStyle: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: themeService.primaryColor),
              borderRadius: BorderRadius.circular(16),
            ),
            formatButtonTextStyle: TextStyle(
              color: themeService.primaryColor,
              fontSize: 13,
            ),
            titleTextStyle: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            
            // 選択した日の予約を取得
            final appointments = _getAppointmentsForDay(selectedDay);
            
            if (appointments.isNotEmpty) {
              // 予約がある場合はリスト表示
              _showDayAppointmentsList(selectedDay, appointments);
            } else {
              // 予約がない場合は新規作成ダイアログ
              _showNewAppointmentDialogForDay(selectedDay);
            }
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
  
  void _showDayAppointmentsList(DateTime day, List<Appointment> appointments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DayAppointmentsView(
        date: day,
        appointments: appointments,
        onNewAppointment: () {
          Navigator.pop(context);
          _showNewAppointmentDialogForDay(day);
        },
        onAppointmentTap: (appointment) {
          Navigator.pop(context);
          _showAppointmentDetails(appointment);
        },
      ),
    );
  }
  
  void _showNewAppointmentDialogForDay(DateTime day) {
    showDialog(
      context: context,
      builder: (context) => _NewAppointmentDialog(selectedDate: day),
    );
  }
  
  Widget _buildListView(ThemeService themeService) {
    // すべての予約を日付順にソート
    final allAppointments = <Appointment>[];
    final sortedDates = _appointments.keys.toList()..sort();
    
    for (final date in sortedDates) {
      allAppointments.addAll(_appointments[date]!);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allAppointments.length,
      itemBuilder: (context, index) {
        final appointment = allAppointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onTap: () => _showAppointmentDetails(appointment),
          showDate: true,
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
      },
    );
  }
  
  Widget _buildTimelineView(ThemeService themeService) {
    final today = DateTime.now();
    final todayAppointments = _getAppointmentsForDay(today);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy年M月d日 (E)', 'ja').format(today),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // タイムライン表示
          SizedBox(
            height: 24 * 60, // 24時間分の高さ
            child: Stack(
              children: [
                // 時間軸
                ...List.generate(24, (hour) {
                  return Positioned(
                    top: hour * 60.0,
                    left: 0,
                    right: 0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey.shade300),
                        ),
                      ],
                    ),
                  );
                }),
                
                // 予約表示
                ...todayAppointments.map((appointment) {
                  final startMinutes = appointment.startTime.hour * 60 + 
                                      appointment.startTime.minute;
                  final duration = appointment.endTime.difference(appointment.startTime).inMinutes;
                  
                  return Positioned(
                    top: startMinutes.toDouble(),
                    left: 60,
                    right: 16,
                    height: duration.toDouble(),
                    child: GestureDetector(
                      onTap: () => _showAppointmentDetails(appointment),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(appointment.status).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(appointment.status),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appointment.customerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              appointment.serviceName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showViewModeMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_view_month),
              title: const Text('カレンダー'),
              trailing: _viewMode == 'calendar' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _viewMode = 'calendar';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('リスト'),
              trailing: _viewMode == 'list' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _viewMode = 'list';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline),
              title: const Text('タイムライン'),
              trailing: _viewMode == 'timeline' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _viewMode = 'timeline';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showGoogleCalendarSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google カレンダー連携'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isGoogleCalendarConnected) ...[
              const Icon(Icons.calendar_month, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Google カレンダーと連携すると、予約情報を自動で同期できます。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isGoogleCalendarConnected = true;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Google カレンダーと連携しました')),
                  );
                },
                icon: const Icon(Icons.link),
                label: const Text('Google アカウントと連携'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ] else ...[
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Google カレンダーと連携済みです',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'account@gmail.com',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isGoogleCalendarConnected = false;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('連携を解除しました')),
                  );
                },
                icon: const Icon(Icons.link_off),
                label: const Text('連携を解除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }
}

// 予約モデル
class Appointment {
  final String id;
  final String customerId;  // 顧客ID追加
  final String customerName;
  final String serviceName;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final String staffName;
  final int price;
  final String? note;
  final bool isFromGoogle;
  
  Appointment({
    required this.id,
    String? customerId,
    required this.customerName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.staffName,
    required this.price,
    this.note,
    this.isFromGoogle = false,
  }) : customerId = customerId ?? 'customer_${id}';
}

enum AppointmentStatus {
  confirmed,
  pending,
  cancelled,
  completed,
}

// 予約カード
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final bool showDate;
  
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.showDate = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
              // 時間
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(appointment.startTime),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeService.primaryColor,
                      ),
                    ),
                    Text(
                      '〜',
                      style: TextStyle(
                        fontSize: 10,
                        color: themeService.primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(appointment.endTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: themeService.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // 詳細
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          DateFormat('M月d日(E)', 'ja').format(appointment.startTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          appointment.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (appointment.isFromGoogle)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month, size: 10, color: Colors.blue.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.serviceName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          appointment.staffName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '¥${NumberFormat('#,###').format(appointment.price)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
                  // ステータス
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(appointment.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(appointment.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                  ),
                ],
              ),
              // クイックアクションボタン
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // チャットボタン
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, size: 18, color: themeService.primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      GlobalModalService.showChat(
                        context,
                        customerId: appointment.customerId,
                        customerName: appointment.customerName,
                      );
                    },
                    tooltip: 'チャット',
                  ),
                  // 電話ボタン
                  IconButton(
                    icon: Icon(Icons.phone_outlined, size: 18, color: themeService.primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      // TODO: 電話番号があれば電話をかける
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('電話機能は準備中です')),
                      );
                    },
                    tooltip: '電話',
                  ),
                  // 顧客詳細ボタン
                  IconButton(
                    icon: Icon(Icons.person_outline, size: 18, color: themeService.primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () {
                      GlobalModalService.showCustomerDetail(
                        context,
                        customerId: appointment.customerId,
                        customerName: appointment.customerName,
                      );
                    },
                    tooltip: '顧客詳細',
                  ),
                  // 詳細ボタン
                  IconButton(
                    icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey.shade600),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: onTap,
                    tooltip: '詳細',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }
  
  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return '確定';
      case AppointmentStatus.pending:
        return '仮予約';
      case AppointmentStatus.cancelled:
        return 'キャンセル';
      case AppointmentStatus.completed:
        return '完了';
    }
  }
}

// 同時刻の複数予約を表示するタイムラインアイテム
class _TimelineGroupItem extends StatelessWidget {
  final DateTime time;
  final List<Appointment> appointments;
  final bool isLast;
  final Function(Appointment) onTap;
  
  const _TimelineGroupItem({
    required this.time,
    required this.appointments,
    required this.isLast,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final timeFormat = DateFormat('HH:mm');
    
    // 最も遅い終了時刻を取得
    DateTime latestEndTime = appointments.first.endTime;
    for (final appointment in appointments) {
      if (appointment.endTime.isAfter(latestEndTime)) {
        latestEndTime = appointment.endTime;
      }
    }
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間表示
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(time),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${appointments.length}件',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeService.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // タイムラインの線とドット（複数予約用の特別なデザイン）
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景の円
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 数字表示
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${appointments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // 横スクロール可能なカードリスト
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: themeService.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '同時刻の予約',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${timeFormat.format(time)} - ${timeFormat.format(latestEndTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 横スクロール可能なカードリスト
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(right: index < appointments.length - 1 ? 8 : 0),
                          child: _CompactAppointmentCard(
                            appointment: appointment,
                            onTap: () => onTap(appointment),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// コンパクトな予約カード（横並び表示用）
class _CompactAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  
  const _CompactAppointmentCard({
    required this.appointment,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final timeFormat = DateFormat('HH:mm');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スタッフバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 12,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      appointment.staffName,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 顧客名
            Text(
              appointment.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // サービス名
            Text(
              appointment.serviceName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // 時間と価格
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${timeFormat.format(appointment.startTime)}-${timeFormat.format(appointment.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  '¥${appointment.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeService.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 予約詳細モーダル
class _AppointmentDetailModal extends StatelessWidget {
  final Appointment appointment;
  
  const _AppointmentDetailModal({required this.appointment});
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                appointment.customerName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // クイックアクションボタン
                              IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  // 予約詳細モーダルを閉じずにチャットを開く
                                  GlobalModalService.showChat(
                                    context,
                                    customerId: appointment.customerId,
                                    customerName: appointment.customerName,
                                    isFromAppointmentDetail: true,
                                  );
                                },
                                tooltip: 'チャット',
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_outlined),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  // TODO: 電話番号があれば電話をかける
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('電話機能は準備中です')),
                                  );
                                },
                                tooltip: '電話',
                              ),
                              IconButton(
                                icon: const Icon(Icons.person_outline),
                                iconSize: 20,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  // 予約詳細モーダルを閉じずに顧客詳細を開く
                                  GlobalModalService.showCustomerDetail(
                                    context,
                                    customerId: appointment.customerId,
                                    customerName: appointment.customerName,
                                    isFromAppointmentDetail: true,
                                  );
                                },
                                tooltip: '顧客詳細',
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy年M月d日(E) HH:mm', 'ja').format(appointment.startTime),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (appointment.isFromGoogle)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_month,
                          color: Colors.blue.shade700,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 詳細情報
                _DetailRow(
                  icon: Icons.cut,
                  label: 'サービス',
                  value: appointment.serviceName,
                ),
                _DetailRow(
                  icon: Icons.access_time,
                  label: '時間',
                  value: '${DateFormat('HH:mm').format(appointment.startTime)} 〜 ${DateFormat('HH:mm').format(appointment.endTime)}',
                ),
                _DetailRow(
                  icon: Icons.person,
                  label: '担当',
                  value: appointment.staffName,
                ),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: '料金',
                  value: '¥${NumberFormat('#,###').format(appointment.price)}',
                ),
                if (appointment.note != null)
                  _DetailRow(
                    icon: Icons.note,
                    label: 'メモ',
                    value: appointment.note!,
                  ),
                
                const SizedBox(height: 24),
                
                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('予約をキャンセルしました')),
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('キャンセル'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('編集画面を開きます')),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('編集'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeService.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 詳細行
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 新規予約ダイアログ
class _NewAppointmentDialog extends StatefulWidget {
  final DateTime? selectedDate;
  
  const _NewAppointmentDialog({this.selectedDate});
  
  @override
  State<_NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<_NewAppointmentDialog> {
  final _phoneController = TextEditingController();
  final _memberNumberController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _serviceController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _selectedStaff = '山田スタイリスト';
  bool _syncToGoogle = true;
  
  // 検索結果
  List<Customer> _suggestions = [];
  Customer? _selectedCustomer;
  bool _isSearching = false;
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    
    // 電話番号入力時の自動検索
    _phoneController.addListener(_onPhoneChanged);
    // 会員番号入力時の自動検索
    _memberNumberController.addListener(_onMemberNumberChanged);
    // 名前入力時のリアルタイム検索
    _customerNameController.addListener(_onNameChanged);
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phoneController.dispose();
    _memberNumberController.dispose();
    _customerNameController.dispose();
    _serviceController.dispose();
    super.dispose();
  }
  
  // 電話番号での検索
  void _onPhoneChanged() {
    if (_phoneController.text.length >= 10) {
      final customerService = Provider.of<CustomerService>(context, listen: false);
      final customer = customerService.findByPhone(_phoneController.text);
      if (customer != null) {
        _selectCustomer(customer);
      }
    }
  }
  
  // 会員番号での検索
  void _onMemberNumberChanged() {
    if (_memberNumberController.text.length >= 3) {
      final customerService = Provider.of<CustomerService>(context, listen: false);
      final customer = customerService.findByMemberNumber(_memberNumberController.text);
      if (customer != null) {
        _selectCustomer(customer);
      }
    }
  }
  
  // 名前でのリアルタイム検索（デバウンス付き）
  void _onNameChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_customerNameController.text.isNotEmpty && _selectedCustomer == null) {
        final customerService = Provider.of<CustomerService>(context, listen: false);
        setState(() {
          _suggestions = customerService.getSuggestions(_customerNameController.text);
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }
  
  // 顧客を選択
  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerNameController.text = customer.name;
      _phoneController.text = customer.phone;
      if (customer.memberNumber != null) {
        _memberNumberController.text = customer.memberNumber!;
      }
      _suggestions = [];
    });
  }
  
  // 選択をクリア
  void _clearSelection() {
    setState(() {
      _selectedCustomer = null;
      _phoneController.clear();
      _memberNumberController.clear();
      _customerNameController.clear();
      _suggestions = [];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return AlertDialog(
      title: const Text('新規予約'),
      content: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顧客情報セクション
              Card(
                color: _selectedCustomer != null ? Colors.green.shade50 : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_search, size: 20),
                          const SizedBox(width: 8),
                          const Text('顧客検索', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_selectedCustomer != null)
                            TextButton.icon(
                              onPressed: _clearSelection,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('クリア'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 電話番号入力
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: '電話番号',
                          hintText: '090-1234-5678',
                          prefixIcon: const Icon(Icons.phone),
                          enabled: _selectedCustomer == null,
                          filled: _selectedCustomer != null,
                          fillColor: _selectedCustomer != null ? Colors.grey.shade100 : null,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      // 会員番号入力
                      TextField(
                        controller: _memberNumberController,
                        decoration: InputDecoration(
                          labelText: '会員番号',
                          hintText: 'M00001',
                          prefixIcon: const Icon(Icons.badge),
                          enabled: _selectedCustomer == null,
                          filled: _selectedCustomer != null,
                          fillColor: _selectedCustomer != null ? Colors.grey.shade100 : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // お客様名入力
                      Column(
                        children: [
                          TextField(
                            controller: _customerNameController,
                            decoration: InputDecoration(
                              labelText: 'お客様名',
                              prefixIcon: const Icon(Icons.person),
                              enabled: _selectedCustomer == null,
                              filled: _selectedCustomer != null,
                              fillColor: _selectedCustomer != null ? Colors.grey.shade100 : null,
                            ),
                          ),
                          // サジェストリスト
                          if (_suggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: _suggestions.map((customer) {
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      child: Text(customer.name[0]),
                                    ),
                                    title: Text(customer.name),
                                    subtitle: Text('${customer.phone} ${customer.memberNumber ?? ""}'),
                                    onTap: () => _selectCustomer(customer),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                      // 選択された顧客の情報表示
                      if (_selectedCustomer != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selectedCustomer!.name} 様が選択されました',
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _serviceController,
                decoration: const InputDecoration(
                labelText: 'サービス',
                prefixIcon: Icon(Icons.cut),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('日付'),
              subtitle: Text(DateFormat('yyyy年M月d日(E)', 'ja').format(_selectedDate)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('開始時間'),
              subtitle: Text(_startTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('終了時間'),
              subtitle: Text(_endTime.format(context)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                  });
                }
              },
            ),
            DropdownButtonFormField<String>(
              value: _selectedStaff,
              decoration: const InputDecoration(
                labelText: '担当スタッフ',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: ['山田スタイリスト', '鈴木スタイリスト', '佐藤スタイリスト']
                  .map((staff) => DropdownMenuItem(
                        value: staff,
                        child: Text(staff),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStaff = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Google カレンダーに同期'),
              secondary: const Icon(Icons.calendar_month),
              value: _syncToGoogle,
              onChanged: (value) {
                setState(() {
                  _syncToGoogle = value!;
                });
              },
            ),
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('予約を作成しました')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeService.primaryColor,
          ),
          child: const Text('作成'),
        ),
      ],
    );
  }
}

// 日付別予約表示ウィジェット（タイムライン/リスト切替可能）
class _DayAppointmentsView extends StatefulWidget {
  final DateTime date;
  final List<Appointment> appointments;
  final VoidCallback onNewAppointment;
  final Function(Appointment) onAppointmentTap;
  
  const _DayAppointmentsView({
    required this.date,
    required this.appointments,
    required this.onNewAppointment,
    required this.onAppointmentTap,
  });
  
  @override
  State<_DayAppointmentsView> createState() => _DayAppointmentsViewState();
}

class _DayAppointmentsViewState extends State<_DayAppointmentsView> {
  String _viewMode = 'timeline'; // 'timeline' or 'list'
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('yyyy年M月d日(E)', 'ja').format(widget.date),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.appointments.length}件の予約',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    // 新規追加ボタン
                    IconButton(
                      onPressed: widget.onNewAppointment,
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 28,
                      color: themeService.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 表示モード切替ボタン
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ViewModeButton(
                          icon: Icons.timeline,
                          label: 'タイムライン',
                          isSelected: _viewMode == 'timeline',
                          onTap: () => setState(() => _viewMode = 'timeline'),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ViewModeButton(
                          icon: Icons.list,
                          label: 'リスト',
                          isSelected: _viewMode == 'list',
                          onTap: () => setState(() => _viewMode = 'list'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // コンテンツ
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _viewMode == 'timeline'
                  ? _buildTimelineView()
                  : _buildListView(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimelineView() {
    // 時間でソートしてグループ化
    final sortedAppointments = List<Appointment>.from(widget.appointments)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // 同じ開始時刻でグループ化
    final timeGroups = <DateTime, List<Appointment>>{};
    for (final appointment in sortedAppointments) {
      final time = appointment.startTime;
      timeGroups[time] ??= [];
      timeGroups[time]!.add(appointment);
    }
    
    final groupList = timeGroups.entries.toList();
    
    return ListView.builder(
      key: const ValueKey('timeline'),
      padding: const EdgeInsets.all(20),
      itemCount: groupList.length,
      itemBuilder: (context, index) {
        final group = groupList[index];
        final isLast = index == groupList.length - 1;
        
        if (group.value.length == 1) {
          // 単一の予約
          return _TimelineItem(
            appointment: group.value.first,
            isLast: isLast,
            onTap: () => widget.onAppointmentTap(group.value.first),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
        } else {
          // 複数の予約（同時刻）
          return _TimelineGroupItem(
            time: group.key,
            appointments: group.value,
            isLast: isLast,
            onTap: widget.onAppointmentTap,
          ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
        }
      },
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list'),
      padding: const EdgeInsets.all(16),
      itemCount: widget.appointments.length,
      itemBuilder: (context, index) {
        final appointment = widget.appointments[index];
        return _AppointmentCard(
          appointment: appointment,
          onTap: () => widget.onAppointmentTap(appointment),
        ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
      },
    );
  }
}

// 表示モード切替ボタン
class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? themeService.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? themeService.primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// タイムラインアイテム
class _TimelineItem extends StatelessWidget {
  final Appointment appointment;
  final bool isLast;
  final VoidCallback onTap;
  
  const _TimelineItem({
    required this.appointment,
    required this.isLast,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final timeFormat = DateFormat('HH:mm');
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間表示
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(appointment.startTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeFormat.format(appointment.endTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // タイムラインの線とドット
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(appointment.status).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // カード
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: themeService.primaryColorLight,
                          child: Text(
                            appointment.customerName[0],
                            style: TextStyle(
                              color: themeService.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.customerName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                appointment.serviceName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusChip(appointment.status),
                      ],
                    ),
                    if (appointment.note != null && appointment.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                appointment.note!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointment.staffName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '¥${appointment.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(AppointmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }
  
  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }
  
  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return '確定';
      case AppointmentStatus.pending:
        return '保留';
      case AppointmentStatus.cancelled:
        return 'キャンセル';
      case AppointmentStatus.completed:
        return '完了';
    }
  }
}

// 同時刻の複数予約を表示するタイムラインアイテム
class _TimelineGroupItem extends StatelessWidget {
  final DateTime time;
  final List<Appointment> appointments;
  final bool isLast;
  final Function(Appointment) onTap;
  
  const _TimelineGroupItem({
    required this.time,
    required this.appointments,
    required this.isLast,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final timeFormat = DateFormat('HH:mm');
    
    // 最も遅い終了時刻を取得
    DateTime latestEndTime = appointments.first.endTime;
    for (final appointment in appointments) {
      if (appointment.endTime.isAfter(latestEndTime)) {
        latestEndTime = appointment.endTime;
      }
    }
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間表示
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(time),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${appointments.length}件',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeService.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // タイムラインの線とドット（複数予約用の特別なデザイン）
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景の円
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // 数字表示
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: themeService.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${appointments.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // 横スクロール可能なカードリスト
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeService.primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: themeService.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '同時刻の予約',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeService.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${timeFormat.format(time)} - ${timeFormat.format(latestEndTime)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 横スクロール可能なカードリスト
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = appointments[index];
                        return Container(
                          width: 200,
                          margin: EdgeInsets.only(right: index < appointments.length - 1 ? 8 : 0),
                          child: _CompactAppointmentCard(
                            appointment: appointment,
                            onTap: () => onTap(appointment),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// コンパクトな予約カード（横並び表示用）
class _CompactAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  
  const _CompactAppointmentCard({
    required this.appointment,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final timeFormat = DateFormat('HH:mm');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スタッフバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 12,
                    color: themeService.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      appointment.staffName,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeService.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 顧客名
            Text(
              appointment.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // サービス名
            Text(
              appointment.serviceName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // 時間と価格
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${timeFormat.format(appointment.startTime)}-${timeFormat.format(appointment.endTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  '¥${appointment.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeService.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}