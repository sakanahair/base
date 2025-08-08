(function() {
    'use strict';

    // 日本語向けの30個のフォント
    const fontOptions = {
        gothic: [
            { name: 'Noto Sans JP', family: '"Noto Sans JP", sans-serif', preview: '美しい日本語フォント' },
            { name: 'M PLUS 1p', family: '"M PLUS 1p", sans-serif', preview: 'モダンで読みやすい' },
            { name: 'M PLUS Rounded 1c', family: '"M PLUS Rounded 1c", sans-serif', preview: '柔らかい印象' },
            { name: 'Kosugi Maru', family: '"Kosugi Maru", sans-serif', preview: '丸みのあるゴシック' },
            { name: 'Kosugi', family: '"Kosugi", sans-serif', preview: 'シンプルなゴシック' },
            { name: 'Sawarabi Gothic', family: '"Sawarabi Gothic", sans-serif', preview: 'さわらびゴシック' },
            { name: 'Zen Kaku Gothic New', family: '"Zen Kaku Gothic New", sans-serif', preview: '禅カクゴシック' },
            { name: 'Zen Maru Gothic', family: '"Zen Maru Gothic", sans-serif', preview: '禅丸ゴシック' },
            { name: 'BIZ UDPGothic', family: '"BIZ UDPGothic", sans-serif', preview: 'ビジネス向け' },
            { name: 'IBM Plex Sans JP', family: '"IBM Plex Sans JP", sans-serif', preview: 'IBM開発フォント' }
        ],
        mincho: [
            { name: 'Noto Serif JP', family: '"Noto Serif JP", serif', preview: '品格ある明朝体' },
            { name: 'Sawarabi Mincho', family: '"Sawarabi Mincho", serif', preview: 'さわらび明朝' },
            { name: 'Shippori Mincho', family: '"Shippori Mincho", serif', preview: 'しっぽり明朝' },
            { name: 'Shippori Mincho B1', family: '"Shippori Mincho B1", serif', preview: 'しっぽり明朝B1' },
            { name: 'Klee One', family: '"Klee One", serif', preview: 'クレー' },
            { name: 'BIZ UDMincho', family: '"BIZ UDMincho", serif', preview: 'ビジネス明朝' },
            { name: 'Zen Old Mincho', family: '"Zen Old Mincho", serif', preview: '禅オールド明朝' },
            { name: 'Zen Antique', family: '"Zen Antique", serif', preview: '禅アンティーク' },
            { name: 'Zen Antique Soft', family: '"Zen Antique Soft", serif', preview: '禅アンティークソフト' },
            { name: 'Kaisei Opti', family: '"Kaisei Opti", serif', preview: '解星オプティ' }
        ],
        decorative: [
            { name: 'Dela Gothic One', family: '"Dela Gothic One", cursive', preview: 'デラゴシック' },
            { name: 'DotGothic16', family: '"DotGothic16", sans-serif', preview: 'ドットゴシック' },
            { name: 'Hachi Maru Pop', family: '"Hachi Maru Pop", cursive', preview: 'はちまるポップ' },
            { name: 'Potta One', family: '"Potta One", cursive', preview: 'ポッタ' },
            { name: 'Reggae One', family: '"Reggae One", cursive', preview: 'レゲエ' },
            { name: 'RocknRoll One', family: '"RocknRoll One", sans-serif', preview: 'ロックンロール' },
            { name: 'Stick', family: '"Stick", sans-serif', preview: 'スティック' },
            { name: 'Train One', family: '"Train One", cursive', preview: 'トレイン' },
            { name: 'Yusei Magic', family: '"Yusei Magic", sans-serif', preview: '遊星マジック' },
            { name: 'Rampart One', family: '"Rampart One", cursive', preview: 'ランパート' }
        ]
    };

    class FontPicker {
        constructor() {
            this.fontKey = 'selected-font';
            this.currentFont = this.getSavedFont() || fontOptions.gothic[2]; // デフォルトはM PLUS Rounded 1c
            this.currentCategory = 'gothic';
            this.init();
        }

        init() {
            this.applyFont(this.currentFont);
            this.setupFontPicker();
        }

        getSavedFont() {
            const saved = localStorage.getItem(this.fontKey);
            if (saved) {
                return JSON.parse(saved);
            }
            return null;
        }

        saveFont(fontData) {
            localStorage.setItem(this.fontKey, JSON.stringify(fontData));
        }

        applyFont(fontData) {
            document.documentElement.style.setProperty('--font-family', fontData.family);
            this.currentFont = fontData;
            this.saveFont(fontData);
        }

        setupFontPicker() {
            // フォントピッカーの初期化を待つ
            const fontList = document.querySelector('.font-list');
            if (!fontList) {
                // HTMLベースのフォントピッカーがない場合は、グローバルAPIのみ提供
                console.log('HTMLベースのフォントピッカーが見つかりません。フローティングコントロール用にAPIのみ提供します。');
                return;
            }

            // カテゴリタブの設定
            const categoryTabs = document.querySelectorAll('.category-tab');
            categoryTabs.forEach(tab => {
                tab.addEventListener('click', () => {
                    // アクティブタブの切り替え
                    categoryTabs.forEach(t => t.classList.remove('active'));
                    tab.classList.add('active');
                    
                    // カテゴリの変更
                    this.currentCategory = tab.getAttribute('data-category');
                    this.renderFontList();
                });
            });

            // 初期表示
            this.renderFontList();
        }

        renderFontList() {
            const fontList = document.querySelector('.font-list');
            if (!fontList) return;

            // リストをクリア
            fontList.innerHTML = '';

            // 選択されたカテゴリのフォントを表示
            const fonts = fontOptions[this.currentCategory] || [];
            fonts.forEach(fontData => {
                const fontOption = document.createElement('button');
                fontOption.className = 'font-option';
                
                // 現在のフォントにアクティブクラスを追加
                if (fontData.family === this.currentFont.family) {
                    fontOption.classList.add('active');
                }

                fontOption.innerHTML = `
                    <div class="font-name">${fontData.name}</div>
                    <div class="font-preview" style="font-family: ${fontData.family}">
                        ${fontData.preview}
                    </div>
                `;

                fontOption.addEventListener('click', () => {
                    // 全てのオプションからアクティブクラスを削除
                    document.querySelectorAll('.font-option').forEach(opt => {
                        opt.classList.remove('active');
                    });
                    
                    // 選択したオプションにアクティブクラスを追加
                    fontOption.classList.add('active');
                    
                    // フォントを適用
                    this.applyFont(fontData);
                });

                fontList.appendChild(fontOption);
            });
        }
    }

    // フォントピッカーの初期化
    window.addEventListener('DOMContentLoaded', () => {
        window.fontPicker = new FontPicker();
    });
})();