import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/store_info_service.dart';
import '../../../../core/services/theme_service.dart';
import '../../../../core/theme/app_theme.dart';

class StoreInfoEditPage extends StatefulWidget {
  const StoreInfoEditPage({super.key});

  @override
  State<StoreInfoEditPage> createState() => _StoreInfoEditPageState();
}

class _StoreInfoEditPageState extends State<StoreInfoEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _postalCodeController;
  late TextEditingController _prefectureController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _buildingController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _establishedYearController;
  late TextEditingController _numberOfSeatsController;
  late TextEditingController _numberOfStaffController;
  late TextEditingController _parkingSpacesController;
  
  // リスト項目用のコントローラー
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _featureController = TextEditingController();
  
  String _selectedIndustry = '美容室・サロン';
  List<String> _services = [];
  List<String> _paymentMethods = [];
  List<String> _features = [];

  final List<String> _industryOptions = [
    '美容室・サロン',
    'レストラン・飲食',
    'クリニック・医療',
    'フィットネス・ジム',
    '小売・物販',
    'その他'
  ];

  @override
  void initState() {
    super.initState();
    final storeService = Provider.of<StoreInfoService>(context, listen: false);
    final info = storeService.storeInfo;
    
    _storeNameController = TextEditingController(text: info?.storeName ?? '');
    _descriptionController = TextEditingController(text: info?.description ?? '');
    _postalCodeController = TextEditingController(text: info?.postalCode ?? '');
    _prefectureController = TextEditingController(text: info?.prefecture ?? '');
    _cityController = TextEditingController(text: info?.city ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
    _buildingController = TextEditingController(text: info?.building ?? '');
    _phoneController = TextEditingController(text: info?.phone ?? '');
    _emailController = TextEditingController(text: info?.email ?? '');
    _websiteController = TextEditingController(text: info?.website ?? '');
    _establishedYearController = TextEditingController(text: info?.establishedYear ?? '');
    _numberOfSeatsController = TextEditingController(text: info?.numberOfSeats ?? '');
    _numberOfStaffController = TextEditingController(text: info?.numberOfStaff ?? '');
    _parkingSpacesController = TextEditingController(text: info?.parkingSpaces ?? '');
    
    _selectedIndustry = info?.industry ?? '美容室・サロン';
    _services = List<String>.from(info?.services ?? []);
    _paymentMethods = List<String>.from(info?.paymentMethods ?? []);
    _features = List<String>.from(info?.features ?? []);
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _postalCodeController.dispose();
    _prefectureController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _buildingController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _establishedYearController.dispose();
    _numberOfSeatsController.dispose();
    _numberOfStaffController.dispose();
    _parkingSpacesController.dispose();
    _serviceController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final storeService = Provider.of<StoreInfoService>(context, listen: false);
    
    await storeService.updateStoreInfo({
      'storeName': _storeNameController.text,
      'industry': _selectedIndustry,
      'description': _descriptionController.text,
      'postalCode': _postalCodeController.text,
      'prefecture': _prefectureController.text,
      'city': _cityController.text,
      'address': _addressController.text,
      'building': _buildingController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'website': _websiteController.text,
      'establishedYear': _establishedYearController.text,
      'numberOfSeats': _numberOfSeatsController.text,
      'numberOfStaff': _numberOfStaffController.text,
      'parkingSpaces': _parkingSpacesController.text,
      'services': _services,
      'paymentMethods': _paymentMethods,
      'features': _features,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final storeService = Provider.of<StoreInfoService>(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('店舗情報を編集', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (storeService.isLoading)
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
              // 基本情報
              _buildSectionTitle('基本情報', Icons.store),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  labelText: '店舗名 *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '店舗名を入力してください';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedIndustry,
                decoration: InputDecoration(
                  labelText: '業種',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _industryOptions.map((industry) {
                  return DropdownMenuItem(
                    value: industry,
                    child: Text(industry),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIndustry = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '店舗説明',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              // 所在地
              _buildSectionTitle('所在地', Icons.location_on),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _postalCodeController,
                      decoration: InputDecoration(
                        labelText: '郵便番号',
                        prefixText: '〒',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _prefectureController,
                      decoration: InputDecoration(
                        labelText: '都道府県',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: '市区町村',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: '番地',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _buildingController,
                decoration: InputDecoration(
                  labelText: '建物名・部屋番号',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 連絡先
              _buildSectionTitle('連絡先', Icons.contact_phone),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '電話番号',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: 'ウェブサイト',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
              
              const SizedBox(height: 32),
              
              // 施設情報
              _buildSectionTitle('施設情報', Icons.business),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _establishedYearController,
                      decoration: InputDecoration(
                        labelText: '設立年',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _numberOfSeatsController,
                      decoration: InputDecoration(
                        labelText: '座席数',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _numberOfStaffController,
                      decoration: InputDecoration(
                        labelText: 'スタッフ数',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _parkingSpacesController,
                      decoration: InputDecoration(
                        labelText: '駐車場',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // サービス
              _buildListSection(
                title: 'サービス・メニュー',
                icon: Icons.menu_book,
                items: _services,
                onAdd: (value) {
                  setState(() {
                    _services.add(value);
                  });
                },
                onRemove: (index) {
                  setState(() {
                    _services.removeAt(index);
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // 設備・特徴
              _buildListSection(
                title: '設備・特徴',
                icon: Icons.star,
                items: _features,
                onAdd: (value) {
                  setState(() {
                    _features.add(value);
                  });
                },
                onRemove: (index) {
                  setState(() {
                    _features.removeAt(index);
                  });
                },
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

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required List<String> items,
    required Function(String) onAdd,
    required Function(int) onRemove,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    // タイトルに応じて適切なコントローラーを選択
    final controller = title.contains('サービス') ? _serviceController : _featureController;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, icon),
        const SizedBox(height: 16),
        
        // 追加フィールド
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: title.contains('サービス') 
                    ? '例：カット、カラー、パーマなど' 
                    : '例：完全個室、Wi-Fi完備など',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add_circle, color: themeService.primaryColor),
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty && !items.contains(value)) {
                        onAdd(value);
                        controller.clear();
                      }
                    },
                  ),
                ),
                onFieldSubmitted: (value) {
                  final trimmedValue = value.trim();
                  if (trimmedValue.isNotEmpty && !items.contains(trimmedValue)) {
                    onAdd(trimmedValue);
                    controller.clear();
                  }
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // アイテムリスト
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                title.contains('サービス') 
                  ? 'サービスメニューを追加してください' 
                  : '設備・特徴を追加してください',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                
                return Chip(
                  label: Text(
                    item,
                    style: const TextStyle(fontSize: 13),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => onRemove(index),
                  backgroundColor: themeService.primaryColor.withOpacity(0.1),
                  deleteIconColor: themeService.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: themeService.primaryColor.withOpacity(0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}