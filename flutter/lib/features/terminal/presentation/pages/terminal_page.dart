import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  late final Terminal terminal;
  late final TerminalController terminalController;
  WebSocketChannel? _channel;
  String _currentCommand = '';
  List<String> _commandHistory = [];
  int _historyIndex = -1;
  String? _sessionId;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    
    terminal = Terminal(
      maxLines: 10000,
    );
    
    terminalController = TerminalController();
    
    // 初期メッセージ
    terminal.write('SAKANA Terminal v1.0.0\r\n');
    terminal.write('=====================\r\n');
    terminal.write('開発環境ターミナル - WebSocket接続中...\r\n\r\n');
    
    // セッションIDを取得
    _loadSessionId();
    
    // キーボード入力処理
    terminal.onOutput = (String data) {
      _handleTerminalInput(data);
    };
  }
  
  Future<void> _loadSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('terminal_session_id');
    
    // WebSocket接続
    _connectWebSocket();
  }
  
  Future<void> _saveSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('terminal_session_id', sessionId);
    _sessionId = sessionId;
  }

  void _connectWebSocket() {
    if (_isConnecting) return;
    _isConnecting = true;
    
    try {
      // WebSocketサーバーに接続（Cloudflareトンネル経由）
      final wsUrl = 'wss://terminal.sakana.hair/terminal';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          // JSONメッセージの処理
          if (message is String && message.startsWith('{')) {
            try {
              final data = json.decode(message);
              
              if (data['type'] == 'session_created') {
                // 新規セッション作成
                _saveSessionId(data['sessionId']);
                terminal.write('\x1B[32m新規セッション作成: ${data['sessionId'].substring(0, 8)}...\x1B[0m\r\n');
                setState(() {
                  _isConnecting = false;
                });
              } else if (data['type'] == 'session_restored') {
                // セッション復元
                terminal.buffer.clear();
                terminal.buffer.setCursor(0, 0);
                terminal.write('\x1B[32mセッション復元: ${data['sessionId'].substring(0, 8)}...\x1B[0m\r\n');
                setState(() {
                  _isConnecting = false;
                });
              }
              return;
            } catch (e) {
              // JSONパースエラー - 通常のメッセージとして処理
            }
          }
          
          // サーバーからの出力を表示
          terminal.write(message);
        },
        onError: (error) {
          terminal.write('\x1B[31mWebSocket Error: $error\x1B[0m\r\n');
          setState(() {
            _isConnecting = false;
          });
          _setupLocalTerminal();
        },
        onDone: () {
          terminal.write('\x1B[33mWebSocket接続が切断されました\x1B[0m\r\n');
          setState(() {
            _isConnecting = false;
          });
          _setupLocalTerminal();
        },
      );
      
      // セッションハンドシェイク送信
      Future.delayed(Duration(milliseconds: 100), () {
        if (_channel != null && _channel!.closeCode == null) {
          _channel!.sink.add(json.encode({
            'type': 'session',
            'sessionId': _sessionId,
            'cols': 80,
            'rows': 30,
          }));
        }
      });
      
    } catch (e) {
      terminal.write('\x1B[31m接続エラー: $e\x1B[0m\r\n');
      setState(() {
        _isConnecting = false;
      });
      _setupLocalTerminal();
    }
  }

  void _setupLocalTerminal() {
    // WebSocket接続失敗時はローカルモード
    terminal.write('\x1B[33mローカルモードで動作中（制限あり）\x1B[0m\r\n');
    terminal.write('\$ ');
  }

  void _handleTerminalInput(String data) {
    // WebSocket接続がある場合は全ての入力を直接送信
    if (_channel != null && _channel!.closeCode == null) {
      // 生の入力データをそのまま送信（PTYが制御文字を処理）
      _channel!.sink.add(data);
      return;
    }
    
    // ローカルモードの処理（WebSocket未接続時）
    if (data.codeUnits.length == 1) {
      final code = data.codeUnits[0];
      
      // Enter key
      if (code == 13 || code == 10) {
        terminal.write('\r\n');
        _executeCommand(_currentCommand);
        _commandHistory.add(_currentCommand);
        _historyIndex = _commandHistory.length;
        _currentCommand = '';
      }
      // Backspace
      else if (code == 127 || code == 8) {
        if (_currentCommand.isNotEmpty) {
          _currentCommand = _currentCommand.substring(0, _currentCommand.length - 1);
          terminal.write('\b \b');
        }
      }
      // Ctrl+C
      else if (code == 3) {
        terminal.write('^C\r\n\$ ');
        _currentCommand = '';
      }
      // Ctrl+L (clear)
      else if (code == 12) {
        terminal.buffer.clear();
        terminal.buffer.setCursor(0, 0);
        terminal.write('SAKANA Terminal v1.0.0\r\n\$ ');
        _currentCommand = '';
      }
      // 通常文字
      else if (code >= 32 && code < 127) {
        _currentCommand += data;
        terminal.write(data);
      }
    }
    // 矢印キー（上下で履歴）
    else if (data == '\x1B[A') { // Up arrow
      if (_historyIndex > 0 && _commandHistory.isNotEmpty) {
        // 現在の行をクリア
        terminal.write('\r\x1B[K\$ ');
        _historyIndex--;
        _currentCommand = _commandHistory[_historyIndex];
        terminal.write(_currentCommand);
      }
    } else if (data == '\x1B[B') { // Down arrow
      if (_historyIndex < _commandHistory.length - 1) {
        terminal.write('\r\x1B[K\$ ');
        _historyIndex++;
        _currentCommand = _commandHistory[_historyIndex];
        terminal.write(_currentCommand);
      } else if (_historyIndex == _commandHistory.length - 1) {
        terminal.write('\r\x1B[K\$ ');
        _historyIndex = _commandHistory.length;
        _currentCommand = '';
      }
    }
  }

  void _executeCommand(String command) {
    if (command.trim().isEmpty) {
      terminal.write('\$ ');
      return;
    }

    // ローカルモードでの簡易コマンド処理（WebSocket接続時は_handleTerminalInputで直接送信）
    _executeLocalCommand(command);
  }

  void _executeLocalCommand(String command) {
    final parts = command.trim().split(' ');
    final cmd = parts[0];
    
    switch (cmd) {
      case 'help':
        terminal.write('利用可能なコマンド:\r\n');
        terminal.write('  help     - このヘルプを表示\r\n');
        terminal.write('  clear    - 画面をクリア\r\n');
        terminal.write('  date     - 現在の日時\r\n');
        terminal.write('  echo     - テキストを表示\r\n');
        terminal.write('  pwd      - 現在のディレクトリ\r\n');
        terminal.write('  ls       - ファイル一覧（模擬）\r\n');
        terminal.write('  flutter  - Flutter情報\r\n');
        terminal.write('  exit     - ターミナルを閉じる\r\n');
        break;
        
      case 'clear':
        terminal.buffer.clear();
        terminal.buffer.setCursor(0, 0);
        break;
        
      case 'date':
        terminal.write('${DateTime.now()}\r\n');
        break;
        
      case 'echo':
        if (parts.length > 1) {
          terminal.write('${parts.sublist(1).join(' ')}\r\n');
        }
        break;
        
      case 'pwd':
        terminal.write('/Users/apple/DEV/SAKANA_AI/flutter\r\n');
        break;
        
      case 'ls':
        terminal.write('lib/\r\n');
        terminal.write('web/\r\n');
        terminal.write('assets/\r\n');
        terminal.write('pubspec.yaml\r\n');
        terminal.write('README.md\r\n');
        break;
        
      case 'flutter':
        terminal.write('Flutter 3.x.x • channel stable\r\n');
        terminal.write('Dart 3.x.x\r\n');
        terminal.write('DevTools 2.x.x\r\n');
        break;
        
      case 'exit':
        Navigator.of(context).pop();
        return;
        
      default:
        terminal.write('\x1B[31mcommand not found: $cmd\x1B[0m\r\n');
        terminal.write('Type "help" for available commands\r\n');
    }
    
    terminal.write('\$ ');
  }

  @override
  void dispose() {
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D30),
        title: Row(
          children: [
            const Icon(Icons.terminal, size: 20),
            const SizedBox(width: 8),
            const Text('Terminal', style: TextStyle(fontSize: 16)),
            const Spacer(),
            if (_channel != null && _channel!.closeCode == null)
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
                    Text('Local Mode', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () async {
              // セッションをリセット
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('terminal_session_id');
              _sessionId = null;
              
              // 再接続
              _channel?.sink.close(status.goingAway);
              _channel = null;
              terminal.buffer.clear();
              terminal.buffer.setCursor(0, 0);
              terminal.write('SAKANA Terminal v1.0.0\r\n');
              terminal.write('=====================\r\n');
              terminal.write('新規セッション作成中...\r\n\r\n');
              _connectWebSocket();
            },
            tooltip: 'New Session',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, size: 20),
            onPressed: () {
              terminal.buffer.clear();
              terminal.buffer.setCursor(0, 0);
              terminal.write('SAKANA Terminal v1.0.0\r\n\$ ');
            },
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () {
              // 設定ダイアログ
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF1E1E1E),
        padding: const EdgeInsets.all(8),
        child: TerminalView(
          terminal,
          controller: terminalController,
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
    );
  }
}