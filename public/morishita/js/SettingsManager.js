(function() {
    'use strict';

    class SettingsManager {
        constructor() {
            this.STORAGE_KEY = 'site_settings';
            this.DEFAULT_SETTINGS_KEY = 'default_settings';
            this.SAVED_THEMES_KEY = 'saved_themes';
            
            // デフォルト設定
            this.defaultSettings = {
                theme: {
                    accentColor: '#64748b',
                    fontFamily: '"M PLUS Rounded 1c", sans-serif',
                    darkMode: false,
                    customColors: {}
                },
                sections: {}
            };

            this.currentSettings = null;
            this.listeners = new Set();
            
            this.init();
        }

        async init() {
            // 保存された設定を読み込む
            await this.loadSettings();
            
            // デフォルト設定を初期化
            this.initializeDefaults();
        }

        /**
         * 設定を読み込む（サーバー優先）
         */
        async loadSettings() {
            try {
                // まずサーバーから読み込みを試みる
                const serverSettings = await this.loadFromServer();
                
                if (serverSettings && serverSettings.siteSettings) {
                    this.currentSettings = serverSettings.siteSettings;
                    console.log('サーバーから設定を読み込みました');
                } else {
                    // サーバーにデータがない場合はlocalStorageから読み込み
                    const saved = localStorage.getItem(this.STORAGE_KEY);
                    if (saved) {
                        this.currentSettings = JSON.parse(saved);
                        // 初回のみサーバーに保存（移行）
                        await this.saveToServer();
                    } else {
                        this.currentSettings = this.deepClone(this.defaultSettings);
                    }
                }
            } catch (error) {
                console.error('設定の読み込みエラー:', error);
                // エラー時はlocalStorageから読み込み
                try {
                    const saved = localStorage.getItem(this.STORAGE_KEY);
                    if (saved) {
                        this.currentSettings = JSON.parse(saved);
                    } else {
                        this.currentSettings = this.deepClone(this.defaultSettings);
                    }
                } catch (localError) {
                    console.error('ローカル設定の読み込みエラー:', localError);
                    this.currentSettings = this.deepClone(this.defaultSettings);
                }
            }
        }

        /**
         * デフォルト設定を初期化
         */
        initializeDefaults() {
            try {
                const savedDefaults = localStorage.getItem(this.DEFAULT_SETTINGS_KEY);
                if (savedDefaults) {
                    this.defaultSettings = JSON.parse(savedDefaults);
                }
            } catch (error) {
                console.error('デフォルト設定の読み込みエラー:', error);
            }
        }

        /**
         * 現在の設定を保存（サーバーとローカル両方）
         */
        async saveSettings() {
            try {
                // サーバーに保存
                await this.saveToServer();
                
                // ローカルキャッシュとしても保存
                try {
                    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(this.currentSettings));
                } catch (localError) {
                    console.warn('ローカルキャッシュ保存エラー:', localError);
                }
                
                this.notifyListeners('settings-saved', this.currentSettings);
                return true;
            } catch (error) {
                console.error('設定の保存エラー:', error);
                return false;
            }
        }

        /**
         * 現在の設定をデフォルトとして登録
         */
        saveAsDefault() {
            try {
                this.defaultSettings = this.deepClone(this.currentSettings);
                localStorage.setItem(this.DEFAULT_SETTINGS_KEY, JSON.stringify(this.defaultSettings));
                this.notifyListeners('default-saved', this.defaultSettings);
                return true;
            } catch (error) {
                console.error('デフォルト設定の保存エラー:', error);
                return false;
            }
        }

        /**
         * デフォルト設定に戻す
         */
        async resetToDefault() {
            this.currentSettings = this.deepClone(this.defaultSettings);
            await this.saveSettings();
            this.applySettings();
            this.notifyListeners('settings-reset', this.currentSettings);
        }

        /**
         * 特定の設定を更新
         */
        updateSetting(path, value) {
            const keys = path.split('.');
            let target = this.currentSettings;
            
            for (let i = 0; i < keys.length - 1; i++) {
                if (!target[keys[i]]) {
                    target[keys[i]] = {};
                }
                target = target[keys[i]];
            }
            
            target[keys[keys.length - 1]] = value;
            this.notifyListeners('setting-updated', { path, value });
        }

        /**
         * 設定を取得
         */
        getSetting(path) {
            const keys = path.split('.');
            let target = this.currentSettings;
            
            for (const key of keys) {
                if (!target || !target[key]) {
                    return undefined;
                }
                target = target[key];
            }
            
            return target;
        }

        /**
         * 現在の設定を適用
         */
        applySettings() {
            // アクセントカラー
            const accentColor = this.getSetting('theme.accentColor');
            if (accentColor) {
                document.documentElement.style.setProperty('--accent-color', accentColor);
            }

            // フォント
            const fontFamily = this.getSetting('theme.fontFamily');
            if (fontFamily) {
                document.documentElement.style.setProperty('--font-family', fontFamily);
                document.body.style.fontFamily = fontFamily;
            }

            // ダークモード
            const darkMode = this.getSetting('theme.darkMode');
            if (darkMode !== undefined) {
                document.body.classList.toggle('dark-mode', darkMode);
            }

            // カスタムカラー
            const customColors = this.getSetting('theme.customColors');
            if (customColors) {
                Object.entries(customColors).forEach(([property, value]) => {
                    document.documentElement.style.setProperty(property, value);
                });
            }

            // セクション別の設定
            const sections = this.getSetting('sections');
            if (sections) {
                Object.entries(sections).forEach(([sectionId, styles]) => {
                    const element = document.getElementById(`${sectionId}-component`);
                    if (element) {
                        Object.entries(styles).forEach(([property, value]) => {
                            element.style[property] = value;
                        });
                    }
                });
            }

            this.notifyListeners('settings-applied', this.currentSettings);
        }

        /**
         * 保存済みテーマを管理
         */
        getSavedThemes() {
            try {
                const saved = localStorage.getItem(this.SAVED_THEMES_KEY);
                return saved ? JSON.parse(saved) : [];
            } catch (error) {
                console.error('保存済みテーマの読み込みエラー:', error);
                return [];
            }
        }

        saveTheme(name) {
            const themes = this.getSavedThemes();
            const newTheme = {
                id: Date.now().toString(),
                name: name,
                settings: this.deepClone(this.currentSettings),
                savedAt: new Date().toISOString()
            };
            
            themes.push(newTheme);
            
            try {
                localStorage.setItem(this.SAVED_THEMES_KEY, JSON.stringify(themes));
                this.notifyListeners('theme-saved', newTheme);
                return true;
            } catch (error) {
                console.error('テーマの保存エラー:', error);
                return false;
            }
        }

        async loadTheme(themeId) {
            const themes = this.getSavedThemes();
            const theme = themes.find(t => t.id === themeId);
            
            if (theme) {
                this.currentSettings = this.deepClone(theme.settings);
                await this.saveSettings();
                this.applySettings();
                this.notifyListeners('theme-loaded', theme);
                return true;
            }
            
            return false;
        }

        deleteTheme(themeId) {
            const themes = this.getSavedThemes();
            const filtered = themes.filter(t => t.id !== themeId);
            
            try {
                localStorage.setItem(this.SAVED_THEMES_KEY, JSON.stringify(filtered));
                this.notifyListeners('theme-deleted', themeId);
                return true;
            } catch (error) {
                console.error('テーマの削除エラー:', error);
                return false;
            }
        }

        /**
         * リスナー管理
         */
        addListener(callback) {
            this.listeners.add(callback);
        }

        removeListener(callback) {
            this.listeners.delete(callback);
        }

        notifyListeners(event, data) {
            this.listeners.forEach(callback => {
                try {
                    callback(event, data);
                } catch (error) {
                    console.error('リスナーエラー:', error);
                }
            });
        }

        /**
         * ユーティリティ
         */
        deepClone(obj) {
            return JSON.parse(JSON.stringify(obj));
        }

        /**
         * エクスポート/インポート機能
         */
        exportSettings() {
            return JSON.stringify({
                currentSettings: this.currentSettings,
                defaultSettings: this.defaultSettings,
                savedThemes: this.getSavedThemes()
            }, null, 2);
        }

        async importSettings(jsonString) {
            try {
                const data = JSON.parse(jsonString);
                
                if (data.currentSettings) {
                    this.currentSettings = data.currentSettings;
                    await this.saveSettings();
                }
                
                if (data.defaultSettings) {
                    this.defaultSettings = data.defaultSettings;
                    localStorage.setItem(this.DEFAULT_SETTINGS_KEY, JSON.stringify(this.defaultSettings));
                }
                
                if (data.savedThemes) {
                    localStorage.setItem(this.SAVED_THEMES_KEY, JSON.stringify(data.savedThemes));
                }
                
                this.applySettings();
                this.notifyListeners('settings-imported', data);
                return true;
            } catch (error) {
                console.error('設定のインポートエラー:', error);
                return false;
            }
        }
        
        /**
         * サーバーに設定を保存
         */
        async saveToServer() {
            try {
                const projectPath = this.getCurrentProjectPath();
                
                // 現在の設定を取得
                const currentServerSettings = await this.loadFromServer() || {};
                
                // サイト設定を更新
                currentServerSettings.siteSettings = this.currentSettings;
                currentServerSettings.defaultSettings = this.defaultSettings;
                currentServerSettings.savedThemes = this.getSavedThemes();
                currentServerSettings.lastUpdated = new Date().toISOString();
                
                // サーバーに送信
                const response = await fetch('api/save-project-settings', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        projectPath: projectPath,
                        settings: currentServerSettings
                    })
                });
                
                if (!response.ok) {
                    throw new Error(`サーバー保存エラー: ${response.status}`);
                }
                
                const result = await response.json();
                console.log('設定をサーバーに保存しました:', result);
                
            } catch (error) {
                console.error('サーバー保存エラー:', error);
                throw error;
            }
        }
        
        /**
         * サーバーから設定を読み込み
         */
        async loadFromServer() {
            try {
                const projectPath = this.getCurrentProjectPath();
                
                const response = await fetch(`/api/load-project-settings?projectPath=${encodeURIComponent(projectPath)}`);
                
                if (!response.ok) {
                    throw new Error(`サーバー読み込みエラー: ${response.status}`);
                }
                
                const result = await response.json();
                
                if (result.success && result.settings) {
                    console.log('サーバーから設定を読み込み:', result.settings);
                    return result.settings;
                }
                
                return null;
                
            } catch (error) {
                console.error('サーバー読み込みエラー:', error);
                return null;
            }
        }
        
        /**
         * 現在のプロジェクトパスを取得
         */
        getCurrentProjectPath() {
            const currentPath = window.location.pathname;
            return currentPath.replace(/^\/site\//, '').replace(/\/$/, '') || 'next/project';
        }
    }

    // グローバルに公開
    window.SettingsManager = SettingsManager;

    // 自動初期化
    document.addEventListener('DOMContentLoaded', async () => {
        window.settingsManager = new SettingsManager();
        await window.settingsManager.init();
        // 保存された設定を自動適用
        window.settingsManager.applySettings();
    });

})();

// 読み込み完了を通知
console.log('SettingsManager.js loaded');