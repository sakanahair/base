import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';

class StoreInfoPage extends StatefulWidget {
  const StoreInfoPage({super.key});

  @override
  State<StoreInfoPage> createState() => _StoreInfoPageState();
}

class _StoreInfoPageState extends State<StoreInfoPage> {
  // モックデータ（業種によって切り替え可能）
  String _selectedIndustry = 'beauty'; // beauty, restaurant, clinic, fitness, retail
  
  final Map<String, Map<String, dynamic>> _mockData = {
    'beauty': {
      'storeName': 'SAKANA HAIR 表参道店',
      'industry': '美容室・サロン',
      'description': '最新トレンドを取り入れた都会的なヘアサロン。経験豊富なスタイリストが、お客様一人ひとりに合わせた施術をご提供します。',
      'postalCode': '150-0001',
      'prefecture': '東京都',
      'city': '渋谷区',
      'address': '神宮前4-12-10',
      'building': '表参道ヒルズウエストウォーク3F',
      'phone': '03-1234-5678',
      'email': 'omotesando@sakana-hair.jp',
      'website': 'https://sakana-hair.jp',
      'establishedYear': '2018',
      'numberOfSeats': '12席',
      'numberOfStaff': '8名',
      'parkingSpaces': '提携駐車場あり',
      'services': ['カット', 'カラー', 'パーマ', 'トリートメント', 'ヘッドスパ', '着付け'],
      'paymentMethods': ['現金', 'クレジットカード', 'PayPay', 'LINE Pay', '交通系IC'],
      'features': ['完全個室あり', 'キッズスペース', 'Wi-Fi完備', 'ドリンクサービス'],
    },
    'restaurant': {
      'storeName': '和食処 さかな',
      'industry': 'レストラン・飲食',
      'description': '新鮮な魚介類を使用した本格和食レストラン。落ち着いた雰囲気の中で、季節の味覚をお楽しみいただけます。',
      'postalCode': '104-0061',
      'prefecture': '東京都',
      'city': '中央区',
      'address': '銀座5-5-5',
      'building': '銀座プレイス B1F',
      'phone': '03-9876-5432',
      'email': 'info@sakana-restaurant.jp',
      'website': 'https://sakana-restaurant.jp',
      'establishedYear': '2015',
      'numberOfSeats': '48席（個室6室）',
      'numberOfStaff': '15名',
      'parkingSpaces': '専用駐車場5台',
      'services': ['ランチ', 'ディナー', 'コース料理', 'お弁当', 'ケータリング', '貸切パーティー'],
      'paymentMethods': ['現金', 'クレジットカード', 'PayPay', '楽天ペイ', 'Uber Eats'],
      'features': ['個室完備', '禁煙・喫煙席', 'バリアフリー', 'ソムリエ在籍'],
    },
    'clinic': {
      'storeName': 'さかなクリニック',
      'industry': 'クリニック・医療',
      'description': '地域の皆様の健康をサポートする総合内科クリニック。最新の医療設備と経験豊富な医師による診療を行っています。',
      'postalCode': '160-0022',
      'prefecture': '東京都',
      'city': '新宿区',
      'address': '新宿3-17-5',
      'building': 'T&Tビル 5F',
      'phone': '03-5555-1234',
      'email': 'contact@sakana-clinic.jp',
      'website': 'https://sakana-clinic.jp',
      'establishedYear': '2020',
      'numberOfSeats': '待合室20席',
      'numberOfStaff': '医師3名、看護師5名、事務2名',
      'parkingSpaces': '専用駐車場3台',
      'services': ['一般内科', '予防接種', '健康診断', 'オンライン診療', '訪問診療'],
      'paymentMethods': ['保険診療', '自費診療', '現金', 'クレジットカード'],
      'features': ['バリアフリー', '予約優先制', 'キッズスペース', '英語対応可'],
    },
    'fitness': {
      'storeName': 'SAKANA FITNESS 渋谷',
      'industry': 'フィットネス・ジム',
      'description': '24時間営業の最新フィットネスジム。パーソナルトレーニングから グループレッスンまで幅広くサポート。',
      'postalCode': '150-0002',
      'prefecture': '東京都',
      'city': '渋谷区',
      'address': '渋谷2-21-1',
      'building': '渋谷ヒカリエ B2F',
      'phone': '03-7777-8888',
      'email': 'shibuya@sakana-fitness.jp',
      'website': 'https://sakana-fitness.jp',
      'establishedYear': '2019',
      'numberOfSeats': '最大収容人数100名',
      'numberOfStaff': 'トレーナー12名、受付3名',
      'parkingSpaces': '提携駐車場（2時間無料）',
      'services': ['マシントレーニング', 'パーソナルトレーニング', 'ヨガ', 'ピラティス', 'ボクシング', 'サウナ'],
      'paymentMethods': ['月会費', 'クレジットカード', '口座振替', 'PayPay'],
      'features': ['24時間営業', 'シャワー完備', 'プロテインバー', 'レンタルウェア'],
    },
    'retail': {
      'storeName': 'SAKANA SELECT SHOP',
      'industry': '小売・物販',
      'description': 'セレクトショップとオリジナルブランドを展開。トレンドと品質にこだわった商品をご提供します。',
      'postalCode': '150-0001',
      'prefecture': '東京都',
      'city': '渋谷区',
      'address': '神宮前6-10-8',
      'building': '',
      'phone': '03-3333-4444',
      'email': 'shop@sakana-select.jp',
      'website': 'https://sakana-select.jp',
      'establishedYear': '2017',
      'numberOfSeats': '売場面積 150㎡',
      'numberOfStaff': '店長1名、スタッフ4名',
      'parkingSpaces': 'コインパーキング隣接',
      'services': ['店頭販売', 'オンライン販売', 'ギフトラッピング', '配送サービス', 'お直しサービス'],
      'paymentMethods': ['現金', 'クレジットカード', 'QRコード決済各種', '商品券', 'ギフトカード'],
      'features': ['免税対応', 'ポイントカード', 'メンバーズ特典', 'シーズンセール'],
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
        title: const Text('店舗情報', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
            // 店舗名と業種
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.store,
                            color: themeService.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentData['storeName'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: themeService.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  currentData['industry'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeService.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentData['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 基本情報
            _buildSection(
              title: '基本情報',
              icon: Icons.info_outline,
              items: [
                _InfoItem('設立年', currentData['establishedYear']),
                _InfoItem('座席数/規模', currentData['numberOfSeats']),
                _InfoItem('スタッフ数', currentData['numberOfStaff']),
                _InfoItem('駐車場', currentData['parkingSpaces']),
              ],
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 所在地
            _buildSection(
              title: '所在地',
              icon: Icons.location_on_outlined,
              items: [
                _InfoItem('郵便番号', '〒${currentData['postalCode']}'),
                _InfoItem('都道府県', currentData['prefecture']),
                _InfoItem('市区町村', currentData['city']),
                _InfoItem('住所', currentData['address']),
                if (currentData['building'].isNotEmpty)
                  _InfoItem('建物名', currentData['building']),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 連絡先
            _buildSection(
              title: '連絡先',
              icon: Icons.contact_phone_outlined,
              items: [
                _InfoItem('電話番号', currentData['phone']),
                _InfoItem('メールアドレス', currentData['email']),
                _InfoItem('ウェブサイト', currentData['website']),
              ],
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // サービス
            _buildListSection(
              title: 'サービス・メニュー',
              icon: Icons.menu_book_outlined,
              items: List<String>.from(currentData['services']),
              color: Colors.blue,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 決済方法
            _buildListSection(
              title: '決済方法',
              icon: Icons.payment_outlined,
              items: List<String>.from(currentData['paymentMethods']),
              color: Colors.green,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 20),
            
            // 設備・特徴
            _buildListSection(
              title: '設備・特徴',
              icon: Icons.star_outline,
              items: List<String>.from(currentData['features']),
              color: Colors.orange,
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Card(
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
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildListSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    return Card(
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
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  
  _InfoItem(this.label, this.value);
}