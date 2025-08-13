import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/service_image_gallery.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/mock_image_generator.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedIndustry = 'beauty'; // beauty, restaurant, clinic, fitness, retail
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // 業種別のカテゴリー定義
  final Map<String, List<String>> _industryCategories = {
    'beauty': ['カット', 'カラー', 'パーマ', 'トリートメント', 'ヘッドスパ', 'セット', 'その他'],
    'restaurant': ['前菜', 'メイン', 'デザート', 'ドリンク', 'コース', 'ランチ', 'ディナー'],
    'clinic': ['診察', '検査', '処置', '手術', '予防接種', 'カウンセリング', 'その他'],
    'fitness': ['パーソナル', 'グループ', 'ヨガ', 'ピラティス', 'マシン', '栄養指導', 'その他'],
    'retail': ['商品', 'サービス', 'レンタル', 'サブスク', 'メンテナンス', '配送', 'その他'],
  };
  
  // モックデータ
  List<ServiceItem> _services = [];
  List<ServiceItem> _filteredServices = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMockData();
    _filterServices();
    _initializeMockImages();
  }
  
  // モック画像を初期化
  Future<void> _initializeMockImages() async {
    final imageService = Provider.of<ImageService>(context, listen: false);
    
    // 美容室のサービス画像
    final cutImages = await MockImageGenerator.generateProductImages('カット', 3);
    for (int i = 0; i < cutImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '1', // カット
        imageData: cutImages[i],
        fileName: 'cut_${i + 1}.png',
      );
    }
    
    final colorImages = await MockImageGenerator.generateProductImages('カラー', 4);
    for (int i = 0; i < colorImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '4', // フルカラー
        imageData: colorImages[i],
        fileName: 'color_${i + 1}.png',
      );
    }
    
    final permImages = await MockImageGenerator.generateProductImages('パーマ', 2);
    for (int i = 0; i < permImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '6', // デジタルパーマ
        imageData: permImages[i],
        fileName: 'perm_${i + 1}.png',
      );
    }
    
    final treatmentImages = await MockImageGenerator.generateProductImages('トリートメント', 2);
    for (int i = 0; i < treatmentImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '7', // ヘアトリートメント
        imageData: treatmentImages[i],
        fileName: 'treatment_${i + 1}.png',
      );
    }
    
    // レストランのメニュー画像
    final lunchImages = await MockImageGenerator.generateProductImages('ランチ', 3);
    for (int i = 0; i < lunchImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '8', // 本日のパスタ
        imageData: lunchImages[i],
        fileName: 'lunch_${i + 1}.png',
      );
    }
    
    final dinnerImages = await MockImageGenerator.generateProductImages('ディナー', 2);
    for (int i = 0; i < dinnerImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '9', // ステーキセット
        imageData: dinnerImages[i],
        fileName: 'dinner_${i + 1}.png',
      );
    }
    
    // クリニックのサービス画像
    final clinicImages = await MockImageGenerator.generateProductImages('診察', 2);
    for (int i = 0; i < clinicImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '10', // 初診
        imageData: clinicImages[i],
        fileName: 'clinic_${i + 1}.png',
      );
    }
    
    final testImages = await MockImageGenerator.generateProductImages('検査', 3);
    for (int i = 0; i < testImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '11', // 血液検査
        imageData: testImages[i],
        fileName: 'test_${i + 1}.png',
      );
    }
    
    // フィットネスのサービス画像
    final personalImages = await MockImageGenerator.generateProductImages('パーソナル', 3);
    for (int i = 0; i < personalImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '12', // パーソナルトレーニング
        imageData: personalImages[i],
        fileName: 'personal_${i + 1}.png',
      );
    }
    
    final yogaImages = await MockImageGenerator.generateProductImages('ヨガ', 2);
    for (int i = 0; i < yogaImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '13', // ヨガクラス
        imageData: yogaImages[i],
        fileName: 'yoga_${i + 1}.png',
      );
    }
    
    // 小売の商品画像
    final productImages = await MockImageGenerator.generateProductImages('商品', 4);
    for (int i = 0; i < productImages.length; i++) {
      await imageService.uploadImage(
        serviceId: '14', // 配送サービス
        imageData: productImages[i],
        fileName: 'product_${i + 1}.png',
      );
    }
  }
  
  void _loadMockData() {
    // 美容室のサービス
    _services = [
      // カット
      ServiceItem(
        id: '1',
        name: 'カット',
        category: 'カット',
        price: 4500,
        duration: 60,
        description: 'シャンプー・ブロー込み',
        industry: 'beauty',
        isActive: true,
        options: ['シャンプーなし (-500円)', '炭酸スパ付き (+1000円)'],
      ),
      ServiceItem(
        id: '2',
        name: '前髪カット',
        category: 'カット',
        price: 1000,
        duration: 15,
        description: '前髪のみのカット',
        industry: 'beauty',
        isActive: true,
      ),
      ServiceItem(
        id: '3',
        name: '子供カット',
        category: 'カット',
        price: 3000,
        duration: 45,
        description: '小学生以下',
        industry: 'beauty',
        isActive: true,
      ),
      // カラー
      ServiceItem(
        id: '4',
        name: 'フルカラー',
        category: 'カラー',
        price: 7000,
        duration: 120,
        description: '根元から毛先まで',
        industry: 'beauty',
        isActive: true,
        options: ['トリートメント付き (+2000円)', 'ハイライト追加 (+3000円)'],
      ),
      ServiceItem(
        id: '5',
        name: 'リタッチカラー',
        category: 'カラー',
        price: 5000,
        duration: 90,
        description: '根元のみ（3cm以内）',
        industry: 'beauty',
        isActive: true,
      ),
      // パーマ
      ServiceItem(
        id: '6',
        name: 'デジタルパーマ',
        category: 'パーマ',
        price: 12000,
        duration: 180,
        description: 'カット込み',
        industry: 'beauty',
        isActive: true,
      ),
      // トリートメント
      ServiceItem(
        id: '7',
        name: 'ヘアトリートメント',
        category: 'トリートメント',
        price: 3000,
        duration: 30,
        description: '髪質改善トリートメント',
        industry: 'beauty',
        isActive: true,
        options: ['ホームケア付き (+1500円)'],
      ),
      // レストランのサービス
      ServiceItem(
        id: '8',
        name: '本日のパスタ',
        category: 'ランチ',
        price: 1200,
        duration: 0,
        description: '日替わりパスタ、サラダ・ドリンク付き',
        industry: 'restaurant',
        isActive: true,
      ),
      ServiceItem(
        id: '9',
        name: 'ステーキセット',
        category: 'ディナー',
        price: 3500,
        duration: 0,
        description: '150g、ライスorパン、サラダ付き',
        industry: 'restaurant',
        isActive: true,
        options: ['大盛り (+500円)', 'デザート付き (+300円)'],
      ),
      // クリニックのサービス
      ServiceItem(
        id: '10',
        name: '初診',
        category: '診察',
        price: 3000,
        duration: 30,
        description: '問診・診察',
        industry: 'clinic',
        isActive: true,
      ),
      ServiceItem(
        id: '11',
        name: '血液検査',
        category: '検査',
        price: 5000,
        duration: 15,
        description: '基本項目',
        industry: 'clinic',
        isActive: true,
      ),
      // フィットネスのサービス
      ServiceItem(
        id: '12',
        name: 'パーソナルトレーニング',
        category: 'パーソナル',
        price: 8000,
        duration: 60,
        description: 'マンツーマン指導',
        industry: 'fitness',
        isActive: true,
        options: ['延長30分 (+4000円)', '食事指導付き (+2000円)'],
      ),
      ServiceItem(
        id: '13',
        name: 'ヨガクラス',
        category: 'ヨガ',
        price: 2500,
        duration: 75,
        description: '初心者歓迎',
        industry: 'fitness',
        isActive: true,
      ),
      // 小売のサービス
      ServiceItem(
        id: '14',
        name: '配送サービス',
        category: '配送',
        price: 500,
        duration: 0,
        description: '5000円以上で無料',
        industry: 'retail',
        isActive: true,
      ),
    ];
  }
  
  void _filterServices() {
    setState(() {
      _filteredServices = _services.where((service) {
        final matchesIndustry = service.industry == _selectedIndustry;
        final matchesSearch = _searchQuery.isEmpty ||
            service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            service.category.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesIndustry && matchesSearch;
      }).toList();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'サービス管理',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_getIndustryName(_selectedIndustry)}のサービス一覧',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 業種切り替えボタン
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() {
                            _selectedIndustry = value;
                            _filterServices();
                          });
                        },
                        itemBuilder: (context) => [
                          _buildIndustryMenuItem('beauty', '美容室・サロン', Icons.cut),
                          _buildIndustryMenuItem('restaurant', 'レストラン・飲食', Icons.restaurant),
                          _buildIndustryMenuItem('clinic', 'クリニック・医療', Icons.local_hospital),
                          _buildIndustryMenuItem('fitness', 'フィットネス・ジム', Icons.fitness_center),
                          _buildIndustryMenuItem('retail', '小売・物販', Icons.store),
                        ],
                        child: Row(
                          children: [
                            Icon(
                              _getIndustryIcon(_selectedIndustry),
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getIndustryName(_selectedIndustry),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddServiceDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('サービス追加'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 検索バー
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'サービスを検索...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _filterServices();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _filterServices();
                    });
                  },
                ),
              ],
            ),
          ),
          // カテゴリータブ
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: ['すべて', ..._industryCategories[_selectedIndustry]!.take(4)]
                  .map((category) => Tab(text: category))
                  .toList(),
            ),
          ),
          // サービスリスト
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ['すべて', ..._industryCategories[_selectedIndustry]!.take(4)].map((category) {
                final services = category == 'すべて' 
                    ? _filteredServices
                    : _filteredServices.where((s) => s.category == category).toList();
                    
                return services.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(services[index]);
                        },
                      );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  PopupMenuItem<String> _buildIndustryMenuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
  
  Widget _buildServiceCard(ServiceItem service) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showEditServiceDialog(context, service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // サムネイル画像（すべての業種）
              FutureBuilder<List<ServiceImage>>(
                  future: Provider.of<ImageService>(context, listen: false)
                      .getServiceImages(service.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Stack(
                            children: [
                              Image.memory(
                                snapshot.data!.first.imageBytes,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                              if (snapshot.data!.length > 1)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '+${snapshot.data!.length - 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                    );
                  },
                ),
              // サービス情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(service.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getCategoryColor(service.category),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!service.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '無効',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (service.options.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: service.options.map((option) {
                          return Chip(
                            label: Text(
                              option,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.grey[100],
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              // 価格と時間
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (service.duration > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${service.duration}分',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              // アクションメニュー
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditServiceDialog(context, service);
                      break;
                    case 'duplicate':
                      _duplicateService(service);
                      break;
                    case 'toggle':
                      _toggleServiceStatus(service);
                      break;
                    case 'delete':
                      _confirmDeleteService(context, service);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('編集'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 12),
                        Text('複製'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          service.isActive ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(service.isActive ? '無効にする' : '有効にする'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'サービスがありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '新しいサービスを追加してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddServiceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('サービスを追加'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ServiceEditDialog(
        industry: _selectedIndustry,
        categories: _industryCategories[_selectedIndustry]!,
        onSave: (service) {
          setState(() {
            _services.add(service);
            _filterServices();
          });
        },
      ),
    );
  }
  
  void _showEditServiceDialog(BuildContext context, ServiceItem service) {
    showDialog(
      context: context,
      builder: (context) => ServiceEditDialog(
        service: service,
        industry: _selectedIndustry,
        categories: _industryCategories[_selectedIndustry]!,
        onSave: (updatedService) {
          setState(() {
            final index = _services.indexWhere((s) => s.id == service.id);
            if (index != -1) {
              _services[index] = updatedService;
              _filterServices();
            }
          });
        },
      ),
    );
  }
  
  void _duplicateService(ServiceItem service) {
    final newService = ServiceItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${service.name} (コピー)',
      category: service.category,
      price: service.price,
      duration: service.duration,
      description: service.description,
      industry: service.industry,
      isActive: service.isActive,
      options: List.from(service.options),
    );
    
    setState(() {
      _services.add(newService);
      _filterServices();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('サービスを複製しました'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _toggleServiceStatus(ServiceItem service) {
    setState(() {
      service.isActive = !service.isActive;
      _filterServices();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(service.isActive ? 'サービスを有効にしました' : 'サービスを無効にしました'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _confirmDeleteService(BuildContext context, ServiceItem service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サービスの削除'),
        content: Text('「${service.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _services.removeWhere((s) => s.id == service.id);
                _filterServices();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('サービスを削除しました'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
  
  String _getIndustryName(String industry) {
    switch (industry) {
      case 'beauty':
        return '美容室・サロン';
      case 'restaurant':
        return 'レストラン・飲食';
      case 'clinic':
        return 'クリニック・医療';
      case 'fitness':
        return 'フィットネス・ジム';
      case 'retail':
        return '小売・物販';
      default:
        return '不明';
    }
  }
  
  IconData _getIndustryIcon(String industry) {
    switch (industry) {
      case 'beauty':
        return Icons.cut;
      case 'restaurant':
        return Icons.restaurant;
      case 'clinic':
        return Icons.local_hospital;
      case 'fitness':
        return Icons.fitness_center;
      case 'retail':
        return Icons.store;
      default:
        return Icons.business;
    }
  }
  
  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    final categories = _industryCategories[_selectedIndustry]!;
    final index = categories.indexOf(category);
    return index >= 0 ? colors[index % colors.length] : Colors.grey;
  }
}

// サービスアイテムのモデル
class ServiceItem {
  final String id;
  String name;
  String category;
  double price;
  int duration; // 分単位（0の場合は時間指定なし）
  String description;
  String industry;
  bool isActive;
  List<String> options;
  
  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.duration,
    required this.description,
    required this.industry,
    required this.isActive,
    this.options = const [],
  });
}

// サービス編集ダイアログ
class ServiceEditDialog extends StatefulWidget {
  final ServiceItem? service;
  final String industry;
  final List<String> categories;
  final Function(ServiceItem) onSave;
  
  const ServiceEditDialog({
    super.key,
    this.service,
    required this.industry,
    required this.categories,
    required this.onSave,
  });
  
  @override
  State<ServiceEditDialog> createState() => _ServiceEditDialogState();
}

class _ServiceEditDialogState extends State<ServiceEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  final List<String> _options = [];
  final TextEditingController _optionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _priceController = TextEditingController(
      text: widget.service?.price.toStringAsFixed(0) ?? '',
    );
    _durationController = TextEditingController(
      text: widget.service?.duration.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _selectedCategory = widget.service?.category ?? widget.categories.first;
    if (widget.service != null) {
      _options.addAll(widget.service!.options);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _optionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.service == null ? Icons.add : Icons.edit,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.service == null ? 'サービスを追加' : 'サービスを編集',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // フォーム
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // サービス名
                    const Text(
                      'サービス名 *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'サービス名を入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // カテゴリー
                    const Text(
                      'カテゴリー *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: widget.categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 価格と時間
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '価格 (円) *',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                  prefixText: '¥ ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '所要時間 (分)',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: OutlineInputBorder(),
                                  suffixText: '分',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 説明
                    const Text(
                      '説明',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'サービスの説明を入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // オプション
                    const Text(
                      'オプション',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _optionController,
                            decoration: const InputDecoration(
                              hintText: 'オプション名と価格',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addOption(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: AppTheme.primaryColor,
                          onPressed: _addOption,
                        ),
                      ],
                    ),
                    if (_options.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _options.map((option) {
                          return Chip(
                            label: Text(option),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _options.remove(option);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // 画像ギャラリー（すべての業種）
                    ServiceImageGallery(
                      serviceId: widget.service?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                      isEditable: true,
                    ),
                  ],
                ),
              ),
            ),
            // フッター
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveService,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(widget.service == null ? '追加' : '保存'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addOption() {
    if (_optionController.text.isNotEmpty) {
      setState(() {
        _options.add(_optionController.text);
        _optionController.clear();
      });
    }
  }
  
  void _saveService() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('必須項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final service = ServiceItem(
      id: widget.service?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text) ?? 0,
      duration: int.tryParse(_durationController.text) ?? 0,
      description: _descriptionController.text,
      industry: widget.industry,
      isActive: widget.service?.isActive ?? true,
      options: _options,
    );
    
    widget.onSave(service);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.service == null ? 'サービスを追加しました' : 'サービスを更新しました'),
        backgroundColor: Colors.green,
      ),
    );
  }
}