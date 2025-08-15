import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/business_hours_service.dart';
import '../../../../core/services/store_info_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'business_hours_edit_page.dart';

class BusinessHoursPage extends StatefulWidget {
  const BusinessHoursPage({super.key});

  @override
  State<BusinessHoursPage> createState() => _BusinessHoursPageState();
}

class _BusinessHoursPageState extends State<BusinessHoursPage> {
  @override
  void initState() {
    super.initState();
    // データを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BusinessHoursService>(context, listen: false).loadBusinessHours();
      Provider.of<StoreInfoService>(context, listen: false).loadStoreInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final hoursService = Provider.of<BusinessHoursService>(context);
    final storeService = Provider.of<StoreInfoService>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('営業時間', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessHoursEditPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: hoursService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : hoursService.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'エラーが発生しました',
                        style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hoursService.error!,
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => hoursService.loadBusinessHours(),
                        child: const Text('再試行'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hoursService.businessHours != null) ...[
                        // 店舗名表示
                        if (storeService.storeInfo != null)
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
                                  storeService.storeInfo!.storeName,
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
                                ...hoursService.businessHours!.regularHours.entries.map((entry) {
                                  final day = entry.key;
                                  final hours = entry.value;
                                  final isOpen = hours.isOpen;
                                  
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
                                            hours.open,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          if (hours.close.isNotEmpty) ...[
                                            Text(
                                              ' 〜 ',
                                              style: TextStyle(color: Colors.green.shade600),
                                            ),
                                            Text(
                                              hours.close,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                          if (hours.lastOrder.isNotEmpty) ...[
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'L.O. ${hours.lastOrder}',
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
                        if (hoursService.businessHours!.breakTime != null && 
                            hoursService.businessHours!.breakTime!.isNotEmpty) ...[
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
                                    hoursService.businessHours!.breakTime!,
                                    style: TextStyle(color: Colors.brown.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        ],
                        
                        // 定休日
                        if (hoursService.businessHours!.holidays.isNotEmpty) ...[
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
                                  ...hoursService.businessHours!.holidays.map((holiday) => Padding(
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
                        ],
                        
                        // 予約受付時間
                        if (hoursService.businessHours!.reservationHours != null &&
                            hoursService.businessHours!.reservationHours!.isNotEmpty) ...[
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
                                          hoursService.businessHours!.reservationHours!,
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
                        ],
                        
                        // 特記事項
                        if (hoursService.businessHours!.specialNotes != null &&
                            hoursService.businessHours!.specialNotes!.isNotEmpty) ...[
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
                                          hoursService.businessHours!.specialNotes!,
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
                      ] else ...[
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                '営業時間が設定されていません',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BusinessHoursEditPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('営業時間を設定'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeService.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}