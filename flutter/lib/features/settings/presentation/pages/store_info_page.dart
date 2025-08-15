import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/services/store_info_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'store_info_edit_page.dart';

class StoreInfoPage extends StatefulWidget {
  const StoreInfoPage({super.key});

  @override
  State<StoreInfoPage> createState() => _StoreInfoPageState();
}

class _StoreInfoPageState extends State<StoreInfoPage> {
  @override
  void initState() {
    super.initState();
    // データを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoreInfoService>(context, listen: false).loadStoreInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final storeService = Provider.of<StoreInfoService>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('店舗情報', style: TextStyle(color: Colors.black87)),
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
                  builder: (context) => const StoreInfoEditPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: storeService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeService.error != null
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
                        storeService.error!,
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => storeService.loadStoreInfo(),
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
                      if (storeService.storeInfo != null) ...[
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
                                            storeService.storeInfo!.storeName,
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
                                              storeService.storeInfo!.industry,
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
                                if (storeService.storeInfo!.description.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    storeService.storeInfo!.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
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
                            _InfoItem('設立年', storeService.storeInfo!.establishedYear),
                            _InfoItem('座席数/規模', storeService.storeInfo!.numberOfSeats),
                            _InfoItem('スタッフ数', storeService.storeInfo!.numberOfStaff),
                            _InfoItem('駐車場', storeService.storeInfo!.parkingSpaces),
                          ],
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 20),
                        
                        // 所在地
                        _buildSection(
                          title: '所在地',
                          icon: Icons.location_on_outlined,
                          items: [
                            if (storeService.storeInfo!.postalCode.isNotEmpty)
                              _InfoItem('郵便番号', '〒${storeService.storeInfo!.postalCode}'),
                            if (storeService.storeInfo!.prefecture.isNotEmpty)
                              _InfoItem('都道府県', storeService.storeInfo!.prefecture),
                            if (storeService.storeInfo!.city.isNotEmpty)
                              _InfoItem('市区町村', storeService.storeInfo!.city),
                            if (storeService.storeInfo!.address.isNotEmpty)
                              _InfoItem('住所', storeService.storeInfo!.address),
                            if (storeService.storeInfo!.building.isNotEmpty)
                              _InfoItem('建物名', storeService.storeInfo!.building),
                          ],
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                        
                        const SizedBox(height: 20),
                        
                        // 連絡先
                        _buildSection(
                          title: '連絡先',
                          icon: Icons.contact_phone_outlined,
                          items: [
                            if (storeService.storeInfo!.phone.isNotEmpty)
                              _InfoItem('電話番号', storeService.storeInfo!.phone),
                            if (storeService.storeInfo!.email.isNotEmpty)
                              _InfoItem('メールアドレス', storeService.storeInfo!.email),
                            if (storeService.storeInfo!.website.isNotEmpty)
                              _InfoItem('ウェブサイト', storeService.storeInfo!.website),
                          ],
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                        
                        if (storeService.storeInfo!.services.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildListSection(
                            title: 'サービス・メニュー',
                            icon: Icons.menu_book_outlined,
                            items: storeService.storeInfo!.services,
                            color: Colors.blue,
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                        ],
                        
                        if (storeService.storeInfo!.paymentMethods.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildListSection(
                            title: '決済方法',
                            icon: Icons.payment_outlined,
                            items: storeService.storeInfo!.paymentMethods,
                            color: Colors.green,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                        ],
                        
                        if (storeService.storeInfo!.features.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildListSection(
                            title: '設備・特徴',
                            icon: Icons.star_outline,
                            items: storeService.storeInfo!.features,
                            color: Colors.orange,
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                        ],
                      ] else ...[
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                '店舗情報が登録されていません',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StoreInfoEditPage(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('店舗情報を登録'),
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
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<_InfoItem> items,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    // 空のアイテムをフィルタリング
    final filteredItems = items.where((item) => item.value.isNotEmpty).toList();
    
    if (filteredItems.isEmpty) return const SizedBox.shrink();
    
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
            ...filteredItems.map((item) => Padding(
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