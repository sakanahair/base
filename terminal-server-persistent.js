#!/usr/bin/env node

// Use the ws module from next/node_modules
const WebSocket = require('./next/node_modules/ws');
const pty = require('./next/node_modules/node-pty');
const path = require('path');
const crypto = require('crypto');

const PORT = process.env.TERMINAL_PORT || 8090;

// セッション管理
const sessions = new Map();
const SESSION_TIMEOUT = 30 * 60 * 1000; // 30分でタイムアウト

// セッションクリーンアップ
setInterval(() => {
  const now = Date.now();
  for (const [sessionId, session] of sessions.entries()) {
    if (now - session.lastActivity > SESSION_TIMEOUT) {
      console.log(`Cleaning up inactive session: ${sessionId}`);
      if (session.shell) {
        session.shell.kill();
      }
      sessions.delete(sessionId);
    }
  }
}, 60000); // 1分ごとにチェック

// WebSocketサーバーを作成
const wss = new WebSocket.Server({ 
  port: PORT,
  path: '/terminal'
});

console.log(`Terminal WebSocket Server (Persistent) running on port ${PORT}`);

wss.on('connection', (ws, req) => {
  console.log('New terminal connection from:', req.socket.remoteAddress);
  
  let currentSession = null;
  
  // 初回メッセージでセッションIDを受信
  ws.on('message', (message) => {
    try {
      const msg = message.toString();
      
      // 初回接続時のセッションハンドシェイク
      if (!currentSession && msg.startsWith('{')) {
        try {
          const data = JSON.parse(msg);
          
          if (data.type === 'session') {
            const sessionId = data.sessionId;
            
            if (sessionId && sessions.has(sessionId)) {
              // 既存セッションに再接続
              currentSession = sessions.get(sessionId);
              currentSession.lastActivity = Date.now();
              currentSession.ws = ws;
              
              console.log(`Reconnected to session: ${sessionId}`);
              ws.send(JSON.stringify({
                type: 'session_restored',
                sessionId: sessionId
              }));
              
              // バッファに保存された出力を再送信
              if (currentSession.buffer && currentSession.buffer.length > 0) {
                // バッファの内容を結合して送信
                setTimeout(() => {
                  const replayData = currentSession.buffer.join('');
                  ws.send(replayData);
                  // 現在のプロンプトを再表示
                  currentSession.shell.write('\x1b[6n'); // カーソル位置を問い合わせて画面をリフレッシュ
                }, 200);
              } else {
                // バッファがない場合は初期プロンプトを送信
                setTimeout(() => {
                  ws.send('\r\n$ ');
                }, 200);
              }
            } else {
              // 新規セッション作成
              const newSessionId = crypto.randomBytes(16).toString('hex');
              
              const shell = pty.spawn('/bin/bash', [], {
                name: 'xterm-256color',
                cols: data.cols || 80,
                rows: data.rows || 30,
                cwd: path.resolve(__dirname, 'flutter'),
                env: { 
                  ...process.env, 
                  TERM: 'xterm-256color',
                  LANG: 'ja_JP.UTF-8',
                  LC_ALL: 'ja_JP.UTF-8'
                }
              });
              
              currentSession = {
                sessionId: newSessionId,
                shell: shell,
                ws: ws,
                lastActivity: Date.now(),
                buffer: []
              };
              
              sessions.set(newSessionId, currentSession);
              
              console.log(`Created new session: ${newSessionId}`);
              ws.send(JSON.stringify({
                type: 'session_created',
                sessionId: newSessionId
              }));
              
              // 初期メッセージ
              shell.write('\x1B[32m=== SAKANA Terminal Server Connected ===\x1B[0m\r\n');
              shell.write(`\x1B[33mSession ID: ${newSessionId}\x1B[0m\r\n`);
              shell.write(`\x1B[33mWorking Directory: ${path.resolve(__dirname, 'flutter')}\x1B[0m\r\n`);
              shell.write('\r\n');
              
              // シェルの出力をWebSocketに送信
              shell.on('data', (data) => {
                try {
                  currentSession.lastActivity = Date.now();
                  
                  // バッファに保存（文字列として）
                  if (!currentSession.buffer) currentSession.buffer = [];
                  currentSession.buffer.push(data.toString());
                  // 最後の5000文字を保持
                  const totalLength = currentSession.buffer.join('').length;
                  if (totalLength > 5000) {
                    const combined = currentSession.buffer.join('');
                    currentSession.buffer = [combined.substring(combined.length - 5000)];
                  }
                  
                  if (currentSession.ws && currentSession.ws.readyState === WebSocket.OPEN) {
                    currentSession.ws.send(data);
                  }
                } catch (e) {
                  console.error('Failed to send data:', e);
                }
              });
              
              shell.on('exit', (code, signal) => {
                console.log(`Shell exited with code ${code} and signal ${signal}`);
                if (currentSession.ws && currentSession.ws.readyState === WebSocket.OPEN) {
                  currentSession.ws.send(`\r\n\x1B[33mShell process terminated (${code || signal})\x1B[0m\r\n`);
                  currentSession.ws.close();
                }
                sessions.delete(newSessionId);
              });
              
              shell.on('error', (error) => {
                console.error('Shell error:', error);
                if (currentSession.ws && currentSession.ws.readyState === WebSocket.OPEN) {
                  currentSession.ws.send(`\x1B[31mShell error: ${error.message}\x1B[0m\r\n`);
                }
              });
            }
            
            return;
          }
        } catch (e) {
          // JSONパースエラー
        }
      }
      
      // 通常のメッセージ処理
      if (currentSession && currentSession.shell) {
        currentSession.lastActivity = Date.now();
        
        // JSONメッセージの場合
        if (msg.startsWith('{')) {
          try {
            const data = JSON.parse(msg);
            
            if (data.type === 'resize') {
              // ターミナルサイズ変更
              currentSession.shell.resize(data.cols, data.rows);
            } else if (data.type === 'command') {
              console.log('Executing command:', data.command);
              currentSession.shell.write(data.command + '\n');
            }
          } catch (e) {
            // JSONパースエラーの場合は生データとして処理
            currentSession.shell.write(msg);
          }
        } else {
          // 生のコマンドとして処理（制御文字含む）
          currentSession.shell.write(msg);
        }
      }
    } catch (e) {
      console.error('Error processing message:', e);
      ws.send(`\x1B[31mError: ${e.message}\x1B[0m\r\n`);
    }
  });
  
  // 接続エラー処理
  ws.on('error', (error) => {
    console.error('WebSocket error:', error);
  });
  
  // クリーンアップ
  ws.on('close', () => {
    console.log('Terminal connection closed');
    if (currentSession) {
      // セッションは維持（タイムアウトまで）
      currentSession.ws = null;
    }
  });
});

// グレースフルシャットダウン
process.on('SIGINT', () => {
  console.log('\nShutting down terminal server...');
  
  // 全セッションをクリーンアップ
  for (const session of sessions.values()) {
    if (session.shell) {
      session.shell.kill();
    }
  }
  
  wss.clients.forEach((ws) => {
    ws.close();
  });
  
  wss.close(() => {
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  
  for (const session of sessions.values()) {
    if (session.shell) {
      session.shell.kill();
    }
  }
  
  wss.close(() => {
    process.exit(0);
  });
});