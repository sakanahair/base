import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import '../../../../core/theme/app_theme.dart';
import '../widgets/service_image_gallery.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/services/service_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/utils/mock_image_generator.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedIndustry = 'beauty'; // beauty, restaurant, clinic, fitness, retail, general
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // 業種別のカテゴリー定義
  final Map<String, List<String>> _industryCategories = {
    'beauty': ['カット', 'カラー', 'パーマ', 'トリートメント', 'ヘッドスパ', 'セット', 'その他'],
    'restaurant': ['前菜', 'メイン', 'デザート', 'ドリンク', 'コース', 'ランチ', 'ディナー'],
    'clinic': ['診察', '検査', '処置', '手術', '予防接種', 'カウンセリング', 'その他'],
    'fitness': ['パーソナル', 'グループ', 'ヨガ', 'ピラティス', 'マシン', '栄養指導', 'その他'],
    'retail': ['商品', 'サービス', 'レンタル', 'サブスク', 'メンテナンス', '配送', 'その他'],
    'general': ['相談', 'コンサルティング', '作業', 'レッスン', 'イベント', 'レンタル', 'その他'],
  };
  
  late ServiceService _serviceService;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _serviceService = context.read<ServiceService>();
    _loadSavedIndustry();
    _initializeServices();
    _initializeMockImages();
  }
  
  Future<void> _initializeServices() async {
    await _serviceService.initialize();
    // Firebaseと同期して削除済みサービスを反映
    await _serviceService.syncWithFirebase();
  }
  
  // 保存された業種を読み込む
  Future<void> _loadSavedIndustry() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndustry = prefs.getString('selected_industry');
    if (savedIndustry != null && _industryCategories.containsKey(savedIndustry)) {
      setState(() {
        _selectedIndustry = savedIndustry;
      });
      _filterServices();
    }
  }
  
  // 選択した業種を保存
  Future<void> _saveSelectedIndustry(String industry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_industry', industry);
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
    // モックデータの初期化はServiceServiceが行うので削除
  }
  
  void _filterServices() {
    setState(() {
      // ServiceServiceの検索機能を使う
      _serviceService.setIndustry(_selectedIndustry);
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
    return Consumer<ServiceService>(
      builder: (context, serviceService, child) {
        final services = serviceService.searchServices(_searchQuery);
        final categories = serviceService.servicesByCategory;
        
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // ヘッダー
                Container(
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    MediaQuery.of(context).size.width < 600 ? 8 : 16,
                    MediaQuery.of(context).size.width < 600 ? 16 : 24,
                    MediaQuery.of(context).size.width < 600 ? 8 : 16,
                  ),
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
                // タイトル部分（シンプルに）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'サービス管理',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
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
                    // キャッシュクリアボタン（一時的）
                    TextButton.icon(
                      onPressed: () async {
                        final imageService = Provider.of<ImageService>(context, listen: false);
                        await imageService.clearCache();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('画像キャッシュをクリアしました'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.cleaning_services, size: 16),
                      label: const Text('キャッシュクリア', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 検索バー、業種選択、サービス追加を1行に（高さ統一）
                SizedBox(
                  height: 48, // 統一された高さ
                  child: Row(
                    children: [
                      // 検索バー（最初に配置）
                      Expanded(
                        child: TextField(
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
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _filterServices();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 業種選択ボタン（2番目）
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 40),
                          elevation: 8,
                          onSelected: (value) {
                            setState(() {
                              _selectedIndustry = value;
                              _saveSelectedIndustry(value);
                              _filterServices();
                            });
                          },
                          itemBuilder: (context) => [
                            _buildIndustryMenuItem('beauty', '美容室・サロン', Icons.cut),
                            _buildIndustryMenuItem('restaurant', 'レストラン・飲食', Icons.restaurant),
                            _buildIndustryMenuItem('clinic', 'クリニック・医療', Icons.local_hospital),
                            _buildIndustryMenuItem('fitness', 'フィットネス・ジム', Icons.fitness_center),
                            _buildIndustryMenuItem('retail', '小売・物販', Icons.store),
                            _buildIndustryMenuItem('general', 'その他一般', Icons.business_center),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getIndustryIcon(_selectedIndustry),
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getIndustryName(_selectedIndustry),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // サービス追加ボタン（3番目）
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddServiceDialog(context),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('追加'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                final filteredServices = category == 'すべて' 
                    ? services
                    : services.where((s) => s.category == category).toList();
                
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                    
                return filteredServices.isEmpty
                    ? _buildEmptyState()
                    : isMobile
                        ? ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              return _buildServiceCard(filteredServices[index]);
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: filteredServices.length,
                            itemBuilder: (context, index) {
                              return _buildServiceCard(filteredServices[index]);
                            },
                          );
              }).toList(),
            ),
            ),
          ],
        ),
      ),
    );
      },
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
  
  Widget _buildServiceCard(ServiceModel service) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dismissible(
      key: Key(service.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 左スワイプ（削除）
          return await _showDeleteConfirmDialog(context, service);
        } else {
          // 右スワイプ（編集）
          _showEditServiceDialog(context, service);
          return false;
        }
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          try {
            await _serviceService.deleteService(service.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('サービスを削除しました'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            print('Error deleting service: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('削除に失敗しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          children: [
            Icon(Icons.edit, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              '編集',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '削除',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white, size: 24),
          ],
        ),
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: isMobile ? 8 : 0),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => _showEditServiceDialog(context, service),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: isMobile 
                ? _buildMobileLayout(service)
                : _buildDesktopLayout(service),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
  
  Widget _buildMobileLayout(ServiceModel service) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // サムネイル画像
        if (service.images.isNotEmpty)
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: NetworkImage(service.images.first),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _getCategoryColor(service.category).withOpacity(0.1),
            ),
            child: Icon(
              _getCategoryIcon(service.category),
              color: _getCategoryColor(service.category),
              size: 24,
            ),
          ),
        // サービス情報
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトルと価格
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '¥${service.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // カテゴリと時間
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(service.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      service.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getCategoryColor(service.category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (service.duration > 0) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.access_time, size: 11, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      '${service.duration}分',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              // 説明
              if (service.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        // メニュー
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          offset: const Offset(0, 20),
          elevation: 8,
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditServiceDialog(context, service);
                break;
              case 'duplicate':
                _duplicateService(service);
                break;
              case 'delete':
                _confirmDeleteService(context, service);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('編集', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('複製', style: TextStyle(fontSize: 13, color: Colors.blue)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除', style: TextStyle(fontSize: 13, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildServiceThumbnail(ServiceImage image) {
    // Firebase URLがある場合はそれを使用
    if (image.firebaseUrl.isNotEmpty) {
      developer.log('Loading image from Firebase URL: ${image.firebaseUrl}', name: 'ServicesPage');
      return Image.network(
        image.firebaseUrl,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          developer.log('Failed to load image from Firebase URL: $error', name: 'ServicesPage', error: error);
          // Firebase URLが失敗した場合はローカルデータを試す
          if (image.localData.isNotEmpty) {
            return Image.memory(
              image.imageBytes,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                );
              },
            );
          }
          return Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      );
    }
    
    // Firebase URLがない場合はローカルデータを使用
    if (image.localData.isNotEmpty) {
      return Image.memory(
        image.imageBytes,
        fit: BoxFit.cover,
        width: 80,
        height: 80,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      );
    }
    
    // どちらもない場合はプレースホルダー
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        color: Colors.grey,
      ),
    );
  }
  
  Widget _buildDesktopLayout(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル（画像の上に配置）
        Text(
          service.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // 画像とコンテンツ
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // サムネイル画像
            Builder(
              builder: (context) {
                if (service.images.isNotEmpty) {
                  final imageUrl = service.images.first;
                  return Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: 70,
                            height: 70,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  _getCategoryIcon(service.category),
                                  color: Colors.grey[400],
                                  size: 28,
                                ),
                              );
                            },
                          ),
                          if (service.images.length > 1)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${service.images.length - 1}',
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
                    ),
                  );
                }
                
                // 画像がない場合のプレースホルダー
                return Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _getCategoryColor(service.category).withOpacity(0.1),
                    border: Border.all(color: _getCategoryColor(service.category).withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getCategoryIcon(service.category),
                    color: _getCategoryColor(service.category),
                    size: 28,
                  ),
                );
              },
            ),
            // サービス情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // カテゴリとステータス
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(service.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          service.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getCategoryColor(service.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!service.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '無効',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                    if (service.options.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 26,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: service.options.length > 3 ? 4 : service.options.length,
                          itemBuilder: (context, index) {
                            if (index == 3 && service.options.length > 3) {
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${service.options.length - 3}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            final option = service.options[index];
                            // オプションテキストを最大20文字に制限
                            final displayText = option.length > 20 
                                ? '${option.substring(0, 20)}...' 
                                : option;
                            return Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!, width: 0.5),
                              ),
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (service.duration > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${service.duration}分',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            // アクションメニュー
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              offset: const Offset(0, 20),
              elevation: 8,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditServiceDialog(context, service);
                    break;
                  case 'duplicate':
                    _duplicateService(service);
                    break;
                  case 'delete':
                    _confirmDeleteService(context, service);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('編集', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  height: 36,
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 16),
                      SizedBox(width: 8),
                      Text('複製', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                  const PopupMenuItem(
                    value: 'delete',
                    height: 36,
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('削除', style: TextStyle(fontSize: 13, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
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
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (context) => ServiceEditDialog(
        industry: _selectedIndustry,
        categories: _industryCategories[_selectedIndustry]!,
        onSave: (service) async {
          print('=== Creating new service (without images) ===');
          print('Service name: ${service.name}');
          
          // 新規サービスを作成（画像なし）
          final newService = await _serviceService.addService(
            name: service.name,
            category: service.category,
            price: service.price,
            duration: service.duration,
            description: service.description,
            options: service.options,
            images: [], // 画像は後から追加
            industry: _selectedIndustry,
          );
          
          print('New service created with ID: ${newService.id}');
          
          // 新規作成時は画像アップロードをしない
          // ユーザーに編集を促す
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('サービスを作成しました。画像を追加するには編集してください'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '編集',
                  textColor: Colors.white,
                  onPressed: () {
                    // 作成されたサービスを編集モードで開く
                    _showEditServiceDialog(context, newService);
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
  
  void _showEditServiceDialog(BuildContext context, ServiceModel service) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      useSafeArea: true,
      builder: (context) => ServiceEditDialog(
        service: service,
        industry: _selectedIndustry,
        categories: _industryCategories[_selectedIndustry]!,
        onSave: (updatedService) async {
          print('=== Updating existing service ===');
          print('Service ID: ${service.id}');
          print('Updated images: ${updatedService.images}');
          
          // 画像URLがFirebase URLであることを確認
          final validImageUrls = updatedService.images
              .where((url) => url.startsWith('https://'))
              .toList();
          
          print('Valid Firebase URLs: $validImageUrls');
          print('Number of valid Firebase URLs: ${validImageUrls.length}');
          
          // 既存サービスの更新
          await _serviceService.updateService(updatedService.copyWith(
            id: service.id, // 実際のIDを確実に使用
            images: validImageUrls, // Firebase URLのみを使用
          ));
          
          // Firebaseと即座に同期してiOSでも利用可能にする
          await _serviceService.syncWithFirebase();
          print('Service synced with Firebase - images should be available on iOS app');
        },
      ),
    );
  }
  
  void _duplicateService(ServiceModel service) async {
    // 複製用のダイアログを表示
    final nameController = TextEditingController(text: '${service.name} (コピー)');
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: const Text('サービスを複製'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('複製するサービスの名前を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'サービス名',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('複製'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.isNotEmpty) {
      await _serviceService.addService(
        name: nameController.text,
        category: service.category,
        price: service.price,
        duration: service.duration,
        description: service.description,
        options: List<String>.from(service.options),
        images: List<String>.from(service.images),
        industry: service.industry,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${nameController.text}」を作成しました'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<bool> _showDeleteConfirmDialog(BuildContext context, ServiceModel service) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: const Text('サービスの削除'),
        content: Text('「${service.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              // ダイアログを閉じて、削除を承認
              Navigator.pop(context, true);
              
              // 画像も削除（バックグラウンド処理）
              final imageService = Provider.of<ImageService>(context, listen: false);
              imageService.deleteAllServiceImages(service.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    ) ?? false;
    
    return result;
  }
  
  void _confirmDeleteService(BuildContext context, ServiceModel service) async {
    print('_confirmDeleteService called for service: ${service.id} - ${service.name}');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 削除中はダイアログを閉じられないように
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        title: const Text('サービスの削除'),
        content: Text('「${service.name}」を削除しますか？\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      try {
        print('Deleting service: ${service.id}');
        
        // 画像を先に削除（バックグラウンド処理）
        final imageService = Provider.of<ImageService>(context, listen: false);
        imageService.deleteAllServiceImages(service.id);
        
        // サービスを削除（Firebaseから削除）
        await _serviceService.deleteService(service.id);
        print('Service deleted: ${service.id}');
        
        // リアルタイムリスナーが自動的に更新を反映するので、手動更新は不要
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('サービスを削除しました'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error deleting service: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('削除に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
      case 'general':
        return 'その他一般';
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
      case 'general':
        return Icons.business_center;
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
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'カット':
        return Icons.cut;
      case 'カラー':
        return Icons.palette;
      case 'パーマ':
        return Icons.waves;
      case 'トリートメント':
        return Icons.spa;
      case 'ヘッドスパ':
        return Icons.self_improvement;
      case 'セット':
        return Icons.style;
      default:
        return Icons.category;
    }
  }
}

// サービス編集ダイアログ
class ServiceEditDialog extends StatefulWidget {
  final ServiceModel? service;
  final String industry;
  final List<String> categories;
  final Function(ServiceModel) onSave;
  
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
  List<String> _imageUrls = [];
  late String _tempServiceId; // 画像アップロード用の一時ID
  final TextEditingController _optionNameController = TextEditingController();
  final TextEditingController _optionPriceController = TextEditingController();
  
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
    
    // 既存サービスの編集時のみIDを使用
    // 新規作成時は画像アップロードを無効化
    _tempServiceId = widget.service?.id ?? '';
    
    if (widget.service != null) {
      _options.addAll(widget.service!.options);
      // Firebaseから取得済みの画像URLをそのまま使用
      _imageUrls = List<String>.from(widget.service!.images);
      // LocalStorageからの読み込みは不要（Firebaseが真実の源）
    }
  }
  
  
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // モバイルの場合はフルスクリーンScaffold
    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(widget.service == null ? 'サービスを追加' : 'サービスを編集'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        body: _buildFormContent(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }
    
    // デスクトップの場合はダイアログ
    return Dialog(
      elevation: 8,
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
              child: _buildFormContent(),
            ),
            // ボタン
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormContent() {
    return SingleChildScrollView(
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
                        // オプション名入力
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _optionNameController,
                            decoration: const InputDecoration(
                              hintText: 'オプション名',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (_) => _addOption(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 価格入力
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _optionPriceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              hintText: '価格',
                              prefixText: '¥',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (_) => _addOption(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 追加ボタン
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: AppTheme.primaryColor,
                          iconSize: 32,
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
                    // 画像ギャラリー（編集時のみ有効）
                    if (widget.service != null && _tempServiceId.isNotEmpty)
                      ServiceImageGallery(
                        serviceId: _tempServiceId,
                        isEditable: true,
                        initialImageUrls: _imageUrls, // Firebaseから取得済みの画像URLを渡す
                        onImagesChanged: (images) {
                          setState(() {
                            _imageUrls = images;
                          });
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '画像はサービス作成後に追加できます',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'まずサービス情報を保存してください',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: isMobile ? null : const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: isMobile ? Border(
          top: BorderSide(color: Colors.grey[300]!),
        ) : null,
      ),
      child: SafeArea(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(widget.service == null ? '追加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _addOption() {
    if (_optionNameController.text.isNotEmpty && _optionPriceController.text.isNotEmpty) {
      setState(() {
        final optionText = '${_optionNameController.text} ¥${_optionPriceController.text}';
        _options.add(optionText);
        _optionNameController.clear();
        _optionPriceController.clear();
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
    
    print('=== Saving service from dialog ===');
    print('Temp Service ID: $_tempServiceId');
    print('Image URLs: $_imageUrls');
    print('Image URLs length: ${_imageUrls.length}');
    
    // Firebase URLのみをフィルタリング
    final validImageUrls = _imageUrls
        .where((url) => url.startsWith('https://firebasestorage.googleapis.com/'))
        .toList();
    
    print('Valid Firebase URLs: $validImageUrls');
    for (var i = 0; i < validImageUrls.length; i++) {
      print('Firebase URL $i: ${validImageUrls[i]}');
    }
    
    final now = DateTime.now();
    final service = ServiceModel(
      id: _tempServiceId, // 一時IDを使用（新規作成時はtemp_、編集時は実際のID）
      name: _nameController.text,
      category: _selectedCategory,
      price: double.tryParse(_priceController.text) ?? 0,
      duration: int.tryParse(_durationController.text) ?? 0,
      description: _descriptionController.text,
      industry: widget.industry,
      options: _options,
      images: validImageUrls, // Firebase URLのみを使用
      createdAt: widget.service?.createdAt ?? now,
      updatedAt: now,
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