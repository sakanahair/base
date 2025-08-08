(function() {
    'use strict';

    class UniversalEditor {
        constructor() {
            this.isActive = false;
            this.currentSection = null;
            this.editorPanel = null;
            this.panelVisible = false;
            this.sectionOverlay = null;
            
            this.init();
        }

        init() {
            this.setupEventListeners();
        }


        /**
         * イベントリスナーの設定
         */
        setupEventListeners() {
            // FloatingControlsからのカスタムイベントをリッスン（SectionClickEditorと協調）
            document.addEventListener('sectionSelected', (event) => {
                console.log('🎯 UniversalEditor - sectionSelectedイベント受信:', event.detail);
                
                if (event.detail && event.detail.section) {
                    // SectionClickEditorを優先し、UniversalEditorは補助的に動作
                    setTimeout(() => {
                        console.log('🎯 UniversalEditor - openEditor実行開始');
                        this.openEditor(event.detail.section);
                    }, 200);
                }
            });

            // キーボードショートカットは削除（編集終了ボタンで制御）
        }

        /**
         * エディターを開く
         */
        openEditor(section) {
            console.log('UniversalEditor.openEditor 呼び出し:', section);
            console.log('セクション要素:', section);
            if (this.isActive) {
                console.log('既に編集モードです - 現在のエディターを閉じます');
                this.closeEditor();
            }

            this.currentSection = section;
            this.isActive = true;
            this.panelVisible = false; // パネルの表示状態を追跡
            
            console.log('編集モード開始 - isActive:', this.isActive);

            // エディターパネルを作成（非表示状態で）
            console.log('エディターパネルを作成します');
            this.createEditorPanel();
            console.log('エディターパネル作成完了 - editorPanel:', !!this.editorPanel);

            // 直接編集モードに入る（パネルは表示しない）
            console.log('オーバーレイを追加します');
            this.addSectionOverlay();
            console.log('編集モード準備完了');
        }

        /**
         * エディターパネルを作成
         */
        createEditorPanel() {
            // 既存のパネルがあれば削除
            if (this.editorPanel) {
                this.editorPanel.remove();
            }

            // セクション名を取得
            const sectionName = this.currentSection.id || this.currentSection.className || 'セクション';

            // パネルコンテナ
            this.editorPanel = document.createElement('div');
            this.editorPanel.className = 'universal-editor-panel';
            this.editorPanel.innerHTML = `
                <div class="editor-container">
                    <div class="editor-inner">
                        <div class="editor-header">
                            <h2 class="editor-title">要素編集コントロール</h2>
                            <div class="section-info">
                                <span class="section-name">${sectionName}</span>
                                <button class="close-btn">✕</button>
                            </div>
                        </div>
                        
                        <div class="editor-content">
                            <div class="control-info">
                                <p>セクション内の要素をクリックして直接編集できます。</p>
                            </div>
                            
                            <div class="edit-actions">
                                <button class="element-save-btn">
                                    編集内容を保存
                                </button>
                                
                                <button class="element-save-default-btn">
                                    デフォルトとして保存
                                </button>
                                
                                <button class="element-reset-default-btn">
                                    デフォルトに戻す
                                </button>
                                
                                <button class="element-reset-colors-btn">
                                    色設定をリセット
                                </button>
                            </div>
                            
                            <div class="edit-status">
                                <span class="status-text">編集待機中...</span>
                            </div>
                        </div>
                    </div>
                </div>
            `;

            // イベントハンドラーを設定
            this.setupPanelEventHandlers();

            // DOMに追加
            document.body.appendChild(this.editorPanel);

            // スクロール位置を調整
            this.adjustScrollPosition();
        }

        /**
         * パネルのイベントハンドラーを設定
         */
        setupPanelEventHandlers() {
            // 閉じるボタン
            const closeBtn = this.editorPanel.querySelector('.close-btn');
            if (closeBtn) {
                closeBtn.addEventListener('click', () => {
                    this.closeEditor();
                });
            }

            // ElementEditManagerが存在するか確認
            if (!window.elementEditManager) {
                console.error('ElementEditManagerが見つかりません');
                return;
            }

            const controls = window.elementEditManager.getControlButtons();

            // 保存ボタン
            const saveBtn = this.editorPanel.querySelector('.element-save-btn');
            if (saveBtn) {
                saveBtn.addEventListener('click', () => {
                    controls.save();
                });
            }

            // デフォルト保存ボタン
            const saveDefaultBtn = this.editorPanel.querySelector('.element-save-default-btn');
            if (saveDefaultBtn) {
                saveDefaultBtn.addEventListener('click', () => {
                    controls.saveAsDefault();
                });
            }

            // デフォルトに戻すボタン
            const resetDefaultBtn = this.editorPanel.querySelector('.element-reset-default-btn');
            if (resetDefaultBtn) {
                resetDefaultBtn.addEventListener('click', () => {
                    controls.resetToDefault();
                });
            }

            // 色設定リセットボタン
            const resetColorsBtn = this.editorPanel.querySelector('.element-reset-colors-btn');
            if (resetColorsBtn) {
                resetColorsBtn.addEventListener('click', () => {
                    controls.resetColors();
                });
            }
        }


        /**
         * エディターを閉じる
         */
        closeEditor() {
            if (!this.isActive || !this.editorPanel) return;

            // オーバーレイを削除
            this.removeSectionOverlay();

            // アニメーション
            this.editorPanel.classList.remove('active');
            
            // アニメーション後に削除
            setTimeout(() => {
                if (this.editorPanel) {
                    this.editorPanel.remove();
                    this.editorPanel = null;
                }
                
                this.isActive = false;
                this.currentSection = null;
                this.panelVisible = false;
            }, 300);
        }

        /**
         * 編集終了ボタンから呼び出される保存メニュー表示
         */
        showSaveMenu() {
            console.log('編集終了 - 保存メニューを表示します');
            console.log('isActive:', this.isActive);
            console.log('editorPanel:', !!this.editorPanel);
            console.log('currentSection:', !!this.currentSection);
            
            if (!this.editorPanel) {
                console.log('エディターパネルが存在しません');
                return;
            }

            // 編集モードを終了してメニューを表示
            console.log('保存メニューを表示します - 現在のクラス:', this.editorPanel.className);
            this.editorPanel.classList.add('active');
            this.panelVisible = true;
            console.log('メニュー表示後のクラス:', this.editorPanel.className);
            console.log('パネルの表示状態:', window.getComputedStyle(this.editorPanel).opacity);
            
            // オーバーレイも表示（編集コントロールと保存メニューを同時表示）
            if (!this.sectionOverlay) {
                console.log('オーバーレイを再作成します');
                this.addSectionOverlay();
            }
        }

        /**
         * セクション以外をオーバーレイ
         */
        addSectionOverlay() {
            // 既存のオーバーレイを削除
            this.removeSectionOverlay();

            // ページ全体にオーバーレイを追加
            const overlay = document.createElement('div');
            overlay.className = 'section-edit-overlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.3);
                z-index: 99998;
                pointer-events: all;
                transition: opacity 0.3s ease;
            `;
            
            document.body.appendChild(overlay);
            this.sectionOverlay = overlay;

            // 選択されたセクションを強調
            if (this.currentSection) {
                this.currentSection.style.position = 'relative';
                this.currentSection.style.zIndex = '100001';
                this.currentSection.style.pointerEvents = 'all';
            }

            // アニメーション
            requestAnimationFrame(() => {
                overlay.style.opacity = '1';
            });
        }

        /**
         * セクションオーバーレイを削除
         */
        removeSectionOverlay() {
            if (this.sectionOverlay) {
                this.sectionOverlay.remove();
                this.sectionOverlay = null;
            }

            // セクションのスタイルをリセット
            if (this.currentSection) {
                this.currentSection.style.position = '';
                this.currentSection.style.zIndex = '';
                this.currentSection.style.pointerEvents = '';
            }
        }


        /**
         * スクロール位置を調整
         */
        adjustScrollPosition() {
            if (!this.currentSection) return;

            const sectionRect = this.currentSection.getBoundingClientRect();
            const windowHeight = window.innerHeight;
            const sectionTop = sectionRect.top + window.scrollY;
            const sectionHeight = sectionRect.height;

            // セクションが画面内に収まるように調整
            if (sectionHeight < windowHeight) {
                const targetScroll = sectionTop - (windowHeight - sectionHeight) / 2;
                window.scrollTo({
                    top: targetScroll,
                    behavior: 'smooth'
                });
            }
        }

        /**
         * 通知を表示
         */
        showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.className = `editor-notification ${type}`;
            notification.textContent = message;

            // アイコンを追加
            const icon = document.createElement('span');
            icon.className = 'notification-icon';
            if (type === 'success') {
                icon.textContent = '✓';
            } else if (type === 'error') {
                icon.textContent = '⚠';
            } else {
                icon.textContent = 'ℹ';
            }
            notification.prepend(icon);

            document.body.appendChild(notification);

            // アニメーション
            requestAnimationFrame(() => {
                notification.classList.add('show');
            });

            // 自動的に削除
            setTimeout(() => {
                notification.classList.remove('show');
                setTimeout(() => {
                    notification.remove();
                }, 300);
            }, 3000);
        }

        /**
         * セクション選択を受け取るパブリックメソッド
         */
        editSection(section) {
            this.openEditor(section);
        }

        /**
         * テスト用メソッド - ブラウザコンソールから呼び出し可能
         */
        testSaveMenu() {
            console.log('=== 保存メニューテスト ===');
            console.log('isActive:', this.isActive);
            console.log('editorPanel:', !!this.editorPanel);
            console.log('panelVisible:', this.panelVisible);
            console.log('currentSection:', this.currentSection);
            
            if (this.isActive && this.editorPanel) {
                console.log('手動でshowSaveMenu()を実行します');
                this.showSaveMenu();
            } else {
                console.log('編集モードがアクティブではありません');
            }
        }

        /**
         * CSS表示テスト用メソッド
         */
        testPanelDisplay() {
            console.log('=== パネル表示テスト ===');
            if (this.editorPanel) {
                console.log('パネルに手動でactiveクラスを追加します');
                this.editorPanel.classList.add('active');
                console.log('クラス追加後:', this.editorPanel.className);
                console.log('計算されたスタイル:', window.getComputedStyle(this.editorPanel));
            } else {
                console.log('エディターパネルが存在しません');
            }
        }
    }

    // グローバルに公開
    window.UniversalEditor = UniversalEditor;

    // 自動初期化
    document.addEventListener('DOMContentLoaded', () => {
        console.log('UniversalEditor DOMContentLoaded - 初期化開始');
        window.universalEditor = new UniversalEditor();
        console.log('UniversalEditor 初期化完了:', window.universalEditor);
    });

})();