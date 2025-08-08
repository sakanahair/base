(function() {
    'use strict';

    // 日本の伝統色を含むおしゃれな30色のカラーパレット
    const colorPalette = [
        // 伝統的な和の色
        { name: 'スレートグレー', color: '#64748b', hover: '#475569' }, // デフォルト
        { name: '桜色', color: '#FFB6C1', hover: '#FFA0B8' },
        { name: '藤色', color: '#C589E8', hover: '#B670E0' },
        { name: '紅梅色', color: '#E91E63', hover: '#D81B60' },
        { name: '山吹色', color: '#FFC107', hover: '#FFB300' },
        { name: '藍色', color: '#3F51B5', hover: '#303F9F' },
        
        // モダンな日本の色
        { name: '抹茶色', color: '#475569', hover: '#475569' },
        { name: '小豆色', color: '#8D6E63', hover: '#795548' },
        { name: '群青色', color: '#1976D2', hover: '#1565C0' },
        { name: '朱色', color: '#FF5722', hover: '#F4511E' },
        { name: '紺碧', color: '#00BCD4', hover: '#00ACC1' },
        { name: '菖蒲色', color: '#9C27B0', hover: '#8E24AA' },
        
        // パステルカラー
        { name: 'ミントグリーン', color: '#00E676', hover: '#00C853' },
        { name: 'コーラルピンク', color: '#FF8A80', hover: '#FF7961' },
        { name: 'ラベンダー', color: '#B39DDB', hover: '#9575CD' },
        { name: 'ピーチ', color: '#FFAB91', hover: '#FF8A65' },
        { name: 'スカイブルー', color: '#81D4FA', hover: '#4FC3F7' },
        { name: 'レモン', color: '#FFF176', hover: '#FFEE58' },
        
        // アースカラー
        { name: 'テラコッタ', color: '#D84315', hover: '#BF360C' },
        { name: 'オリーブ', color: '#827717', hover: '#6A5F14' },
        { name: 'サンド', color: '#D7CCC8', hover: '#BCAAA4' },
        { name: 'ストーン', color: '#757575', hover: '#616161' },
        { name: 'モス', color: '#388E3C', hover: '#2E7D32' },
        { name: 'クレイ', color: '#6D4C41', hover: '#5D4037' },
        
        // モノトーン＆メタリック
        { name: 'チャコール', color: '#424242', hover: '#212121' },
        { name: 'シルバー', color: '#9E9E9E', hover: '#757575' },
        { name: 'ローズゴールド', color: '#E91E99', hover: '#D81B84' },
        { name: 'ブロンズ', color: '#A1887F', hover: '#8D6E63' },
        { name: 'ティール', color: '#009688', hover: '#00897B' },
        { name: 'ワイン', color: '#880E4F', hover: '#6A0A3D' }
    ];

    class ColorPicker {
        constructor() {
            this.colorKey = 'accent-color';
            this.currentColor = this.getSavedColor() || colorPalette[0];
            this.init();
        }

        init() {
            this.applyColor(this.currentColor);
            this.setupColorPicker();
        }

        getSavedColor() {
            const saved = localStorage.getItem(this.colorKey);
            if (saved) {
                return JSON.parse(saved);
            }
            return null;
        }

        saveColor(colorData) {
            localStorage.setItem(this.colorKey, JSON.stringify(colorData));
        }

        applyColor(colorData) {
            document.documentElement.style.setProperty('--primary-color', colorData.color);
            document.documentElement.style.setProperty('--primary-hover', colorData.hover);
            document.documentElement.style.setProperty('--accent-color', colorData.color);
            document.documentElement.style.setProperty('--accent-hover', colorData.hover);
            this.currentColor = colorData;
            this.saveColor(colorData);
        }

        setupColorPicker() {
            // header.jsで処理されるため、ここではパレットの生成のみ行う
            const palette = document.querySelector('.color-palette');
            
            if (!palette) {
                // パレットが見つからない場合は、DOMContentLoadedを待つ
                setTimeout(() => this.setupColorPicker(), 100);
                return;
            }

            // カラーパレットを生成
            colorPalette.forEach((colorData, index) => {
                const colorOption = document.createElement('button');
                colorOption.className = 'color-option';
                colorOption.style.backgroundColor = colorData.color;
                colorOption.title = colorData.name;
                colorOption.setAttribute('data-color-index', index);

                // 現在の色にアクティブクラスを追加
                if (colorData.color === this.currentColor.color) {
                    colorOption.classList.add('active');
                }

                colorOption.addEventListener('click', () => {
                    // 全てのオプションからアクティブクラスを削除
                    document.querySelectorAll('.color-option').forEach(opt => {
                        opt.classList.remove('active');
                    });
                    
                    // 選択したオプションにアクティブクラスを追加
                    colorOption.classList.add('active');
                    
                    // 色を適用
                    this.applyColor(colorData);
                });

                palette.appendChild(colorOption);
            });
        }
    }

    // カラーピッカーの初期化
    window.addEventListener('DOMContentLoaded', () => {
        window.colorPicker = new ColorPicker();
    });
})();