import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class RecentAppointmentsCard extends StatelessWidget {
  const RecentAppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    
    final appointments = [
      _AppointmentItem(
        customerName: '田中 花子',
        service: 'カット＆カラー',
        time: DateTime.now().add(const Duration(hours: 1)),
        staffName: '山田スタイリスト',
        status: _AppointmentStatus.confirmed,
      ),
      _AppointmentItem(
        customerName: '佐藤 太郎',
        service: 'カット',
        time: DateTime.now().add(const Duration(hours: 2)),
        staffName: '鈴木スタイリスト',
        status: _AppointmentStatus.confirmed,
      ),
      _AppointmentItem(
        customerName: '高橋 美咲',
        service: 'パーマ',
        time: DateTime.now().add(const Duration(hours: 3)),
        staffName: '山田スタイリスト',
        status: _AppointmentStatus.pending,
      ),
      _AppointmentItem(
        customerName: '渡辺 健一',
        service: 'カット',
        time: DateTime.now().add(const Duration(hours: 4)),
        staffName: '田中スタイリスト',
        status: _AppointmentStatus.confirmed,
      ),
      _AppointmentItem(
        customerName: '伊藤 優子',
        service: 'トリートメント',
        time: DateTime.now().add(const Duration(hours: 5)),
        staffName: '鈴木スタイリスト',
        status: _AppointmentStatus.confirmed,
      ),
    ];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本日の予約',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('すべて見る'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...appointments.map((appointment) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sidebarBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          appointment.customerName.substring(0, 1),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(appointment.status),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                appointment.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _getStatusText(appointment.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(appointment.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeFormat.format(appointment.time),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.cut,
                                size: 14,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                appointment.service,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '担当: ${appointment.staffName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Color _getStatusColor(_AppointmentStatus status) {
    switch (status) {
      case _AppointmentStatus.confirmed:
        return AppTheme.successColor;
      case _AppointmentStatus.pending:
        return AppTheme.warningColor;
      case _AppointmentStatus.cancelled:
        return AppTheme.errorColor;
    }
  }
  
  String _getStatusText(_AppointmentStatus status) {
    switch (status) {
      case _AppointmentStatus.confirmed:
        return '確定';
      case _AppointmentStatus.pending:
        return '保留';
      case _AppointmentStatus.cancelled:
        return 'キャンセル';
    }
  }
}

enum _AppointmentStatus {
  confirmed,
  pending,
  cancelled,
}

class _AppointmentItem {
  final String customerName;
  final String service;
  final DateTime time;
  final String staffName;
  final _AppointmentStatus status;

  _AppointmentItem({
    required this.customerName,
    required this.service,
    required this.time,
    required this.staffName,
    required this.status,
  });
}