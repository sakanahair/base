import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalSession {
  final String id;
  String name;
  final Terminal terminal;
  final TerminalController controller;
  WebSocketChannel? channel;
  bool isConnecting = false;
  String? sessionId;
  bool isActive = true;
  
  TerminalSession({
    required this.id,
    required this.name,
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
  
  @override
  void initState() {
    super.initState();
    // 最初にタブコントローラーを初期化
    _tabController = TabController(length: 1, vsync: this);
    // セッションを復元または新規作成
    _loadSessions();
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
            name: sessionData['name'],
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
      setState(() {
        _tabController.dispose();
        _tabController = TabController(
          length: _sessions.length,
          vsync: this,
        );
      });
      
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
      'name': session.name,
      'sessionId': session.sessionId,
      'counter': _sessionCounter,
    }).toList();
    await prefs.setString('terminal_sessions', json.encode(sessionsList));
  }
  
  void _addNewSession() {
    final session = TerminalSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Terminal ${_sessionCounter++}',
    );
    
    if (mounted) {
      setState(() {
        _sessions.add(session);
        // TabControllerを再作成
        _tabController.dispose();
        _tabController = TabController(
          length: _sessions.length,
          vsync: this,
          initialIndex: _sessions.length - 1,
        );
      });
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
    session.channel?.sink.close(status.goingAway);
    
    if (mounted) {
      setState(() {
        _sessions.removeAt(index);
        // TabControllerを再作成
        _tabController.dispose();
        _tabController = TabController(
          length: _sessions.length,
          vsync: this,
          initialIndex: index > 0 ? index - 1 : 0,
        );
      });
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
      _handleTerminalInput(session, data);
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
      _handleTerminalInput(session, data);
    };
    
    // WebSocket再接続
    _connectWebSocket(session, reconnect: true);
  }
  
  void _handleTerminalInput(TerminalSession session, String data) {
    // WebSocket接続がある場合は全ての入力を直接送信
    if (session.channel != null && session.channel!.closeCode == null) {
      // 生の入力データをそのまま送信（PTYが制御文字を処理）
      session.channel!.sink.add(data);
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
          session.channel!.sink.add(json.encode({
            'type': 'session',
            'sessionId': reconnect ? session.sessionId : null,
            'cols': 80,
            'rows': 30,
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
    for (var session in _sessions) {
      session.isActive = false;
      session.channel?.sink.close(status.goingAway);
    }
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D30),
        toolbarHeight: 48,
        title: Row(
          children: [
            const Icon(Icons.terminal, size: 20),
            const SizedBox(width: 8),
            const Text('Multi Terminal', style: TextStyle(fontSize: 16)),
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
          preferredSize: const Size.fromHeight(48),
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
                          Text(session.name, style: const TextStyle(fontSize: 12)),
                          if (_sessions.length > 1) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _closeSession(index),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                onPressed: _addNewSession,
                tooltip: 'New Terminal',
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () async {
              // 全セッションをクリア
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
                  _tabController.dispose();
                  _tabController = TabController(length: 1, vsync: this);
                });
              }
              
              _addNewSession();
            },
            tooltip: 'Reset All',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, size: 20),
            onPressed: () {
              if (_sessions.isNotEmpty && _tabController.index < _sessions.length) {
                final session = _sessions[_tabController.index];
                session.terminal.buffer.clear();
                session.terminal.buffer.setCursor(0, 0);
                session.terminal.write('SAKANA Terminal v1.0.0\r\n\$ ');
              }
            },
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _sessions.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: _sessions.map((session) {
              return Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.all(8),
                child: TerminalView(
                  session.terminal,
                  controller: session.controller,
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
              );
            }).toList(),
          ),
    );
  }
}