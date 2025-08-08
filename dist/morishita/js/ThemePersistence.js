(function() {
    'use strict';

    class ThemePersistence {
        constructor() {
            this.settingsManager = null;
            this.autoSaveEnabled = true;
            this.autoSaveDelay = 1000; // 1秒後に自動保存
            this.saveTimeout = null;
            
            this.init();
        }

        init() {
            // SettingsManagerの初期化を待つ
            this.waitForSettingsManager().then(() => {
                this.setupAutoSave();
                this.setupEventListeners();
                
                // 初回読み込み時に設定を適用
                this.applyPersistedTheme();
            });
        }

        /**
         * SettingsManagerの初期化を待つ
         */
        waitForSettingsManager() {
            return new Promise((resolve) => {
                const checkManager = () => {
                    if (window.settingsManager) {
                        this.settingsManager = window.settingsManager;
                        resolve();
                    } else {
                        setTimeout(checkManager, 100);
                    }
                };
                checkManager();
            });
        }

        /**
         * 保存されたテーマを適用
         */
        applyPersistedTheme() {
            // settingsManagerが既に設定を適用しているので、追加の処理があればここに記述
            console.log('テーマ設定を適用しました');
        }

        /**
         * 自動保存のセットアップ
         */
        setupAutoSave() {
            // CSS変数の変更を監視
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    if (mutation.type === 'attributes' && mutation.attributeName === 'style') {
                        this.scheduleAutoSave();
                    }
                });
            });

            observer.observe(document.documentElement, {
                attributes: true,
                attributeFilter: ['style']
            });

            // body要素のクラス変更も監視（ダークモード）
            const bodyObserver = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
                        this.scheduleAutoSave();
                    }
                });
            });

            bodyObserver.observe(document.body, {
                attributes: true,
                attributeFilter: ['class']
            });
        }

        /**
         * イベントリスナーのセットアップ
         */
        setupEventListeners() {
            // カスタムイベントでテーマ変更を検知
            document.addEventListener('themeChanged', (event) => {
                this.handleThemeChange(event.detail);
            });

            document.addEventListener('colorChanged', (event) => {
                this.handleColorChange(event.detail);
            });

            document.addEventListener('fontChanged', (event) => {
                this.handleFontChange(event.detail);
            });

            // ページ離脱時に保存
            window.addEventListener('beforeunload', () => {
                if (this.saveTimeout) {
                    this.saveCurrentTheme();
                }
            });
        }

        /**
         * テーマ変更を処理
         */
        handleThemeChange(detail) {
            if (detail && detail.darkMode !== undefined) {
                this.settingsManager.updateSetting('theme.darkMode', detail.darkMode);
                this.scheduleAutoSave();
            }
        }

        /**
         * カラー変更を処理
         */
        handleColorChange(detail) {
            if (detail && detail.color) {
                if (detail.property === '--accent-color') {
                    this.settingsManager.updateSetting('theme.accentColor', detail.color);
                } else if (detail.property) {
                    const customColors = this.settingsManager.getSetting('theme.customColors') || {};
                    customColors[detail.property] = detail.color;
                    this.settingsManager.updateSetting('theme.customColors', customColors);
                }
                this.scheduleAutoSave();
            }
        }

        /**
         * フォント変更を処理
         */
        handleFontChange(detail) {
            if (detail && detail.fontFamily) {
                this.settingsManager.updateSetting('theme.fontFamily', detail.fontFamily);
                this.scheduleAutoSave();
            }
        }

        /**
         * 自動保存をスケジュール
         */
        scheduleAutoSave() {
            if (!this.autoSaveEnabled) return;

            // 既存のタイムアウトをクリア
            if (this.saveTimeout) {
                clearTimeout(this.saveTimeout);
            }

            // 新しいタイムアウトを設定
            this.saveTimeout = setTimeout(() => {
                this.saveCurrentTheme();
                this.saveTimeout = null;
            }, this.autoSaveDelay);
        }

        /**
         * 現在のテーマを保存
         */
        saveCurrentTheme() {
            // 現在のCSS変数を読み取って更新
            const computedStyle = getComputedStyle(document.documentElement);
            
            // アクセントカラー
            const accentColor = computedStyle.getPropertyValue('--accent-color').trim();
            if (accentColor) {
                this.settingsManager.updateSetting('theme.accentColor', accentColor);
            }

            // フォント
            const fontFamily = computedStyle.getPropertyValue('--font-family').trim();
            if (fontFamily) {
                this.settingsManager.updateSetting('theme.fontFamily', fontFamily);
            }

            // ダークモード
            const isDarkMode = document.body.classList.contains('dark-mode');
            this.settingsManager.updateSetting('theme.darkMode', isDarkMode);

            // 設定を保存
            this.settingsManager.saveSettings();
            console.log('テーマ設定を自動保存しました');
        }

        /**
         * 自動保存の有効/無効を切り替え
         */
        setAutoSaveEnabled(enabled) {
            this.autoSaveEnabled = enabled;
            if (!enabled && this.saveTimeout) {
                clearTimeout(this.saveTimeout);
                this.saveTimeout = null;
            }
        }

        /**
         * セクション別の設定を保存
         */
        saveSectionStyle(sectionId, styles) {
            const sections = this.settingsManager.getSetting('sections') || {};
            sections[sectionId] = styles;
            this.settingsManager.updateSetting('sections', sections);
            this.scheduleAutoSave();
        }

        /**
         * 編集モードとの連携
         */
        syncWithEditor(editorData) {
            if (!editorData) return;

            // 色の同期
            if (editorData.colors) {
                Object.entries(editorData.colors).forEach(([property, value]) => {
                    if (property.startsWith('--')) {
                        const customColors = this.settingsManager.getSetting('theme.customColors') || {};
                        customColors[property] = value;
                        this.settingsManager.updateSetting('theme.customColors', customColors);
                    }
                });
            }

            // セクション固有のスタイル
            if (editorData.sectionId && editorData.styles) {
                this.saveSectionStyle(editorData.sectionId, editorData.styles);
            }

            this.scheduleAutoSave();
        }
    }

    // グローバルに公開
    window.ThemePersistence = ThemePersistence;

    // 自動初期化
    document.addEventListener('DOMContentLoaded', () => {
        window.themePersistence = new ThemePersistence();
    });

})();

// 読み込み完了を通知
console.log('ThemePersistence.js loaded');