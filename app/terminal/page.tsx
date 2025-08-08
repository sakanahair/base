'use client';

import { useEffect, useRef, useState } from 'react';
import './terminal.css';

export default function TerminalPage() {
  const terminalRef = useRef<HTMLDivElement>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const [terminal, setTerminal] = useState<any>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!terminalRef.current) return;

    // 動的インポートでxterm.jsを読み込む（SSR回避）
    const loadTerminal = async () => {
      try {
        const { Terminal } = await import('xterm');
        const { FitAddon } = await import('xterm-addon-fit');
        const { WebLinksAddon } = await import('xterm-addon-web-links');
        
        // CSSを動的に追加
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = 'https://cdn.jsdelivr.net/npm/xterm@5.3.0/css/xterm.css';
        document.head.appendChild(link);

        // Terminalインスタンスを作成
        const term = new Terminal({
          cursorBlink: true,
          fontSize: 14,
          fontFamily: 'Menlo, Monaco, "Courier New", monospace',
          theme: {
            background: '#1e1e1e',
            foreground: '#d4d4d4',
            cursor: '#d4d4d4',
            black: '#000000',
            red: '#cd3131',
            green: '#0dbc79',
            yellow: '#e5e510',
            blue: '#2472c8',
            magenta: '#bc3fbc',
            cyan: '#11a8cd',
            white: '#e5e5e5',
            brightBlack: '#666666',
            brightRed: '#f14c4c',
            brightGreen: '#23d18b',
            brightYellow: '#f5f543',
            brightBlue: '#3b8eea',
            brightMagenta: '#d670d6',
            brightCyan: '#29b8db',
            brightWhite: '#e5e5e5'
          }
        });

        // アドオンを追加
        const fitAddon = new FitAddon();
        const webLinksAddon = new WebLinksAddon();
        term.loadAddon(fitAddon);
        term.loadAddon(webLinksAddon);

        // ターミナルをDOMにアタッチ
        if (terminalRef.current) {
          term.open(terminalRef.current);
          fitAddon.fit();
        }

        // ウィンドウリサイズ対応
        const handleResize = () => fitAddon.fit();
        window.addEventListener('resize', handleResize);

        // ウェルカムメッセージ
        term.writeln('🚀 Web Terminal - Powered by xterm.js');
        term.writeln('');
        term.writeln('This is a demo terminal. Commands are simulated locally.');
        term.writeln('Try typing: help, clear, date, echo <message>');
        term.writeln('');
        term.write('$ ');

        // コマンドライン処理
        let currentLine = '';
        
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        term.onKey(({ key, domEvent }: any) => {
          const printable = !domEvent.altKey && !domEvent.ctrlKey && !domEvent.metaKey;
          
          if (domEvent.keyCode === 13) { // Enter
            term.writeln('');
            processCommand(term, currentLine);
            currentLine = '';
            term.write('$ ');
          } else if (domEvent.keyCode === 8) { // Backspace
            if (currentLine.length > 0) {
              currentLine = currentLine.slice(0, -1);
              term.write('\b \b');
            }
          } else if (printable) {
            currentLine += key;
            term.write(key);
          }
        });

        setTerminal(term);
        setIsConnected(true);
        setIsLoading(false);

        return () => {
          window.removeEventListener('resize', handleResize);
          term.dispose();
        };
      } catch (error) {
        console.error('Failed to load terminal:', error);
        setIsLoading(false);
      }
    };

    loadTerminal();
  }, []);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const processCommand = (term: any, cmd: string) => {
    const trimmedCmd = cmd.trim();
    const parts = trimmedCmd.split(' ');
    const command = parts[0];
    const args = parts.slice(1).join(' ');

    switch (command) {
      case '':
        break;
      case 'help':
        term.writeln('Available commands:');
        term.writeln('  help      - Show this help message');
        term.writeln('  clear     - Clear the terminal');
        term.writeln('  date      - Show current date and time');
        term.writeln('  echo      - Echo a message');
        term.writeln('  ls        - List files (simulated)');
        term.writeln('  pwd       - Print working directory');
        term.writeln('  whoami    - Display current user');
        break;
      case 'clear':
        term.clear();
        break;
      case 'date':
        term.writeln(new Date().toString());
        break;
      case 'echo':
        term.writeln(args || '');
        break;
      case 'ls':
        term.writeln('file1.txt  file2.js  directory/  README.md');
        break;
      case 'pwd':
        term.writeln('/home/user/web-terminal');
        break;
      case 'whoami':
        term.writeln('web-user');
        break;
      default:
        term.writeln(`Command not found: ${command}`);
        term.writeln('Type "help" for available commands');
    }
  };

  const clearTerminal = () => {
    if (terminal) {
      terminal.clear();
    }
  };

  const resetTerminal = () => {
    if (terminal) {
      terminal.reset();
      terminal.writeln('🚀 Terminal reset');
      terminal.write('$ ');
    }
  };

  return (
    <div className="min-h-screen bg-gray-900 p-4">
      <div className="max-w-7xl mx-auto">
        <div className="bg-gray-800 rounded-lg shadow-2xl overflow-hidden">
          <div className="bg-gray-700 px-4 py-2 flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="w-3 h-3 bg-red-500 rounded-full"></div>
              <div className="w-3 h-3 bg-yellow-500 rounded-full"></div>
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="ml-2 text-gray-300 text-sm">Terminal</span>
            </div>
            <div className="flex space-x-2">
              <button
                onClick={clearTerminal}
                className="px-3 py-1 text-xs bg-gray-600 text-gray-300 rounded hover:bg-gray-500"
                disabled={!isConnected}
              >
                Clear
              </button>
              <button
                onClick={resetTerminal}
                className="px-3 py-1 text-xs bg-gray-600 text-gray-300 rounded hover:bg-gray-500"
                disabled={!isConnected}
              >
                Reset
              </button>
              <span className={`px-3 py-1 text-xs rounded ${
                isConnected ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
              }`}>
                {isConnected ? 'Connected' : isLoading ? 'Loading...' : 'Disconnected'}
              </span>
            </div>
          </div>
          <div 
            ref={terminalRef} 
            className="p-2 bg-black"
            style={{ height: '600px' }}
          >
            {isLoading && (
              <div className="flex items-center justify-center h-full text-gray-400">
                <div className="text-center">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-400 mx-auto mb-4"></div>
                  <p>Loading terminal...</p>
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="mt-4 bg-gray-800 rounded-lg p-4">
          <h2 className="text-white text-lg font-semibold mb-2">ターミナル情報</h2>
          <div className="text-gray-300 text-sm space-y-1">
            <p>• このターミナルはブラウザ内でローカルに動作します</p>
            <p>• 実際のシステムコマンドは実行されません（シミュレーション）</p>
            <p>• WebSocketを使用してバックエンドと接続することも可能です</p>
          </div>
        </div>
      </div>
    </div>
  );
}