(function() {
    'use strict';

    class ImageOptimizer {
        constructor() {
            // 一時的に無効化
            console.log('ImageOptimizer: 一時的に無効化されています');
            return;
            
            this.init();
        }

        init() {
            // DOMContentLoadedを待つ
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.optimizeBackgroundImages());
            } else {
                this.optimizeBackgroundImages();
            }

            // componentsLoadedイベントも監視
            document.addEventListener('componentsLoaded', () => this.optimizeBackgroundImages());
        }

        /**
         * 背景画像の最適化
         */
        optimizeBackgroundImages() {
            // element-settings.jsonから背景画像設定を読み込む
            this.loadBackgroundSettings();
        }

        /**
         * 設定から背景画像を読み込み
         */
        async loadBackgroundSettings() {
            try {
                // ElementEditManagerの設定を使用
                if (window.elementEditManager) {
                    const settings = await window.elementEditManager.loadFromServer();
                    if (settings && settings.elementEdits) {
                        this.applyOptimizedBackgrounds(settings.elementEdits);
                    }
                } else {
                    // フォールバック: 直接element-settings.jsonを読み込む
                    const response = await fetch('element-settings.json');
                    if (response.ok) {
                        const data = await response.json();
                        if (data.elementEdits) {
                            this.applyOptimizedBackgrounds(data.elementEdits);
                        }
                    }
                }
            } catch (error) {
                console.error('背景画像設定の読み込みエラー:', error);
            }
        }

        /**
         * 最適化された背景画像を適用
         */
        applyOptimizedBackgrounds(elementEdits) {
            Object.entries(elementEdits).forEach(([selector, edit]) => {
                if (edit.editedStyles && edit.editedStyles.backgroundImage) {
                    this.optimizeAndApplyBackground(selector, edit.editedStyles.backgroundImage);
                }
            });
        }

        /**
         * 背景画像を最適化して適用
         */
        optimizeAndApplyBackground(selector, backgroundImage) {
            // セレクターから要素を取得
            const match = selector.match(/^(.+)_(\d+)$/);
            if (!match) return;

            const [, baseSelector, index] = match;
            const elements = document.querySelectorAll(baseSelector);
            const element = elements[parseInt(index)];

            if (!element) return;

            // 画像URLを抽出
            const urlMatch = backgroundImage.match(/url\(['"]?([^'")]+)['"]?\)/);
            if (!urlMatch) {
                // URLがない場合はそのまま適用
                element.style.backgroundImage = backgroundImage;
                return;
            }

            const imageUrl = urlMatch[1];

            // プレースホルダー背景を設定（グラデーションのみ）
            const gradientOnly = backgroundImage.replace(/,\s*url\([^)]+\)/, '');
            element.style.backgroundImage = gradientOnly;
            element.style.transition = 'filter 0.3s ease-in-out';

            // プリロード用のImage要素を作成
            const img = new Image();
            
            // 画像の読み込み開始時
            img.onloadstart = () => {
                console.log(`背景画像の読み込み開始: ${imageUrl}`);
            };

            // 画像の読み込み完了時
            img.onload = () => {
                console.log(`背景画像の読み込み完了: ${imageUrl}`);
                
                // フェードイン効果で背景画像を適用
                requestAnimationFrame(() => {
                    element.style.backgroundImage = backgroundImage;
                    
                    // 遅延読み込み用のクラスを追加
                    element.classList.add('bg-loaded');
                });
            };

            // エラー時の処理
            img.onerror = () => {
                console.error(`背景画像の読み込みエラー: ${imageUrl}`);
                // エラー時はグラデーションのみ適用
                element.style.backgroundImage = 'linear-gradient(rgba(0, 0, 0, 0.62), rgba(0, 0, 0, 0.62))';
            };

            // 画像の読み込みを開始
            img.src = imageUrl;

            // IntersectionObserverで画面内に入ったときに読み込む
            if ('IntersectionObserver' in window) {
                const observer = new IntersectionObserver((entries) => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            // 画面内に入ったら高品質画像を読み込む
                            img.src = imageUrl;
                            observer.unobserve(entry.target);
                        }
                    });
                }, {
                    rootMargin: '50px'
                });

                observer.observe(element);
            } else {
                // IntersectionObserverがサポートされていない場合は即座に読み込む
                img.src = imageUrl;
            }
        }

        /**
         * 画像URLを最適化（サイズ調整など）
         */
        getOptimizedImageUrl(originalUrl, width) {
            // 将来的にはここでサーバーサイドの画像最適化APIを呼び出す
            // 例: /api/optimize-image?url=...&width=...&quality=...
            return originalUrl;
        }
    }

    // グローバルに公開
    window.ImageOptimizer = ImageOptimizer;

    // 自動初期化
    window.imageOptimizer = new ImageOptimizer();

})();