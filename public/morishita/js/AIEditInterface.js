(function() {
    'use strict';

    class AIEditInterface {
        constructor() {
            this.currentSessionId = null;
            this.eventSource = null;
            this.commandHistory = [];
            this.historyIndex = -1;
            this.outputBuffer = '';
            this.autoConnectEnabled = true;
            this.currentDirectory = window.location.pathname.replace(/\/index\.html$/, '');
            this.ansiFilterEnabled = true; // ANSIフィルターをデフォルトで有効
            this.currentElementAnalysis = null; // 現在の要素解析データ
            this.gitHistoryManager = null; // Git履歴管理
            
            // APIベースパスを動的に計算
            this.apiBasePath = this.calculateApiBasePath();
            console.log('[AIEditInterface] API Base Path:', this.apiBasePath);
        }

        /**
         * APIのベースパスを動的に計算
         */
        calculateApiBasePath() {
            const protocol = window.location.protocol;
            const host = window.location.host;
            
            // 絶対パスを使用（プロトコルとホストを含む）
            const basePath = `${protocol}//${host}`;
            
            console.log('[AIEditInterface] Current Path:', window.location.pathname);
            console.log('[AIEditInterface] Protocol:', protocol);
            console.log('[AIEditInterface] Host:', host);
            
            return basePath;
        }

        /**
         * AIタブのコンテンツを作成
         */
        createContent(container, elementAnalysis = null) {
            // 要素解析データを保存
            this.currentElementAnalysis = elementAnalysis;
            
            // Git履歴管理の初期化（現在のサイトディレクトリを指定）
            if (!this.gitHistoryManager && window.GitHistoryManager) {
                const workingDir = this.getCurrentSiteDirectory();
                this.gitHistoryManager = new window.GitHistoryManager(workingDir);
            }
            
            container.innerHTML = '';
            container.style.cssText = 'padding: 0; display: flex; flex-direction: column; height: 500px;';

            // 接続状態エリア
            const sessionArea = document.createElement('div');
            sessionArea.style.cssText = `
                padding: 15px;
                background: #f8f8f8;
                border-bottom: 1px solid #e0e0e0;
            `;

            const statusDiv = document.createElement('div');
            statusDiv.id = 'ai-connection-status';
            statusDiv.style.cssText = `
                font-size: 14px;
                color: #666;
                text-align: center;
            `;
            statusDiv.innerHTML = '<span style="color: #FF9800;">⚡</span> 自動接続中...';

            sessionArea.appendChild(statusDiv);

            // セッション操作ボタンエリア
            const sessionControls = document.createElement('div');
            sessionControls.style.cssText = `
                margin-top: 10px;
                display: flex;
                gap: 10px;
                justify-content: center;
            `;

            // 再起動ボタン
            const restartBtn = document.createElement('button');
            restartBtn.textContent = '🔄 セッション再起動';
            restartBtn.style.cssText = `
                padding: 6px 12px;
                background: #FF5722;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
                transition: background 0.2s;
            `;
            restartBtn.onclick = () => this.restartSession();
            restartBtn.onmouseover = () => restartBtn.style.background = '#E64A19';
            restartBtn.onmouseout = () => restartBtn.style.background = '#FF5722';

            // 再接続ボタン
            const reconnectBtn = document.createElement('button');
            reconnectBtn.textContent = '🔌 再接続';
            reconnectBtn.style.cssText = `
                padding: 6px 12px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 12px;
                transition: background 0.2s;
            `;
            reconnectBtn.onclick = () => this.autoConnect();
            reconnectBtn.onmouseover = () => reconnectBtn.style.background = '#1976D2';
            reconnectBtn.onmouseout = () => reconnectBtn.style.background = '#2196F3';

            sessionControls.appendChild(restartBtn);
            sessionControls.appendChild(reconnectBtn);
            sessionArea.appendChild(sessionControls);

            // 現在の要素情報表示エリア
            const elementInfoArea = document.createElement('div');
            elementInfoArea.id = 'element-info-area';
            elementInfoArea.style.cssText = `
                background: #f0f0f0;
                padding: 10px;
                border-bottom: 1px solid #ddd;
                font-size: 12px;
                max-height: 100px;
                overflow-y: auto;
            `;
            this.updateElementInfo(elementInfoArea);

            // 出力エリア
            const outputArea = document.createElement('div');
            outputArea.id = 'ai-output';
            outputArea.style.cssText = `
                flex: 1;
                background: #1e1e1e;
                color: #00ff00;
                font-family: 'Courier New', monospace;
                font-size: 13px;
                padding: 10px;
                overflow-y: auto;
                white-space: pre-wrap;
                word-wrap: break-word;
            `;

            // 入力エリア
            const inputArea = document.createElement('div');
            inputArea.style.cssText = `
                padding: 10px;
                background: #f0f0f0;
                border-top: 1px solid #ddd;
                display: flex;
                gap: 10px;
            `;

            const commandInput = document.createElement('textarea');
            commandInput.id = 'ai-command-input';
            commandInput.placeholder = 'コマンドを入力... (Shift+Enterで送信)';
            commandInput.style.cssText = `
                flex: 1;
                padding: 8px 12px;
                border: 1px solid #ddd;
                border-radius: 4px;
                font-family: 'Courier New', monospace;
                font-size: 14px;
                resize: vertical;
                min-height: 36px;
                max-height: 100px;
            `;

            const sendBtn = document.createElement('button');
            sendBtn.id = 'ai-send-button';
            sendBtn.textContent = '送信';
            sendBtn.style.cssText = `
                padding: 8px 16px;
                background: #64748b;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
                font-weight: 500;
            `;
            sendBtn.onclick = () => this.sendCommand();

            const enterBtn = document.createElement('button');
            enterBtn.id = 'ai-enter-button';
            enterBtn.textContent = '↵ Enter';
            enterBtn.style.cssText = `
                padding: 8px 16px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
                font-weight: 500;
                min-width: 80px;
            `;
            enterBtn.onclick = () => this.sendEnterKey();

            inputArea.appendChild(commandInput);
            inputArea.appendChild(sendBtn);
            inputArea.appendChild(enterBtn);

            // コンテナに追加
            container.appendChild(sessionArea);
            container.appendChild(elementInfoArea);
            container.appendChild(outputArea);
            container.appendChild(inputArea);

            // イベントリスナー設定
            commandInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && e.shiftKey) {
                    e.preventDefault();
                    this.sendCommand();
                } else if (e.key === 'ArrowUp') {
                    e.preventDefault();
                    this.navigateHistory(-1);
                } else if (e.key === 'ArrowDown') {
                    e.preventDefault();
                    this.navigateHistory(1);
                }
            });

            // 自動接続を開始
            this.autoConnect();
        }

        /**
         * 現在のサイトディレクトリを取得
         */
        getCurrentSiteDirectory() {
            // 現在のURLパスから作業ディレクトリを推定
            const currentPath = window.location.pathname;
            if (currentPath.startsWith('/site/')) {
                // /site/next/project/ -> public/site/next/project
                return 'public' + currentPath.replace(/\/$/, '');
            }
            // デフォルトはプロジェクトディレクトリ
            return 'public/site/next/project';
        }

        /**
         * 自動接続
         */
        async autoConnect() {
            try {
                this.updateStatus('プロジェクト専用セッションを検索中...', 'connecting');
                
                // 現在のプロジェクトディレクトリを取得
                const projectDir = this.getCurrentSiteDirectory();
                const fullProjectDir = projectDir.startsWith('/') ? projectDir : 
                    `/Users/apple/DEV/LINEBIZ/ai-controller/site-manager/${projectDir}`;
                
                // プロジェクトディレクトリを指定してセッションを取得
                const apiUrl = `${this.apiBasePath}/api/sessions?projectDir=${encodeURIComponent(fullProjectDir)}`;
                console.log('[AIEditInterface] Fetching sessions from:', apiUrl);
                
                const response = await fetch(apiUrl);
                
                if (!response.ok) {
                    console.error('[AIEditInterface] API Error:', response.status, response.statusText);
                    throw new Error(`API returned ${response.status}: ${response.statusText}`);
                }
                
                const data = await response.json();
                console.log('[AIEditInterface] Sessions data:', data);

                if (data.sessions && data.sessions.length > 0) {
                    // 最初のセッション（最も適切なセッション）に自動接続
                    const session = data.sessions[0];
                    console.log('[AIEditInterface] Found session:', session);
                    console.log('[AIEditInterface] Session ID:', session.sessionId);
                    
                    if (!session.sessionId) {
                        console.error('[AIEditInterface] Session has no sessionId:', session);
                        this.appendOutput('[エラー] セッションIDが無効です\n');
                        this.updateStatus('接続エラー', 'error');
                        return;
                    }
                    
                    this.connectToSession(session.sessionId);
                    
                    const dirName = fullProjectDir.split('/').pop() || 'project';
                    this.appendOutput(`[システム] ${dirName} 専用セッションに自動接続を試みています...\n`);
                    
                    // Claude CLIセッションの場合は特別な表示
                    if (session.isClaude) {
                        this.appendOutput('[システム] Claude CLIセッションを検出しました\n');
                    }
                } else {
                    console.log('[AIEditInterface] No sessions found in data:', data);
                    this.updateStatus('利用可能なセッションがありません', 'warning');
                    this.appendOutput('[エラー] セッションが見つかりません。Claude CLIを起動してください。\n');
                    this.appendOutput(`[デバッグ] API URL: ${this.apiBasePath}/api/sessions\n`);
                    this.appendOutput(`[デバッグ] Project Dir: ${fullProjectDir}\n`);
                }
            } catch (error) {
                console.error('[AIEditInterface] 自動接続エラー:', error);
                console.error('[AIEditInterface] エラー詳細:', {
                    message: error.message,
                    stack: error.stack,
                    apiBasePath: this.apiBasePath,
                    fullProjectDir: fullProjectDir
                });
                this.updateStatus('自動接続に失敗しました', 'error');
                this.appendOutput(`[エラー] 自動接続に失敗しました: ${error.message}\n`);
                this.appendOutput(`[デバッグ] APIパス: ${this.apiBasePath}/api/sessions\n`);
            }
        }

        /**
         * セッションに接続
         */
        connectToSession(sessionId) {
            if (!sessionId) {
                console.error('[AIEditInterface] セッションIDが指定されていません');
                this.appendOutput('[エラー] セッションIDが指定されていません\n');
                this.updateStatus('接続エラー', 'error');
                return;
            }
            
            console.log('[AIEditInterface] Connecting to session:', sessionId);
            this.disconnect();

            this.currentSessionId = sessionId;
            this.updateStatus('接続中...', 'connecting');

            const streamUrl = `${this.apiBasePath}/api/session/${sessionId}/stream`;
            console.log('[AIEditInterface] Connecting to stream:', streamUrl);
            
            try {
                this.eventSource = new EventSource(streamUrl);
                console.log('[AIEditInterface] EventSource created successfully');
            } catch (error) {
                console.error('[AIEditInterface] EventSource creation error:', error);
                this.appendOutput(`[エラー] ストリーム接続エラー: ${error.message}\n`);
                this.updateStatus('接続エラー', 'error');
                this.currentSessionId = null;
                return;
            }

            this.eventSource.onopen = () => {
                this.updateStatus('接続済み', 'connected');
                this.appendOutput(`[システム] セッション ${sessionId.substring(0, 8)}... に接続しました\n`);
            };

            this.eventSource.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    if (data.type === 'output') {
                        console.log('[DEBUG] Raw output:', data.data);
                        console.log('[DEBUG] Filter enabled:', this.ansiFilterEnabled);
                        
                        const filteredOutput = this.ansiFilterEnabled ? 
                            this.filterAnsiEscapeCodes(data.data) : data.data;
                        
                        console.log('[DEBUG] Filtered output:', filteredOutput);
                        this.appendOutput(filteredOutput);
                    } else if (data.type === 'error') {
                        this.appendOutput(`[エラー] ${data.message}\n`);
                    } else if (data.type === 'disconnected') {
                        this.updateStatus('切断されました', 'disconnected');
                        this.disconnect();
                    }
                } catch (err) {
                    console.error('メッセージ処理エラー:', err);
                }
            };

            this.eventSource.onerror = (error) => {
                console.error('EventSourceエラー:', error);
                this.updateStatus('接続エラー', 'error');
                this.disconnect();
            };
        }

        /**
         * 切断
         */
        disconnect() {
            if (this.eventSource) {
                this.eventSource.close();
                this.eventSource = null;
            }
            this.currentSessionId = null;
            this.updateStatus('接続されていません', 'disconnected');
        }

        /**
         * セッションを再起動
         */
        async restartSession() {
            if (!this.currentSessionId) {
                this.appendOutput('[エラー] 再起動するセッションがありません\n');
                return;
            }

            try {
                this.updateStatus('セッション再起動中...', 'connecting');
                this.appendOutput('[システム] セッションを再起動しています...\n');
                
                const restartUrl = `${this.apiBasePath}/api/session/${this.currentSessionId}/restart`;
                console.log('[AIEditInterface] Restarting session:', restartUrl);
                
                const response = await fetch(restartUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
                
                if (!response.ok) {
                    const error = await response.json();
                    throw new Error(error.error || 'セッション再起動に失敗しました');
                }
                
                const result = await response.json();
                console.log('[AIEditInterface] Restart result:', result);
                
                // 少し待ってから再接続
                setTimeout(() => {
                    this.connectToSession(this.currentSessionId);
                    this.appendOutput('[システム] セッションが再起動されました\n');
                }, 1000);
                
            } catch (error) {
                console.error('[AIEditInterface] セッション再起動エラー:', error);
                this.appendOutput(`[エラー] セッション再起動エラー: ${error.message}\n`);
                this.updateStatus('再起動エラー', 'error');
            }
        }

        /**
         * コマンドを送信
         */
        async sendCommand() {
            const input = document.getElementById('ai-command-input');
            const command = input.value.trim();

            if (!this.currentSessionId) {
                this.appendOutput('[エラー] セッションが選択されていません\n');
                this.appendOutput('[ヒント] 自動接続を待つか、Claude CLIが起動していることを確認してください\n');
                // 自動接続を再試行
                this.autoConnect();
                return;
            }

            if (command === '') {
                return;
            }

            const sendBtn = document.getElementById('ai-send-button');
            sendBtn.disabled = true;
            sendBtn.textContent = '送信中...';

            // コマンド履歴に追加
            this.commandHistory.push(command);
            this.historyIndex = this.commandHistory.length;

            // 入力をクリア
            input.value = '';

            // 要素情報を含むコマンドを構築
            const enhancedCommand = this.buildEnhancedCommand(command);

            // コマンドを表示
            this.appendOutput(`$ ${command}\n`);

            try {
                const sendUrl = `${this.apiBasePath}/api/send-command/${this.currentSessionId}`;
                console.log('[AIEditInterface] Sending command to:', sendUrl);
                
                const response = await fetch(sendUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ command: enhancedCommand })
                });

                const result = await response.json();

                if (response.ok && result.success) {
                    // コマンド送信後、自動的にEnterキーも送信
                    setTimeout(() => {
                        this.sendEnterKey();
                    }, 100);
                } else {
                    this.appendOutput(`[エラー] ${result.error || 'コマンド送信に失敗しました'}\n`);
                }
            } catch (error) {
                console.error('コマンド送信エラー:', error);
                this.appendOutput('[エラー] コマンド送信中にエラーが発生しました\n');
            } finally {
                sendBtn.disabled = false;
                sendBtn.textContent = '送信';
            }
        }

        /**
         * 履歴をナビゲート
         */
        navigateHistory(direction) {
            const input = document.getElementById('ai-command-input');
            
            if (this.commandHistory.length === 0) return;

            this.historyIndex += direction;
            
            if (this.historyIndex < 0) {
                this.historyIndex = 0;
            } else if (this.historyIndex >= this.commandHistory.length) {
                this.historyIndex = this.commandHistory.length;
                input.value = '';
                return;
            }

            input.value = this.commandHistory[this.historyIndex];
        }

        /**
         * 出力を追加
         */
        appendOutput(text) {
            const output = document.getElementById('ai-output');
            if (!output) return;

            let displayText = text;
            
            // ANSIフィルターが有効な場合のみフィルタリング
            if (this.ansiFilterEnabled) {
                displayText = this.filterAnsiEscapeCodes(text);
            }
            
            // HTMLエスケープ処理（コマンドライン以外）
            const lines = displayText.split('\n');
            const processedLines = lines.map(line => {
                // $ で始まるコマンドラインはそのまま保持
                if (line.startsWith('$ ')) {
                    return `<span style="color: #ffff00; font-weight: bold;">${this.escapeHtml(line)}</span>`;
                }
                // [システム] や [エラー] メッセージ
                else if (line.startsWith('[システム]')) {
                    return `<span style="color: #00ff00;">${this.escapeHtml(line)}</span>`;
                }
                else if (line.startsWith('[エラー]')) {
                    return `<span style="color: #ff6666;">${this.escapeHtml(line)}</span>`;
                }
                // その他の行
                else {
                    return this.escapeHtml(line);
                }
            });
            
            // 出力を追加（innerHTML を使用）
            output.innerHTML += processedLines.join('\n');
            // 自動スクロール
            output.scrollTop = output.scrollHeight;
        }

        /**
         * HTMLエスケープ
         */
        escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        /**
         * Enterキーのみを送信
         */
        async sendEnterKey() {
            if (!this.currentSessionId) {
                this.appendOutput('[エラー] セッションが選択されていません\n');
                this.appendOutput('[ヒント] 自動接続を待つか、Claude CLIが起動していることを確認してください\n');
                // 自動接続を再試行
                this.autoConnect();
                return;
            }

            const enterBtn = document.getElementById('ai-enter-button');
            enterBtn.disabled = true;
            enterBtn.textContent = '送信中...';

            try {
                const sendUrl = `${this.apiBasePath}/api/send-command/${this.currentSessionId}`;
                const response = await fetch(sendUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ command: '' }) // 空のコマンドを送信（Enterキーのみ）
                });

                const result = await response.json();

                if (!response.ok || !result.success) {
                    this.appendOutput(`[エラー] ${result.error || 'Enter送信に失敗しました'}\n`);
                }
            } catch (error) {
                console.error('Enter送信エラー:', error);
                this.appendOutput('[エラー] Enter送信中にエラーが発生しました\n');
            } finally {
                enterBtn.disabled = false;
                enterBtn.textContent = '↵ Enter';
            }
        }

        /**
         * ANSIエスケープコードをフィルタリング
         */
        filterAnsiEscapeCodes(text) {
            if (!text) return text;
            
            console.log('[DEBUG] filterAnsiEscapeCodes called with:', text.substring(0, 100));
            
            // ANSIエスケープシーケンスを徹底的に削除
            let displayText = text
                .replace(/\x1b\[[0-9;]*m/g, '') // カラーコード削除
                .replace(/\x1b\[[0-9]*[A-Z]/g, '') // カーソル移動コマンド削除
                .replace(/\x1b\[[?][0-9]*[a-z]/g, '') // その他のエスケープシーケンス
                .replace(/\x1b\[2K/g, '') // 行クリア
                .replace(/\x1b\[G/g, '') // カーソル位置
                .replace(/\x1b\[[0-9]*J/g, '') // 画面クリア
                .replace(/\x1b\[[0-9]*K/g, '') // 行末までクリア
                .replace(/\x1b\[\?[0-9]+[hl]/g, '') // カーソル表示/非表示
                .replace(/\[2K/g, '') // 残りの行クリア
                .replace(/\[1A/g, '') // 残りのカーソル上移動
                .replace(/\[\d+[A-Z]/g, '') // 残りのエスケープシーケンス
                .replace(/\x1b[>=]/g, '') // その他のエスケープ文字
                .replace(/\u001b/g, '') // Unicodeエスケープ
                .replace(/38;5;\d+m/g, '') // 残存するカラーコード（38;5;220m等）
                .replace(/\d+;5;\d+m/g, ''); // その他のカラーコード
            
            console.log('[DEBUG] After ANSI removal:', displayText.substring(0, 100));
            
            // 必要な行（コマンドプロンプトと結果）だけを抽出
            const lines = displayText.split('\n');
            const filteredLines = [];
            let isCommandLine = false;
            let lastWasCommand = false;
            let isAfterBulletPoint = false;
            
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                const trimmedLine = line.trim();
                
                // ⚫︎を検出したら、その後の出力を最優先で取得
                if (trimmedLine.includes('⚫︎') || trimmedLine.includes('●') || trimmedLine.includes('◉')) {
                    isAfterBulletPoint = true;
                    console.log(`[DEBUG] ⚫︎を検出: "${trimmedLine}"`);
                    console.log(`[DEBUG] isAfterBulletPoint = true`);
                    continue; // ⚫︎自体の行は表示しない
                }
                
                // bash-3.2$ で始まる行（コマンド）を検出
                if (line.includes('bash-3.2$')) {
                    const commandMatch = line.match(/bash-3\.2\$\s*(.*)$/);
                    if (commandMatch) {
                        const command = commandMatch[1].trim();
                        if (command) {
                            // 前の行との間に空行を入れる（読みやすさのため）
                            if (filteredLines.length > 0 && !lastWasCommand) {
                                filteredLines.push('');
                            }
                            filteredLines.push(`$ ${command}`);
                            isCommandLine = true;
                            lastWasCommand = true;
                            isAfterBulletPoint = false;
                            continue;
                        }
                    }
                }
                
                // 空行は基本的に無視（特定の場合を除く）
                if (!trimmedLine) {
                    lastWasCommand = false;
                    continue;
                }
                
                // Claude CLIの装飾を含む行は無視（より包括的なパターン）
                if (trimmedLine.match(/[╭│╰─┬┐╮┴┘╯⎿]/u) || // ボックス描画文字とコーナー文字
                    trimmedLine.match(/[⏺✽✳✴✵✶✷✸✹✺⊛◉●◐◑◒◓]/u) || // 処理中インジケータ
                    trimmedLine.match(/(Puttering|Meandering|Pondering|Thinking|Processing|Working|Analyzing|Perusing|Reading|Searching|Computing|Calculating|Flibbertigibbeting|Contemplating|Musing|Ruminating|Approaching|Running|Waiting)/i) ||
                    trimmedLine.match(/\b(shortcuts|interrupt|tokens|esc|model|usage|limit|Opus)\b/i) ||
                    trimmedLine.match(/[↑↓→←·]/u) || // 矢印と中点
                    trimmedLine.match(/\?\s*for/i) || // "? for" パターン
                    trimmedLine.match(/\/model\s+to\s+use/i) || // モデル切り替えメッセージ
                    trimmedLine.match(/best\s+available/i) || // "best available" メッセージ
                    trimmedLine.match(/^\\s*[>＞]\s*$/) || // 単独のプロンプト記号
                    trimmedLine.match(/^\\s*[?？]\s*$/) || // 単独の疑問符
                    trimmedLine.match(/^\\s*\.\s*$/) || // 単独のドット
                    trimmedLine.match(/^[━─]+$/) || // 水平線
                    trimmedLine.match(/^\\s*sho\s*$/) || // 分割された文字列の断片
                    trimmedLine.match(/^\\s*rtcuts\s*$/) || 
                    trimmedLine.match(/^\\s*hortcuts\s*$/) ||
                    trimmedLine.match(/^\\s*short\s*$/) ||
                    trimmedLine.match(/^\\s*shor\s*$/) ||
                    trimmedLine.match(/^\\s*sh\s*$/) ||
                    trimmedLine.match(/^\\s*t\s·\s/) || // "t · /model" のような断片
                    trimmedLine.match(/^\\s*\?\s*fo\s*$/) || // "? fo" 断片
                    trimmedLine === '?' || trimmedLine === 'for' || trimmedLine === 'sho' || 
                    trimmedLine === 'rtcuts' || trimmedLine === 'hortcuts' || trimmedLine === 'sh' ||
                    trimmedLine === 'short' || trimmedLine === 'shor' || trimmedLine === '? fo' ||
                    trimmedLine.length < 2 && !trimmedLine.match(/\d/)) { // 1文字の無意味な出力（数字以外）
                    continue;
                }
                
                // HTMLタグを除去
                let cleanLine = line.replace(/<[^>]*>/g, '');
                
                // Claude特有の表記を削除
                cleanLine = cleanLine
                    .replace(/\bBash\([^)]+\)/g, '') // Bash(...)表記
                    .replace(/\bTool\([^)]+\)/g, '') // Tool(...)表記
                    .replace(/\(\s*\)/g, '') // 空の括弧
                    .replace(/\s{3,}/g, '  '); // 3つ以上の連続スペースを2つに
                
                const finalCleanLine = cleanLine.trim();
                
                // ⚫︎以降の出力は最優先で取得（デバッグのためほぼすべて表示）
                if (isAfterBulletPoint) {
                    if (finalCleanLine && finalCleanLine.length > 0) {
                        console.log(`[DEBUG] ⚫︎以降の出力: "${finalCleanLine}"`);
                        // ⚫︎以降はほぼすべて取得
                        if (!finalCleanLine.match(/^[·\s]*$/) && // 中点やスペースだけの行以外
                            finalCleanLine.trim() !== '') { // 空でない行
                            filteredLines.push(cleanLine);
                            lastWasCommand = false;
                            console.log(`[DEBUG] ⚫︎以降の出力を追加: "${cleanLine}"`);
                        }
                    }
                } else {
                    // 通常のフィルタリング（⚫︎以外）
                    if (finalCleanLine && 
                        finalCleanLine.length > 1 &&
                        !finalCleanLine.match(/^[·\s]*$/) && // 中点やスペースだけの行
                        !finalCleanLine.match(/^\(B$/) && // エスケープシーケンスの残骸
                        !finalCleanLine.match(/^[▸▹▶▷►‣•‧⁃]\s*$/) && // 単独の矢印や点
                        !finalCleanLine.match(/^\s*[>]\s*[^\s]+\s*$/) && // "> コマンド" の形式（重複表示）
                        !finalCleanLine.match(/limit\s*·/) && // usage limit 関連
                        !finalCleanLine.match(/^\s*model\s*$/) && // 単独のmodel
                        !finalCleanLine.match(/^(short|shor|sho|rtcuts|hortcuts|shortcu|sh|\?\s*fo)$/i) && // 断片文字列
                        (!finalCleanLine.match(/^[a-zA-Z]{1,8}$/) || finalCleanLine.match(/[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]/)) && // 8文字以下の意味不明な英語断片（ただし日本語は保持）
                        !finalCleanLine.match(/^\d+m$/) && // カラーコードの残骸（220m等）
                        finalCleanLine.length > 3) { // 3文字以下は基本的に無視
                        
                        filteredLines.push(cleanLine);
                        lastWasCommand = false;
                    }
                }
            }
            
            // 先頭と末尾の空白を削除
            let result = filteredLines.join('\n').trim();
            
            // 何も残らない場合は空文字を返す
            if (!result) return '';
            
            // 最後に改行を追加
            result += '\n';
            
            console.log('[DEBUG] Final filtered result:', result.substring(0, 100));
            
            return result;
        }

        /**
         * 要素情報を含むコマンドを構築
         */
        buildEnhancedCommand(userCommand) {
            if (!this.currentElementAnalysis) {
                return userCommand;
            }

            const analysis = this.currentElementAnalysis;
            const elementContext = `

[現在編集中の要素情報]
- 要素タイプ: ${analysis.element ? analysis.element.tagName : 'unknown'}
- セレクタ: ${analysis.selector || 'unknown'}
- 現在のテキスト: "${analysis.content || ''}"
- 編集可能なプロパティ:
${analysis.editable ? analysis.editable.map(item => `  - ${item.property}: ${item.value || 'none'}`).join('\n') : '  なし'}

上記の要素に対して、以下のコマンドを実行してください：
${userCommand}`;

            return userCommand + elementContext;
        }

        /**
         * 現在の要素情報を更新表示
         */
        updateElementInfo(container) {
            if (!container) return;

            if (!this.currentElementAnalysis) {
                container.innerHTML = '<div style="color: #666;">要素が選択されていません</div>';
                return;
            }

            const analysis = this.currentElementAnalysis;
            container.innerHTML = `
                <div style="font-weight: bold; margin-bottom: 5px;">編集中の要素:</div>
                <div style="color: #333;">
                    <span style="color: #2196F3;">${analysis.element ? analysis.element.tagName : 'unknown'}</span>
                    ${analysis.selector ? `<span style="color: #666;">${analysis.selector}</span>` : ''}
                </div>
                ${analysis.content ? `<div style="color: #666; margin-top: 5px;">テキスト: "${analysis.content.substring(0, 50)}${analysis.content.length > 50 ? '...' : ''}"</div>` : ''}
            `;
        }




        /**
         * ステータスを更新
         */
        updateStatus(message, type = 'info') {
            const statusDiv = document.getElementById('ai-connection-status');
            if (!statusDiv) return;

            statusDiv.textContent = message;
            
            const colors = {
                connected: '#64748b',
                connecting: '#FF9800',
                disconnected: '#666',
                error: '#F44336',
                warning: '#FF9800',
                info: '#666'
            };

            statusDiv.style.color = colors[type] || colors.info;
        }

        /**
         * 要素解析データを設定
         */
        setElementAnalysis(analysis) {
            this.currentElementAnalysis = analysis;
            const elementInfoArea = document.getElementById('element-info-area');
            if (elementInfoArea) {
                this.updateElementInfo(elementInfoArea);
            }
        }
    }

    // グローバルに公開
    window.AIEditInterface = AIEditInterface;
})();