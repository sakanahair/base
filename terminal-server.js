#!/usr/bin/env node

// Use the ws module from next/node_modules
const WebSocket = require('./next/node_modules/ws');
const pty = require('./next/node_modules/node-pty');
const path = require('path');

const PORT = process.env.TERMINAL_PORT || 8090;

// WebSocketサーバーを作成
const wss = new WebSocket.Server({ 
  port: PORT,
  path: '/terminal'
});

console.log(`Terminal WebSocket Server running on port ${PORT}`);

wss.on('connection', (ws, req) => {
  console.log('New terminal connection from:', req.socket.remoteAddress);
  
  // シェルプロセスを起動（PTYを使用）
  const shell = pty.spawn('/bin/bash', [], {
    name: 'xterm-256color',
    cols: 80,
    rows: 30,
    cwd: path.resolve(__dirname, 'flutter'),
    env: { 
      ...process.env, 
      TERM: 'xterm-256color',
      LANG: 'ja_JP.UTF-8',
      LC_ALL: 'ja_JP.UTF-8'
    }
  });
  
  // 初期メッセージ
  ws.send('\x1B[32m=== SAKANA Terminal Server Connected ===\x1B[0m\r\n');
  ws.send(`\x1B[33mWorking Directory: ${path.resolve(__dirname, 'flutter')}\x1B[0m\r\n`);
  ws.send('\r\n');
  
  // シェルの出力をWebSocketに送信
  shell.on('data', (data) => {
    try {
      ws.send(data);
    } catch (e) {
      console.error('Failed to send data:', e);
    }
  });
  
  // WebSocketからのメッセージをシェルに送信
  ws.on('message', (message) => {
    try {
      const msg = message.toString();
      
      // JSONメッセージの場合
      if (msg.startsWith('{')) {
        try {
          const data = JSON.parse(msg);
          
          if (data.type === 'command') {
            console.log('Executing command:', data.command);
            shell.write(data.command + '\n');
          } else if (data.type === 'resize') {
            // ターミナルサイズ変更
            shell.resize(data.cols, data.rows);
          }
        } catch (e) {
          // JSONパースエラーの場合は生データとして処理
          shell.write(msg);
        }
      } else {
        // 生のコマンドとして処理（制御文字含む）
        shell.write(msg);
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
    try {
      shell.kill('SIGTERM');
      setTimeout(() => {
        if (!shell.killed) {
          shell.kill('SIGKILL');
        }
      }, 1000);
    } catch (e) {
      console.error('Error killing shell:', e);
    }
  });
  
  shell.on('exit', (code, signal) => {
    console.log(`Shell exited with code ${code} and signal ${signal}`);
    ws.send(`\r\n\x1B[33mShell process terminated (${code || signal})\x1B[0m\r\n`);
    ws.close();
  });
  
  // エラーハンドリング
  shell.on('error', (error) => {
    console.error('Shell error:', error);
    ws.send(`\x1B[31mShell error: ${error.message}\x1B[0m\r\n`);
  });
});

// グレースフルシャットダウン
process.on('SIGINT', () => {
  console.log('\nShutting down terminal server...');
  wss.clients.forEach((ws) => {
    ws.close();
  });
  wss.close(() => {
    process.exit(0);
  });
});

process.on('SIGTERM', () => {
  console.log('Received SIGTERM, shutting down...');
  wss.close(() => {
    process.exit(0);
  });
});