(function() {
    'use strict';

    // テーマ管理クラス
    class ThemeManager {
        constructor() {
            this.themeKey = 'preferred-theme';
            this.darkModeClass = 'dark-mode';
            this.lightModeClass = 'light-mode';
            this.init();
        }

        init() {
            // 強制的にライトモードを適用（デバッグ用）
            console.log('テーマ初期化: ライトモードを強制適用');
            
            // 保存されたテーマを取得
            const savedTheme = this.getSavedTheme();
            console.log('保存されたテーマ:', savedTheme);
            
            // まず確実にダークモードクラスを削除
            document.body.classList.remove(this.darkModeClass);
            document.body.classList.add(this.lightModeClass);
            
            // デフォルトはライトモード（システム設定に関係なく）
            // ダークモードは明示的に選択された場合のみ適用
            
            // テーマを適用
            if (savedTheme === 'dark') {
                console.log('保存されたダークモード設定を適用');
                this.enableDarkMode();
            } else {
                // 保存されたテーマがない場合やlight、その他の場合はライトモード
                console.log('ライトモードを適用');
                this.enableLightMode();
            }

            // テーマ切り替えボタンのイベントリスナーを設定
            this.setupThemeToggle();
            
            // システムテーマ監視を無効化 - ユーザーの明示的な選択のみを尊重
        }

        getSavedTheme() {
            return localStorage.getItem(this.themeKey);
        }

        saveTheme(theme) {
            localStorage.setItem(this.themeKey, theme);
        }

        enableDarkMode() {
            document.body.classList.add(this.darkModeClass);
            document.body.classList.remove(this.lightModeClass);
            this.saveTheme('dark');
        }

        enableLightMode() {
            document.body.classList.remove(this.darkModeClass);
            document.body.classList.add(this.lightModeClass);
            this.saveTheme('light');
        }

        toggleTheme() {
            if (document.body.classList.contains(this.darkModeClass)) {
                this.enableLightMode();
            } else {
                this.enableDarkMode();
            }
        }

        setupThemeToggle() {
            // すべてのテーマ切り替えボタンを取得
            const toggleButtons = document.querySelectorAll('.theme-toggle');
            
            toggleButtons.forEach(button => {
                button.addEventListener('click', () => {
                    this.toggleTheme();
                });
            });
        }

        // システムテーマ監視を削除 - デフォルトはライトモードに固定
    }

    // テーママネージャーの初期化
    window.themeManager = new ThemeManager();
})();