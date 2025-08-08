(function() {
    'use strict';

    class BuildManager {
        constructor() {
            this.init();
        }

        init() {
            console.log('BuildManager初期化開始');
            this.isBuilding = false;
        }

        /**
         * ビルドプロセスを開始
         */
        async startBuild() {
            if (this.isBuilding) {
                this.showNotification('既にビルド中です', 'warning');
                return;
            }

            console.log('ビルドプロセス開始');
            this.isBuilding = true;
            
            const startTime = Date.now();
            
            try {
                // ビルド開始通知
                this.showBuildProgress('ビルドを開始しています...', 0);
                
                // 現在の設定を取得
                const currentSettings = await this.getCurrentSettings();
                
                // サーバーにビルドリクエストを送信
                const response = await fetch('api/build', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        projectPath: this.getCurrentProjectPath(),
                        timestamp: new Date().toISOString(),
                        savedStyles: currentSettings.styles,
                        elementEdits: currentSettings.edits,
                        customCSS: currentSettings.customCSS
                    })
                });

                if (!response.ok) {
                    throw new Error(`ビルドリクエストが失敗しました: ${response.status}`);
                }

                // プログレス更新
                this.showBuildProgress('ファイルを処理中...', 30);
                
                const result = await response.json();
                
                // プログレス更新
                this.showBuildProgress('ファイルをコピー中...', 60);
                
                // 少し待機（UX向上のため）
                await this.sleep(1000);
                
                // プログレス完了
                this.showBuildProgress('ビルド完了', 100);
                
                const buildTime = ((Date.now() - startTime) / 1000).toFixed(1);
                
                // 成功通知
                this.showNotification(
                    `ビルドが完了しました！(${buildTime}秒)\n出力先: dist/フォルダ`,
                    'success',
                    5000
                );

                console.log('ビルド完了:', result);
                
                // プログレスバーを少し待ってから非表示
                setTimeout(() => {
                    this.hideBuildProgress();
                    // ビルド完了後にFloatingControlsに通知
                    if (window.floatingControls) {
                        window.floatingControls.onBuildComplete();
                    }
                }, 2000);

            } catch (error) {
                console.error('ビルドエラー:', error);
                this.showBuildProgress('ビルドエラー', 0, true);
                
                this.showNotification(
                    `ビルドに失敗しました: ${error.message}`,
                    'error',
                    8000
                );

                setTimeout(() => {
                    this.hideBuildProgress();
                }, 3000);

            } finally {
                this.isBuilding = false;
            }
        }

        /**
         * 現在のプロジェクトパスを取得
         */
        getCurrentProjectPath() {
            const currentPath = window.location.pathname;
            return currentPath.replace(/^\/site\//, '').replace(/\/$/, '') || 'next/project';
        }

        /**
         * 現在の設定を取得
         */
        async getCurrentSettings() {
            const settings = {
                styles: {},
                edits: {},
                customCSS: []
            };

            try {
                // サーバーから設定を取得（ElementEditManagerと同じロジック）
                await this.getServerSettings(settings);
                // 現在のCSS変数をすべて取得
                const computedStyle = getComputedStyle(document.documentElement);
                const cssVariables = {};
                
                // 主要なCSS変数を取得
                const cssVarNames = [
                    '--accent-color',
                    '--font-family',
                    '--primary-color',
                    '--secondary-color',
                    '--text-color',
                    '--bg-color',
                    '--card-bg',
                    '--heading-font-size',
                    '--body-font-size',
                    '--hero-bg-image',
                    '--section-bg'
                ];
                
                cssVarNames.forEach(varName => {
                    const value = computedStyle.getPropertyValue(varName).trim();
                    if (value) {
                        cssVariables[varName] = value;
                    }
                });

                // テーマ設定
                const savedTheme = localStorage.getItem('site_theme_settings');
                if (savedTheme) {
                    const themeData = JSON.parse(savedTheme);
                    settings.styles = {
                        ...cssVariables,
                        accentColor: themeData.accentColor || cssVariables['--accent-color'],
                        fontFamily: themeData.fontFamily || cssVariables['--font-family'],
                        darkMode: document.body.classList.contains('dark-mode'),
                        cssVariables: cssVariables
                    };
                } else {
                    settings.styles = {
                        ...cssVariables,
                        accentColor: cssVariables['--accent-color'],
                        fontFamily: cssVariables['--font-family'],
                        darkMode: document.body.classList.contains('dark-mode'),
                        cssVariables: cssVariables
                    };
                }

                // 選択されたフォント
                const selectedFont = localStorage.getItem('selected-font');
                if (selectedFont) {
                    const fontData = JSON.parse(selectedFont);
                    settings.styles.fontFamily = fontData.family || settings.styles.fontFamily;
                }

                // 要素の編集内容（詳細版）
                const elementEdits = localStorage.getItem('element_edits');
                if (elementEdits) {
                    const editsData = JSON.parse(elementEdits);
                    settings.edits = editsData;
                    
                    // 編集された要素から追加のスタイル情報を抽出
                    Object.entries(editsData).forEach(([selector, data]) => {
                        if (data.styles) {
                            // 背景画像やフォントサイズなどの特別な処理
                            if (data.styles.backgroundImage) {
                                settings.customCSS.push(`${selector} { background-image: ${data.styles.backgroundImage} !important; }`);
                            }
                            if (data.styles.fontSize) {
                                settings.customCSS.push(`${selector} { font-size: ${data.styles.fontSize} !important; }`);
                            }
                            if (data.styles.background) {
                                settings.customCSS.push(`${selector} { background: ${data.styles.background} !important; }`);
                            }
                        }
                    });
                }
                
                // 自動保存データも確認
                const autoSaveEdits = localStorage.getItem('element_edits_autosave');
                if (autoSaveEdits && !elementEdits) {
                    settings.edits = JSON.parse(autoSaveEdits);
                }

            } catch (error) {
                console.error('設定の取得エラー:', error);
            }

            console.log('ビルド時の設定（詳細版）:', settings);
            return settings;
        }

        /**
         * サーバーから設定を取得
         */
        async getServerSettings(settings) {
            try {
                const projectPath = this.getCurrentProjectPath();
                
                const response = await fetch(`/api/load-settings?path=${encodeURIComponent(projectPath)}`, {
                    method: 'GET'
                });
                
                if (response.ok) {
                    const result = await response.json();
                    console.log('サーバーから取得した設定:', result);
                    
                    if (result.data && result.data.elementEdits) {
                        // 新しい構造（フラット）と古い構造（ネスト）の両方に対応
                        if (result.data.elementEdits.manual || result.data.elementEdits.autoSave) {
                            // 古い構造
                            settings.edits = result.data.elementEdits.manual || result.data.elementEdits.autoSave || {};
                        } else {
                            // 新しい構造（フラット）
                            settings.edits = result.data.elementEdits;
                        }
                        
                        console.log('ビルド用編集データ:', Object.keys(settings.edits).length, '個の要素');
                        
                        // 編集データからCSSを生成
                        Object.entries(settings.edits).forEach(([selector, data]) => {
                            if (data.styles) {
                                // 背景画像やその他のスタイルを処理
                                Object.entries(data.styles).forEach(([property, value]) => {
                                    if (property === 'backgroundImage') {
                                        settings.customCSS.push(`${selector} { background-image: ${value} !important; }`);
                                    } else if (property === 'fontSize') {
                                        settings.customCSS.push(`${selector} { font-size: ${value} !important; }`);
                                    } else if (property === 'backgroundColor') {
                                        settings.customCSS.push(`${selector} { background-color: ${value} !important; }`);
                                    } else if (property === 'color') {
                                        settings.customCSS.push(`${selector} { color: ${value} !important; }`);
                                    }
                                });
                            }
                        });
                    }
                } else {
                    console.log('サーバー設定が見つかりません、localStorageにフォールバック');
                    this.getLocalStorageSettings(settings);
                }
            } catch (error) {
                console.error('サーバー設定の取得エラー:', error);
                this.getLocalStorageSettings(settings);
            }
        }

        /**
         * localStorageから設定を取得（フォールバック）
         */
        getLocalStorageSettings(settings) {
            // 要素の編集内容（詳細版）
            const elementEdits = localStorage.getItem('element_edits');
            if (elementEdits) {
                const editsData = JSON.parse(elementEdits);
                settings.edits = editsData;
                
                // 編集された要素から追加のスタイル情報を抽出
                Object.entries(editsData).forEach(([selector, data]) => {
                    if (data.styles) {
                        // 背景画像やフォントサイズなどの特別な処理
                        if (data.styles.backgroundImage) {
                            settings.customCSS.push(`${selector} { background-image: ${data.styles.backgroundImage} !important; }`);
                        }
                        if (data.styles.fontSize) {
                            settings.customCSS.push(`${selector} { font-size: ${data.styles.fontSize} !important; }`);
                        }
                        if (data.styles.backgroundColor) {
                            settings.customCSS.push(`${selector} { background-color: ${data.styles.backgroundColor} !important; }`);
                        }
                    }
                });
            }
            
            // 自動保存データも確認
            const autoSaveEdits = localStorage.getItem('element_edits_autosave');
            if (autoSaveEdits && !elementEdits) {
                settings.edits = JSON.parse(autoSaveEdits);
            }
        }

        /**
         * ビルドプログレスバーを表示
         */
        showBuildProgress(message, progress, isError = false) {
            // 既存のプログレスバーを削除
            this.hideBuildProgress();

            const progressContainer = document.createElement('div');
            progressContainer.id = 'build-progress-container';
            progressContainer.style.cssText = `
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: white;
                padding: 24px;
                border-radius: 12px;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
                z-index: 100030;
                min-width: 320px;
                animation: buildProgressSlideIn 0.3s ease-out;
            `;

            const title = document.createElement('h3');
            title.textContent = isError ? 'ビルドエラー' : 'ビルド中';
            title.style.cssText = `
                margin: 0 0 16px 0;
                font-size: 18px;
                color: ${isError ? '#f44336' : '#333'};
                text-align: center;
            `;

            const messageEl = document.createElement('p');
            messageEl.textContent = message;
            messageEl.style.cssText = `
                margin: 0 0 16px 0;
                font-size: 14px;
                color: #666;
                text-align: center;
            `;

            const progressBarContainer = document.createElement('div');
            progressBarContainer.style.cssText = `
                width: 100%;
                height: 8px;
                background: #f0f0f0;
                border-radius: 4px;
                overflow: hidden;
            `;

            const progressBar = document.createElement('div');
            progressBar.style.cssText = `
                height: 100%;
                background: ${isError ? '#f44336' : 'linear-gradient(90deg, #64748b, #64748b)'};
                width: ${progress}%;
                transition: width 0.3s ease;
                border-radius: 4px;
            `;

            const percentText = document.createElement('div');
            percentText.textContent = `${progress}%`;
            percentText.style.cssText = `
                margin-top: 8px;
                text-align: center;
                font-size: 12px;
                color: #666;
            `;

            progressBarContainer.appendChild(progressBar);
            progressContainer.appendChild(title);
            progressContainer.appendChild(messageEl);
            progressContainer.appendChild(progressBarContainer);
            progressContainer.appendChild(percentText);

            // オーバーレイ
            const overlay = document.createElement('div');
            overlay.id = 'build-progress-overlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.5);
                z-index: 100029;
                animation: fadeIn 0.3s ease;
            `;

            overlay.appendChild(progressContainer);
            document.body.appendChild(overlay);
        }

        /**
         * ビルドプログレスバーを非表示
         */
        hideBuildProgress() {
            const overlay = document.getElementById('build-progress-overlay');
            if (overlay) {
                overlay.style.animation = 'fadeOut 0.3s ease';
                overlay.style.animationFillMode = 'forwards';
                setTimeout(() => {
                    // より確実に削除
                    if (overlay && overlay.parentNode) {
                        overlay.parentNode.removeChild(overlay);
                    } else if (overlay) {
                        // parentNodeがない場合は直接削除
                        overlay.remove();
                    }
                    // 念のため再度確認して削除
                    const remainingOverlay = document.getElementById('build-progress-overlay');
                    if (remainingOverlay) {
                        remainingOverlay.remove();
                    }
                }, 300);
            }
        }

        /**
         * 通知を表示
         */
        showNotification(message, type = 'info', duration = 4000) {
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                padding: 16px 24px;
                background: ${this.getNotificationColor(type)};
                color: white;
                border-radius: 8px;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
                z-index: 100031;
                animation: slideInNotification 0.3s ease;
                font-size: 14px;
                max-width: 400px;
                white-space: pre-line;
            `;

            // アイコンを追加
            const icon = this.getNotificationIcon(type);
            notification.innerHTML = `${icon} ${message}`;

            document.body.appendChild(notification);

            setTimeout(() => {
                notification.style.animation = 'slideOutNotification 0.3s ease';
                setTimeout(() => {
                    if (notification.parentNode) {
                        notification.parentNode.removeChild(notification);
                    }
                }, 300);
            }, duration);
        }

        /**
         * 通知の色を取得
         */
        getNotificationColor(type) {
            const colors = {
                success: '#64748b',
                error: '#f44336',
                warning: '#FF9800',
                info: '#2196F3'
            };
            return colors[type] || colors.info;
        }

        /**
         * 通知のアイコンを取得
         */
        getNotificationIcon(type) {
            const icons = {
                success: '✅',
                error: '❌',
                warning: '⚠️',
                info: 'ℹ️'
            };
            return icons[type] || icons.info;
        }

        /**
         * スリープ関数
         */
        sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }
    }

    // スタイルを追加
    const style = document.createElement('style');
    style.textContent = `
        @keyframes buildProgressSlideIn {
            from { 
                transform: translate(-50%, -50%) scale(0.8); 
                opacity: 0; 
            }
            to { 
                transform: translate(-50%, -50%) scale(1); 
                opacity: 1; 
            }
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes fadeOut {
            from { opacity: 1; }
            to { opacity: 0; }
        }
        
        @keyframes slideInNotification {
            from { transform: translateX(100px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }
        
        @keyframes slideOutNotification {
            from { transform: translateX(0); opacity: 1; }
            to { transform: translateX(100px); opacity: 0; }
        }
    `;
    document.head.appendChild(style);

    // グローバルに公開
    window.BuildManager = BuildManager;

    // 自動初期化
    document.addEventListener('DOMContentLoaded', () => {
        window.buildManager = new BuildManager();
    });

    console.log('BuildManager.js loaded');
})();