import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:file_picker/file_picker.dart';

class TerminalSession {
  final String id;
  final Terminal terminal;
  final TerminalController controller;
  WebSocketChannel? channel;
  bool isConnecting = false;
  String? sessionId;
  bool isActive = true;
  
  TerminalSession({
    required this.id,
    this.sessionId,
  }) : terminal = Terminal(maxLines: 10000),
       controller = TerminalController();
}

class MultiTerminalPage extends StatefulWidget {
  const MultiTerminalPage({super.key});

  @override
  State<MultiTerminalPage> createState() => _MultiTerminalPageState();
}

class _MultiTerminalPageState extends State<MultiTerminalPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final List<TerminalSession> _sessions = [];
  int _sessionCounter = 1;
  late DropzoneViewController _dropzoneController;
  bool _isDragging = false;
  bool _isKeyboardVisible = false;
  final FocusNode _terminalFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    // 最初にタブコントローラーを初期化
    _tabController = TabController(length: 1, vsync: this);
    // セッションを復元または新規作成
    _loadSessions();
    
    // キーボード表示状態の監視
    _terminalFocusNode.addListener(() {
      setState(() {
        _isKeyboardVisible = _terminalFocusNode.hasFocus;
      });
    });
  }
  
  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString('terminal_sessions');
    
    if (sessionsJson != null) {
      try {
        final sessionsList = json.decode(sessionsJson) as List;
        for (final sessionData in sessionsList) {
          final session = TerminalSession(
            id: sessionData['id'],
            sessionId: sessionData['sessionId'],
          );
          _sessions.add(session);
          _sessionCounter = sessionData['counter'] ?? _sessionCounter;
        }
      } catch (e) {
        print('Failed to load sessions: $e');
      }
    }
    
    // セッションが無い場合は新規作成
    if (_sessions.isEmpty) {
      _addNewSession();
    } else {
      // TabControllerを更新
      if (mounted) {
        _tabController.dispose();
        _tabController = TabController(
          length: _sessions.length,
          vsync: this,
        );
        setState(() {});
      }
      
      // 既存セッションを再接続
      for (final session in _sessions) {
        _reconnectSession(session);
      }
    }
  }
  
  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsList = _sessions.map((session) => {
      'id': session.id,
      'sessionId': session.sessionId,
      'counter': _sessionCounter,
    }).toList();
    await prefs.setString('terminal_sessions', json.encode(sessionsList));
  }
  
  void _addNewSession() {
    final session = TerminalSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _sessionCounter++;
    
    if (mounted) {
      setState(() {
        _sessions.add(session);
      });
      // TabControllerを再作成（setState外で）
      _tabController.dispose();
      _tabController = TabController(
        length: _sessions.length,
        vsync: this,
        initialIndex: _sessions.length - 1,
      );
    }
    
    // 新しいセッションを初期化
    _initializeSession(session);
    _saveSessions();
  }
  
  void _closeSession(int index) {
    if (_sessions.length <= 1) {
      // 最後のセッションは閉じない
      return;
    }
    
    final session = _sessions[index];
    session.isActive = false;
    try {
      session.channel?.sink.close(status.goingAway);
    } catch (e) {
      // WebSocketクローズエラーを無視
    }
    
    if (mounted) {
      setState(() {
        _sessions.removeAt(index);
      });
      // TabControllerを再作成（setState外で）
      _tabController.dispose();
      _tabController = TabController(
        length: _sessions.length,
        vsync: this,
        initialIndex: index > 0 ? index - 1 : 0,
      );
    }
    
    _saveSessions();
  }
  
  void _initializeSession(TerminalSession session) {
    // 初期メッセージ
    session.terminal.write('SAKANA Terminal v1.0.0\r\n');
    session.terminal.write('=====================\r\n');
    session.terminal.write('開発環境ターミナル - WebSocket接続中...\r\n\r\n');
    
    // キーボード入力処理
    session.terminal.onOutput = (String data) {
      // デバッグ: 入力データの確認
      if (kDebugMode) {
        print('Terminal input: "${data}" (bytes: ${data.codeUnits})');
      }
      _handleTerminalInput(session, data);
    };
    
    // ターミナル出力時に自動スクロール
    session.terminal.onTitleChange = (String title) {
      // タイトル変更時もスクロール
      Future.delayed(const Duration(milliseconds: 50), () {
        // 最下部へスクロール
        session.controller.clearSelection();
      });
    };
    
    // WebSocket接続
    _connectWebSocket(session);
  }
  
  void _reconnectSession(TerminalSession session) {
    // 初期メッセージ
    session.terminal.write('SAKANA Terminal v1.0.0\r\n');
    session.terminal.write('=====================\r\n');
    session.terminal.write('セッション復元中...\r\n\r\n');
    
    // キーボード入力処理
    session.terminal.onOutput = (String data) {
      // デバッグ: 入力データの確認
      if (kDebugMode) {
        print('Terminal input: "${data}" (bytes: ${data.codeUnits})');
      }
      _handleTerminalInput(session, data);
    };
    
    // ターミナル出力時に自動スクロール
    session.terminal.onTitleChange = (String title) {
      // タイトル変更時もスクロール
      Future.delayed(const Duration(milliseconds: 50), () {
        // 最下部へスクロール
        session.controller.clearSelection();
      });
    };
    
    // WebSocket再接続
    _connectWebSocket(session, reconnect: true);
  }
  
  void _handleTerminalInput(TerminalSession session, String data) {
    // WebSocket接続がある場合は全ての入力を直接送信
    if (session.channel != null && session.channel!.closeCode == null) {
      // データが空でない場合のみ送信
      if (data.isNotEmpty) {
        // スペースキーが正しく処理されない問題への対処
        // onOutputが空文字列を返すことがあるため、明示的にチェック
        session.channel!.sink.add(data);
        
        // 入力後に最下部へスクロール
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && session.controller != null) {
            try {
              session.controller.clearSelection();
            } catch (e) {
              // スクロールエラーを無視
            }
          }
        });
      }
      return;
    }
    
    // ローカルモードの処理は省略
    session.terminal.write(data);
  }
  
  void _connectWebSocket(TerminalSession session, {bool reconnect = false}) async {
    if (session.isConnecting || !session.isActive) return;
    session.isConnecting = true;
    
    try {
      final wsUrl = 'wss://terminal.sakana.hair/terminal';
      
      session.channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      session.channel!.stream.listen(
        (message) {
          // JSONメッセージの処理
          if (message is String && message.startsWith('{')) {
            try {
              final data = json.decode(message);
              
              if (data['type'] == 'session_created') {
                // 新規セッション作成
                session.sessionId = data['sessionId'];
                session.terminal.write('\x1B[32m新規セッション作成: ${data['sessionId'].substring(0, 8)}...\x1B[0m\r\n');
                if (mounted) {
                  setState(() {
                    session.isConnecting = false;
                  });
                }
                _saveSessions();
              } else if (data['type'] == 'session_restored') {
                // セッション復元
                session.terminal.buffer.clear();
                session.terminal.buffer.setCursor(0, 0);
                session.terminal.write('\x1B[32mセッション復元: ${data['sessionId'].substring(0, 8)}...\x1B[0m\r\n');
                if (mounted) {
                  setState(() {
                    session.isConnecting = false;
                  });
                }
              }
              return;
            } catch (e) {
              // JSONパースエラー - 通常のメッセージとして処理
            }
          }
          
          // サーバーからの出力を表示
          session.terminal.write(message);
          // 自動的に最下部にスクロール
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && session.controller != null) {
              try {
                session.controller.clearSelection();
              } catch (e) {
                // スクロールエラーを無視
              }
            }
          });
        },
        onError: (error) {
          if (!session.isActive) return;
          session.terminal.write('\x1B[31mWebSocket Error: $error\x1B[0m\r\n');
          if (mounted) {
            setState(() {
              session.isConnecting = false;
            });
          }
        },
        onDone: () {
          if (!session.isActive) return;
          session.terminal.write('\x1B[33mWebSocket接続が切断されました\x1B[0m\r\n');
          if (mounted) {
            setState(() {
              session.isConnecting = false;
            });
          }
        },
      );
      
      // セッションハンドシェイク送信
      Future.delayed(Duration(milliseconds: 100), () {
        if (session.channel != null && session.channel!.closeCode == null) {
          // モバイル用にターミナルサイズを調整
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;
          final cols = isMobile ? 60 : 80;
          final rows = isMobile ? 20 : 30;
          
          session.channel!.sink.add(json.encode({
            'type': 'session',
            'sessionId': reconnect ? session.sessionId : null,
            'cols': cols,
            'rows': rows,
          }));
        }
      });
      
    } catch (e) {
      session.terminal.write('\x1B[31m接続エラー: $e\x1B[0m\r\n');
      if (mounted) {
        setState(() {
          session.isConnecting = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    // セッションを先にクリーンアップ
    for (var session in _sessions) {
      session.isActive = false;
      try {
        session.channel?.sink.close(status.goingAway);
      } catch (e) {
        // エラーを無視
      }
    }
    // TabControllerをdispose
    try {
      _tabController.dispose();
    } catch (e) {
      // エラーを無視
    }
    _terminalFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    // 横向きモバイルでは画面を最大活用
    final appBarHeight = isMobile && isLandscape ? 48.0 : (isMobile ? 56.0 : 48.0);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D30),
        toolbarHeight: appBarHeight,
        title: Row(
          children: [
            Icon(Icons.terminal, size: isMobile ? 24 : 20),
            const Spacer(),
            if (_sessions.isNotEmpty && 
                _tabController.index < _sessions.length && 
                _sessions[_tabController.index].channel != null &&
                _sessions[_tabController.index].channel!.closeCode == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Connected', style: TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Connecting', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 56 : 48),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppTheme.secondaryColor,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: _sessions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final session = entry.value;
                    return Tab(
                      child: Row(
                        children: [
                          Icon(Icons.terminal, size: isMobile ? 18 : 14),
                          if (_sessions.length > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _closeSession(index),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 4 : 2),
                                child: Icon(Icons.close, size: isMobile ? 20 : 16),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: isMobile ? 24 : 20, color: Colors.white),
                onPressed: _addNewSession,
                tooltip: 'New Terminal',
                padding: EdgeInsets.all(isMobile ? 12 : 8),
              ),
            ],
          ),
        ),
        actions: isMobile 
          ? [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 24),
                onSelected: (value) {
                  switch (value) {
                    case 'upload':
                      _handleFileUpload();
                      break;
                    case 'reset':
                      _handleResetAll();
                      break;
                    case 'clear':
                      _handleClearTerminal();
                      break;
                    case 'close':
                      Navigator.of(context).pop();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'upload',
                    child: ListTile(
                      leading: Icon(Icons.upload_file),
                      title: Text('Upload File'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'reset',
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Reset All'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'close',
                    child: ListTile(
                      leading: Icon(Icons.close),
                      title: Text('Close'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ]
          : [
          IconButton(
            icon: Icon(Icons.upload_file, size: isTablet ? 22 : 20),
            onPressed: _handleFileUpload,
            tooltip: 'Upload File',
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: isTablet ? 22 : 20),
            onPressed: _handleResetAll,
            tooltip: 'Reset All',
          ),
          IconButton(
            icon: Icon(Icons.clear_all, size: isTablet ? 22 : 20),
            onPressed: _handleClearTerminal,
            tooltip: 'Clear',
          ),
          IconButton(
            icon: Icon(Icons.close, size: isTablet ? 22 : 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _sessions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              // モバイル用タブインジケーター
              if (isMobile && _sessions.length > 1)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_sessions.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _tabController.index == index
                              ? AppTheme.secondaryColor
                              : Colors.grey.withOpacity(0.5),
                        ),
                      );
                    }),
                  ),
                ),
              GestureDetector(
                // 左右スワイプでタブを切り替え（モバイルのみ）
                onHorizontalDragEnd: isMobile ? (details) {
                  if (details.velocity.pixelsPerSecond.dx > 100) {
                    // 右にスワイプ - 前のタブへ
                    if (_tabController.index > 0) {
                      _tabController.animateTo(_tabController.index - 1);
                    }
                  } else if (details.velocity.pixelsPerSecond.dx < -100) {
                    // 左にスワイプ - 次のタブへ
                    if (_tabController.index < _sessions.length - 1) {
                      _tabController.animateTo(_tabController.index + 1);
                    }
                  }
                } : null,
                child: TabBarView(
                controller: _tabController,
                physics: isMobile ? const NeverScrollableScrollPhysics() : null,
                children: _sessions.map((session) {
                  return Stack(
                    children: [
                      Container(
                        color: const Color(0xFF1E1E1E),
                        padding: EdgeInsets.all(isMobile ? 4 : 8),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // モバイルではタップでキーボードを表示
                                if (isMobile) {
                                  _terminalFocusNode.requestFocus();
                                }
                              },
                              child: RawKeyboardListener(
                              focusNode: isMobile ? _terminalFocusNode : (FocusNode()..requestFocus()),
                              onKey: (RawKeyEvent event) {
                                // スペースキーの特別処理
                                if (event is RawKeyDownEvent &&
                                    event.logicalKey == LogicalKeyboardKey.space) {
                                  if (session.channel != null && 
                                      session.channel!.closeCode == null) {
                                    // スペースを直接送信
                                    session.channel!.sink.add(' ');
                                    if (kDebugMode) {
                                      print('Space key sent directly to WebSocket');
                                    }
                                  }
                                }
                              },
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: isMobile && _isKeyboardVisible 
                                    ? (isLandscape ? screenHeight * 0.5 : screenHeight * 0.4)
                                    : double.infinity,
                                ),
                                child: TerminalView(
                                session.terminal,
                                controller: session.controller,
                                autofocus: true,
                                theme: const TerminalTheme(
                                cursor: Color(0xFFD4D4D4),
                                selection: Color(0xFF264F78),
                                foreground: Color(0xFFD4D4D4),
                                background: Color(0xFF1E1E1E),
                                black: Color(0xFF000000),
                                red: Color(0xFFCD3131),
                                green: Color(0xFF0DBC79),
                                yellow: Color(0xFFE5E510),
                                blue: Color(0xFF2472C8),
                                magenta: Color(0xFFBC3FBC),
                                cyan: Color(0xFF11A8CD),
                                white: Color(0xFFE5E5E5),
                                brightBlack: Color(0xFF666666),
                                brightRed: Color(0xFFF14C4C),
                                brightGreen: Color(0xFF23D18B),
                                brightYellow: Color(0xFFF5F543),
                                brightBlue: Color(0xFF3B8EEA),
                                brightMagenta: Color(0xFFD670D6),
                                brightCyan: Color(0xFF29B8DB),
                                brightWhite: Color(0xFFFFFFFF),
                                searchHitBackground: Color(0xFF444444),
                                searchHitBackgroundCurrent: Color(0xFF666666),
                                searchHitForeground: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                            DropzoneView(
                              operation: DragOperation.copy,
                              cursor: CursorType.Default,
                              onCreated: (controller) {
                                _dropzoneController = controller;
                              },
                              onDrop: (event) async {
                                setState(() {
                                  _isDragging = false;
                                });
                                
                                if (event is html.File) {
                                  final file = event as html.File;
                                  final currentSession = _sessions[_tabController.index];
                                  
                                  // ファイルサイズチェック（10MB制限）
                                  if (file.size > 10 * 1024 * 1024) {
                                    currentSession.terminal.write('\r\n\x1B[31mError: File size exceeds 10MB limit\x1B[0m\r\n');
                                    return;
                                  }
                                  
                                  // ファイル読み込み
                                  final reader = html.FileReader();
                                  reader.readAsArrayBuffer(file);
                                  
                                  reader.onLoadEnd.listen((e) {
                                    if (currentSession.channel != null && 
                                        currentSession.channel!.closeCode == null) {
                                      // ファイルをBase64エンコード
                                      final bytes = reader.result as Uint8List;
                                      final base64Content = base64Encode(bytes);
                                      
                                      // ファイルアップロードメッセージを送信
                                      currentSession.channel!.sink.add(json.encode({
                                        'type': 'file_upload',
                                        'filename': file.name,
                                        'content': base64Content,
                                        'encoding': 'base64',
                                      }));
                                      
                                      // アップロード開始通知
                                      currentSession.terminal.write('\r\n\x1B[33mUploading: ${file.name}...\x1B[0m\r\n');
                                    }
                                  });
                                  
                                  reader.onError.listen((error) {
                                    currentSession.terminal.write('\r\n\x1B[31mError reading file: $error\x1B[0m\r\n');
                                  });
                                }
                              },
                              onHover: () {
                                setState(() {
                                  _isDragging = true;
                                });
                              },
                              onLeave: () {
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                              onError: (error) {
                                print('Dropzone error: $error');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              ),
              // ドラッグオーバーレイ
              if (_isDragging)
                Container(
                  color: Colors.blue.withOpacity(0.2),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ファイルをドロップしてアップロード',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      floatingActionButton: isMobile ? _buildMobileFloatingButtons() : null,
    );
  }
  
  // モバイル用フローティングボタン
  Widget _buildMobileFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // キーボード表示/非表示トグル
        FloatingActionButton.small(
          heroTag: 'keyboard',
          backgroundColor: const Color(0xFF2D2D30),
          onPressed: () {
            if (_isKeyboardVisible) {
              FocusScope.of(context).unfocus();
            } else {
              _terminalFocusNode.requestFocus();
            }
          },
          child: Icon(
            _isKeyboardVisible ? Icons.keyboard_hide : Icons.keyboard,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        // コピー/ペースト用ボタン
        FloatingActionButton.small(
          heroTag: 'copy',
          backgroundColor: const Color(0xFF2D2D30),
          onPressed: () async {
            // クリップボードから貼り付け
            final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
            if (clipboardData != null && clipboardData.text != null) {
              final currentSession = _sessions[_tabController.index];
              if (currentSession.channel != null && 
                  currentSession.channel!.closeCode == null) {
                currentSession.channel!.sink.add(clipboardData.text!);
              }
            }
          },
          child: const Icon(Icons.paste, size: 20),
        ),
        const SizedBox(height: 8),
        // 新規タブ追加ボタン
        FloatingActionButton.small(
          heroTag: 'add_tab',
          backgroundColor: AppTheme.secondaryColor,
          onPressed: _addNewSession,
          child: const Icon(Icons.add, size: 20),
        ),
      ],
    );
  }
  
  // ファイルアップロード処理
  Future<void> _handleFileUpload() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final currentSession = _sessions[_tabController.index];
      
      // ファイルサイズチェック（100MB制限）
      if (file.size > 100 * 1024 * 1024) {
        currentSession.terminal.write('\r\n\x1B[31mError: File size exceeds 100MB limit\x1B[0m\r\n');
        return;
      }
      
      if (currentSession.channel != null && 
          currentSession.channel!.closeCode == null && 
          file.bytes != null) {
        // ファイルをBase64エンコード
        final base64Content = base64Encode(file.bytes!);
        
        // ファイルアップロードメッセージを送信
        currentSession.channel!.sink.add(json.encode({
          'type': 'file_upload',
          'filename': file.name,
          'content': base64Content,
          'encoding': 'base64',
        }));
        
        // アップロード開始通知
        currentSession.terminal.write('\r\n\x1B[33mUploading: ${file.name}...\x1B[0m\r\n');
      }
    }
  }
  
  // 全セッションリセット処理
  Future<void> _handleResetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('terminal_sessions');
    
    for (var session in _sessions) {
      session.isActive = false;
      session.channel?.sink.close(status.goingAway);
    }
    
    if (mounted) {
      setState(() {
        _sessions.clear();
        _sessionCounter = 1;
      });
      // TabControllerを再作成（setState外で）
      _tabController.dispose();
      _tabController = TabController(length: 1, vsync: this);
    }
    
    _addNewSession();
  }
  
  // ターミナルクリア処理
  void _handleClearTerminal() {
    if (_sessions.isNotEmpty && _tabController.index < _sessions.length) {
      final session = _sessions[_tabController.index];
      session.terminal.buffer.clear();
      session.terminal.buffer.setCursor(0, 0);
      session.terminal.write('SAKANA Terminal v1.0.0\r\n\$ ');
    }
  }
}