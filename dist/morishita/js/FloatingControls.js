(function() {
    'use strict';

    class FloatingControls {
        constructor() {
            this.isExpanded = false;
            this.selectedSection = null;
            this.isEditMode = false;
            this.init();
        }

        init() {
            this.createFloatingControls();
            this.setupEventListeners();
            this.restoreSavedFont();
        }

        /**
         * 保存されたフォントを復元
         */
        restoreSavedFont() {
            try {
                const savedFont = localStorage.getItem('selected-font');
                if (savedFont) {
                    const fontData = JSON.parse(savedFont);
                    if (fontData && fontData.family) {
                        // CSS変数を設定
                        document.documentElement.style.setProperty('--font-family', fontData.family);
                        
                        // 動的CSSルールを作成して最高優先度で適用
                        const styleId = 'font-override-styles';
                        let existingStyle = document.getElementById(styleId);
                        if (existingStyle) {
                            existingStyle.remove();
                        }
                        
                        const style = document.createElement('style');
                        style.id = styleId;
                        style.textContent = `
                            * { font-family: ${fontData.family} !important; }
                            body, html { font-family: ${fontData.family} !important; }
                            h1, h2, h3, h4, h5, h6 { font-family: ${fontData.family} !important; }
                            p, div, span, a, button, input, textarea, select, label { font-family: ${fontData.family} !important; }
                            .hero-title, .hero-subtitle, .section-title, .program-name, .price-amount { font-family: ${fontData.family} !important; }
                            .campaign-text, .footer-text, .nav-link { font-family: ${fontData.family} !important; }
                            
                            /* フォントピッカーのリストは除外（各ボタンは独自のフォントを保持） */
                            .font-options button { font-family: inherit !important; }
                        `;
                        document.head.appendChild(style);
                        
                        // bodyタグに直接適用
                        document.body.style.setProperty('font-family', fontData.family, 'important');
                        
                        // 全ての要素に直接フォントを適用（フォントピッカーのボタンは除外）
                        setTimeout(() => {
                            const allElements = document.querySelectorAll('*');
                            allElements.forEach(el => {
                                if (!el.closest('.font-options')) {
                                    el.style.setProperty('font-family', fontData.family, 'important');
                                }
                            });
                        }, 100);
                        
                        console.log('保存されたフォントを復元:', fontData.name, fontData.family);
                        console.log('body fontFamily設定:', document.body.style.fontFamily);
                        console.log('強制復元完了');
                    }
                }
            } catch (error) {
                console.error('フォント復元エラー:', error);
            }
        }

        /**
         * モバイル用ピッカーオーバーレイを作成
         */
        createPickerOverlay() {
            const existingOverlay = document.getElementById('picker-overlay');
            if (existingOverlay) return;

            const overlay = document.createElement('div');
            overlay.id = 'picker-overlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.5);
                z-index: 100005;
                display: block;
            `;
            
            // オーバーレイクリックでピッカーを閉じる
            overlay.addEventListener('click', () => {
                this.hideAllPickers();
            });
            
            document.body.appendChild(overlay);
        }

        /**
         * すべてのピッカーを非表示にする
         */
        hideAllPickers() {
            const container = document.getElementById('pickers-container');
            if (container) {
                container.style.display = 'none';
            }
            
            const overlay = document.getElementById('picker-overlay');
            if (overlay) {
                overlay.remove();
            }
        }

        createFloatingControls() {
            // メインコンテナ
            const container = document.createElement('div');
            container.id = 'floating-controls';
            // モバイル判定
            const isMobile = window.innerWidth <= 768;
            
            container.style.cssText = `
                position: fixed;
                bottom: ${isMobile ? '15px' : '30px'};
                right: ${isMobile ? '15px' : '30px'};
                z-index: 100005;
                display: flex;
                flex-direction: column;
                align-items: flex-end;
                gap: ${isMobile ? '10px' : '15px'};
                max-width: ${isMobile ? 'calc(100vw - 30px)' : 'auto'};
            `;

            // メインボタンコンテナ（2x2グリッド）
            const mainButtonsContainer = document.createElement('div');
            mainButtonsContainer.style.cssText = `
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 10px;
                order: 4;
            `;

            // 編集ボタン（左上）
            const editButton = document.createElement('button');
            editButton.id = 'floating-edit-btn';
            editButton.textContent = '編集';
            editButton.style.cssText = `
                min-width: ${isMobile ? '70px' : '80px'};
                height: ${isMobile ? '45px' : '50px'};
                border-radius: ${isMobile ? '22px' : '25px'};
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                color: var(--text-color, #333);
                border: 1px solid rgba(255, 255, 255, 0.3);
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
                transition: all 0.3s ease;
                padding: 0 ${isMobile ? '12px' : '16px'};
                font-family: var(--font-family);
            `;

            // 全般ボタン（旧設定、右上）
            const mainButton = document.createElement('button');
            mainButton.id = 'floating-main-btn';
            mainButton.textContent = '全般';
            mainButton.style.cssText = `
                min-width: ${isMobile ? '70px' : '80px'};
                height: ${isMobile ? '45px' : '50px'};
                border-radius: ${isMobile ? '22px' : '25px'};
                background: linear-gradient(135deg, var(--accent-color, #64748b), var(--accent-color, #475569));
                color: white;
                border: none;
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
                transition: all 0.3s ease;
                padding: 0 ${isMobile ? '12px' : '16px'};
                font-family: var(--font-family);
            `;

            // コントロールボタンズ
            const controlsGroup = document.createElement('div');
            controlsGroup.id = 'controls-group';
            controlsGroup.style.cssText = `
                display: flex;
                flex-direction: column;
                gap: 10px;
                opacity: 0;
                transform: scale(0.8) translateY(20px);
                transition: all 0.3s ease;
                pointer-events: none;
            `;

            // ダークモードボタン
            const darkModeBtn = this.createControlButton('ダーク', 'ダークモード', () => {
                if (window.themeManager) {
                    window.themeManager.toggleTheme();
                    this.updateDarkModeButton(darkModeBtn);
                    
                    // 設定マネージャーに通知
                    const isDarkMode = document.body.classList.contains('dark-mode');
                    if (window.settingsManager) {
                        window.settingsManager.updateSetting('theme.darkMode', isDarkMode);
                    }
                    
                    // カスタムイベントを発火
                    document.dispatchEvent(new CustomEvent('themeChanged', {
                        detail: { darkMode: isDarkMode }
                    }));
                }
            });

            // カラーピッカーボタン
            const colorBtn = this.createControlButton('カラー', 'カラーピッカー', () => {
                this.toggleColorPicker();
            });

            // フォントボタン
            const fontBtn = this.createControlButton('フォント', 'フォント', () => {
                this.toggleFontPicker();
            });

            // ピッカー用のコンテナ
            const pickersContainer = document.createElement('div');
            pickersContainer.id = 'pickers-container';
            pickersContainer.style.cssText = `
                position: ${isMobile ? 'fixed' : 'absolute'};
                ${isMobile ? 'top: 50%; left: 50%; transform: translate(-50%, -50%);' : 'bottom: 80px; left: -380px;'}
                display: none;
                z-index: 100010;
            `;

            // セクション選択コンテナ
            const sectionPickerContainer = document.createElement('div');
            sectionPickerContainer.id = 'section-picker-container';
            sectionPickerContainer.style.cssText = `
                position: absolute;
                bottom: 60px;
                right: 0;
                display: none;
            `;

            // 組み立て
            controlsGroup.appendChild(darkModeBtn);
            controlsGroup.appendChild(colorBtn);
            controlsGroup.appendChild(fontBtn);
            
            // ビルドボタン（左下）
            const buildButton = document.createElement('button');
            buildButton.id = 'floating-build-btn';
            buildButton.textContent = 'ビルド';
            buildButton.style.cssText = `
                min-width: ${isMobile ? '70px' : '80px'};
                height: ${isMobile ? '45px' : '50px'};
                border-radius: ${isMobile ? '22px' : '25px'};
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                color: var(--text-color, #333);
                border: 1px solid rgba(255, 255, 255, 0.3);
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
                transition: all 0.3s ease;
                padding: 0 ${isMobile ? '12px' : '16px'};
                font-family: var(--font-family);
            `;

            // 本番ボタン（右下、旧ビルド後ページ）
            const buildPageButton = document.createElement('button');
            buildPageButton.id = 'floating-build-page-btn';
            buildPageButton.textContent = '本番';
            buildPageButton.style.cssText = `
                min-width: ${isMobile ? '70px' : '80px'};
                height: ${isMobile ? '45px' : '50px'};
                border-radius: ${isMobile ? '22px' : '25px'};
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                color: var(--text-color, #333);
                border: 1px solid rgba(255, 255, 255, 0.3);
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
                transition: all 0.3s ease;
                padding: 0 ${isMobile ? '12px' : '16px'};
                font-family: var(--font-family);
                display: none;
            `;

            // 2x2グリッドに配置（上段：編集、全般、下段：ビルド、本番）
            mainButtonsContainer.appendChild(editButton);
            mainButtonsContainer.appendChild(mainButton);
            mainButtonsContainer.appendChild(buildButton);
            mainButtonsContainer.appendChild(buildPageButton);
            
            container.appendChild(sectionPickerContainer);
            container.appendChild(pickersContainer);
            container.appendChild(controlsGroup);
            container.appendChild(mainButtonsContainer);

            document.body.appendChild(container);

            // 初期状態設定
            this.updateDarkModeButton(darkModeBtn);
            
            // ページロード時にdistフォルダの存在をチェック
            this.checkDistFolder().then(exists => {
                if (exists) {
                    const buildPageButton = document.getElementById('floating-build-page-btn');
                    if (buildPageButton) {
                        buildPageButton.style.display = 'block';
                    }
                }
            });
        }

        createControlButton(text, tooltip, onClick) {
            const button = document.createElement('button');
            button.textContent = text;
            button.title = tooltip;
            
            const isMobile = window.innerWidth <= 768;
            
            button.style.cssText = `
                min-width: ${isMobile ? '60px' : '70px'};
                height: ${isMobile ? '36px' : '40px'};
                border-radius: ${isMobile ? '18px' : '20px'};
                background: rgba(255, 255, 255, 0.9);
                backdrop-filter: blur(10px);
                color: var(--text-color, #333);
                border: 1px solid rgba(255, 255, 255, 0.3);
                font-size: ${isMobile ? '11px' : '12px'};
                font-weight: 500;
                cursor: pointer;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                transition: all 0.3s ease;
                padding: 0 ${isMobile ? '8px' : '12px'};
                font-family: var(--font-family);
            `;

            // ホバー効果
            button.addEventListener('mouseenter', () => {
                const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                button.style.transform = 'scale(1.1)';
                button.style.background = accentColor;
                button.style.color = 'white';
            });

            button.addEventListener('mouseleave', () => {
                button.style.transform = 'scale(1)';
                button.style.background = 'rgba(255, 255, 255, 0.9)';
                button.style.color = '#333';
            });

            button.addEventListener('click', onClick);

            return button;
        }

        setupEventListeners() {
            const mainButton = document.getElementById('floating-main-btn');
            const editButton = document.getElementById('floating-edit-btn');
            const buildButton = document.getElementById('floating-build-btn');
            const buildPageButton = document.getElementById('floating-build-page-btn');
            
            mainButton.addEventListener('click', () => {
                this.toggleControls();
            });

            editButton.addEventListener('click', () => {
                if (this.isEditMode) {
                    // 編集終了
                    this.endEditMode();
                } else {
                    // 編集開始 - 即座に全体編集モードに入る
                    this.startDirectEditMode();
                }
            });

            buildButton.addEventListener('click', () => {
                this.startBuild();
            });

            buildPageButton.addEventListener('click', () => {
                // distフォルダのindex.htmlを新しいタブで開く（本番環境）
                const distUrl = window.location.origin + window.location.pathname.replace('index.html', '') + 'dist/index.html';
                window.open(distUrl, '_blank');
            });

            // メインボタンのホバー効果
            mainButton.addEventListener('mouseenter', () => {
                mainButton.style.transform = 'scale(1.05)';
                mainButton.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.3)';
            });

            mainButton.addEventListener('mouseleave', () => {
                mainButton.style.transform = 'scale(1)';
                mainButton.style.boxShadow = '0 4px 16px rgba(0, 0, 0, 0.2)';
            });

            // 編集ボタンのホバー効果
            editButton.addEventListener('mouseenter', () => {
                const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                editButton.style.transform = 'scale(1.05)';
                editButton.style.background = accentColor;
                editButton.style.color = 'white';
            });

            editButton.addEventListener('mouseleave', () => {
                editButton.style.transform = 'scale(1)';
                editButton.style.background = 'rgba(255, 255, 255, 0.9)';
                editButton.style.color = '#333';
            });

            // ビルドボタンのホバー効果
            buildButton.addEventListener('mouseenter', () => {
                const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                buildButton.style.transform = 'scale(1.05)';
                buildButton.style.background = accentColor;
                buildButton.style.color = 'white';
            });

            buildButton.addEventListener('mouseleave', () => {
                buildButton.style.transform = 'scale(1)';
                buildButton.style.background = 'rgba(255, 255, 255, 0.9)';
                buildButton.style.color = '#333';
            });

            // 本番ボタンのホバー効果
            buildPageButton.addEventListener('mouseenter', () => {
                const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                buildPageButton.style.transform = 'scale(1.05)';
                buildPageButton.style.background = accentColor;
                buildPageButton.style.color = 'white';
            });

            buildPageButton.addEventListener('mouseleave', () => {
                buildPageButton.style.transform = 'scale(1)';
                buildPageButton.style.background = 'rgba(255, 255, 255, 0.9)';
                buildPageButton.style.color = '#333';
            });

            // 外側クリックで閉じる
            document.addEventListener('click', (e) => {
                const container = document.getElementById('floating-controls');
                if (container && !container.contains(e.target)) {
                    this.closeAllPickers();
                    this.closeSectionPicker();
                    if (this.isExpanded) {
                        this.toggleControls();
                    }
                }
            });

            // セクション選択イベントを監視
            document.addEventListener('sectionSelected', () => {
                this.startEditMode();
            });

            // セクション選択解除イベントを監視（保存メニューが表示されている時は無視）
            document.addEventListener('sectionDeselected', () => {
                if (!document.querySelector('.save-menu-overlay')) {
                    this.endEditMode();
                }
            });
        }

        toggleControls() {
            this.isExpanded = !this.isExpanded;
            const controlsGroup = document.getElementById('controls-group');
            const mainButton = document.getElementById('floating-main-btn');

            if (this.isExpanded) {
                controlsGroup.style.opacity = '1';
                controlsGroup.style.transform = 'scale(1) translateY(0)';
                controlsGroup.style.pointerEvents = 'all';
                mainButton.style.transform = 'rotate(45deg)';
            } else {
                controlsGroup.style.opacity = '0';
                controlsGroup.style.transform = 'scale(0.8) translateY(20px)';
                controlsGroup.style.pointerEvents = 'none';
                mainButton.style.transform = 'rotate(0deg)';
                this.closeAllPickers();
            }
        }

        updateDarkModeButton(button) {
            const isDarkMode = document.body.classList.contains('dark-mode');
            button.textContent = isDarkMode ? 'ライト' : 'ダーク';
            button.title = isDarkMode ? 'ライトモード' : 'ダークモード';
        }

        updateMainButtonColor() {
            const mainButton = document.getElementById('floating-main-btn');
            if (mainButton) {
                // CSS変数から現在のアクセントカラーを取得
                const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                mainButton.style.background = `linear-gradient(135deg, ${accentColor}, ${accentColor}dd)`;
            }
        }

        toggleColorPicker() {
            this.closeOtherPickers('color');
            const picker = this.getOrCreateColorPicker();
            const isVisible = picker.style.display === 'block';
            picker.style.display = isVisible ? 'none' : 'block';
        }

        toggleFontPicker() {
            // モバイルでの制限を通知
            if (window.innerWidth <= 768) {
                alert('フォントの変更はPCでのみ可能です。\nモバイルデバイスでは変更できません。');
                return;
            }
            
            this.closeOtherPickers('font');
            const picker = this.getOrCreateFontPicker();
            const isVisible = picker.style.display === 'block';
            picker.style.display = isVisible ? 'none' : 'block';
        }

        closeOtherPickers(except) {
            const container = document.getElementById('pickers-container');
            if (!container) return;

            container.querySelectorAll('.floating-picker').forEach(picker => {
                if (!picker.classList.contains(`${except}-picker`)) {
                    picker.style.display = 'none';
                }
            });
        }

        closeAllPickers() {
            const container = document.getElementById('pickers-container');
            if (!container) return;

            container.querySelectorAll('.floating-picker').forEach(picker => {
                picker.style.display = 'none';
            });
            container.style.display = 'none';
        }

        getOrCreateColorPicker() {
            const container = document.getElementById('pickers-container');
            let picker = container.querySelector('.color-picker');
            
            if (!picker) {
                picker = this.createColorPickerPanel();
                container.appendChild(picker);
            }
            
            container.style.display = 'block';
            
            // モバイルの場合は背景オーバーレイを追加
            if (window.innerWidth <= 768) {
                this.createPickerOverlay();
            }
            
            return picker;
        }

        getOrCreateFontPicker() {
            const container = document.getElementById('pickers-container');
            let picker = container.querySelector('.font-picker');
            
            if (!picker) {
                picker = this.createFontPickerPanel();
                container.appendChild(picker);
            }
            
            container.style.display = 'block';
            
            // モバイルの場合は背景オーバーレイを追加
            if (window.innerWidth <= 768) {
                this.createPickerOverlay();
            }
            
            return picker;
        }

        createColorPickerPanel() {
            const panel = document.createElement('div');
            panel.className = 'floating-picker color-picker';
            
            const isMobile = window.innerWidth <= 768;
            
            panel.style.cssText = `
                background: var(--card-bg, rgba(255, 255, 255, 0.95));
                backdrop-filter: blur(15px);
                border-radius: 16px;
                padding: ${isMobile ? '15px' : '20px'};
                box-shadow: var(--box-shadow-hover, 0 8px 32px rgba(0, 0, 0, 0.15));
                border: 1px solid rgba(255, 255, 255, 0.3);
                width: ${isMobile ? 'calc(100vw - 50px)' : '360px'};
                max-width: ${isMobile ? '350px' : 'none'};
                max-height: ${isMobile ? '70vh' : '480px'};
                overflow-y: auto;
                margin-bottom: 10px;
                font-family: var(--font-family);
                color: var(--text-color);
            `;

            const colors = [
                { name: '桜', color: '#FF6B9D' },
                { name: '若草', color: '#64748b' },
                { name: '空', color: '#2196F3' },
                { name: '夕焼け', color: '#FF5722' },
                { name: '紫', color: '#9C27B0' },
                { name: '金', color: '#FFC107' },
                { name: '深緑', color: '#2E7D32' },
                { name: 'あかね', color: '#E57373' },
                { name: '藍', color: '#1976D2' },
                { name: '茶', color: '#6D4C41' },
                { name: '紺', color: '#303F9F' },
                { name: '橙', color: '#FF7043' },
                { name: '銀', color: '#9E9E9E' },
                { name: '竹', color: '#475569' },
                { name: '鶯', color: '#827717' },
                { name: '牡丹', color: '#C2185B' },
                { name: '白金', color: '#CFD8DC' },
                { name: '若竹', color: '#64748b' },
                { name: '朱', color: '#F44336' },
                { name: '瑠璃', color: '#3F51B5' },
                { name: '黄金', color: '#FFB300' },
                { name: '紅', color: '#E91E63' },
                { name: '松葉', color: '#388E3C' },
                { name: '琥珀', color: '#FF8F00' },
                { name: '青磁', color: '#00ACC1' },
                { name: '薔薇', color: '#EC407A' },
                { name: '抹茶', color: '#475569' },
                { name: '珊瑚', color: '#FF7043' },
                { name: '紫苑', color: '#7B1FA2' },
                { name: '群青', color: '#1565C0' }
            ];

            panel.innerHTML = `
                <h3 style="margin: 0 0 15px 0; color: var(--heading-color, #333); font-size: ${isMobile ? '14px' : '16px'}; font-family: var(--font-family);">アクセントカラー (30色)</h3>
                <div class="color-grid" style="display: grid; grid-template-columns: repeat(${isMobile ? '4' : '5'}, 1fr); gap: ${isMobile ? '6px' : '8px'}; margin-bottom: 16px;"></div>
                <div class="color-actions" style="display: flex; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid rgba(0, 0, 0, 0.1); flex-wrap: ${isMobile ? 'wrap' : 'nowrap'};">
                    <button class="color-save-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">保存</button>
                    <button class="color-default-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: var(--primary-color, #2196F3); color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">デフォルトに登録</button>
                    <button class="color-reset-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: #FF5722; color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">リセット</button>
                </div>
            `;

            const grid = panel.querySelector('.color-grid');
            colors.forEach(colorData => {
                const colorBtn = document.createElement('button');
                colorBtn.style.cssText = `
                    width: ${isMobile ? '40px' : '45px'};
                    height: ${isMobile ? '40px' : '45px'};
                    border-radius: 50%;
                    border: 2px solid rgba(255, 255, 255, 0.8);
                    background: ${colorData.color};
                    cursor: pointer;
                    transition: all 0.3s ease;
                `;
                colorBtn.title = colorData.name;

                colorBtn.addEventListener('click', () => {
                    document.documentElement.style.setProperty('--accent-color', colorData.color);
                    if (window.colorPicker) {
                        window.colorPicker.applyColor(colorData);
                    }
                    // メインボタンの色も更新
                    this.updateMainButtonColor();
                    
                    // 設定マネージャーに通知
                    if (window.settingsManager) {
                        window.settingsManager.updateSetting('theme.accentColor', colorData.color);
                    }
                    
                    // カスタムイベントを発火
                    document.dispatchEvent(new CustomEvent('colorChanged', {
                        detail: { color: colorData.color, property: '--accent-color' }
                    }));
                });

                colorBtn.addEventListener('mouseenter', () => {
                    colorBtn.style.transform = 'scale(1.15)';
                    colorBtn.style.borderColor = '#333';
                });

                colorBtn.addEventListener('mouseleave', () => {
                    colorBtn.style.transform = 'scale(1)';
                    colorBtn.style.borderColor = 'rgba(255, 255, 255, 0.8)';
                });

                grid.appendChild(colorBtn);
            });

            // アクションボタンのイベントハンドラー
            const saveBtn = panel.querySelector('.color-save-btn');
            const defaultBtn = panel.querySelector('.color-default-btn');
            const resetBtn = panel.querySelector('.color-reset-btn');

            saveBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.saveSettings();
                    this.showNotification('カラー設定を保存しました', 'success');
                }
            });

            defaultBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.saveAsDefault();
                    this.showNotification('現在の設定をデフォルトとして登録しました', 'success');
                }
            });

            resetBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.resetToDefault();
                    this.showNotification('デフォルト設定に戻しました', 'info');
                    // メインボタンの色も更新
                    this.updateMainButtonColor();
                }
            });

            // ホバーエフェクト
            [saveBtn, defaultBtn, resetBtn].forEach(btn => {
                btn.addEventListener('mouseenter', () => {
                    btn.style.opacity = '0.9';
                    btn.style.transform = 'scale(1.02)';
                });
                btn.addEventListener('mouseleave', () => {
                    btn.style.opacity = '1';
                    btn.style.transform = 'scale(1)';
                });
            });

            return panel;
        }

        createFontPickerPanel() {
            const panel = document.createElement('div');
            panel.className = 'floating-picker font-picker';
            
            const isMobile = window.innerWidth <= 768;
            
            panel.style.cssText = `
                background: var(--card-bg, rgba(255, 255, 255, 0.95));
                backdrop-filter: blur(15px);
                border-radius: 16px;
                padding: ${isMobile ? '15px' : '20px'};
                box-shadow: var(--box-shadow-hover, 0 8px 32px rgba(0, 0, 0, 0.15));
                border: 1px solid rgba(255, 255, 255, 0.3);
                width: ${isMobile ? 'calc(100vw - 50px)' : '350px'};
                max-width: ${isMobile ? '350px' : 'none'};
                max-height: ${isMobile ? '70vh' : '400px'};
                overflow-y: auto;
                margin-bottom: 10px;
                font-family: var(--font-family);
                color: var(--text-color);
            `;

            const fonts = [
                // ゴシック体
                { name: 'Noto Sans JP', family: '"Noto Sans JP", sans-serif', preview: '美しい日本語フォント' },
                { name: 'M PLUS 1p', family: '"M PLUS 1p", sans-serif', preview: 'モダンで読みやすい' },
                { name: 'M PLUS Rounded 1c', family: '"M PLUS Rounded 1c", sans-serif', preview: '柔らかい印象' },
                { name: 'Kosugi Maru', family: '"Kosugi Maru", sans-serif', preview: '丸みのあるゴシック' },
                { name: 'Kosugi', family: '"Kosugi", sans-serif', preview: 'シンプルなゴシック' },
                { name: 'Sawarabi Gothic', family: '"Sawarabi Gothic", sans-serif', preview: 'さわらびゴシック' },
                { name: 'Zen Kaku Gothic New', family: '"Zen Kaku Gothic New", sans-serif', preview: '禅カクゴシック' },
                { name: 'Zen Maru Gothic', family: '"Zen Maru Gothic", sans-serif', preview: '禅丸ゴシック' },
                { name: 'BIZ UDPGothic', family: '"BIZ UDPGothic", sans-serif', preview: 'ビジネス向け' },
                { name: 'IBM Plex Sans JP', family: '"IBM Plex Sans JP", sans-serif', preview: 'IBM開発フォント' },
                
                // 明朝体
                { name: 'Noto Serif JP', family: '"Noto Serif JP", serif', preview: '品格ある明朝体' },
                { name: 'Sawarabi Mincho', family: '"Sawarabi Mincho", serif' },
                { name: 'Shippori Mincho', family: '"Shippori Mincho", serif' },
                { name: 'Shippori Mincho B1', family: '"Shippori Mincho B1", serif' },
                { name: 'Klee One', family: '"Klee One", serif' },
                { name: 'BIZ UDMincho', family: '"BIZ UDMincho", serif' },
                { name: 'Zen Old Mincho', family: '"Zen Old Mincho", serif' },
                { name: 'Zen Antique', family: '"Zen Antique", serif' },
                { name: 'Zen Antique Soft', family: '"Zen Antique Soft", serif' },
                { name: 'Kaisei Opti', family: '"Kaisei Opti", serif' },
                
                // 装飾・デザイン
                { name: 'Dela Gothic One', family: '"Dela Gothic One", cursive' },
                { name: 'DotGothic16', family: '"DotGothic16", sans-serif' },
                { name: 'Hachi Maru Pop', family: '"Hachi Maru Pop", cursive' },
                { name: 'Potta One', family: '"Potta One", cursive' },
                { name: 'Reggae One', family: '"Reggae One", cursive' },
                { name: 'RocknRoll One', family: '"RocknRoll One", sans-serif' },
                { name: 'Stick', family: '"Stick", sans-serif' },
                { name: 'Train One', family: '"Train One", cursive' },
                { name: 'Yusei Magic', family: '"Yusei Magic", sans-serif' },
                { name: 'Rampart One', family: '"Rampart One", cursive' }
            ];

            panel.innerHTML = `
                <h3 style="margin: 0 0 15px 0; color: var(--heading-color, #333); font-size: ${isMobile ? '14px' : '16px'}; font-family: var(--font-family);">フォント選択 (30種類)</h3>
                <div class="font-options" style="margin-bottom: 16px;"></div>
                <div class="font-actions" style="display: flex; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid rgba(0, 0, 0, 0.1); flex-wrap: ${isMobile ? 'wrap' : 'nowrap'};">
                    <button class="font-save-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">保存</button>
                    <button class="font-default-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: var(--primary-color, #2196F3); color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">デフォルトに登録</button>
                    <button class="font-reset-btn" style="flex: 1; padding: ${isMobile ? '6px 8px' : '8px 12px'}; background: #FF5722; color: white; border: none; border-radius: 6px; font-size: ${isMobile ? '11px' : '12px'}; cursor: pointer; font-family: var(--font-family);">リセット</button>
                </div>
            `;

            const container = panel.querySelector('.font-options');
            fonts.forEach(fontData => {
                const fontBtn = document.createElement('button');
                fontBtn.style.cssText = `
                    display: block;
                    width: 100%;
                    padding: ${isMobile ? '10px 12px' : '12px 16px'};
                    margin-bottom: ${isMobile ? '6px' : '8px'};
                    border: 1px solid var(--border-color, rgba(0, 0, 0, 0.1));
                    border-radius: 8px;
                    background: var(--card-bg, rgba(255, 255, 255, 0.8));
                    color: var(--text-color);
                    text-align: left;
                    cursor: pointer;
                    font-family: ${fontData.family};
                    font-size: ${isMobile ? '13px' : '14px'};
                    transition: all 0.3s ease;
                `;
                fontBtn.textContent = `${fontData.name} - サンプルテキスト`;

                // モバイル対応: clickとtouchendの両方をサポート
                const handleFontSelection = () => {
                    // 1. CSS変数を直接設定
                    document.documentElement.style.setProperty('--font-family', fontData.family);
                    
                    // 2. 動的CSSルールを作成して最高優先度で適用
                    const styleId = 'font-override-styles';
                    let existingStyle = document.getElementById(styleId);
                    if (existingStyle) {
                        existingStyle.remove();
                    }
                    
                    const style = document.createElement('style');
                    style.id = styleId;
                    style.textContent = `
                        * { font-family: ${fontData.family} !important; }
                        body, html { font-family: ${fontData.family} !important; }
                        h1, h2, h3, h4, h5, h6 { font-family: ${fontData.family} !important; }
                        p, div, span, a, button, input, textarea, select, label { font-family: ${fontData.family} !important; }
                        .hero-title, .hero-subtitle, .section-title, .program-name, .price-amount { font-family: ${fontData.family} !important; }
                        .campaign-text, .footer-text, .nav-link { font-family: ${fontData.family} !important; }
                        
                        /* フォントピッカーのリストは除外（各ボタンは独自のフォントを保持） */
                        .font-options button { font-family: inherit !important; }
                    `;
                    document.head.appendChild(style);
                    
                    // 3. bodyタグに直接フォントを適用（強制上書き）
                    document.body.style.setProperty('font-family', fontData.family, 'important');
                    
                    // 4. 全ての要素に直接フォントを適用（フォントピッカーのボタンは除外）
                    const allElements = document.querySelectorAll('*');
                    allElements.forEach(el => {
                        if (!el.closest('.font-options')) {
                            el.style.setProperty('font-family', fontData.family, 'important');
                        }
                    });
                    
                    // 5. font-picker.jsと互換性のあるデータ形式で保存
                    const compatibleFontData = {
                        name: fontData.name,
                        family: fontData.family,
                        preview: fontData.preview || 'サンプルテキスト'
                    };
                    
                    // 6. font-picker.jsのapplyFontを呼び出し（存在する場合）
                    if (window.fontPicker && typeof window.fontPicker.applyFont === 'function') {
                        window.fontPicker.applyFont(compatibleFontData);
                    } else {
                        // font-picker.jsが利用できない場合は直接localStorage保存
                        localStorage.setItem('selected-font', JSON.stringify(compatibleFontData));
                    }
                    
                    // 7. 設定マネージャーに通知
                    if (window.settingsManager) {
                        window.settingsManager.updateSetting('theme.fontFamily', fontData.family);
                    }
                    
                    // 8. カスタムイベントを発火
                    document.dispatchEvent(new CustomEvent('fontChanged', {
                        detail: { fontFamily: fontData.family, fontData: compatibleFontData }
                    }));
                    
                    // 9. 少し遅延してから再度適用（動的コンテンツ対応、フォントピッカーは除外）
                    setTimeout(() => {
                        document.body.style.setProperty('font-family', fontData.family, 'important');
                        const newElements = document.querySelectorAll('*');
                        newElements.forEach(el => {
                            if (!el.closest('.font-options')) {
                                el.style.setProperty('font-family', fontData.family, 'important');
                            }
                        });
                        
                        // モバイル専用: レンダリング強制更新
                        if (isMobile) {
                            document.body.style.transform = 'translateZ(0)';
                            setTimeout(() => {
                                document.body.style.transform = '';
                            }, 10);
                        }
                    }, 100);
                    
                    // モバイル専用: 即座にレンダリング更新
                    if (isMobile) {
                        // フォントがロードされるまで少し待つ
                        setTimeout(() => {
                            document.body.offsetHeight; // リフロー強制実行
                            window.getComputedStyle(document.body).fontFamily; // スタイル再計算強制実行
                        }, 50);
                    }
                    
                    console.log('フォント変更:', fontData.name, fontData.family);
                    console.log('body fontFamily:', document.body.style.fontFamily);
                    console.log('強制適用完了');
                };

                // クリックイベント（デスクトップ）
                fontBtn.addEventListener('click', handleFontSelection);
                
                // タッチイベント（モバイル）
                fontBtn.addEventListener('touchend', (e) => {
                    e.preventDefault(); // デフォルトのクリックイベントを防止
                    handleFontSelection();
                });
                
                // モバイルでのダブルタップズーム防止
                if (isMobile) {
                    fontBtn.addEventListener('touchstart', (e) => {
                        e.preventDefault();
                    });
                }

                fontBtn.addEventListener('mouseenter', () => {
                    fontBtn.style.background = 'rgba(100, 116, 139, 0.2)';
                    fontBtn.style.borderColor = '#64748b';
                });

                fontBtn.addEventListener('mouseleave', () => {
                    fontBtn.style.background = 'rgba(255, 255, 255, 0.8)';
                    fontBtn.style.borderColor = 'rgba(0, 0, 0, 0.1)';
                });

                container.appendChild(fontBtn);
            });

            // アクションボタンのイベントハンドラー
            const saveBtn = panel.querySelector('.font-save-btn');
            const defaultBtn = panel.querySelector('.font-default-btn');
            const resetBtn = panel.querySelector('.font-reset-btn');

            saveBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.saveSettings();
                    this.showNotification('フォント設定を保存しました', 'success');
                }
            });

            defaultBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.saveAsDefault();
                    this.showNotification('現在の設定をデフォルトとして登録しました', 'success');
                }
            });

            resetBtn.addEventListener('click', () => {
                if (window.settingsManager) {
                    window.settingsManager.resetToDefault();
                    this.showNotification('デフォルト設定に戻しました', 'info');
                }
            });

            // ホバーエフェクト
            [saveBtn, defaultBtn, resetBtn].forEach(btn => {
                btn.addEventListener('mouseenter', () => {
                    btn.style.opacity = '0.9';
                    btn.style.transform = 'scale(1.02)';
                });
                btn.addEventListener('mouseleave', () => {
                    btn.style.opacity = '1';
                    btn.style.transform = 'scale(1)';
                });
            });

            return panel;
        }

        toggleSectionPicker() {
            const picker = this.getOrCreateSectionPicker();
            const isVisible = picker.style.display === 'block';
            
            if (isVisible) {
                this.closeSectionPicker();
            } else {
                this.closeAllPickers();
                picker.style.display = 'block';
                const container = document.getElementById('section-picker-container');
                container.style.display = 'block';
            }
        }

        closeSectionPicker() {
            const container = document.getElementById('section-picker-container');
            if (container) {
                container.style.display = 'none';
                const picker = container.querySelector('.section-picker');
                if (picker) {
                    picker.style.display = 'none';
                }
            }
        }

        getOrCreateSectionPicker() {
            const container = document.getElementById('section-picker-container');
            let picker = container.querySelector('.section-picker');
            
            if (!picker) {
                picker = this.createSectionPickerPanel();
                container.appendChild(picker);
            }
            
            return picker;
        }

        createSectionPickerPanel() {
            const panel = document.createElement('div');
            panel.className = 'floating-picker section-picker';
            panel.style.cssText = `
                background: rgba(255, 255, 255, 0.95);
                backdrop-filter: blur(15px);
                border-radius: 16px;
                padding: 20px;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15);
                border: 1px solid rgba(255, 255, 255, 0.3);
                width: 300px;
                max-height: 400px;
                overflow-y: auto;
                margin-bottom: 10px;
            `;

            // セクションを検出
            const sections = this.detectSections();
            
            panel.innerHTML = `
                <h3 style="margin: 0 0 15px 0; color: #333; font-size: 16px;">セクション選択 (${sections.length}個)</h3>
                <div class="section-options"></div>
            `;

            const container = panel.querySelector('.section-options');
            sections.forEach(sectionData => {
                const sectionBtn = document.createElement('button');
                sectionBtn.style.cssText = `
                    display: block;
                    width: 100%;
                    padding: 12px 16px;
                    margin-bottom: 8px;
                    border: 1px solid rgba(0, 0, 0, 0.1);
                    border-radius: 8px;
                    background: rgba(255, 255, 255, 0.8);
                    text-align: left;
                    cursor: pointer;
                    font-size: 14px;
                    transition: all 0.3s ease;
                `;
                sectionBtn.textContent = `${sectionData.displayName} (${sectionData.id})`;

                sectionBtn.addEventListener('click', () => {
                    this.selectSection(sectionData);
                    this.closeSectionPicker();
                });

                sectionBtn.addEventListener('mouseenter', () => {
                    const accentColor = getComputedStyle(document.documentElement).getPropertyValue('--accent-color').trim() || '#64748b';
                    sectionBtn.style.background = `${accentColor}20`;
                    sectionBtn.style.borderColor = accentColor;
                });

                sectionBtn.addEventListener('mouseleave', () => {
                    sectionBtn.style.background = 'rgba(255, 255, 255, 0.8)';
                    sectionBtn.style.borderColor = 'rgba(0, 0, 0, 0.1)';
                });

                container.appendChild(sectionBtn);
            });

            return panel;
        }

        detectSections() {
            const sections = [];
            const addedSectionIds = new Set(); // 重複チェック用
            
            // 複数の方法でセクションを検出
            console.log('🔍 セクション検出開始');
            
            // 方法1: [id$="-component"] セレクタを優先
            const componentElements = document.querySelectorAll('[id$="-component"]');
            console.log('📋 -component要素:', componentElements.length, '個');
            
            const sectionNames = {
                'header': 'ヘッダー',
                'hero': 'ヒーロー', 
                'about': 'スタジオ紹介',
                'programs': 'プログラム',
                'schedule': 'スケジュール',
                'access': 'アクセス',
                'footer': 'フッター'
            };

            // -component要素を優先的に処理
            componentElements.forEach(element => {
                const sectionId = element.id.replace('-component', '');
                const displayName = sectionNames[sectionId] || sectionId;
                
                if (!addedSectionIds.has(sectionId)) {
                    sections.push({
                        id: sectionId,
                        displayName: displayName,
                        element: element
                    });
                    addedSectionIds.add(sectionId);
                    
                    console.log('➕ セクション追加:', {
                        id: sectionId,
                        displayName: displayName,
                        elementId: element.id
                    });
                }
            });
            
            // 方法2: -componentが見つからない場合のフォールバック
            if (sections.length === 0) {
                // セクションタグとクラス名で検索
                const fallbackElements = document.querySelectorAll('section, .hero, .about, .programs, .schedule, .access, header, footer');
                console.log('📋 フォールバック要素:', fallbackElements.length, '個');
                
                fallbackElements.forEach(element => {
                    let sectionId = '';
                    
                    // IDから判定
                    if (element.id) {
                        sectionId = element.id.replace('-section', '').replace('section-', '');
                    }
                    
                    // クラス名から判定
                    if (!sectionId && element.className) {
                        const classList = element.className.toLowerCase();
                        if (classList.includes('hero')) sectionId = 'hero';
                        else if (classList.includes('about')) sectionId = 'about';
                        else if (classList.includes('program')) sectionId = 'programs';
                        else if (classList.includes('schedule')) sectionId = 'schedule';
                        else if (classList.includes('access')) sectionId = 'access';
                    }
                    
                    // タグ名から判定
                    if (!sectionId) {
                        if (element.tagName.toLowerCase() === 'header') sectionId = 'header';
                        else if (element.tagName.toLowerCase() === 'footer') sectionId = 'footer';
                    }
                    
                    if (sectionId && !addedSectionIds.has(sectionId)) {
                        const displayName = sectionNames[sectionId] || sectionId;
                        sections.push({
                            id: sectionId,
                            displayName: displayName,
                            element: element
                        });
                        addedSectionIds.add(sectionId);
                        
                        console.log('➕ フォールバックセクション追加:', {
                            id: sectionId,
                            displayName: displayName
                        });
                    }
                });
            }

            console.log('✅ 検出完了:', sections.length, '個のセクション（重複除外済み）');
            return sections;
        }

        selectSection(sectionData) {
            // 前回選択されたセクションのハイライトを削除
            this.clearSectionHighlight();
            
            // 新しいセクションを選択
            this.selectedSection = sectionData;
            
            // セクションピッカーを閉じる
            this.closeSectionPicker();
            
            // セクションにスクロール
            this.scrollToSection(sectionData.element);
            
            // セクションをハイライト
            this.highlightSection(sectionData.element);
            
            // カスタムイベントを発火（SectionClickEditor用）
            console.log('🚀 sectionSelectedイベント発火準備');
            console.log('選択されたセクション:', {
                id: sectionData.id,
                displayName: sectionData.displayName,
                element: sectionData.element,
                tagName: sectionData.element.tagName,
                className: sectionData.element.className
            });
            
            const event = new CustomEvent('sectionSelected', {
                detail: { section: sectionData.element }
            });
            document.dispatchEvent(event);
            console.log('✅ sectionSelectedイベント発火完了');
            
            // UniversalEditorに通知（存在する場合）
            console.log('セクション選択完了 - UniversalEditorに通知');
            console.log('window.universalEditor:', !!window.universalEditor);
            if (window.universalEditor) {
                console.log('UniversalEditor.editSection()を呼び出します');
                window.universalEditor.editSection(sectionData.element);
            } else {
                console.error('window.universalEditorが存在しません');
            }
        }

        scrollToSection(element) {
            const headerHeight = document.querySelector('.site-header')?.offsetHeight || 0;
            const targetPosition = element.offsetTop - headerHeight - 20;
            
            window.scrollTo({
                top: targetPosition,
                behavior: 'smooth'
            });
        }

        highlightSection(element) {
            element.style.setProperty('outline', '3px solid var(--accent-color, #64748b)', 'important');
            element.style.setProperty('outline-offset', '4px', 'important');
            element.style.setProperty('background-color', 'rgba(var(--accent-color-rgb, 139, 195, 74), 0.1)', 'important');
            element.style.setProperty('position', 'relative', 'important');
            element.style.setProperty('z-index', '9999', 'important');
            
            // 選択インジケーターを追加
            const indicator = document.createElement('div');
            indicator.className = 'section-selected-indicator';
            indicator.textContent = `✓ 選択中: ${this.selectedSection.displayName}`;
            indicator.style.cssText = `
                position: absolute;
                top: -35px;
                left: 10px;
                background: var(--accent-color, #64748b);
                color: white;
                padding: 6px 16px;
                border-radius: 6px;
                font-size: 13px;
                font-weight: bold;
                z-index: 99999;
                box-shadow: 0 2px 6px rgba(0,0,0,0.3);
                border: 1px solid white;
            `;
            
            element.appendChild(indicator);
        }

        clearSectionHighlight() {
            if (this.selectedSection) {
                const element = this.selectedSection.element;
                element.style.removeProperty('outline');
                element.style.removeProperty('outline-offset');
                element.style.removeProperty('background-color');
                element.style.removeProperty('position');
                element.style.removeProperty('z-index');
                
                // インジケーターを削除
                const indicator = element.querySelector('.section-selected-indicator');
                if (indicator) {
                    indicator.remove();
                }
                
                // セクション選択解除イベントを発火
                document.dispatchEvent(new CustomEvent('sectionDeselected'));
            }
        }

        /**
         * 編集モードを開始
         */
        startEditMode() {
            this.isEditMode = true;
            const editButton = document.getElementById('floating-edit-btn');
            if (editButton) {
                editButton.textContent = '編集終了';
                editButton.style.background = 'linear-gradient(135deg, #FF5722, #E64A19)';
                editButton.style.color = 'white';
                editButton.style.border = '1px solid #FF5722';
            }
        }

        /**
         * 直接編集モードを開始
         */
        startDirectEditMode() {
            console.log('直接編集モードを開始します');
            
            // 編集モード状態を設定
            this.isEditMode = true;
            
            // 編集ボタンの表示を更新
            const editButton = document.getElementById('floating-edit-btn');
            if (editButton) {
                editButton.textContent = '編集終了';
                editButton.style.background = 'linear-gradient(135deg, #FF5722, #E64A19)';
                editButton.style.color = 'white';
                editButton.style.border = '1px solid #FF5722';
            }
            
            // セクション境界とラベルを表示
            this.showSectionBoundaries();
            
            // SectionClickEditorを全体で有効化
            if (window.sectionClickEditor) {
                window.sectionClickEditor.activateGlobal();
            }
            
            // 通知を表示
            this.showNotification('全体編集モードが開始されました。要素をクリックして編集できます。', 'success');
        }

        /**
         * 編集モードを終了
         */
        endEditMode() {
            console.log('編集終了ボタンが押されました');
            
            // 編集ボタンの状態を戻す
            this.isEditMode = false;
            const editButton = document.getElementById('floating-edit-btn');
            if (editButton) {
                editButton.textContent = '編集';
                editButton.style.background = 'rgba(255, 255, 255, 0.9)';
                editButton.style.color = '#333';
                editButton.style.border = '1px solid rgba(255, 255, 255, 0.3)';
            }
            
            // セクション境界表示を削除
            this.hideSectionBoundaries();
            
            // SectionClickEditorを無効化
            if (window.sectionClickEditor) {
                window.sectionClickEditor.deactivate();
            }
            
            // 通知を表示
            this.showNotification('編集モードを終了しました。', 'info');
        }

        /**
         * セクション境界とラベルを表示
         */
        showSectionBoundaries() {
            // 既存の境界表示があれば削除
            this.hideSectionBoundaries();
            
            const sections = this.detectSections();
            
            sections.forEach(sectionData => {
                const element = sectionData.element;
                
                // セクション境界のスタイルを追加
                element.style.setProperty('outline', '2px dashed var(--accent-color, #64748b)', 'important');
                element.style.setProperty('outline-offset', '4px', 'important');
                element.style.setProperty('position', 'relative', 'important');
                
                // セクションラベルを作成
                const label = document.createElement('div');
                label.className = 'section-boundary-label';
                label.textContent = sectionData.displayName;
                label.style.cssText = `
                    position: absolute;
                    top: -25px;
                    left: 10px;
                    background: var(--accent-color, #64748b);
                    color: white;
                    padding: 4px 12px;
                    border-radius: 4px;
                    font-size: 12px;
                    font-weight: 600;
                    z-index: 99999;
                    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
                    font-family: var(--font-family, sans-serif);
                    pointer-events: none;
                `;
                
                element.appendChild(label);
            });
            
            console.log(`${sections.length}個のセクション境界を表示しました`);
        }

        /**
         * セクション境界とラベルを非表示
         */
        hideSectionBoundaries() {
            // セクション境界のスタイルを削除
            const elementsWithOutline = document.querySelectorAll('[style*="outline"]');
            elementsWithOutline.forEach(element => {
                element.style.removeProperty('outline');
                element.style.removeProperty('outline-offset');
            });
            
            // セクションラベルを削除
            const labels = document.querySelectorAll('.section-boundary-label');
            labels.forEach(label => label.remove());
            
            console.log('セクション境界表示を削除しました');
        }

        /**
         * 保存メニューを強制表示
         */
        showSaveMenu() {
            console.log('保存メニューを強制表示します');
            
            // 既存の保存メニューがあれば削除
            const existingMenu = document.querySelector('.save-menu-overlay');
            if (existingMenu) {
                existingMenu.remove();
            }
            
            // 保存メニューオーバーレイを作成
            const overlay = document.createElement('div');
            overlay.className = 'save-menu-overlay';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.5);
                z-index: 100010;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            
            // 保存メニューパネル
            const panel = document.createElement('div');
            panel.className = 'save-menu-panel';
            panel.style.cssText = `
                background: white;
                border-radius: 16px;
                padding: 30px;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
                width: 400px;
                max-width: 90vw;
            `;
            
            panel.innerHTML = `
                <h2 style="margin: 0 0 20px 0; font-size: 20px; color: #333; text-align: center;">編集内容の保存</h2>
                <div style="display: flex; flex-direction: column; gap: 12px;">
                    <button class="save-btn" style="padding: 12px 20px; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 8px; font-size: 14px; cursor: pointer; font-weight: 500;">編集内容を保存</button>
                    <button class="save-default-btn" style="padding: 12px 20px; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 8px; font-size: 14px; cursor: pointer; font-weight: 500; opacity: 0.8;">デフォルトとして保存</button>
                    <button class="reset-default-btn" style="padding: 12px 20px; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 8px; font-size: 14px; cursor: pointer; font-weight: 500; opacity: 0.7;">デフォルトに戻す</button>
                    <button class="reset-colors-btn" style="padding: 12px 20px; background: var(--accent-color, #64748b); color: white; border: none; border-radius: 8px; font-size: 14px; cursor: pointer; font-weight: 500; opacity: 0.6;">色設定をリセット</button>
                    <div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid #eee;">
                        <button class="close-btn" style="padding: 12px 20px; background: #666; color: white; border: none; border-radius: 8px; font-size: 14px; cursor: pointer; font-weight: 500; width: 100%;">保存せずに閉じる（キャンセル）</button>
                    </div>
                </div>
            `;
            
            overlay.appendChild(panel);
            document.body.appendChild(overlay);
            
            // イベントハンドラー
            const saveBtn = panel.querySelector('.save-btn');
            const saveDefaultBtn = panel.querySelector('.save-default-btn');
            const resetDefaultBtn = panel.querySelector('.reset-default-btn');
            const resetColorsBtn = panel.querySelector('.reset-colors-btn');
            const closeBtn = panel.querySelector('.close-btn');
            
            let saveClicked = false;
            saveBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                
                if (saveClicked) {
                    console.log('保存ボタン重複クリック防止');
                    return;
                }
                saveClicked = true;
                
                console.log('保存ボタンクリック - 保存処理開始');
                saveBtn.disabled = true;
                saveBtn.textContent = '保存中...';
                
                // 直接localStorageに保存をテスト
                try {
                    const testData = {
                        timestamp: new Date().toISOString(),
                        editCount: Math.random()
                    };
                    localStorage.setItem('test_save', JSON.stringify(testData));
                    console.log('直接localStorage保存テスト成功:', testData);
                } catch (error) {
                    console.error('localStorage保存テストエラー:', error);
                }
                
                if (window.elementEditManager) {
                    try {
                        console.log('ElementEditManagerの状態:', {
                            exists: !!window.elementEditManager,
                            editedElementsSize: window.elementEditManager.editedElements.size,
                            storageKey: window.elementEditManager.STORAGE_KEY
                        });
                        
                        window.elementEditManager.getControlButtons().save();
                        console.log('ElementEditManager.save()実行完了');
                        this.showNotification('✓ 編集内容を保存しました', 'success');
                    } catch (error) {
                        console.error('保存処理エラー:', error);
                        this.showNotification('保存に失敗しました', 'error');
                    }
                } else {
                    console.warn('ElementEditManagerが見つかりません');
                    this.showNotification('保存機能が利用できません', 'error');
                }
                
                this.closeModal(overlay);
            });
            
            saveDefaultBtn.addEventListener('click', () => {
                console.log('デフォルト保存ボタンクリック');
                if (window.elementEditManager) {
                    try {
                        window.elementEditManager.getControlButtons().saveAsDefault();
                        this.showNotification('✓ デフォルトとして保存しました', 'success');
                    } catch (error) {
                        console.error('デフォルト保存エラー:', error);
                        this.showNotification('デフォルト保存に失敗しました', 'error');
                    }
                }
                this.closeModal(overlay);
            });
            
            resetDefaultBtn.addEventListener('click', () => {
                console.log('デフォルトリセットボタンクリック');
                if (window.elementEditManager) {
                    try {
                        window.elementEditManager.getControlButtons().resetToDefault();
                        this.showNotification('✓ デフォルトに戻しました', 'info');
                    } catch (error) {
                        console.error('デフォルトリセットエラー:', error);
                        this.showNotification('リセットに失敗しました', 'error');
                    }
                }
                this.closeModal(overlay);
            });
            
            resetColorsBtn.addEventListener('click', () => {
                console.log('色設定リセットボタンクリック');
                if (window.elementEditManager) {
                    try {
                        window.elementEditManager.getControlButtons().resetColors();
                        this.showNotification('✓ 色設定をリセットしました', 'info');
                    } catch (error) {
                        console.error('色設定リセットエラー:', error);
                        this.showNotification('色設定リセットに失敗しました', 'error');
                    }
                }
                this.closeModal(overlay);
            });
            
            closeBtn.addEventListener('click', (e) => {
                e.preventDefault();
                e.stopPropagation();
                console.log('キャンセルボタンクリック');
                this.closeModal(overlay);
                this.showNotification('編集をキャンセルしました', 'info');
            });
            
            // オーバーレイクリックで閉じる（1回のみ実行）
            let overlayClicked = false;
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay && !overlayClicked) {
                    overlayClicked = true;
                    console.log('オーバーレイクリックで閉じました');
                    this.closeModal(overlay);
                    this.showNotification('編集をキャンセルしました', 'info');
                }
            });
        }

        /**
         * モーダルを確実に閉じる
         */
        closeModal(overlay) {
            console.log('closeModal実行開始 - 全編集モード終了');
            console.log('overlay:', overlay);
            
            // 既に削除済みかチェック
            if (overlay && !overlay.parentNode) {
                console.log('オーバーレイは既に削除済み');
                return;
            }
            
            // 保存メニューオーバーレイを削除
            if (overlay && overlay.parentNode) {
                overlay.parentNode.removeChild(overlay);
                console.log('保存メニューoverlay削除完了');
            }
            
            // クラス名でも検索して削除
            const saveMenuOverlays = document.querySelectorAll('.save-menu-overlay');
            saveMenuOverlays.forEach(el => {
                if (el.parentNode) {
                    el.remove();
                    console.log('save-menu-overlay削除:', el);
                }
            });
            
            // UniversalEditorを終了
            if (window.universalEditor && window.universalEditor.isActive) {
                window.universalEditor.closeEditor();
                console.log('UniversalEditor終了完了');
            }
            
            // SectionClickEditorを無効化
            if (window.sectionClickEditor && window.sectionClickEditor.isActive) {
                window.sectionClickEditor.deactivate();
                console.log('SectionClickEditor無効化完了');
            }
            
            // セクションハイライトをクリア
            if (this.selectedSection) {
                this.clearSectionHighlight();
                console.log('セクションハイライトクリア完了');
            }
            
            // 既存のセクション編集オーバーレイも削除
            const editOverlays = document.querySelectorAll('.section-edit-overlay');
            editOverlays.forEach(el => {
                el.remove();
                console.log('編集オーバーレイ削除:', el);
            });
            
            // 全体的なスタイルリセット
            document.querySelectorAll('[style*="outline"]').forEach(el => {
                el.style.outline = '';
                el.style.outlineOffset = '';
                el.style.position = '';
                el.style.zIndex = '';
            });
            
            // 編集ボタンの状態をリセット
            this.isEditMode = false;
            this.selectedSection = null;
            const editButton = document.getElementById('floating-edit-btn');
            if (editButton) {
                editButton.textContent = '編集';
                editButton.style.background = 'rgba(255, 255, 255, 0.9)';
                editButton.style.color = '#333';
                editButton.style.border = '1px solid rgba(255, 255, 255, 0.3)';
                console.log('編集ボタンの状態をリセット完了');
            }
            
            console.log('closeModal実行完了 - 全編集モード正常終了');
        }

        /**
         * ビルドプロセスを開始
         */
        startBuild() {
            if (window.buildManager) {
                window.buildManager.startBuild();
            } else {
                this.showNotification('ビルド機能が利用できません', 'error');
            }
        }

        /**
         * ビルド完了時の処理
         */
        onBuildComplete() {
            console.log('ビルド完了通知を受信');
            
            // distフォルダの存在確認
            this.checkDistFolder().then(exists => {
                if (exists) {
                    // ビルド後ページボタンを表示
                    const buildPageButton = document.getElementById('floating-build-page-btn');
                    if (buildPageButton) {
                        buildPageButton.style.display = 'block';
                        // アニメーション付きで表示
                        buildPageButton.style.animation = 'fadeIn 0.3s ease';
                    }
                } else {
                    console.warn('distフォルダが見つかりません');
                }
            });
        }

        /**
         * distフォルダの存在確認
         */
        async checkDistFolder() {
            try {
                const response = await fetch('api/check-dist', {
                    method: 'GET',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });
                
                const result = await response.json();
                return result.exists;
            } catch (error) {
                console.error('distフォルダ確認エラー:', error);
                return false;
            }
        }

        /**
         * テスト用：強制的に全てのモーダルを閉じる
         */
        forceCloseAllModals() {
            // 全ての保存メニューオーバーレイを削除
            document.querySelectorAll('.save-menu-overlay').forEach(el => el.remove());
            // 全てのセクション編集オーバーレイを削除  
            document.querySelectorAll('.section-edit-overlay').forEach(el => el.remove());
            // セクションハイライトをクリア
            this.clearSectionHighlight();
            console.log('全てのモーダルを強制削除しました');
        }

        /**
         * 通知を表示
         */
        showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                padding: 12px 20px;
                background: ${type === 'success' ? '#64748b' : type === 'error' ? '#f44336' : '#2196F3'};
                color: white;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                font-size: 14px;
                z-index: 100001;
                animation: slideIn 0.3s ease;
            `;
            notification.textContent = message;

            // アニメーション用のスタイルが既にあるかチェック
            if (!document.getElementById('notification-animations')) {
                const style = document.createElement('style');
                style.id = 'notification-animations';
                style.textContent = `
                    @keyframes slideIn {
                        from {
                            transform: translateX(100%);
                            opacity: 0;
                        }
                        to {
                            transform: translateX(0);
                            opacity: 1;
                        }
                    }
                    @keyframes fadeIn {
                        from {
                            opacity: 0;
                        }
                        to {
                            opacity: 1;
                        }
                    }
                `;
                document.head.appendChild(style);
            }

            document.body.appendChild(notification);

            // 3秒後に自動削除
            setTimeout(() => {
                notification.style.animation = 'slideIn 0.3s ease reverse';
                setTimeout(() => {
                    notification.remove();
                }, 300);
            }, 3000);
        }
    }

    // 初期化
    document.addEventListener('DOMContentLoaded', () => {
        window.floatingControls = new FloatingControls();
    });

    // ComponentLoader完了後にも初期化（念のため）
    document.addEventListener('componentsLoaded', () => {
        if (!document.getElementById('floating-controls')) {
            window.floatingControls = new FloatingControls();
        }
    });

})();