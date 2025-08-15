import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/services/memo_service.dart';

class SmartMemoPad extends StatefulWidget {
  final String? initialText;
  final String? customerId;
  final String? customerName;
  final Function(String)? onSave;
  final bool isDialog;
  
  const SmartMemoPad({
    super.key,
    this.initialText,
    this.customerId,
    this.customerName,
    this.onSave,
    this.isDialog = false,
  });

  @override
  State<SmartMemoPad> createState() => _SmartMemoPadState();
}

class _SmartMemoPadState extends State<SmartMemoPad> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasChanges = false;
  String _savedText = '';
  List<String> _searchResults = [];
  bool _isSearching = false;
  Timer? _autoSaveTimer;
  DateTime? _lastSaveTime;
  bool _isSaving = false;
  
  // フォーマットツールの状態
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  
  // メモのテンプレート
  final List<Map<String, String>> _templates = [
    {'title': 'カット詳細', 'content': '【カット内容】\n・長さ：\n・スタイル：\n・特記事項：'},
    {'title': 'カラー記録', 'content': '【カラー情報】\n・カラー剤：\n・配合：\n・放置時間：\n・仕上がり：'},
    {'title': 'パーマ記録', 'content': '【パーマ情報】\n・薬剤：\n・ロッド：\n・放置時間：\n・仕上がり：'},
    {'title': '次回提案', 'content': '【次回ご提案】\n・施術内容：\n・時期：\n・注意点：'},
    {'title': 'アレルギー情報', 'content': '【アレルギー・注意事項】\n・薬剤：\n・症状：\n・対応：'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _savedText = widget.initialText ?? '';
    _controller.addListener(_onTextChanged);
    
    // MemoServiceから既存のメモを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMemo();
    });
  }
  
  void _loadInitialMemo() async {
    // initialTextが既に指定されている場合はスキップ
    if (widget.initialText != null && widget.initialText!.isNotEmpty) {
      print('Using provided initialText, skipping MemoService load');
      return;
    }
    
    // MemoServiceが初期化されるまで少し待つ
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final memoService = Provider.of<MemoService>(context, listen: false);
    String initialMemo = '';
    
    if (widget.customerId != null) {
      initialMemo = memoService.getCustomerMemo(widget.customerId!);
      print('Loading customer memo for ID: ${widget.customerId}, length: ${initialMemo.length}');
    } else {
      initialMemo = memoService.getGeneralMemo();
      print('Loading general memo from MemoService, length: ${initialMemo.length}');
    }
    
    // 既存のメモがある場合は読み込む
    if (initialMemo.isNotEmpty) {
      setState(() {
        _controller.text = initialMemo;
        _savedText = initialMemo;
        _hasChanges = false;
      });
      print('Initial memo loaded into controller: ${initialMemo.substring(0, initialMemo.length > 50 ? 50 : initialMemo.length)}...');
    } else {
      print('No saved memo found in MemoService');
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final hasChanges = _controller.text != _savedText;
    
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
    
    // 自動保存のデバウンス処理（2秒間入力がなければ保存）
    if (hasChanges) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        _autoSave();
      });
    }
  }
  
  Future<void> _autoSave() async {
    if (!_hasChanges || _isSaving) return;
    
    print('Auto-saving memo...');
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (widget.onSave != null) {
        widget.onSave!(_controller.text);
      }
      
      // MemoServiceに保存
      if (widget.customerId != null) {
        print('Saving customer memo for ID: ${widget.customerId}');
        final memoService = Provider.of<MemoService>(context, listen: false);
        await memoService.saveCustomerMemo(widget.customerId!, _controller.text);
      } else {
        print('Saving general memo');
        final memoService = Provider.of<MemoService>(context, listen: false);
        await memoService.saveGeneralMemo(_controller.text);
      }
      
      setState(() {
        _savedText = _controller.text;
        _hasChanges = false;
        _lastSaveTime = DateTime.now();
        _isSaving = false;
      });
      
      print('Auto-save completed');
      
      // 自動保存の通知（控えめに）
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('自動保存しました'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );
      }
    } catch (e) {
      print('Error during auto-save: $e');
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _insertTemplate(String template) {
    final currentPosition = _controller.selection.baseOffset;
    final text = _controller.text;
    final newText = text.substring(0, currentPosition) + 
                    template + 
                    text.substring(currentPosition);
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: currentPosition + template.length),
    );
  }
  
  void _insertTimestamp() {
    final timestamp = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    _insertTemplate('\n--- $timestamp ---\n');
  }
  
  void _insertBulletPoint() {
    final currentPosition = _controller.selection.baseOffset;
    final text = _controller.text;
    
    // 現在の行の開始位置を見つける
    int lineStart = currentPosition;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    
    final newText = text.substring(0, lineStart) + 
                    '• ' + 
                    text.substring(lineStart);
    _controller.text = newText;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: currentPosition + 2),
    );
  }
  
  void _insertCheckbox() {
    _insertTemplate('☐ ');
  }
  
  Future<void> _saveMemo() async {
    if (_isSaving) return;
    
    print('Manual save triggered');
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (widget.onSave != null) {
        widget.onSave!(_controller.text);
      }
      
      // MemoServiceに保存
      if (widget.customerId != null) {
        print('Saving customer memo for ID: ${widget.customerId}');
        final memoService = Provider.of<MemoService>(context, listen: false);
        await memoService.saveCustomerMemo(widget.customerId!, _controller.text);
      } else {
        print('Saving general memo - Text length: ${_controller.text.length}');
        final memoService = Provider.of<MemoService>(context, listen: false);
        await memoService.saveGeneralMemo(_controller.text);
      }
      
      setState(() {
        _savedText = _controller.text;
        _hasChanges = false;
        _lastSaveTime = DateTime.now();
        _isSaving = false;
      });
      
      print('Manual save completed');
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('保存しました'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error during manual save: $e');
      setState(() {
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存エラー: $e'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _searchInMemo(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    
    final lines = _controller.text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        _searchResults.add('${i + 1}: ${lines[i]}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isDialog ? BorderRadius.circular(16) : BorderRadius.zero,
        boxShadow: widget.isDialog ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.05),
              borderRadius: widget.isDialog 
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  )
                : BorderRadius.zero,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.note_alt, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.customerName != null 
                          ? '${widget.customerName}のメモ'
                          : 'メモ帳',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isSaving)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '保存中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '未保存',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (widget.isDialog) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          if (_hasChanges) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black54,
                              builder: (context) => AlertDialog(
                                title: const Text('保存確認'),
                                content: const Text('変更が保存されていません。保存しますか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('破棄'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _saveMemo();
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('保存して閉じる'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // ツールバー
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // テンプレートメニュー
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.snippet_folder, size: 20),
                        tooltip: 'テンプレート',
                        offset: const Offset(0, 30),
                        elevation: 8,
                        itemBuilder: (context) => _templates.map((template) {
                          return PopupMenuItem(
                            value: template['content'],
                            child: ListTile(
                              dense: true,
                              title: Text(template['title']!),
                              subtitle: Text(
                                template['content']!.split('\n').first,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                        onSelected: _insertTemplate,
                      ),
                      const VerticalDivider(width: 1),
                      // クイック挿入ツール
                      IconButton(
                        icon: const Icon(Icons.access_time, size: 20),
                        tooltip: 'タイムスタンプ',
                        onPressed: _insertTimestamp,
                      ),
                      IconButton(
                        icon: const Icon(Icons.fiber_manual_record, size: 20),
                        tooltip: '箇条書き',
                        onPressed: _insertBulletPoint,
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_box_outline_blank, size: 20),
                        tooltip: 'チェックボックス',
                        onPressed: _insertCheckbox,
                      ),
                      const VerticalDivider(width: 1),
                      // 検索
                      IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        tooltip: '検索',
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierColor: Colors.black54,
                            builder: (context) => AlertDialog(
                              title: const Text('メモ内検索'),
                              content: TextField(
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: '検索キーワードを入力',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: _searchInMemo,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchResults = [];
                                      _isSearching = false;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('閉じる'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const VerticalDivider(width: 1),
                      // 保存ボタン
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          backgroundColor: _hasChanges ? theme.primaryColor : Colors.grey,
                        ),
                        onPressed: _hasChanges ? _saveMemo : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // メモ本文エリア
          Expanded(
            child: Stack(
              children: [
                RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event is RawKeyDownEvent) {
                      final isCtrlPressed = event.isControlPressed || event.isMetaPressed;
                      
                      if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
                        _saveMemo();
                      }
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'メモを入力...\n\nショートカット:\n• Ctrl+S: 保存',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                
                // 検索結果オーバーレイ
                if (_isSearching && _searchResults.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        border: Border(
                          top: BorderSide(color: Colors.yellow[700]!),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              _searchResults[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              // 該当行にジャンプ
                              final lineNumber = int.parse(_searchResults[index].split(':')[0]) - 1;
                              final lines = _controller.text.split('\n');
                              int position = 0;
                              for (int i = 0; i < lineNumber && i < lines.length; i++) {
                                position += lines[i].length + 1;
                              }
                              _controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: position),
                              );
                              _focusNode.requestFocus();
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // ステータスバー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: widget.isDialog 
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )
                : BorderRadius.zero,
            ),
            child: Row(
              children: [
                Text(
                  '文字数: ${_controller.text.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  '行数: ${_controller.text.split('\n').length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (_lastSaveTime != null)
                  Text(
                    '最終保存: ${DateFormat('HH:mm').format(_lastSaveTime!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}