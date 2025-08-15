import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/theme_service.dart';
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
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMockAppointments();
  }
  
  void _loadMockAppointments() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // 今日の予約
    _appointments[normalizedToday] = [
      Appointment(
        id: '1',
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
      Appointment(
        id: '2',
        customerName: '佐藤 太郎',
        serviceName: 'カット',
        startTime: DateTime(today.year, today.month, today.day, 14, 0),
        endTime: DateTime(today.year, today.month, today.day, 15, 0),
        status: AppointmentStatus.confirmed,
        staffName: '鈴木スタイリスト',
        price: 4500,
      ),
      Appointment(
        id: '3',
        customerName: '鈴木 美咲',
        serviceName: 'トリートメント',
        startTime: DateTime(today.year, today.month, today.day, 15, 30),
        endTime: DateTime(today.year, today.month, today.day, 16, 30),
        status: AppointmentStatus.pending,
        staffName: '山田スタイリスト',
        price: 6000,
      ),
    ];
    
    // 明日の予約
    final tomorrow = normalizedToday.add(const Duration(days: 1));
    _appointments[tomorrow] = [
      Appointment(
        id: '4',
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
    return _appointments[normalized] ?? [];
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
      appBar: AppBar(
        title: const Text('予約管理', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // Google カレンダー連携状態
          Container(
            margin: const EdgeInsets.only(right: 8),
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
          const SizedBox(width: 8),
        ],
      ),
      body: _viewMode == 'calendar' 
        ? _buildCalendarView(themeService, isMobile)
        : _viewMode == 'list'
          ? _buildListView(themeService)
          : _buildTimelineView(themeService),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewAppointmentDialog,
        backgroundColor: themeService.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildCalendarView(ThemeService themeService, bool isMobile) {
    final selectedAppointments = _selectedDay != null 
      ? _getAppointmentsForDay(_selectedDay!)
      : [];
    
    return Column(
      children: [
        // カレンダー
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'ja_JP',
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              eventLoader: _getAppointmentsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
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
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
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
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        
        // 選択日の予約一覧
        Expanded(
          child: selectedAppointments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDay != null
                        ? '${DateFormat('M月d日').format(_selectedDay!)}の予約はありません'
                        : '日付を選択してください',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: selectedAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = selectedAppointments[index];
                  return _AppointmentCard(
                    appointment: appointment,
                    onTap: () => _showAppointmentDetails(appointment),
                  ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
                },
              ),
        ),
      ],
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
    required this.customerName,
    required this.serviceName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.staffName,
    required this.price,
    this.note,
    this.isFromGoogle = false,
  });
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
          child: Row(
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
                          Text(
                            appointment.customerName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
                        icon: const Icon(Icons.cancel),
                        label: const Text('キャンセル'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
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
  const _NewAppointmentDialog();
  
  @override
  State<_NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<_NewAppointmentDialog> {
  final _customerNameController = TextEditingController();
  final _serviceController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _selectedStaff = '山田スタイリスト';
  bool _syncToGoogle = true;
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return AlertDialog(
      title: const Text('新規予約'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'お客様名',
                prefixIcon: Icon(Icons.person),
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
  
  @override
  void dispose() {
    _customerNameController.dispose();
    _serviceController.dispose();
    super.dispose();
  }
}