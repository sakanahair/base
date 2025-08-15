import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/business_hours_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/models/business_hours_model.dart';
import '../../../../core/theme/app_theme.dart';

class BusinessHoursEditPage extends StatefulWidget {
  const BusinessHoursEditPage({super.key});

  @override
  State<BusinessHoursEditPage> createState() => _BusinessHoursEditPageState();
}

class _BusinessHoursEditPageState extends State<BusinessHoursEditPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, DayHours> _regularHours;
  late List<DateTime> _holidays;
  late TextEditingController _breakTimeController;
  late TextEditingController _specialNotesController;
  late TextEditingController _reservationHoursController;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // 定期休業日
  final Map<String, bool> _regularClosedDays = {
    '毎週月曜日': false,
    '毎週火曜日': false,
    '毎週水曜日': false,
    '毎週木曜日': false,
    '毎週金曜日': false,
    '毎週土曜日': false,
    '毎週日曜日': false,
  };
  
  @override
  void initState() {
    super.initState();
    final service = Provider.of<BusinessHoursService>(context, listen: false);
    final hours = service.businessHours;
    
    if (hours != null) {
      _regularHours = Map.from(hours.regularHours);
      _holidays = _parseHolidaysToDateTimes(hours.holidays);
      _breakTimeController = TextEditingController(text: hours.breakTime ?? '');
      _specialNotesController = TextEditingController(text: hours.specialNotes ?? '');
      _reservationHoursController = TextEditingController(text: hours.reservationHours ?? '');
      
      // 定期休業日の設定を反映
      _regularHours.forEach((day, hours) {
        if (!hours.isOpen) {
          _regularClosedDays['毎週$day'] = true;
        }
      });
    } else {
      _regularHours = _createDefaultHours();
      _holidays = [];
      _breakTimeController = TextEditingController();
      _specialNotesController = TextEditingController();
      _reservationHoursController = TextEditingController(text: '24時間オンライン予約可能');
    }
  }
  
  List<DateTime> _parseHolidaysToDateTimes(List<String> holidays) {
    // 実際のアプリケーションでは、日付文字列をDateTimeに変換する処理が必要
    // ここではデモ用に現在の年の特定の日付を返す
    final now = DateTime.now();
    return [
      DateTime(now.year, 1, 1), // 元日
      DateTime(now.year, 1, 2), // 正月
      DateTime(now.year, 1, 3), // 正月
      DateTime(now.year, 12, 31), // 大晦日
    ];
  }
  
  Map<String, DayHours> _createDefaultHours() {
    return {
      '月曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '火曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '水曜日': DayHours(open: '定休日', close: '', isOpen: false, lastOrder: ''),
      '木曜日': DayHours(open: '10:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '金曜日': DayHours(open: '10:00', close: '21:00', isOpen: true, lastOrder: '20:00'),
      '土曜日': DayHours(open: '09:00', close: '20:00', isOpen: true, lastOrder: '19:00'),
      '日曜日': DayHours(open: '09:00', close: '19:00', isOpen: true, lastOrder: '18:00'),
    };
  }
  
  @override
  void dispose() {
    _breakTimeController.dispose();
    _specialNotesController.dispose();
    _reservationHoursController.dispose();
    super.dispose();
  }
  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final service = Provider.of<BusinessHoursService>(context, listen: false);
    
    // 定期休業日を反映
    _regularClosedDays.forEach((day, isClosed) {
      final dayName = day.replaceAll('毎週', '');
      if (isClosed) {
        _regularHours[dayName] = DayHours(
          open: '定休日',
          close: '',
          isOpen: false,
          lastOrder: '',
        );
      }
    });
    
    // 休業日を文字列リストに変換
    final holidayStrings = _holidays.map((date) {
      return DateFormat('yyyy年M月d日').format(date);
    }).toList();
    
    final updatedHours = service.businessHours?.copyWith(
      regularHours: _regularHours,
      holidays: holidayStrings,
      breakTime: _breakTimeController.text.isEmpty ? null : _breakTimeController.text,
      specialNotes: _specialNotesController.text.isEmpty ? null : _specialNotesController.text,
      reservationHours: _reservationHoursController.text.isEmpty ? null : _reservationHoursController.text,
    );
    
    if (updatedHours != null) {
      await service.saveBusinessHours(updatedHours);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('営業時間を保存しました')),
      );
      Navigator.pop(context);
    }
  }
  
  void _toggleHoliday(DateTime day) {
    setState(() {
      final normalizedDay = DateTime(day.year, day.month, day.day);
      if (_holidays.any((h) => isSameDay(h, normalizedDay))) {
        _holidays.removeWhere((h) => isSameDay(h, normalizedDay));
      } else {
        _holidays.add(normalizedDay);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final service = Provider.of<BusinessHoursService>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('営業時間を編集', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (service.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                '保存',
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 通常営業時間
              _buildSectionTitle('通常営業時間', Icons.schedule),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _regularHours.entries.map((entry) {
                      final day = entry.key;
                      final hours = entry.value;
                      final isRegularClosed = _regularClosedDays['毎週$day'] ?? false;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isRegularClosed ? Colors.red : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (!isRegularClosed) ...[
                              Expanded(
                                child: Row(
                                  children: [
                                    _buildTimeField(
                                      label: '開店',
                                      value: hours.open,
                                      onChanged: (value) {
                                        setState(() {
                                          _regularHours[day] = hours.copyWith(open: value);
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('〜'),
                                    const SizedBox(width: 8),
                                    _buildTimeField(
                                      label: '閉店',
                                      value: hours.close,
                                      onChanged: (value) {
                                        setState(() {
                                          _regularHours[day] = hours.copyWith(close: value);
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _buildTimeField(
                                      label: 'L.O.',
                                      value: hours.lastOrder,
                                      onChanged: (value) {
                                        setState(() {
                                          _regularHours[day] = hours.copyWith(lastOrder: value);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '定休日',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 定期休業日
              _buildSectionTitle('定期休業日', Icons.event_busy),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _regularClosedDays.entries.map((entry) {
                      return FilterChip(
                        label: Text(entry.key),
                        selected: entry.value,
                        onSelected: (selected) {
                          setState(() {
                            _regularClosedDays[entry.key] = selected;
                          });
                        },
                        selectedColor: Colors.red.shade100,
                        checkmarkColor: Colors.red,
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // カレンダーで休業日を選択
              _buildSectionTitle('臨時休業日', Icons.calendar_today),
              const SizedBox(height: 16),
              
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        locale: 'ja_JP',
                        selectedDayPredicate: (day) {
                          return _holidays.any((holiday) => isSameDay(holiday, day));
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          _toggleHoliday(selectedDay);
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
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          selectedDecoration: BoxDecoration(
                            color: Colors.red.shade400,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: const TextStyle(color: Colors.red),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          formatButtonTextStyle: TextStyle(
                            color: themeService.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (_holidays.any((holiday) => isSameDay(holiday, day))) {
                              return Positioned(
                                bottom: 1,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_holidays.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '選択された休業日',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _holidays.map((date) {
                            return Chip(
                              label: Text(
                                DateFormat('M月d日').format(date),
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => _toggleHoliday(date),
                              backgroundColor: Colors.red.shade50,
                              deleteIconColor: Colors.red,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // その他の設定
              _buildSectionTitle('その他の設定', Icons.settings),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _breakTimeController,
                decoration: InputDecoration(
                  labelText: '休憩時間',
                  hintText: '例: 14:30〜17:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _reservationHoursController,
                decoration: InputDecoration(
                  labelText: '予約受付時間',
                  hintText: '例: 24時間オンライン予約可能',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _specialNotesController,
                decoration: InputDecoration(
                  labelText: '備考',
                  hintText: '例: 最終受付はカットのみ閉店30分前',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: themeService.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimeField({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Expanded(
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: onChanged,
      ),
    );
  }
}