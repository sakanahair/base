(function() {
    'use strict';

    class ChatInterface {
        constructor() {
            this.isOpen = false;
            this.messages = [];
            this.mockResponses = [
                'こんにちは！No.0 PILATESへようこそ。どのようなご用件でしょうか？',
                'ピラティスは心と身体のバランスを整える素晴らしいエクササイズです。',
                '初心者の方でも安心して始められるプログラムをご用意しています。',
                '体験レッスンのご予約も承っております。ご希望の日時はございますか？',
                'お身体のお悩みに合わせたプログラムをご提案できます。',
                'ご質問があれば、お気軽にお聞きください！'
            ];
            this.init();
        }

        init() {
            this.createChatWindow();
            this.setupEventListeners();
        }

        createChatWindow() {
            // チャットウィンドウコンテナ
            const container = document.createElement('div');
            container.id = 'chat-interface';
            container.className = 'chat-interface';
            container.style.cssText = `
                position: fixed;
                bottom: 90px;
                left: 20px;
                width: 360px;
                height: 500px;
                max-width: calc(100vw - 40px);
                max-height: calc(100vh - 120px);
                background: var(--card-bg, rgba(255, 255, 255, 0.98));
                backdrop-filter: blur(20px);
                border-radius: 20px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
                border: 1px solid rgba(255, 255, 255, 0.3);
                display: none;
                flex-direction: column;
                overflow: hidden;
                z-index: 100030;
                transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                transform-origin: bottom left;
            `;

            // ヘッダー
            const header = document.createElement('div');
            header.className = 'chat-header';
            header.style.cssText = `
                padding: 16px 20px;
                background: linear-gradient(135deg, var(--primary-color, #6c757d), var(--accent-color, #64748b));
                color: white;
                display: flex;
                align-items: center;
                justify-content: space-between;
                border-radius: 20px 20px 0 0;
            `;

            const headerInfo = document.createElement('div');
            headerInfo.style.cssText = `
                display: flex;
                align-items: center;
                gap: 12px;
            `;

            const avatar = document.createElement('div');
            avatar.style.cssText = `
                width: 40px;
                height: 40px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 20px;
            `;
            avatar.textContent = '🧘';

            const headerText = document.createElement('div');
            headerText.innerHTML = `
                <div style="font-weight: 600; font-size: 16px;">No.0 PILATES</div>
                <div style="font-size: 12px; opacity: 0.9;">オンライン</div>
            `;

            headerInfo.appendChild(avatar);
            headerInfo.appendChild(headerText);

            const closeBtn = document.createElement('button');
            closeBtn.style.cssText = `
                background: none;
                border: none;
                color: white;
                font-size: 24px;
                cursor: pointer;
                padding: 0;
                width: 32px;
                height: 32px;
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 50%;
                transition: background 0.2s;
            `;
            closeBtn.innerHTML = '×';
            closeBtn.onclick = () => this.close();

            header.appendChild(headerInfo);
            header.appendChild(closeBtn);

            // メッセージエリア
            const messagesArea = document.createElement('div');
            messagesArea.id = 'chat-messages';
            messagesArea.className = 'chat-messages';
            messagesArea.style.cssText = `
                flex: 1;
                overflow-y: auto;
                padding: 20px;
                display: flex;
                flex-direction: column;
                gap: 12px;
                background: var(--card-bg, #fafafa);
            `;

            // 入力エリア
            const inputArea = document.createElement('div');
            inputArea.className = 'chat-input-area';
            inputArea.style.cssText = `
                padding: 16px;
                border-top: 1px solid var(--border-color, #e0e0e0);
                display: flex;
                gap: 12px;
                align-items: flex-end;
                background: var(--card-bg, white);
            `;

            const inputWrapper = document.createElement('div');
            inputWrapper.style.cssText = `
                flex: 1;
                position: relative;
            `;

            const input = document.createElement('textarea');
            input.id = 'chat-input';
            input.placeholder = 'メッセージを入力...';
            input.style.cssText = `
                width: 100%;
                border: 1px solid var(--border-color, #e0e0e0);
                border-radius: 20px;
                padding: 10px 16px;
                resize: none;
                outline: none;
                font-family: inherit;
                font-size: 14px;
                line-height: 1.4;
                min-height: 40px;
                max-height: 120px;
                background: var(--input-bg, white);
                color: var(--text-color, #333);
                transition: border-color 0.2s;
            `;

            const sendBtn = document.createElement('button');
            sendBtn.id = 'chat-send-btn';
            sendBtn.style.cssText = `
                width: 40px;
                height: 40px;
                border-radius: 50%;
                background: linear-gradient(135deg, var(--primary-color, #6c757d), var(--accent-color, #64748b));
                border: none;
                color: white;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                transition: all 0.2s;
                flex-shrink: 0;
            `;
            sendBtn.innerHTML = `
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                    <path d="M2 21L23 12L2 3V10L17 12L2 14V21Z" fill="white"/>
                </svg>
            `;

            inputWrapper.appendChild(input);
            inputArea.appendChild(inputWrapper);
            inputArea.appendChild(sendBtn);

            // 組み立て
            container.appendChild(header);
            container.appendChild(messagesArea);
            container.appendChild(inputArea);

            document.body.appendChild(container);

            // スタイルを追加
            this.addStyles();

            // 初期メッセージ
            this.addMessage('assistant', 'こんにちは！No.0 PILATESへようこそ。どのようなご用件でしょうか？');
        }

        addStyles() {
            const style = document.createElement('style');
            style.textContent = `
                .chat-interface {
                    font-family: var(--font-family, 'Helvetica Neue', Arial, sans-serif);
                }

                .chat-interface.open {
                    display: flex !important;
                    animation: chatSlideIn 0.3s ease-out;
                }

                @keyframes chatSlideIn {
                    from {
                        transform: scale(0.8) translateY(20px);
                        opacity: 0;
                    }
                    to {
                        transform: scale(1) translateY(0);
                        opacity: 1;
                    }
                }

                .chat-messages::-webkit-scrollbar {
                    width: 6px;
                }

                .chat-messages::-webkit-scrollbar-track {
                    background: transparent;
                }

                .chat-messages::-webkit-scrollbar-thumb {
                    background: rgba(0, 0, 0, 0.2);
                    border-radius: 3px;
                }

                .chat-message {
                    display: flex;
                    align-items: flex-start;
                    gap: 8px;
                    animation: messageSlideIn 0.3s ease-out;
                }

                @keyframes messageSlideIn {
                    from {
                        transform: translateY(10px);
                        opacity: 0;
                    }
                    to {
                        transform: translateY(0);
                        opacity: 1;
                    }
                }

                .chat-message.user {
                    flex-direction: row-reverse;
                }

                .chat-message-avatar {
                    width: 32px;
                    height: 32px;
                    border-radius: 50%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 16px;
                    flex-shrink: 0;
                }

                .chat-message.user .chat-message-avatar {
                    background: rgba(100, 116, 139, 0.1);
                }

                .chat-message.assistant .chat-message-avatar {
                    background: rgba(108, 117, 125, 0.1);
                }

                .chat-message-content {
                    max-width: 70%;
                    padding: 10px 16px;
                    border-radius: 18px;
                    font-size: 14px;
                    line-height: 1.4;
                    position: relative;
                }

                .chat-message.user .chat-message-content {
                    background: linear-gradient(135deg, var(--primary-color, #6c757d), var(--accent-color, #64748b));
                    color: white;
                    border-bottom-right-radius: 4px;
                }

                .chat-message.assistant .chat-message-content {
                    background: var(--message-bg, #f0f0f0);
                    color: var(--text-color, #333);
                    border-bottom-left-radius: 4px;
                }

                .chat-typing {
                    display: inline-flex;
                    align-items: center;
                    gap: 4px;
                    padding: 8px 16px;
                }

                .chat-typing span {
                    width: 8px;
                    height: 8px;
                    border-radius: 50%;
                    background: #999;
                    animation: typing 1.4s infinite;
                }

                .chat-typing span:nth-child(2) {
                    animation-delay: 0.2s;
                }

                .chat-typing span:nth-child(3) {
                    animation-delay: 0.4s;
                }

                @keyframes typing {
                    0%, 60%, 100% {
                        transform: translateY(0);
                        opacity: 0.4;
                    }
                    30% {
                        transform: translateY(-10px);
                        opacity: 1;
                    }
                }

                #chat-input:focus {
                    border-color: #00BCD4;
                }

                #chat-send-btn:hover {
                    transform: scale(1.1);
                }

                #chat-send-btn:active {
                    transform: scale(0.95);
                }

                /* ダークモード対応 */
                body.dark-mode .chat-interface {
                    background: rgba(30, 30, 30, 0.98);
                    border-color: rgba(255, 255, 255, 0.1);
                }

                body.dark-mode .chat-messages {
                    background: #1a1a1a;
                }

                body.dark-mode .chat-input-area {
                    background: #252525;
                    border-color: #444;
                }

                body.dark-mode #chat-input {
                    background: #2a2a2a;
                    border-color: #444;
                    color: #fff;
                }

                body.dark-mode .chat-message.assistant .chat-message-content {
                    background: #2a2a2a;
                    color: #fff;
                }

                /* モバイル対応 */
                @media (max-width: 768px) {
                    .chat-interface {
                        width: calc(100vw - 40px);
                        height: calc(100vh - 120px);
                        bottom: 80px;
                    }
                }
            `;
            document.head.appendChild(style);
        }

        setupEventListeners() {
            const input = document.getElementById('chat-input');
            const sendBtn = document.getElementById('chat-send-btn');

            // 送信ボタンクリック
            sendBtn.addEventListener('click', () => this.sendMessage());

            // Enterキーで送信（Shift+Enterは改行）
            input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.sendMessage();
                }
            });

            // テキストエリアの高さ自動調整
            input.addEventListener('input', () => {
                input.style.height = 'auto';
                input.style.height = Math.min(input.scrollHeight, 120) + 'px';
            });
        }

        open() {
            const container = document.getElementById('chat-interface');
            container.classList.add('open');
            this.isOpen = true;
            
            // 入力欄にフォーカス
            setTimeout(() => {
                document.getElementById('chat-input').focus();
            }, 300);
        }

        close() {
            const container = document.getElementById('chat-interface');
            container.classList.remove('open');
            this.isOpen = false;
        }

        toggle() {
            if (this.isOpen) {
                this.close();
            } else {
                this.open();
            }
        }

        sendMessage() {
            const input = document.getElementById('chat-input');
            const message = input.value.trim();

            if (!message) return;

            // ユーザーメッセージを追加
            this.addMessage('user', message);

            // 入力欄をクリア
            input.value = '';
            input.style.height = 'auto';

            // タイピング表示
            this.showTypingIndicator();

            // モック応答（実際はChatGPT APIを呼び出す）
            setTimeout(() => {
                this.hideTypingIndicator();
                const response = this.getMockResponse(message);
                this.addMessage('assistant', response);
            }, 1000 + Math.random() * 1000);
        }

        addMessage(role, content) {
            const messagesArea = document.getElementById('chat-messages');
            
            const messageEl = document.createElement('div');
            messageEl.className = `chat-message ${role}`;

            const avatar = document.createElement('div');
            avatar.className = 'chat-message-avatar';
            avatar.textContent = role === 'user' ? '👤' : '🧘';

            const contentEl = document.createElement('div');
            contentEl.className = 'chat-message-content';
            contentEl.textContent = content;

            messageEl.appendChild(avatar);
            messageEl.appendChild(contentEl);

            messagesArea.appendChild(messageEl);

            // 最新のメッセージまでスクロール
            messagesArea.scrollTop = messagesArea.scrollHeight;

            // メッセージを保存
            this.messages.push({ role, content });
        }

        showTypingIndicator() {
            const messagesArea = document.getElementById('chat-messages');
            
            const typingEl = document.createElement('div');
            typingEl.id = 'typing-indicator';
            typingEl.className = 'chat-message assistant';

            const avatar = document.createElement('div');
            avatar.className = 'chat-message-avatar';
            avatar.textContent = '🧘';

            const typing = document.createElement('div');
            typing.className = 'chat-typing';
            typing.innerHTML = '<span></span><span></span><span></span>';

            typingEl.appendChild(avatar);
            typingEl.appendChild(typing);

            messagesArea.appendChild(typingEl);
            messagesArea.scrollTop = messagesArea.scrollHeight;
        }

        hideTypingIndicator() {
            const typingEl = document.getElementById('typing-indicator');
            if (typingEl) {
                typingEl.remove();
            }
        }

        getMockResponse(message) {
            // キーワードに基づいた応答
            const lowerMessage = message.toLowerCase();
            
            if (lowerMessage.includes('料金') || lowerMessage.includes('価格')) {
                return '料金については、月4回コースが月額16,000円、月8回コースが月額28,000円となっております。体験レッスンは3,000円でご利用いただけます。';
            } else if (lowerMessage.includes('予約') || lowerMessage.includes('体験')) {
                return '体験レッスンのご予約承ります！ご希望の日時をお教えください。平日は10:00-21:00、土日祝は9:00-18:00で営業しております。';
            } else if (lowerMessage.includes('初心者') || lowerMessage.includes('はじめて')) {
                return '初心者の方も大歓迎です！経験豊富なインストラクターが、お一人おひとりのレベルに合わせて丁寧に指導いたします。';
            } else if (lowerMessage.includes('効果') || lowerMessage.includes('ダイエット')) {
                return 'ピラティスは体幹を鍛え、姿勢改善や柔軟性向上、インナーマッスルの強化に効果的です。継続することで基礎代謝も上がり、太りにくい体質作りにも役立ちます。';
            } else {
                // ランダムな応答
                return this.mockResponses[Math.floor(Math.random() * this.mockResponses.length)];
            }
        }

        // ChatGPT API連携用のメソッド（将来の実装用）
        async sendToChatGPT(message) {
            // TODO: ChatGPT APIの実装
            // const response = await fetch('/api/chat', {
            //     method: 'POST',
            //     headers: { 'Content-Type': 'application/json' },
            //     body: JSON.stringify({ 
            //         messages: this.messages,
            //         model: 'gpt-3.5-turbo'
            //     })
            // });
            // const data = await response.json();
            // return data.choices[0].message.content;
        }
    }

    // グローバルに公開
    window.ChatInterface = ChatInterface;

    // DOMContentLoaded時に初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            window.chatInterface = new ChatInterface();
        });
    } else {
        window.chatInterface = new ChatInterface();
    }

})();