import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentSettingsPage extends StatefulWidget {
  const PaymentSettingsPage({super.key});

  @override
  State<PaymentSettingsPage> createState() => _PaymentSettingsPageState();
}

class _PaymentSettingsPageState extends State<PaymentSettingsPage> {
  String _selectedIndustry = 'beauty';
  
  final Map<String, Map<String, dynamic>> _mockData = {
    'beauty': {
      'storeName': 'SAKANA HAIR 表参道店',
      'acceptedPayments': {
        '現金': {'enabled': true, 'icon': Icons.money, 'color': Colors.green},
        'クレジットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue, 
          'brands': ['VISA', 'Mastercard', 'JCB', 'AMEX', 'Diners']},
        'デビットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.teal},
        'PayPay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'LINE Pay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': const Color(0xFF00B900)},
        '楽天ペイ': {'enabled': false, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'd払い': {'enabled': false, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'au PAY': {'enabled': false, 'icon': Icons.qr_code_2, 'color': Colors.orange},
        'メルペイ': {'enabled': false, 'icon': Icons.qr_code_2, 'color': Colors.red},
        '交通系IC': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue,
          'brands': ['Suica', 'PASMO', 'ICOCA', 'Kitaca', 'TOICA', 'manaca', 'SUGOCA', 'nimoca', 'はやかけん']},
        '電子マネー': {'enabled': false, 'icon': Icons.account_balance_wallet, 'color': Colors.purple,
          'brands': ['iD', 'QUICPay', 'nanaco', 'WAON', '楽天Edy']},
      },
      'paymentPolicy': '前払い制（施術前にお支払い）',
      'cancellationPolicy': '予約前日まで無料、当日キャンセルは50%',
      'depositRequired': false,
      'minimumCharge': null,
      'serviceCharge': null,
      'taxSettings': '内税表示',
    },
    'restaurant': {
      'storeName': '和食処 さかな',
      'acceptedPayments': {
        '現金': {'enabled': true, 'icon': Icons.money, 'color': Colors.green},
        'クレジットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue,
          'brands': ['VISA', 'Mastercard', 'JCB', 'AMEX', 'Diners', 'UnionPay']},
        'PayPay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        '楽天ペイ': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'd払い': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'Uber Eats': {'enabled': true, 'icon': Icons.delivery_dining, 'color': Colors.green},
        '出前館': {'enabled': true, 'icon': Icons.delivery_dining, 'color': Colors.orange},
        '食事券': {'enabled': true, 'icon': Icons.confirmation_number, 'color': Colors.purple},
        'GoToEat': {'enabled': true, 'icon': Icons.confirmation_number, 'color': Colors.blue},
        '交通系IC': {'enabled': false, 'icon': Icons.credit_card, 'color': Colors.blue},
      },
      'paymentPolicy': '後払い制（お食事後にレジでお支払い）',
      'cancellationPolicy': 'コース予約は前日17時まで無料',
      'depositRequired': true,
      'depositDetails': '10名様以上のご予約は前金3,000円/人',
      'minimumCharge': 'ディナータイム お一人様3,000円〜',
      'serviceCharge': 'ディナータイム 10%（個室利用時）',
      'taxSettings': '内税表示',
    },
    'clinic': {
      'storeName': 'さかなクリニック',
      'acceptedPayments': {
        '保険診療': {'enabled': true, 'icon': Icons.medical_services, 'color': Colors.red},
        '現金': {'enabled': true, 'icon': Icons.money, 'color': Colors.green},
        'クレジットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue,
          'brands': ['VISA', 'Mastercard', 'JCB']},
        'デビットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.teal},
        'PayPay': {'enabled': false, 'icon': Icons.qr_code_2, 'color': Colors.red},
        '医療ローン': {'enabled': true, 'icon': Icons.account_balance, 'color': Colors.indigo},
      },
      'paymentPolicy': '診療後にお支払い',
      'cancellationPolicy': '予約前日までにご連絡ください',
      'depositRequired': false,
      'minimumCharge': null,
      'serviceCharge': null,
      'taxSettings': '医療費は非課税',
      'insuranceInfo': '各種健康保険取り扱い、自費診療も対応',
    },
    'fitness': {
      'storeName': 'SAKANA FITNESS 渋谷',
      'acceptedPayments': {
        'クレジットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue,
          'brands': ['VISA', 'Mastercard', 'JCB', 'AMEX']},
        '口座振替': {'enabled': true, 'icon': Icons.account_balance, 'color': Colors.indigo},
        'PayPay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        '現金': {'enabled': false, 'icon': Icons.money, 'color': Colors.green},
        'コンビニ払い': {'enabled': true, 'icon': Icons.store, 'color': Colors.orange},
        '月会費プラン': {'enabled': true, 'icon': Icons.subscriptions, 'color': Colors.purple,
          'plans': ['レギュラー会員 8,800円/月', 'プレミアム会員 12,000円/月', 'VIP会員 20,000円/月']},
      },
      'paymentPolicy': '月会費制（毎月27日引き落とし）',
      'cancellationPolicy': '退会は前月15日までに申請',
      'depositRequired': true,
      'depositDetails': '入会金 5,000円 + 事務手数料 3,000円',
      'minimumCharge': null,
      'serviceCharge': null,
      'taxSettings': '内税表示',
    },
    'retail': {
      'storeName': 'SAKANA SELECT SHOP',
      'acceptedPayments': {
        '現金': {'enabled': true, 'icon': Icons.money, 'color': Colors.green},
        'クレジットカード': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue,
          'brands': ['VISA', 'Mastercard', 'JCB', 'AMEX', 'Diners']},
        'PayPay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'LINE Pay': {'enabled': true, 'icon': Icons.qr_code_2, 'color': const Color(0xFF00B900)},
        '楽天ペイ': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'd払い': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        'au PAY': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.orange},
        'メルペイ': {'enabled': true, 'icon': Icons.qr_code_2, 'color': Colors.red},
        '交通系IC': {'enabled': true, 'icon': Icons.credit_card, 'color': Colors.blue},
        '商品券': {'enabled': true, 'icon': Icons.confirmation_number, 'color': Colors.purple},
        'ギフトカード': {'enabled': true, 'icon': Icons.card_giftcard, 'color': Colors.pink},
      },
      'paymentPolicy': 'レジにてお支払い',
      'cancellationPolicy': 'オンライン注文は発送前までキャンセル可',
      'depositRequired': false,
      'minimumCharge': null,
      'serviceCharge': null,
      'taxSettings': '内税表示',
      'returnPolicy': '購入後7日以内、未使用品に限り返品可',
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
        title: const Text('決済設定'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
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
            // 店舗名
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
            
            // 利用可能な決済方法
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
                        Icon(Icons.payment, size: 20, color: themeService.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          '利用可能な決済方法',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...(currentData['acceptedPayments'] as Map<String, dynamic>).entries.map((entry) {
                      final method = entry.key;
                      final details = entry.value as Map<String, dynamic>;
                      final isEnabled = details['enabled'] as bool;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isEnabled ? Colors.white : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isEnabled 
                              ? (details['color'] as Color).withOpacity(0.3)
                              : Colors.grey.shade300,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isEnabled 
                                ? (details['color'] as Color).withOpacity(0.1)
                                : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              details['icon'] as IconData,
                              color: isEnabled 
                                ? details['color'] as Color
                                : Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            method,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isEnabled ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          subtitle: details.containsKey('brands') 
                            ? Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: (details['brands'] as List).take(3).map((brand) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isEnabled 
                                        ? (details['color'] as Color).withOpacity(0.1)
                                        : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      brand,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isEnabled 
                                          ? details['color'] as Color
                                          : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ).toList()
                                  ..addAll(
                                    (details['brands'] as List).length > 3
                                      ? [Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            '+${(details['brands'] as List).length - 3}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        )]
                                      : [],
                                  ),
                              )
                            : details.containsKey('plans')
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (details['plans'] as List).map((plan) => 
                                    Text(
                                      plan,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ).toList(),
                                )
                              : null,
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (value) {
                              // 実際の実装では状態を更新
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('決済方法の設定は準備中です')),
                              );
                            },
                            activeColor: details['color'] as Color,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 支払いポリシー
            _buildInfoCard(
              title: '支払いポリシー',
              icon: Icons.policy,
              color: Colors.blue,
              content: currentData['paymentPolicy'] as String,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            
            // キャンセルポリシー
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'キャンセルポリシー',
              icon: Icons.cancel_presentation,
              color: Colors.orange,
              content: currentData['cancellationPolicy'] as String,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
            // デポジット
            if (currentData['depositRequired'] == true) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'デポジット・入会金',
                icon: Icons.savings,
                color: Colors.green,
                content: currentData['depositDetails'] as String,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            ],
            
            // 最低料金
            if (currentData['minimumCharge'] != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: '最低料金',
                icon: Icons.attach_money,
                color: Colors.purple,
                content: currentData['minimumCharge'] as String,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            ],
            
            // サービス料
            if (currentData['serviceCharge'] != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'サービス料',
                icon: Icons.room_service,
                color: Colors.teal,
                content: currentData['serviceCharge'] as String,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
            ],
            
            // 税金設定
            const SizedBox(height: 16),
            _buildInfoCard(
              title: '税金設定',
              icon: Icons.receipt_long,
              color: Colors.indigo,
              content: currentData['taxSettings'] as String,
              subtitle: currentData['insuranceInfo'] as String?,
            ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
            
            // 返品ポリシー
            if (currentData['returnPolicy'] != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: '返品ポリシー',
                icon: Icons.assignment_return,
                color: Colors.pink,
                content: currentData['returnPolicy'] as String,
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
    String? subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}