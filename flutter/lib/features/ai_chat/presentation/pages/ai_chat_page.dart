import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/responsive_helper.dart';

class AIModel {
  final String name;
  final String displayName;
  final String icon;
  final bool isPremium;
  final String? description;

  AIModel({
    required this.name,
    required this.displayName,
    required this.icon,
    this.isPremium = false,
    this.description,
  });
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Uint8List? _selectedImage;
  String? _selectedImageName;
  bool _showModelSelector = false;
  bool _webSearchEnabled = false;
  
  final List<AIModel> _models = [
    AIModel(name: 'mixture', displayName: 'Mixture-of-Agents', icon: '😊', description: 'タスクに最適なAIモデルを自動で組み合わせます。'),
    AIModel(name: 'gpt5', displayName: 'GPT-5', icon: '🌀'),
    AIModel(name: 'gpt5pro', displayName: 'GPT-5 Pro', icon: '🌀'),
    AIModel(name: 'o3pro', displayName: 'o3-pro', icon: '🌀'),
    AIModel(name: 'o4mini', displayName: 'o4-mini-high', icon: '🌀'),
    AIModel(name: 'claude-sonnet', displayName: 'Claude Sonnet 4', icon: '✳️'),
    AIModel(name: 'claude-opus', displayName: 'Claude Opus 4.1', icon: '✳️'),
    AIModel(name: 'gemini-flash', displayName: 'Gemini 2.5 Flash', icon: '🔷'),
    AIModel(name: 'gemini-pro', displayName: 'Gemini 2.5 Pro', icon: '🔷'),
    AIModel(name: 'deepseek', displayName: 'DeepSeek R1', icon: '🔷'),
    AIModel(name: 'grok', displayName: 'Grok4 0709', icon: '⭕'),
  ];
  
  AIModel _selectedModel = AIModel(name: 'claude-opus', displayName: 'Claude Opus 4', icon: '✳️');

  @override
  void initState() {
    super.initState();
    // 初期メッセージ - アップグレードプロンプト
    _messages.add(ChatMessage(
      text: 'こんにちは、何をお手伝いできますか？',
      isUser: false,
      timestamp: DateTime.now(),
      isUpgradePrompt: true,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() {
      // ユーザーメッセージを追加
      _messages.add(ChatMessage(
        text: _messageController.text.isNotEmpty ? _messageController.text : '画像をアップロードしました',
        isUser: true,
        timestamp: DateTime.now(),
        imageData: _selectedImage,
        imageName: _selectedImageName,
      ));

      // AIの返答をシミュレート
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages.add(ChatMessage(
            text: _getAIResponse(_messageController.text),
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      });

      _messageController.clear();
      _selectedImage = null;
      _selectedImageName = null;
    });
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImage = result.files.single.bytes!;
          _selectedImageName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像の選択に失敗しました: $e')),
      );
    }
  }

  String _getAIResponse(String message) {
    // 簡単なAI応答のシミュレーション
    if (message.contains('予約')) {
      return '予約に関するお問い合わせですね。予約管理ページから新規予約の追加や既存予約の確認ができます。';
    } else if (message.contains('顧客')) {
      return '顧客管理についてのご質問ですね。顧客管理ページでは、顧客情報の検索、編集、新規登録が可能です。';
    } else if (message.contains('売上') || message.contains('分析')) {
      return '売上分析に関するお問い合わせですね。分析ページで詳細なレポートをご確認いただけます。';
    } else {
      return 'ご質問ありがとうございます。より具体的な情報をお聞かせください。予約、顧客管理、売上分析などについてお手伝いできます。';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      color: AppTheme.backgroundColor,
      child: Stack(
        children: [
          Column(
            children: [
              // ヘッダー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {},
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'AIチャット',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // チャットメッセージエリア
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),

              // 入力エリア
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // モデル選択バー
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showModelSelector = !_showModelSelector;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.3)),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: _pickImage,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    _selectedModel.icon,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedModel.displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _showModelSelector ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'ウェブ検索',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _webSearchEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _webSearchEnabled = value ?? false;
                                      });
                                    },
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 選択された画像のプレビュー
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                image: DecorationImage(
                                  image: MemoryImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedImageName ?? '画像',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _selectedImageName = null;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 入力フィールド
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Message',
                                hintStyle: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: AppTheme.backgroundColor,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _sendMessage,
                              icon: Icon(
                                Icons.send,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // モデル選択ダイアログ
          if (_showModelSelector)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showModelSelector = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: () {
                                    setState(() {
                                      _showModelSelector = false;
                                    });
                                  },
                                ),
                                const Text(
                                  'AIチャット',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _models.length,
                              itemBuilder: (context, index) {
                                final model = _models[index];
                                final isSelected = model.name == _selectedModel.name;
                                return ListTile(
                                  leading: Text(
                                    model.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  title: Text(
                                    model.displayName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: model.description != null
                                      ? Text(
                                          model.description!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        )
                                      : null,
                                  trailing: Radio<String>(
                                    value: model.name,
                                    groupValue: _selectedModel.name,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedModel = model;
                                        _showModelSelector = false;
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedModel = model;
                                      _showModelSelector = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isUpgradePrompt == true) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '1つのサブスクリプションで、全てのモデルが使い放題',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'GPT-5、o3-pro、Claude Opus 4.1、Claude Sonnet 4、Gemini 2.5 Pro、Grok 4など',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Plusにアップグレード',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? AppTheme.primaryColor 
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
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
            // 画像がある場合は表示
            if (message.imageData != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.imageData!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : AppTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser 
                    ? Colors.white.withOpacity(0.7) 
                    : AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Uint8List? imageData;
  final String? imageName;
  final bool? isUpgradePrompt;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imageData,
    this.imageName,
    this.isUpgradePrompt,
  });
}

