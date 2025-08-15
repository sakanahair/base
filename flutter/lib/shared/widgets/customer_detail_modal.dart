import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/customer_service.dart';
import '../../core/services/theme_service.dart';
import '../../core/services/tag_service.dart';
import '../../core/services/memo_service.dart';
import '../../core/services/global_modal_service.dart';
import '../../core/theme/app_theme.dart';
import 'smart_memo_pad.dart';
import 'tag_manager_dialog.dart';

class CustomerDetailModal extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;

  const CustomerDetailModal({
    super.key,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  @override
  State<CustomerDetailModal> createState() => _CustomerDetailModalState();
}

class _CustomerDetailModalState extends State<CustomerDetailModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;
  
  // 編集用コントローラー
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _birthdayController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // コントローラーの初期化
    _nameController = TextEditingController(text: widget.customerName);
    _phoneController = TextEditingController(text: widget.customerPhone ?? '');
    _emailController = TextEditingController(text: widget.customerEmail ?? '');
    _addressController = TextEditingController();
    _birthdayController = TextEditingController();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final customerService = Provider.of<CustomerService>(context);
    final tagService = Provider.of<TagService>(context);
    final memoService = Provider.of<MemoService>(context);
    
    // 顧客データの取得（実際のデータがある場合）
    final customer = customerService.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => Customer(
        id: widget.customerId,
        name: widget.customerName,
        phone: widget.customerPhone ?? '',
        email: widget.customerEmail ?? '',
        channel: 'App',
        registeredDate: DateTime.now(),
        visitCount: 0,
        totalSpent: 0,
        tags: [],
        gender: '',
        memo: '',
      ),
    );
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeService.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: TextStyle(
                        color: themeService.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.phone.isNotEmpty)
                          Text(
                            customer.phone,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // アクションボタン
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isEditMode ? Icons.save : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_isEditMode) {
                              // 保存処理
                              _saveCustomerData();
                            }
                            _isEditMode = !_isEditMode;
                          });
                        },
                        tooltip: _isEditMode ? '保存' : '編集',
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.white),
                        onPressed: () {
                          GlobalModalService.showChat(
                            context,
                            customerId: widget.customerId,
                            customerName: customer.name,
                            isFromCustomerDetail: true,
                          );
                        },
                        tooltip: 'チャット',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: '閉じる',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // タブバー
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: themeService.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: themeService.primaryColor,
                tabs: const [
                  Tab(text: '基本情報'),
                  Tab(text: '予約履歴'),
                  Tab(text: '施術履歴'),
                  Tab(text: 'メモ・タグ'),
                  Tab(text: 'チャット'),
                ],
              ),
            ),
            
            // タブコンテンツ
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 基本情報タブ
                  _buildBasicInfoTab(customer),
                  
                  // 予約履歴タブ
                  _buildAppointmentHistoryTab(),
                  
                  // 施術履歴タブ
                  _buildServiceHistoryTab(),
                  
                  // メモ・タグタブ
                  _buildMemoTagTab(customer, tagService, memoService),
                  
                  // チャット履歴タブ
                  _buildChatHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBasicInfoTab(Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: '連絡先情報',
            children: [
              _buildInfoRow(
                icon: Icons.person,
                label: '名前',
                value: customer.name,
                isEditable: _isEditMode,
                controller: _nameController,
              ),
              _buildInfoRow(
                icon: Icons.phone,
                label: '電話番号',
                value: customer.phone,
                isEditable: _isEditMode,
                controller: _phoneController,
                onTap: _isEditMode ? null : () => _makePhoneCall(customer.phone),
              ),
              _buildInfoRow(
                icon: Icons.email,
                label: 'メール',
                value: customer.email,
                isEditable: _isEditMode,
                controller: _emailController,
                onTap: _isEditMode ? null : () => _sendEmail(customer.email),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: '個人情報',
            children: [
              _buildInfoRow(
                icon: Icons.cake,
                label: '誕生日',
                value: customer.birthday != null 
                  ? DateFormat('yyyy年MM月dd日').format(customer.birthday!)
                  : '未登録',
                isEditable: _isEditMode,
                controller: _birthdayController,
              ),
              _buildInfoRow(
                icon: Icons.home,
                label: '住所',
                value: '未登録',  // TODO: addressフィールドをCustomerクラスに追加
                isEditable: _isEditMode,
                controller: _addressController,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: '顧客情報',
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: '登録日',
                value: DateFormat('yyyy年MM月dd日').format(customer.registeredDate),
              ),
              _buildInfoRow(
                icon: Icons.shopping_bag,
                label: '総購入回数',
                value: '12回',  // TODO: 実際のデータから取得
              ),
              _buildInfoRow(
                icon: Icons.attach_money,
                label: '総購入金額',
                value: '¥${NumberFormat('#,###').format(156000)}',  // TODO: 実際のデータから取得
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,  // TODO: 実際の予約データ
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index == 0 ? Colors.green : Colors.grey,
              child: Icon(
                index == 0 ? Icons.event_available : Icons.event_busy,
                color: Colors.white,
              ),
            ),
            title: Text('カット + カラー'),
            subtitle: Text('2025年1月${20 - index}日 14:00-16:00'),
            trailing: Text(
              index == 0 ? '予約中' : '完了',
              style: TextStyle(
                color: index == 0 ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // TODO: 予約詳細を表示
            },
          ),
        );
      },
    );
  }
  
  Widget _buildServiceHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,  // TODO: 実際の施術データ
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '2024年${12 - index}月15日',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '¥${NumberFormat('#,###').format(12000 + index * 1000)}',
                      style: TextStyle(
                        color: Provider.of<ThemeService>(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('カット + パーマ'),
                Text(
                  '担当: 山田スタイリスト',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMemoTagTab(Customer customer, TagService tagService, MemoService memoService) {
    final userTags = tagService.getUserTags(widget.customerId);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タグセクション
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'タグ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => TagManagerDialog(
                              userId: widget.customerId,
                              userName: customer.name,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: userTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Provider.of<ThemeService>(context).primaryColor.withOpacity(0.1),
                        deleteIcon: _isEditMode ? const Icon(Icons.close, size: 16) : null,
                        onDeleted: _isEditMode ? () {
                          // TODO: タグ削除機能の実装
                          setState(() {});
                        } : null,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // メモセクション
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'メモ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        hintText: 'メモを入力...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        // TODO: メモ保存機能
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,  // TODO: 実際のチャット履歴
      itemBuilder: (context, index) {
        final isFromCustomer = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isFromCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.6,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFromCustomer ? Colors.grey.shade200 : Provider.of<ThemeService>(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'これはサンプルメッセージです。',
                      style: TextStyle(
                        color: isFromCustomer ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '14:${30 + index}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isFromCustomer ? Colors.grey : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isEditable = false,
    TextEditingController? controller,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: isEditable && controller != null
              ? TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                )
              : InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: onTap != null ? Colors.blue : Colors.black87,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
  
  void _saveCustomerData() {
    // TODO: 顧客データの保存処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('顧客情報を更新しました')),
    );
  }
  
  void _makePhoneCall(String phone) {
    // TODO: 電話発信処理
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('電話: $phone')),
    );
  }
  
  void _sendEmail(String email) {
    // TODO: メール送信処理
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('メール: $email')),
    );
  }
}