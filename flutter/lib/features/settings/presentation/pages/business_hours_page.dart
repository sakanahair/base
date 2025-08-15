import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';

class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  // 業種別のモックデータ
  String _selectedIndustry = 'beauty';
  
  final Map<String, Map<String, dynamic>> _mockData = {
    'beauty': {
      'storeName': 'SAKANA HAIR 表参道店',
      'regularHours': {
        '月曜日': {'open': '10:00', 'close': '20:00', 'isOpen': true, 'lastOrder': '19:00'},
        '火曜日': {'open': '10:00', 'close': '20:00', 'isOpen': true, 'lastOrder': '19:00'},
        '水曜日': {'open': '定休日', 'close': '', 'isOpen': false, 'lastOrder': ''},
        '木曜日': {'open': '10:00', 'close': '20:00', 'isOpen': true, 'lastOrder': '19:00'},
        '金曜日': {'open': '10:00', 'close': '21:00', 'isOpen': true, 'lastOrder': '20:00'},
        '土曜日': {'open': '09:00', 'close': '20:00', 'isOpen': true, 'lastOrder': '19:00'},
        '日曜日': {'open': '09:00', 'close': '19:00', 'isOpen': true, 'lastOrder': '18:00'},
      },
      'holidays': ['年末年始（12/31〜1/3）', '夏季休業（8/13〜8/15）'],
      'specialNotes': '最終受付はカットのみ閉店30分前、カラー・パーマは閉店1時間前',
      'reservationHours': '24時間オンライン予約可能',
      'breakTime': null,
    },
    'restaurant': {
      'storeName': '和食処 さかな',
      'regularHours': {
        '月曜日': {'open': '定休日', 'close': '', 'isOpen': false, 'lastOrder': ''},
        '火曜日': {'open': '11:30', 'close': '22:00', 'isOpen': true, 'lastOrder': '21:00'},
        '水曜日': {'open': '11:30', 'close': '22:00', 'isOpen': true, 'lastOrder': '21:00'},
        '木曜日': {'open': '11:30', 'close': '22:00', 'isOpen': true, 'lastOrder': '21:00'},
        '金曜日': {'open': '11:30', 'close': '23:00', 'isOpen': true, 'lastOrder': '22:00'},
        '土曜日': {'open': '11:00', 'close': '23:00', 'isOpen': true, 'lastOrder': '22:00'},
        '日曜日': {'open': '11:00', 'close': '21:00', 'isOpen': true, 'lastOrder': '20:00'},
      },
      'holidays': ['月曜日（祝日の場合は翌日）', '年末年始'],
      'specialNotes': 'ランチ 11:30-14:30 / ディナー 17:00-ラストオーダー',
      'reservationHours': '前日までの予約推奨',
      'breakTime': '14:30〜17:00',
    },
    'clinic': {
      'storeName': 'さかなクリニック',
      'regularHours': {
        '月曜日': {'open': '09:00', 'close': '18:00', 'isOpen': true, 'lastOrder': '17:30'},
        '火曜日': {'open': '09:00', 'close': '18:00', 'isOpen': true, 'lastOrder': '17:30'},
        '水曜日': {'open': '09:00', 'close': '13:00', 'isOpen': true, 'lastOrder': '12:30'},
        '木曜日': {'open': '09:00', 'close': '18:00', 'isOpen': true, 'lastOrder': '17:30'},
        '金曜日': {'open': '09:00', 'close': '18:00', 'isOpen': true, 'lastOrder': '17:30'},
        '土曜日': {'open': '09:00', 'close': '13:00', 'isOpen': true, 'lastOrder': '12:30'},
        '日曜日': {'open': '定休日', 'close': '', 'isOpen': false, 'lastOrder': ''},
      },
      'holidays': ['日曜日', '祝日', '年末年始', 'お盆期間'],
      'specialNotes': '午前受付 8:30-12:00 / 午後受付 14:00-17:30',
      'reservationHours': '電話予約 8:30-17:30（診療時間内）',
      'breakTime': '13:00〜14:00',
    },
    'fitness': {
      'storeName': 'SAKANA FITNESS 渋谷',
      'regularHours': {
        '月曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '火曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '水曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '木曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '金曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '土曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
        '日曜日': {'open': '24時間', 'close': '', 'isOpen': true, 'lastOrder': ''},
      },
      'holidays': ['年中無休（メンテナンス日除く）'],
      'specialNotes': 'スタッフ対応時間 10:00-21:00 / パーソナルトレーニング 10:00-22:00',
      'reservationHours': 'アプリから24時間予約可能',
      'breakTime': null,
    },
    'retail': {
      'storeName': 'SAKANA SELECT SHOP',
      'regularHours': {
        '月曜日': {'open': '11:00', 'close': '20:00', 'isOpen': true, 'lastOrder': ''},
        '火曜日': {'open': '11:00', 'close': '20:00', 'isOpen': true, 'lastOrder': ''},
        '水曜日': {'open': '定休日', 'close': '', 'isOpen': false, 'lastOrder': ''},
        '木曜日': {'open': '11:00', 'close': '20:00', 'isOpen': true, 'lastOrder': ''},
        '金曜日': {'open': '11:00', 'close': '20:00', 'isOpen': true, 'lastOrder': ''},
        '土曜日': {'open': '10:00', 'close': '20:00', 'isOpen': true, 'lastOrder': ''},
        '日曜日': {'open': '10:00', 'close': '19:00', 'isOpen': true, 'lastOrder': ''},
      },
      'holidays': ['水曜日（不定休）', '年末年始'],
      'specialNotes': 'セール期間中は営業時間を延長する場合があります',
      'reservationHours': 'オンラインショップは24時間営業',
      'breakTime': null,
    },
  };

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final currentData = _mockData[_selectedIndustry]!;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('営業時間'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 業種切り替えボタン（デモ用）
          PopupMenuButton<String>(
            icon: Icon(Icons.swap_horiz, color: themeService.primaryColor),
            onSelected: (value) {
              setState(() {
                _selectedIndustry = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'beauty', child: Text('美容室・サロン')),
              const PopupMenuItem(value: 'restaurant', child: Text('レストラン・飲食')),
              const PopupMenuItem(value: 'clinic', child: Text('クリニック・医療')),
              const PopupMenuItem(value: 'fitness', child: Text('フィットネス・ジム')),
              const PopupMenuItem(value: 'retail', child: Text('小売・物販')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('編集機能は準備中です')),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 店舗名表示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeService.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeService.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.store, color: themeService.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    currentData['storeName'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeService.primaryColor,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // 通常営業時間
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 20, color: themeService.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          '営業時間',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...currentData['regularHours'].entries.map((entry) {
                      final day = entry.key;
                      final hours = entry.value;
                      final isOpen = hours['isOpen'] as bool;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOpen ? Colors.green.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isOpen ? Colors.green.shade700 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            if (isOpen) ...[
                              Icon(Icons.access_time, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 8),
                              Text(
                                hours['open'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              if (hours['close'].isNotEmpty) ...[
                                Text(
                                  ' 〜 ',
                                  style: TextStyle(color: Colors.green.shade600),
                                ),
                                Text(
                                  hours['close'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                              if (hours['lastOrder'].isNotEmpty) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'L.O. ${hours['lastOrder']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '定休日',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            
            // 休憩時間
            if (currentData['breakTime'] != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.coffee, size: 20, color: Colors.brown),
                      const SizedBox(width: 12),
                      const Text(
                        '休憩時間：',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        currentData['breakTime'],
                        style: TextStyle(color: Colors.brown.shade700),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            ],
            
            // 定休日
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_busy, size: 20, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        const Text(
                          '定休日・休業日',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(currentData['holidays'] as List).map((holiday) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 16, color: Colors.red.shade300),
                          const SizedBox(width: 8),
                          Text(holiday),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
            // 予約受付時間
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '予約受付',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentData['reservationHours'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            
            // 特記事項
            if (currentData['specialNotes'] != null) ...[
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.amber.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '備考',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentData['specialNotes'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}