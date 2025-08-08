(function() {
    'use strict';

    class QuickEditMenu {
        constructor(element, analysis, options) {
            console.log('QuickEditMenu v2025-07-21: 現代的なタブベースのインターフェースを初期化中', { element, analysis, options });
            this.element = element;
            this.analysis = analysis;
            this.options = options || {};
            this.menu = null;
            this.isEditing = false;
            
            // 既存のクイック編集メニューがあれば削除
            this.closeExistingMenus();
            
            this.create();
            this.show();
        }
        
        /**
         * 既存のクイック編集メニューを削除
         */
        closeExistingMenus() {
            const existingMenus = document.querySelectorAll('.quick-edit-menu');
            existingMenus.forEach(menu => menu.remove());
        }

        /**
         * メニューを作成
         */
        create() {
            this.menu = document.createElement('div');
            this.menu.className = 'quick-edit-menu';
            
            // モバイル判定
            const isMobile = window.innerWidth <= 768;
            
            this.menu.style.cssText = `
                position: fixed;
                background: #ffffff;
                border: none;
                border-radius: ${isMobile ? '12px' : '16px'};
                padding: 0;
                box-shadow: 0 4px 24px rgba(0, 0, 0, 0.12), 0 0 1px rgba(0, 0, 0, 0.08);
                z-index: 10002;
                min-width: ${isMobile ? 'auto' : '420px'};
                max-width: ${isMobile ? 'calc(100vw - 20px)' : '520px'};
                width: ${isMobile ? 'calc(100vw - 20px)' : 'auto'};
                animation: quickEditSlideIn 0.2s ease;
                box-sizing: border-box;
                overflow: hidden;
            `;

            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = `
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: ${isMobile ? '16px' : '20px'};
                background: linear-gradient(180deg, #fafafa 0%, #f5f5f5 100%);
                border-bottom: 1px solid rgba(0, 0, 0, 0.08);
            `;

            const title = document.createElement('span');
            title.textContent = 'クイック編集';
            title.style.cssText = `
                font-size: ${isMobile ? '15px' : '16px'}; 
                font-weight: 600; 
                color: #1a1a1a; 
                flex: 1;
                letter-spacing: 0.02em;
            `;

            const closeBtn = document.createElement('button');
            closeBtn.innerHTML = '×';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: ${isMobile ? '22px' : '26px'};
                color: #666;
                cursor: pointer;
                padding: 0;
                width: ${isMobile ? '28px' : '32px'};
                height: ${isMobile ? '28px' : '32px'};
                display: flex;
                align-items: center;
                justify-content: center;
                border-radius: 6px;
                transition: all 0.2s ease;
                flex-shrink: 0;
                line-height: 1;
            `;
            closeBtn.onmouseover = () => {
                closeBtn.style.background = 'rgba(0, 0, 0, 0.06)';
                closeBtn.style.color = '#333';
            };
            closeBtn.onmouseout = () => {
                closeBtn.style.background = 'none';
                closeBtn.style.color = '#666';
            };
            closeBtn.onclick = () => this.close();

            header.appendChild(title);
            header.appendChild(closeBtn);
            this.menu.appendChild(header);

            // タブコンテナ
            const tabContainer = document.createElement('div');
            tabContainer.style.cssText = 'display: flex; flex-direction: column; height: 100%;';
            
            // タブヘッダー
            const tabHeader = document.createElement('div');
            tabHeader.style.cssText = `
                display: flex;
                background: #f8f8f8;
                border-bottom: 1px solid #e0e0e0;
                padding: 0 ${isMobile ? '12px' : '16px'};
                overflow-x: auto;
                -webkit-overflow-scrolling: touch;
                scrollbar-width: thin;
            `;
            
            // タブコンテンツエリア
            const tabContent = document.createElement('div');
            tabContent.style.cssText = `
                flex: 1;
                padding: ${isMobile ? '16px' : '20px'};
                overflow-y: auto;
                max-height: ${isMobile ? '50vh' : '400px'};
                scrollbar-width: thin;
            `;
            
            // タブデータを整理
            const tabData = this.organizeTabData();
            const tabs = [];
            const panels = [];
            
            // タブとパネルを作成
            Object.entries(tabData).forEach(([tabKey, tabInfo], index) => {
                // タブボタン
                const tab = document.createElement('button');
                tab.textContent = tabInfo.label;
                tab.style.cssText = `
                    background: none;
                    border: none;
                    padding: ${isMobile ? '10px 16px' : '12px 20px'};
                    font-size: ${isMobile ? '13px' : '14px'};
                    color: #666;
                    cursor: pointer;
                    border-bottom: 2px solid transparent;
                    transition: all 0.2s ease;
                    white-space: nowrap;
                    font-weight: 500;
                `;
                
                // パネル
                const panel = document.createElement('div');
                panel.style.cssText = `
                    display: ${index === 0 ? 'flex' : 'none'};
                    flex-direction: column;
                    gap: 16px;
                    animation: fadeIn 0.2s ease;
                `;
                panel.dataset.tabKey = tabKey; // タブキーを記録
                
                // 初期状態で最初のタブを選択
                if (index === 0) {
                    tab.style.color = '#2196F3';
                    tab.style.borderBottomColor = '#2196F3';
                    tab.style.fontWeight = '600';
                }
                
                // タブクリックイベント
                tab.onclick = () => this.switchTab(tabKey, tabs, panels);
                
                // フィールドをパネルに追加
                if (tabKey === 'edit') {
                    // 編集タブの特別なコンテンツ
                    this.createEditTabContent(panel);
                } else if (tabKey === 'ai') {
                    // AIタブの特別なコンテンツ
                    this.createAITabContent(panel);
                } else if (tabKey === 'history') {
                    // 履歴タブの特別なコンテンツ
                    this.createHistoryTabContent(panel);
                } else {
                    tabInfo.items.forEach(item => {
                        const field = this.createEditField(item);
                        panel.appendChild(field);
                    });
                }
                
                tabs.push({ key: tabKey, element: tab });
                panels.push({ key: tabKey, element: panel });
                
                tabHeader.appendChild(tab);
                tabContent.appendChild(panel);
            });
            
            tabContainer.appendChild(tabHeader);
            tabContainer.appendChild(tabContent);
            this.menu.appendChild(tabContainer);
            
            // タブ情報を保存
            this.tabs = tabs;
            this.panels = panels;

            // フッターエリア
            const footer = document.createElement('div');
            footer.style.cssText = `
                padding: ${isMobile ? '12px 16px' : '16px 20px'};
                background: #fafafa;
                border-top: 1px solid #e0e0e0;
                display: flex;
                flex-direction: column;
                gap: 12px;
            `;
            
            // 自動保存トグル
            const autoSaveContainer = document.createElement('div');
            autoSaveContainer.style.cssText = `
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding: ${isMobile ? '8px 12px' : '10px 16px'};
                background: #f0f0f0;
                border-radius: 8px;
                min-height: 40px;
                border: 1px solid #e0e0e0;
            `;
            
            // 左側：自動保存アイコンとステータス
            const leftSection = document.createElement('div');
            leftSection.style.cssText = `
                display: flex;
                align-items: center;
                gap: 8px;
                flex: 1;
            `;
            
            const autoSaveButton = document.createElement('button');
            autoSaveButton.style.cssText = `
                background: none;
                border: none;
                cursor: pointer;
                display: flex;
                align-items: center;
                gap: 6px;
                padding: 4px;
                border-radius: 4px;
                transition: background-color 0.2s;
            `;
            
            const autoSaveCheckbox = document.createElement('input');
            autoSaveCheckbox.type = 'checkbox';
            autoSaveCheckbox.checked = window.elementEditManager?.autoSaveEnabled ?? true;
            autoSaveCheckbox.style.cssText = `
                display: none;
            `;
            
            const autoSaveIcon = document.createElement('span');
            autoSaveIcon.style.cssText = `
                font-size: 18px;
                color: ${autoSaveCheckbox.checked ? '#64748b' : '#888'};
                line-height: 1;
            `;
            autoSaveIcon.textContent = autoSaveCheckbox.checked ? '✓' : '○';
            
            const autoSaveStatus = document.createElement('span');
            autoSaveStatus.style.cssText = `
                font-size: ${isMobile ? '11px' : '12px'};
                color: ${autoSaveCheckbox.checked ? '#64748b' : '#888'};
                font-weight: 500;
                min-width: 28px;
            `;
            autoSaveStatus.textContent = autoSaveCheckbox.checked ? '有効' : '無効';
            
            // 右側：戻るアイコンと編集アイコン
            const rightSection = document.createElement('div');
            rightSection.style.cssText = `
                display: flex;
                align-items: center;
                gap: 12px;
            `;
            
            const undoButton = document.createElement('button');
            undoButton.style.cssText = `
                background: none;
                border: none;
                cursor: pointer;
                font-size: 18px;
                color: #666;
                padding: 6px;
                border-radius: 6px;
                transition: all 0.2s;
                line-height: 1;
                min-width: 28px;
                height: 28px;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            undoButton.textContent = '↶';
            undoButton.title = 'やり直し';
            
            const saveButton = document.createElement('button');
            saveButton.style.cssText = `
                background: none;
                border: none;
                cursor: pointer;
                font-size: 16px;
                color: #666;
                padding: 6px;
                border-radius: 6px;
                transition: all 0.2s;
                line-height: 1;
                min-width: 28px;
                height: 28px;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            saveButton.textContent = '💾';
            saveButton.title = '保存メニュー';
            
            const editButton = document.createElement('button');
            editButton.style.cssText = `
                background: none;
                border: none;
                cursor: pointer;
                font-size: 16px;
                color: #666;
                padding: 6px;
                border-radius: 6px;
                transition: all 0.2s;
                line-height: 1;
                min-width: 28px;
                height: 28px;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            editButton.textContent = '✎';
            editButton.title = '詳細編集';
            
            // イベントハンドラー
            autoSaveButton.addEventListener('click', () => {
                autoSaveCheckbox.checked = !autoSaveCheckbox.checked;
                if (window.elementEditManager) {
                    const isEnabled = window.elementEditManager.toggleAutoSave();
                    autoSaveStatus.textContent = isEnabled ? '有効' : '無効';
                    autoSaveStatus.style.color = isEnabled ? '#64748b' : '#888';
                    autoSaveIcon.textContent = isEnabled ? '✓' : '○';
                    autoSaveIcon.style.color = isEnabled ? '#64748b' : '#888';
                } else {
                    console.error('ElementEditManagerが初期化されていません');
                    autoSaveCheckbox.checked = false;
                    autoSaveStatus.textContent = '利用不可';
                    autoSaveStatus.style.color = '#f44336';
                    autoSaveIcon.textContent = '✗';
                    autoSaveIcon.style.color = '#f44336';
                }
            });
            
            undoButton.addEventListener('click', () => {
                // やり直し機能の実装
                this.handleUndo();
            });
            
            saveButton.addEventListener('click', () => {
                // 保存メニューを開く
                console.log('保存メニューボタンクリック（ヘッダー）');
                this.openSaveMenu();
            });
            
            editButton.addEventListener('click', () => {
                // 詳細編集を開く
                this.openDetailedEdit();
            });
            
            // ホバーエフェクト
            [autoSaveButton, undoButton, saveButton, editButton].forEach(btn => {
                btn.addEventListener('mouseenter', () => {
                    btn.style.backgroundColor = 'rgba(0,0,0,0.1)';
                });
                btn.addEventListener('mouseleave', () => {
                    btn.style.backgroundColor = 'transparent';
                });
            });
            
            // DOM構造の構築
            leftSection.appendChild(autoSaveButton);
            autoSaveButton.appendChild(autoSaveIcon);
            autoSaveButton.appendChild(autoSaveStatus);
            
            rightSection.appendChild(undoButton);
            rightSection.appendChild(saveButton);
            rightSection.appendChild(editButton);
            
            autoSaveContainer.appendChild(leftSection);
            autoSaveContainer.appendChild(rightSection);
            footer.appendChild(autoSaveContainer);
            
            // ヘッダーのコンパクトアイコンで機能を提供するため、従来の大きなボタンは削除
            this.menu.appendChild(footer);

            // アニメーションスタイル
            this.addAnimationStyles();
        }

        /**
         * 編集フィールドを作成
         */
        createEditField(item) {
            const field = document.createElement('div');
            field.style.cssText = 'display: flex; flex-direction: column; gap: 8px;';

            const label = document.createElement('label');
            label.textContent = item.label;
            label.style.cssText = 'font-size: 14px; color: #333; font-weight: 600;';
            field.appendChild(label);

            let input;

            switch (item.type) {
                case 'text':
                    input = this.createTextInput(item);
                    break;
                case 'color':
                    input = this.createColorInput(item);
                    break;
                case 'size':
                    input = this.createSizeInput(item);
                    break;
                case 'icon':
                    input = this.createIconInput(item);
                    break;
                case 'image':
                    input = this.createImageInput(item);
                    break;
                case 'background':
                    input = this.createBackgroundInput(item);
                    break;
                case 'link':
                    input = this.createUrlInput(item);
                    break;
                default:
                    input = this.createTextInput(item);
            }

            field.appendChild(input);
            return field;
        }

        /**
         * テキスト入力を作成
         */
        createTextInput(item) {
            const input = document.createElement('input');
            input.type = 'text';
            input.value = item.value;
            
            const isMobile = window.innerWidth <= 768;
            
            input.style.cssText = `
                padding: ${isMobile ? '10px 14px' : '12px 16px'};
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                font-size: ${isMobile ? '14px' : '16px'};
                background: white;
                width: 100%;
                box-sizing: border-box;
                color: #333;
                transition: all 0.2s ease;
                outline: none;
                pointer-events: auto !important;
                position: relative;
                z-index: 1;
            `;

            input.onfocus = () => {
                input.style.borderColor = '#2196F3';
                input.style.boxShadow = '0 0 0 3px rgba(33, 150, 243, 0.1)';
                input.style.background = '#ffffff';
                console.log('テキスト入力フォーカス:', item.property, item.value);
            };

            input.onblur = () => {
                input.style.borderColor = 'rgba(0, 0, 0, 0.15)';
                input.style.boxShadow = 'none';
                input.style.background = 'white';
            };

            input.oninput = () => {
                this.handleChange(item.property, input.value, item.type);
            };

            return input;
        }

        /**
         * カラー入力を作成
         */
        createColorInput(item) {
            const container = document.createElement('div');
            container.style.cssText = 'display: flex; gap: 8px; align-items: center;';

            const colorInput = document.createElement('input');
            colorInput.type = 'color';
            colorInput.value = this.normalizeColor(item.value);
            colorInput.style.cssText = `
                width: 60px;
                height: 48px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                cursor: pointer;
                padding: 4px;
            `;

            const textInput = document.createElement('input');
            textInput.type = 'text';
            textInput.value = item.value;
            textInput.style.cssText = `
                flex: 1;
                padding: 12px 16px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                font-size: 14px;
                font-family: monospace;
                background: white;
                color: #333;
            `;

            colorInput.oninput = () => {
                textInput.value = colorInput.value;
                this.handleChange(item.property, colorInput.value, item.type);
            };

            textInput.oninput = () => {
                const normalized = this.normalizeColor(textInput.value);
                if (normalized) {
                    colorInput.value = normalized;
                    this.handleChange(item.property, textInput.value, item.type);
                }
            };

            container.appendChild(colorInput);
            container.appendChild(textInput);

            return container;
        }

        /**
         * サイズ入力を作成
         */
        createSizeInput(item) {
            const container = document.createElement('div');
            container.style.cssText = 'display: flex; gap: 8px; align-items: center;';

            const sizeValue = parseInt(item.value);
            const sizeUnit = item.value.replace(sizeValue, '');

            const rangeInput = document.createElement('input');
            rangeInput.type = 'range';
            rangeInput.min = '8';
            rangeInput.max = '72';
            rangeInput.value = sizeValue;
            rangeInput.style.cssText = 'flex: 1; height: 8px;';

            const textInput = document.createElement('input');
            textInput.type = 'text';
            textInput.value = item.value;
            textInput.style.cssText = `
                width: 80px;
                padding: 12px 16px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                font-size: 14px;
                text-align: center;
                background: white;
                color: #333;
            `;

            rangeInput.oninput = () => {
                const newValue = rangeInput.value + sizeUnit;
                textInput.value = newValue;
                this.handleChange(item.property, newValue, item.type);
            };

            textInput.oninput = () => {
                const match = textInput.value.match(/^(\d+)(.*)$/);
                if (match) {
                    rangeInput.value = match[1];
                    this.handleChange(item.property, textInput.value, item.type);
                }
            };

            container.appendChild(rangeInput);
            container.appendChild(textInput);

            return container;
        }

        /**
         * アイコン入力を作成
         */
        createIconInput(item) {
            const container = document.createElement('div');
            const isMobile = window.innerWidth <= 768;
            
            container.style.cssText = `
                display: flex; 
                flex-direction: column; 
                gap: ${isMobile ? '8px' : '12px'};
                width: 100%;
                box-sizing: border-box;
            `;

            // アイコン表示とボタンを横並びに配置
            const topRow = document.createElement('div');
            topRow.style.cssText = `
                display: flex;
                align-items: center;
                gap: ${isMobile ? '8px' : '12px'};
                width: 100%;
            `;

            // アイコン表示エリア
            const iconDisplay = document.createElement('div');
            iconDisplay.style.cssText = `
                display: flex;
                align-items: center;
                justify-content: center;
                width: ${isMobile ? '50px' : '60px'};
                height: ${isMobile ? '50px' : '60px'};
                border: 2px solid rgba(0, 0, 0, 0.1);
                border-radius: 8px;
                background: #f8f9fa;
                font-size: ${isMobile ? '1.2rem' : '1.5rem'};
                cursor: pointer;
                transition: all 0.2s ease;
                flex-shrink: 0;
            `;
            iconDisplay.textContent = item.value;

            // アイコン選択ボタン
            const selectBtn = document.createElement('button');
            selectBtn.textContent = 'アイコンを選択';
            selectBtn.style.cssText = `
                padding: ${isMobile ? '6px 12px' : '8px 16px'};
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 6px;
                font-size: ${isMobile ? '12px' : '14px'};
                cursor: pointer;
                transition: background 0.2s ease;
                flex: 1;
                min-width: 0;
            `;

            selectBtn.onclick = () => {
                console.log('アイコン選択ボタンがクリックされました');
                console.log('window.sectionClickEditor:', window.sectionClickEditor);
                console.log('showIconPickerModal exists:', window.sectionClickEditor && window.sectionClickEditor.showIconPickerModal);
                
                if (window.sectionClickEditor && window.sectionClickEditor.showIconPickerModal) {
                    const callback = (selectedIcon) => {
                        console.log('アイコン選択コールバック実行:', selectedIcon);
                        // HTMLタグが含まれている場合はinnerHTMLを使用
                        if (selectedIcon.includes('<') && selectedIcon.includes('>')) {
                            iconDisplay.innerHTML = selectedIcon;
                        } else {
                            iconDisplay.textContent = selectedIcon;
                        }
                        // アイコンの場合は'icon'プロパティを使用
                        this.handleChange('icon', selectedIcon, 'icon');
                    };
                    console.log('showIconPickerModal呼び出し前');
                    try {
                        window.sectionClickEditor.showIconPickerModal(iconDisplay, callback);
                        console.log('showIconPickerModal呼び出し成功');
                    } catch (error) {
                        console.error('showIconPickerModal呼び出しエラー:', error);
                    }
                } else {
                    console.error('sectionClickEditorまたはshowIconPickerModalが見つかりません');
                }
            };

            // アイコン表示とボタンをtopRowに追加
            topRow.appendChild(iconDisplay);
            topRow.appendChild(selectBtn);
            container.appendChild(topRow);

            // サイズコントロール
            const sizeLabel = document.createElement('label');
            sizeLabel.textContent = 'サイズ';
            sizeLabel.style.cssText = 'font-size: 12px; color: #666; font-weight: 600;';

            const sizeInput = document.createElement('input');
            sizeInput.type = 'range';
            sizeInput.min = '12';
            sizeInput.max = '72';
            sizeInput.value = parseInt(getComputedStyle(this.element).fontSize) || 16;
            sizeInput.style.cssText = 'width: 100%;';

            const sizeValue = document.createElement('span');
            sizeValue.textContent = sizeInput.value + 'px';
            sizeValue.style.cssText = 'font-size: 12px; color: #666;';

            sizeInput.oninput = () => {
                const newSize = sizeInput.value + 'px';
                sizeValue.textContent = newSize;
                iconDisplay.style.fontSize = newSize;
                this.handleChange('fontSize', newSize, 'size');
            };

            // カラーコントロール
            const colorLabel = document.createElement('label');
            colorLabel.textContent = '色';
            colorLabel.style.cssText = 'font-size: 12px; color: #666; font-weight: 600;';

            const colorInput = document.createElement('input');
            colorInput.type = 'color';
            colorInput.value = this.normalizeColor(getComputedStyle(this.element).color) || '#000000';
            colorInput.style.cssText = `
                width: 100%;
                height: 40px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 6px;
                cursor: pointer;
            `;

            colorInput.oninput = () => {
                iconDisplay.style.color = colorInput.value;
                this.handleChange('color', colorInput.value, 'color');
            };

            // サイズコントロール行
            const sizeRow = document.createElement('div');
            sizeRow.style.cssText = `display: flex; flex-direction: column; gap: ${isMobile ? '3px' : '4px'};`;
            sizeRow.appendChild(sizeLabel);
            const sizeControl = document.createElement('div');
            sizeControl.style.cssText = `display: flex; gap: ${isMobile ? '6px' : '8px'}; align-items: center;`;
            sizeControl.appendChild(sizeInput);
            sizeControl.appendChild(sizeValue);
            sizeRow.appendChild(sizeControl);

            // カラーコントロール行
            const colorRow = document.createElement('div');
            colorRow.style.cssText = `display: flex; flex-direction: column; gap: ${isMobile ? '3px' : '4px'};`;
            colorRow.appendChild(colorLabel);
            colorRow.appendChild(colorInput);

            // コンテナに要素を追加
            container.appendChild(sizeRow);
            container.appendChild(colorRow);

            return container;
        }

        /**
         * 画像入力を作成
         */
        createImageInput(item) {
            const container = document.createElement('div');
            container.style.cssText = 'display: flex; flex-direction: column; gap: 12px;';

            // 現在の画像表示エリア
            const imageDisplay = document.createElement('div');
            imageDisplay.style.cssText = `
                display: flex;
                align-items: center;
                justify-content: center;
                width: 120px;
                height: 80px;
                border: 2px solid rgba(0, 0, 0, 0.1);
                border-radius: 8px;
                background: #f8f9fa;
                overflow: hidden;
                cursor: pointer;
                transition: all 0.2s ease;
                margin: 0 auto;
            `;

            // 現在の画像またはプレースホルダー
            if (item.value && (item.value.startsWith('http') || item.value.startsWith('data:'))) {
                const currentImg = document.createElement('img');
                currentImg.src = item.value;
                currentImg.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
                imageDisplay.appendChild(currentImg);
            } else {
                const placeholder = document.createElement('div');
                placeholder.textContent = '画像なし';
                placeholder.style.cssText = 'color: #999; font-size: 14px;';
                imageDisplay.appendChild(placeholder);
            }

            // URL入力フィールド
            const urlInput = document.createElement('input');
            urlInput.type = 'url';
            urlInput.value = item.value || '';
            urlInput.placeholder = '画像URL';
            urlInput.style.cssText = `
                padding: 10px 12px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 6px;
                font-size: 14px;
                background: white;
                color: #333;
                transition: all 0.2s ease;
                outline: none;
            `;

            urlInput.onfocus = () => {
                urlInput.style.borderColor = 'var(--accent-color, #64748b)';
                urlInput.style.boxShadow = '0 0 0 3px rgba(100, 116, 139, 0.1)';
            };

            urlInput.onblur = () => {
                urlInput.style.borderColor = 'rgba(0, 0, 0, 0.15)';
                urlInput.style.boxShadow = 'none';
            };

            urlInput.oninput = () => {
                this.handleChange(item.property, urlInput.value, item.type);
                // プレビュー更新
                this.updateImagePreview(imageDisplay, urlInput.value);
            };

            // アップロードボタン
            const uploadBtn = document.createElement('button');
            uploadBtn.textContent = '📁 画像をアップロード';
            uploadBtn.style.cssText = `
                padding: 10px 16px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 14px;
                cursor: pointer;
                transition: all 0.2s ease;
                width: 100%;
            `;

            uploadBtn.onmouseover = () => {
                uploadBtn.style.transform = 'translateY(-1px)';
                uploadBtn.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.3)';
            };

            uploadBtn.onmouseout = () => {
                uploadBtn.style.transform = 'translateY(0)';
                uploadBtn.style.boxShadow = 'none';
            };

            uploadBtn.onclick = () => {
                console.log('画像アップロードボタンクリック', window.imageUploader);
                if (window.imageUploader) {
                    window.imageUploader.showUploadDialog((dataUrl, size, imageId) => {
                        console.log('画像選択:', { size, imageId, dataUrl: dataUrl.substring(0, 50) + '...' });
                        urlInput.value = dataUrl;
                        
                        // 要素タイプに応じて適切なプロパティを選択
                        let targetProperty = item.property;
                        if (this.element && this.element.tagName.toLowerCase() === 'img') {
                            targetProperty = 'src';
                        }
                        
                        console.log('画像適用:', { targetProperty, elementTag: this.element.tagName });
                        this.handleChange(targetProperty, dataUrl, 'image');
                        this.updateImagePreview(imageDisplay, dataUrl);
                    });
                } else {
                    console.error('ImageUploaderが初期化されていません');
                    alert('画像アップロード機能の初期化に失敗しました。ページをリロードしてください。');
                }
            };

            // 既存のアップロード画像表示
            if (window.imageUploader && window.imageUploader.compressedImages.size > 0) {
                const existingTitle = document.createElement('div');
                existingTitle.textContent = 'アップロード済み画像:';
                existingTitle.style.cssText = 'font-size: 12px; color: #666; margin-bottom: 8px;';

                const existingGrid = document.createElement('div');
                existingGrid.style.cssText = `
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(40px, 1fr));
                    gap: 6px;
                    max-height: 80px;
                    overflow-y: auto;
                    border: 1px solid #eee;
                    border-radius: 6px;
                    padding: 8px;
                    background: #fafafa;
                `;

                window.imageUploader.compressedImages.forEach((compressedVersions, imageId) => {
                    const miniBtn = document.createElement('button');
                    miniBtn.style.cssText = `
                        width: 40px;
                        height: 40px;
                        border: 1px solid #ddd;
                        border-radius: 4px;
                        background: white;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        padding: 0;
                        overflow: hidden;
                    `;

                    const miniImg = document.createElement('img');
                    miniImg.src = compressedVersions[40] || compressedVersions[64];
                    miniImg.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
                    miniBtn.appendChild(miniImg);

                    miniBtn.onmouseover = () => {
                        miniBtn.style.borderColor = '#2196F3';
                        miniBtn.style.transform = 'scale(1.05)';
                    };

                    miniBtn.onmouseout = () => {
                        miniBtn.style.borderColor = '#ddd';
                        miniBtn.style.transform = 'scale(1)';
                    };

                    miniBtn.onclick = () => {
                        const selectedImage = compressedVersions[100] || compressedVersions[64];
                        urlInput.value = selectedImage;
                        
                        // 要素タイプに応じて適切なプロパティを選択
                        let targetProperty = item.property;
                        if (this.element && this.element.tagName.toLowerCase() === 'img') {
                            targetProperty = 'src';
                        }
                        
                        console.log('既存画像選択:', { targetProperty, elementTag: this.element.tagName });
                        this.handleChange(targetProperty, selectedImage, 'image');
                        this.updateImagePreview(imageDisplay, selectedImage);
                    };

                    existingGrid.appendChild(miniBtn);
                });

                container.appendChild(existingTitle);
                container.appendChild(existingGrid);
            }

            container.appendChild(imageDisplay);
            container.appendChild(urlInput);
            container.appendChild(uploadBtn);

            return container;
        }

        /**
         * 画像プレビュー更新
         */
        updateImagePreview(imageDisplay, url) {
            imageDisplay.innerHTML = '';
            
            if (url && (url.startsWith('http') || url.startsWith('data:'))) {
                const img = document.createElement('img');
                img.src = url;
                img.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
                img.onerror = () => {
                    imageDisplay.innerHTML = '<div style="color: #f44336; font-size: 12px;">画像読み込み失敗</div>';
                };
                imageDisplay.appendChild(img);
            } else {
                const placeholder = document.createElement('div');
                placeholder.textContent = '画像なし';
                placeholder.style.cssText = 'color: #999; font-size: 14px;';
                imageDisplay.appendChild(placeholder);
            }
        }

        /**
         * 背景画像入力を作成
         */
        createBackgroundInput(item) {
            const container = document.createElement('div');
            container.style.cssText = 'display: flex; flex-direction: column; gap: 12px;';

            // 現在の背景表示エリア
            const bgDisplay = document.createElement('div');
            bgDisplay.style.cssText = `
                display: flex;
                align-items: center;
                justify-content: center;
                width: 100%;
                height: 80px;
                border: 2px solid rgba(0, 0, 0, 0.1);
                border-radius: 8px;
                background: #f8f9fa;
                overflow: hidden;
                cursor: pointer;
                transition: all 0.2s ease;
                position: relative;
            `;

            // 現在の背景画像またはプレースホルダー
            const updateBackgroundPreview = (value) => {
                if (value && (value.includes('url(') || value.startsWith('http') || value.startsWith('data:'))) {
                    // URLからbackground-imageスタイルを生成
                    let bgValue = value;
                    if (!value.includes('url(')) {
                        bgValue = `url('${value}')`;
                    }
                    bgDisplay.style.background = `${bgValue} center/cover no-repeat`;
                    bgDisplay.innerHTML = '';
                } else {
                    bgDisplay.style.background = '#f8f9fa';
                    bgDisplay.innerHTML = '<div style="color: #999; font-size: 14px;">背景画像なし</div>';
                }
            };
            
            updateBackgroundPreview(item.value);

            // URL入力フィールド
            const urlInput = document.createElement('input');
            urlInput.type = 'url';
            // 背景値からURLを抽出する改良版
            let extractedUrl = '';
            if (item.value) {
                // url()を含む最後の部分を探す（グラデーションの後にある画像URL）
                const urlMatches = item.value.match(/url\(['"]?([^'")]+)['"]?\)/g);
                if (urlMatches && urlMatches.length > 0) {
                    // 最後のurl()を取得（これが背景画像）
                    const lastUrl = urlMatches[urlMatches.length - 1];
                    extractedUrl = lastUrl.replace(/url\(['"]?|['"]?\)/g, '');
                }
            }
            urlInput.value = extractedUrl;
            urlInput.placeholder = '背景画像URL';
            urlInput.style.cssText = `
                padding: 10px 12px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 6px;
                font-size: 14px;
                background: white;
                color: #333;
                transition: all 0.2s ease;
                outline: none;
            `;

            urlInput.onfocus = () => {
                urlInput.style.borderColor = 'var(--accent-color, #64748b)';
                urlInput.style.boxShadow = '0 0 0 3px rgba(100, 116, 139, 0.1)';
            };

            urlInput.onblur = () => {
                urlInput.style.borderColor = 'rgba(0, 0, 0, 0.15)';
                urlInput.style.boxShadow = 'none';
            };

            urlInput.oninput = () => {
                const bgValue = urlInput.value ? `url('${urlInput.value}')` : '';
                this.handleChange(item.property, bgValue, item.type);
                updateBackgroundPreview(bgValue);
            };

            // アップロードボタン
            const uploadBtn = document.createElement('button');
            uploadBtn.textContent = '🖼️ 背景画像をアップロード';
            uploadBtn.id = 'bg-upload-btn-' + Date.now(); // デバッグ用ID
            uploadBtn.style.cssText = `
                padding: 10px 16px;
                background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%);
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 14px;
                cursor: pointer;
                transition: all 0.2s ease;
                width: 100%;
            `;
            
            console.log('背景画像アップロードボタンを作成:', uploadBtn.id);

            uploadBtn.onmouseover = () => {
                uploadBtn.style.transform = 'translateY(-1px)';
                uploadBtn.style.boxShadow = '0 4px 12px rgba(255, 107, 107, 0.3)';
            };

            uploadBtn.onmouseout = () => {
                uploadBtn.style.transform = 'translateY(0)';
                uploadBtn.style.boxShadow = 'none';
            };

            // クリックイベントを設定
            uploadBtn.addEventListener('click', async (e) => {
                console.log('🖼️ 背景画像アップロードボタンクリック!', uploadBtn.id);
                console.log('クリックイベント:', e);
                e.preventDefault();
                e.stopPropagation();
                
                try {
                    // ImageUploaderの初期化を確認・待機
                    console.log('ImageUploaderの初期化確認中...');
                    const imageUploader = await this.waitForImageUploader();
                    
                    if (imageUploader) {
                        console.log('ImageUploader初期化成功、ダイアログを表示');
                        imageUploader.showUploadDialog((dataUrl, size, imageId) => {
                            console.log('画像選択完了:', { size, imageId });
                            // 画像選択後、すぐに背景に適用
                            const bgValue = `url('${dataUrl}')`;
                            urlInput.value = dataUrl;
                            this.handleChange(item.property, bgValue, 'background');
                            updateBackgroundPreview(bgValue);
                        });
                    } else {
                        console.error('ImageUploaderの初期化に失敗しました');
                        // フォールバック：シンプルなファイル選択を同期的に実行
                        console.log('フォールバック：シンプルなファイル選択を使用');
                        this.showSimpleFileUpload(urlInput, updateBackgroundPreview, item);
                    }
                } catch (error) {
                    console.error('アップロードボタンエラー:', error);
                    alert('エラーが発生しました: ' + error.message);
                }
            });
            
            // 念のためonclickも設定
            uploadBtn.onclick = (e) => {
                console.log('onclick も発火:', uploadBtn.id);
            };

            // ファイルブラウザボタン
            const browseBtn = document.createElement('button');
            browseBtn.textContent = '📂 画像ファイルを管理';
            browseBtn.style.cssText = `
                padding: 10px 16px;
                background: #607D8B;
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 14px;
                cursor: pointer;
                transition: all 0.2s ease;
                width: 100%;
                margin-top: 8px;
            `;

            browseBtn.onmouseover = () => {
                browseBtn.style.background = '#455A64';
                browseBtn.style.transform = 'translateY(-1px)';
            };

            browseBtn.onmouseout = () => {
                browseBtn.style.background = '#607D8B';
                browseBtn.style.transform = 'translateY(0)';
            };

            browseBtn.onclick = () => {
                this.showImageBrowser((selectedUrl) => {
                    const bgValue = `url('${selectedUrl}')`;
                    urlInput.value = selectedUrl;
                    this.handleChange(item.property, bgValue, 'background');
                    updateBackgroundPreview(bgValue);
                });
            };

            // 既存のアップロード画像表示
            if (window.imageUploader && window.imageUploader.compressedImages.size > 0) {
                const existingTitle = document.createElement('div');
                existingTitle.textContent = 'アップロード済み画像:';
                existingTitle.style.cssText = 'font-size: 12px; color: #666; margin-bottom: 8px; margin-top: 12px;';

                const existingGrid = document.createElement('div');
                existingGrid.style.cssText = `
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(60px, 1fr));
                    gap: 8px;
                    max-height: 120px;
                    overflow-y: auto;
                    border: 1px solid #eee;
                    border-radius: 6px;
                    padding: 8px;
                    background: #fafafa;
                `;

                window.imageUploader.compressedImages.forEach((compressedVersions, imageId) => {
                    const isMobile = window.innerWidth <= 768;
                    const miniBtn = document.createElement('button');
                    miniBtn.style.cssText = `
                        width: ${isMobile ? '40px' : '50px'};
                        height: ${isMobile ? '40px' : '50px'};
                        border: 2px solid #ddd;
                        border-radius: 4px;
                        background: white;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        padding: 0;
                        overflow: hidden;
                        position: relative;
                    `;

                    const miniImg = document.createElement('img');
                    miniImg.src = compressedVersions[64] || compressedVersions[100];
                    miniImg.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
                    miniBtn.appendChild(miniImg);

                    miniBtn.onmouseover = () => {
                        miniBtn.style.borderColor = '#FF6B6B';
                        miniBtn.style.transform = 'scale(1.05)';
                    };

                    miniBtn.onmouseout = () => {
                        miniBtn.style.borderColor = '#ddd';
                        miniBtn.style.transform = 'scale(1)';
                    };

                    miniBtn.onclick = () => {
                        const selectedImage = compressedVersions[100] || compressedVersions[64];
                        // 画像選択後、すぐに背景に適用
                        const bgValue = `url('${selectedImage}')`;
                        urlInput.value = selectedImage;
                        this.handleChange(item.property, bgValue, 'background');
                        updateBackgroundPreview(bgValue);
                    };

                    existingGrid.appendChild(miniBtn);
                });

                container.appendChild(existingTitle);
                container.appendChild(existingGrid);
            }

            // エフェクトボタン（オプション）
            const effectBtn = document.createElement('button');
            effectBtn.textContent = '🎨 エフェクト設定';
            effectBtn.style.cssText = `
                padding: 10px 16px;
                background: #9C27B0;
                color: white;
                border: none;
                border-radius: 6px;
                font-size: 14px;
                cursor: pointer;
                transition: all 0.2s ease;
                width: 100%;
                margin-top: 8px;
            `;
            
            effectBtn.onmouseover = () => {
                effectBtn.style.background = '#7B1FA2';
                effectBtn.style.transform = 'translateY(-1px)';
            };
            
            effectBtn.onmouseout = () => {
                effectBtn.style.background = '#9C27B0';
                effectBtn.style.transform = 'translateY(0)';
            };
            
            effectBtn.onclick = () => {
                const currentValue = urlInput.value;
                // data:URLまたはサーバーの画像URLに対応
                if (currentValue && (currentValue.startsWith('data:') || currentValue.includes('uploads/images/'))) {
                    this.showBackgroundEffectsModal(currentValue, (finalStyle) => {
                        this.handleChange(item.property, finalStyle, 'background');
                        updateBackgroundPreview(finalStyle);
                    });
                } else {
                    alert('まず画像を選択してください');
                }
            };

            // テスト用シンプルボタン
            const testBtn = document.createElement('button');
            testBtn.textContent = '🧪 テスト（クリック確認）';
            testBtn.style.cssText = `
                padding: 8px 12px;
                background: #9E9E9E;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 12px;
                cursor: pointer;
                width: 100%;
                margin-top: 4px;
            `;
            testBtn.onclick = () => {
                console.log('🧪 テストボタンがクリックされました!');
                alert('テストボタンが正常に動作しています');
            };
            
            container.appendChild(bgDisplay);
            container.appendChild(urlInput);
            container.appendChild(uploadBtn);
            container.appendChild(testBtn);
            container.appendChild(browseBtn);
            container.appendChild(effectBtn);

            console.log('背景入力フィールド作成完了。ボタン数:', container.querySelectorAll('button').length);

            return container;
        }

        /**
         * ImageUploaderの初期化を待機
         */
        /**
         * シンプルなファイルアップロード
         */
        showSimpleFileUpload(urlInput, updatePreview, item) {
            console.log('シンプルなファイルアップロードを開始');
            
            // ファイル入力要素を作成
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.accept = 'image/*';
            fileInput.style.cssText = `
                position: fixed;
                top: -9999px;
                left: -9999px;
                opacity: 0;
                pointer-events: none;
            `;
            
            fileInput.onchange = (e) => {
                console.log('ファイルが選択されました');
                const file = e.target.files[0];
                if (file && file.type.startsWith('image/')) {
                    console.log('ファイル情報:', { name: file.name, size: file.size, type: file.type });
                    
                    // ファイル読み込み
                    const reader = new FileReader();
                    reader.onload = (e) => {
                        const dataUrl = e.target.result;
                        console.log('画像読み込み完了、設定画面を表示');
                        
                        // 設定画面を表示
                        this.showImageSettingsModal(file, dataUrl, (finalStyle) => {
                            urlInput.value = dataUrl;
                            this.handleChange(item.property, finalStyle, 'background');
                            updatePreview(finalStyle);
                        });
                    };
                    reader.onerror = () => {
                        console.error('ファイル読み込みエラー');
                        alert('画像ファイルの読み込みに失敗しました。');
                    };
                    reader.readAsDataURL(file);
                } else if (file) {
                    console.log('画像ファイルではありません:', file.type);
                    alert('画像ファイルを選択してください。');
                } else {
                    console.log('ファイルが選択されませんでした');
                }
                
                // ファイルインプットを削除
                setTimeout(() => {
                    if (fileInput.parentNode) {
                        fileInput.parentNode.removeChild(fileInput);
                    }
                }, 100);
            };
            
            // ドキュメントに追加
            document.body.appendChild(fileInput);
            
            // 即座にクリック（同期処理でユーザーアクティベーション維持）
            console.log('ファイル選択ダイアログを表示');
            fileInput.click();
        }

        async waitForImageUploader(maxWait = 1000) {
            return new Promise((resolve) => {
                console.log('waitForImageUploader開始（短縮版）');
                console.log('window.imageUploader:', window.imageUploader);
                console.log('window.ImageUploader:', window.ImageUploader);
                
                // 既に初期化済みの場合
                if (window.imageUploader && window.imageUploader.showUploadDialog) {
                    console.log('ImageUploader既に初期化済み');
                    resolve(window.imageUploader);
                    return;
                }
                
                // 手動で初期化を試行
                try {
                    if (window.ImageUploader) {
                        console.log('ImageUploaderクラスが見つかりました、手動初期化します');
                        window.imageUploader = new window.ImageUploader();
                        resolve(window.imageUploader);
                        return;
                    }
                } catch (error) {
                    console.error('ImageUploaderの手動初期化に失敗:', error);
                }
                
                // 短時間の待機のみ（フォールバックを早く発動させる）
                setTimeout(() => {
                    if (window.imageUploader && window.imageUploader.showUploadDialog) {
                        console.log('短時間待機で初期化成功');
                        resolve(window.imageUploader);
                    } else {
                        console.error('ImageUploaderの初期化に失敗 - フォールバックへ');
                        resolve(null);
                    }
                }, maxWait);
            });
        }

        /**
         * 画像設定モーダルを表示
         */
        showImageSettingsModal(file, dataUrl, onApply) {
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                z-index: 100070;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.3s ease;
            `;
            
            const content = document.createElement('div');
            const isMobile = window.innerWidth <= 768;
            content.style.cssText = `
                background: white;
                border-radius: 16px;
                padding: 24px;
                max-width: ${isMobile ? '350px' : '500px'};
                width: 90%;
                max-height: 85vh;
                overflow-y: auto;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                -webkit-overflow-scrolling: touch;
            `;
            
            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;';
            
            const title = document.createElement('h3');
            title.textContent = '🎨 背景画像設定';
            title.style.cssText = 'margin: 0; font-size: 18px; color: #333;';
            
            const closeBtn = document.createElement('button');
            closeBtn.innerHTML = '✕';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 20px;
                color: #999;
                cursor: pointer;
                padding: 8px;
                border-radius: 6px;
            `;
            closeBtn.onclick = () => modal.remove();
            
            header.appendChild(title);
            header.appendChild(closeBtn);
            content.appendChild(header);
            
            // プレビュー画像
            const previewContainer = document.createElement('div');
            previewContainer.style.cssText = `
                position: relative;
                width: 100%;
                height: 150px;
                border-radius: 8px;
                overflow: hidden;
                margin-bottom: 20px;
                border: 1px solid #ddd;
            `;
            
            const previewImg = document.createElement('div');
            previewImg.style.cssText = `
                width: 100%;
                height: 100%;
                background-image: url('${dataUrl}');
                background-size: cover;
                background-position: center;
                background-repeat: no-repeat;
                position: relative;
            `;
            
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: transparent;
                pointer-events: none;
            `;
            
            previewImg.appendChild(overlay);
            previewContainer.appendChild(previewImg);
            content.appendChild(previewContainer);
            
            // ファイル情報
            const fileInfo = document.createElement('div');
            fileInfo.style.cssText = 'margin-bottom: 20px; padding: 12px; background: #f5f5f5; border-radius: 8px; font-size: 13px; color: #666;';
            fileInfo.innerHTML = `
                📄 <strong>${file.name}</strong><br>
                📏 ${(file.size / 1024 / 1024).toFixed(2)} MB • ${file.type}
            `;
            content.appendChild(fileInfo);
            
            // 設定項目
            const settings = {
                position: 'center',
                size: 'cover',
                overlayColor: '#000000',
                overlayOpacity: 0
            };
            
            // 配置設定
            const positionSection = this.createSettingSection('📍 配置', [
                { value: 'center', label: '中央' },
                { value: 'top', label: '上' },
                { value: 'bottom', label: '下' },
                { value: 'left', label: '左' },
                { value: 'right', label: '右' }
            ], settings.position, (value) => {
                settings.position = value;
                updatePreview();
            });
            content.appendChild(positionSection);
            
            // サイズ設定
            const sizeSection = this.createSettingSection('📐 サイズ', [
                { value: 'cover', label: '全画面' },
                { value: 'contain', label: '全体表示' },
                { value: 'auto', label: '元サイズ' }
            ], settings.size, (value) => {
                settings.size = value;
                updatePreview();
            });
            content.appendChild(sizeSection);
            
            // オーバーレイ設定
            const overlaySection = document.createElement('div');
            overlaySection.style.cssText = 'margin-bottom: 20px;';
            
            const overlayTitle = document.createElement('h4');
            overlayTitle.textContent = '🎨 オーバーレイ';
            overlayTitle.style.cssText = 'margin: 0 0 10px 0; font-size: 14px; color: #333;';
            overlaySection.appendChild(overlayTitle);
            
            const overlayControls = document.createElement('div');
            overlayControls.style.cssText = 'display: flex; gap: 10px; align-items: center;';
            
            const colorPicker = document.createElement('input');
            colorPicker.type = 'color';
            colorPicker.value = settings.overlayColor;
            colorPicker.style.cssText = 'width: 40px; height: 30px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer;';
            
            const opacitySlider = document.createElement('input');
            opacitySlider.type = 'range';
            opacitySlider.min = '0';
            opacitySlider.max = '100';
            opacitySlider.value = settings.overlayOpacity;
            opacitySlider.style.cssText = 'flex: 1;';
            
            const opacityLabel = document.createElement('span');
            opacityLabel.textContent = settings.overlayOpacity + '%';
            opacityLabel.style.cssText = 'font-size: 12px; color: #666; min-width: 35px;';
            
            colorPicker.oninput = () => {
                settings.overlayColor = colorPicker.value;
                updatePreview();
            };
            
            opacitySlider.oninput = () => {
                settings.overlayOpacity = parseInt(opacitySlider.value);
                opacityLabel.textContent = settings.overlayOpacity + '%';
                updatePreview();
            };
            
            overlayControls.appendChild(colorPicker);
            overlayControls.appendChild(opacitySlider);
            overlayControls.appendChild(opacityLabel);
            overlaySection.appendChild(overlayControls);
            content.appendChild(overlaySection);
            
            // プレビュー更新関数
            function updatePreview() {
                previewImg.style.backgroundPosition = settings.position;
                previewImg.style.backgroundSize = settings.size;
                
                if (settings.overlayOpacity > 0) {
                    const opacity = (settings.overlayOpacity / 100).toFixed(2);
                    overlay.style.background = `${settings.overlayColor}${Math.round(settings.overlayOpacity * 2.55).toString(16).padStart(2, '0')}`;
                } else {
                    overlay.style.background = 'transparent';
                }
            }
            
            // ボタン
            const buttonGroup = document.createElement('div');
            buttonGroup.style.cssText = 'display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px;';
            
            const cancelBtn = document.createElement('button');
            cancelBtn.textContent = 'キャンセル';
            cancelBtn.style.cssText = `
                padding: 10px 16px;
                background: #f5f5f5;
                border: 1px solid #ddd;
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            `;
            cancelBtn.onclick = () => modal.remove();
            
            const applyBtn = document.createElement('button');
            applyBtn.textContent = '✨ 適用';
            applyBtn.style.cssText = `
                padding: 10px 16px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            `;
            
            applyBtn.onclick = () => {
                const finalStyle = this.generateBackgroundStyle(dataUrl, settings);
                onApply(finalStyle);
                modal.remove();
            };
            
            buttonGroup.appendChild(cancelBtn);
            buttonGroup.appendChild(applyBtn);
            content.appendChild(buttonGroup);
            
            modal.appendChild(content);
            document.body.appendChild(modal);
            
            // 外側クリックで閉じる
            modal.onclick = (e) => {
                if (e.target === modal) {
                    modal.remove();
                }
            };
            
            // 初期プレビュー更新
            updatePreview();
        }
        
        /**
         * 設定セクションを作成
         */
        createSettingSection(title, options, currentValue, onChange) {
            const section = document.createElement('div');
            section.style.cssText = 'margin-bottom: 20px;';
            
            const sectionTitle = document.createElement('h4');
            sectionTitle.textContent = title;
            sectionTitle.style.cssText = 'margin: 0 0 10px 0; font-size: 14px; color: #333;';
            section.appendChild(sectionTitle);
            
            const buttonGroup = document.createElement('div');
            buttonGroup.style.cssText = 'display: flex; gap: 8px; flex-wrap: wrap;';
            
            options.forEach(option => {
                const btn = document.createElement('button');
                btn.textContent = option.label;
                btn.style.cssText = `
                    padding: 8px 12px;
                    border: 2px solid ${option.value === currentValue ? '#2196F3' : '#ddd'};
                    background: ${option.value === currentValue ? '#2196F3' : 'white'};
                    color: ${option.value === currentValue ? 'white' : '#333'};
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 12px;
                    transition: all 0.2s;
                `;
                
                btn.onclick = () => {
                    buttonGroup.querySelectorAll('button').forEach(b => {
                        b.style.border = '2px solid #ddd';
                        b.style.background = 'white';
                        b.style.color = '#333';
                    });
                    btn.style.border = '2px solid #2196F3';
                    btn.style.background = '#2196F3';
                    btn.style.color = 'white';
                    onChange(option.value);
                };
                
                buttonGroup.appendChild(btn);
            });
            
            section.appendChild(buttonGroup);
            return section;
        }
        
        /**
         * 背景スタイルを生成（改良版）
         */
        generateBackgroundStyle(imageUrl, settings) {
            let bgImage = `url('${imageUrl}')`;
            
            // オーバーレイを追加
            if (settings && settings.overlayOpacity > 0) {
                const opacity = Math.round(settings.overlayOpacity * 2.55).toString(16).padStart(2, '0');
                bgImage = `linear-gradient(${settings.overlayColor}${opacity}, ${settings.overlayColor}${opacity}), ${bgImage}`;
            }
            
            return bgImage;
        }

        /**
         * 画像ブラウザを表示
         */
        showImageBrowser(onSelect) {
            // 画像の使用状況を確認
            const imageUsage = this.scanImageUsage();
            
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 100010;
                animation: fadeIn 0.2s ease;
            `;

            const browser = document.createElement('div');
            browser.style.cssText = `
                background: white;
                border-radius: 12px;
                padding: 24px;
                max-width: 900px;
                width: 90%;
                max-height: 85vh;
                overflow-y: auto;
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
                animation: slideIn 0.3s ease;
            `;

            const header = document.createElement('div');
            header.style.cssText = `
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 20px;
                padding-bottom: 12px;
                border-bottom: 2px solid #f0f0f0;
            `;

            const title = document.createElement('h3');
            title.textContent = '画像ファイル管理';
            title.style.cssText = 'margin: 0; color: #333; font-size: 20px;';

            const closeBtn = document.createElement('button');
            closeBtn.textContent = '✕';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 24px;
                color: #999;
                cursor: pointer;
                padding: 0;
                width: 32px;
                height: 32px;
            `;
            closeBtn.onclick = () => modal.remove();

            header.appendChild(title);
            header.appendChild(closeBtn);
            browser.appendChild(header);

            // 画像グリッド
            const grid = document.createElement('div');
            grid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
                gap: 16px;
                margin-top: 20px;
            `;

            // プロジェクト画像を取得
            const projectImages = [
                'images/aaa.webp',
                'images/logo.png',
                'images/pilates-studio.png'
            ];

            // プロジェクト画像セクション
            const projectSection = document.createElement('div');
            projectSection.style.cssText = 'margin-bottom: 24px;';
            
            const projectTitle = document.createElement('h4');
            projectTitle.textContent = 'プロジェクト画像';
            projectTitle.style.cssText = 'margin: 0 0 12px 0; color: #666; font-size: 16px;';
            projectSection.appendChild(projectTitle);

            const projectGrid = document.createElement('div');
            projectGrid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
                gap: 12px;
            `;

            projectImages.forEach(imagePath => {
                const usage = imageUsage[imagePath] || [];
                const imageCard = this.createImageCard(imagePath, false, () => {
                    onSelect(imagePath);
                    modal.remove();
                }, null, usage);
                projectGrid.appendChild(imageCard);
            });

            projectSection.appendChild(projectGrid);
            browser.appendChild(projectSection);

            // アップロード画像セクション
            if (window.imageUploader && window.imageUploader.compressedImages.size > 0) {
                const uploadSection = document.createElement('div');
                
                const uploadTitle = document.createElement('h4');
                uploadTitle.textContent = 'アップロード画像';
                uploadTitle.style.cssText = 'margin: 24px 0 12px 0; color: #666; font-size: 16px;';
                uploadSection.appendChild(uploadTitle);

                const uploadGrid = document.createElement('div');
                uploadGrid.style.cssText = `
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
                    gap: 12px;
                `;

                window.imageUploader.compressedImages.forEach((compressedVersions, imageId) => {
                    const imageSrc = compressedVersions[100] || compressedVersions[64];
                    const usage = imageUsage[imageSrc] || [];
                    const imageCard = this.createImageCard(imageSrc, true, () => {
                        onSelect(imageSrc);
                        modal.remove();
                    }, imageId, usage);
                    uploadGrid.appendChild(imageCard);
                });

                uploadSection.appendChild(uploadGrid);
                browser.appendChild(uploadSection);
            }

            modal.appendChild(browser);
            document.body.appendChild(modal);

            // アニメーションスタイル
            if (!document.querySelector('#image-browser-styles')) {
                const style = document.createElement('style');
                style.id = 'image-browser-styles';
                style.textContent = `
                    @keyframes fadeIn {
                        from { opacity: 0; }
                        to { opacity: 1; }
                    }
                    @keyframes slideIn {
                        from { transform: translateY(20px); opacity: 0; }
                        to { transform: translateY(0); opacity: 1; }
                    }
                `;
                document.head.appendChild(style);
            }
        }

        /**
         * 画像カードを作成
         */
        createImageCard(imageSrc, canDelete, onSelect, imageId, usage = []) {
            const card = document.createElement('div');
            card.style.cssText = `
                border: 2px solid ${usage.length > 0 ? '#64748b' : '#e0e0e0'};
                border-radius: 8px;
                overflow: hidden;
                cursor: pointer;
                transition: all 0.2s ease;
                background: white;
                position: relative;
                ${usage.length > 0 ? 'box-shadow: 0 2px 8px rgba(76, 175, 80, 0.2);' : ''}
            `;

            const img = document.createElement('img');
            img.src = imageSrc;
            img.style.cssText = `
                width: 100%;
                height: 150px;
                object-fit: cover;
                display: block;
            `;

            const info = document.createElement('div');
            info.style.cssText = `
                padding: 8px;
                font-size: 12px;
                background: #f8f9fa;
                border-top: 1px solid #e0e0e0;
            `;
            
            const fileName = imageSrc.split('/').pop();
            const fileNameDiv = document.createElement('div');
            fileNameDiv.style.cssText = 'color: #333; font-weight: 500; margin-bottom: 4px;';
            fileNameDiv.textContent = fileName.length > 20 ? fileName.substring(0, 20) + '...' : fileName;
            info.appendChild(fileNameDiv);
            
            // 使用状況を表示
            if (usage.length > 0) {
                const usageDiv = document.createElement('div');
                usageDiv.style.cssText = 'color: #64748b; font-size: 11px; display: flex; align-items: center; gap: 4px;';
                const icon = document.createElement('span');
                icon.textContent = '✓';
                icon.style.cssText = 'font-weight: bold;';
                usageDiv.appendChild(icon);
                
                const usageText = document.createElement('span');
                if (usage.length === 1) {
                    usageText.textContent = `${usage[0].section}で使用中`;
                } else {
                    usageText.textContent = `${usage.length}箇所で使用中`;
                }
                usageDiv.appendChild(usageText);
                
                info.appendChild(usageDiv);
                
                // ホバーで詳細表示
                const tooltip = document.createElement('div');
                tooltip.style.cssText = `
                    position: absolute;
                    bottom: 100%;
                    left: 50%;
                    transform: translateX(-50%);
                    background: rgba(0, 0, 0, 0.9);
                    color: white;
                    padding: 8px 12px;
                    border-radius: 6px;
                    font-size: 11px;
                    white-space: nowrap;
                    display: none;
                    z-index: 1000;
                    margin-bottom: 8px;
                    max-width: 250px;
                `;
                
                const usageList = usage.map(u => `• ${u.section}: ${u.property}`).join('\n');
                tooltip.textContent = usageList;
                card.appendChild(tooltip);
                
                card.onmouseenter = () => {
                    tooltip.style.display = 'block';
                };
                
                card.onmouseleave = () => {
                    tooltip.style.display = 'none';
                };
            } else {
                const unusedDiv = document.createElement('div');
                unusedDiv.style.cssText = 'color: #999; font-size: 11px;';
                unusedDiv.textContent = '未使用';
                info.appendChild(unusedDiv);
            }

            card.appendChild(img);
            card.appendChild(info);

            // 削除ボタン（アップロード画像のみ）
            if (canDelete && imageId) {
                const deleteBtn = document.createElement('button');
                deleteBtn.textContent = '🗑️';
                deleteBtn.style.cssText = `
                    position: absolute;
                    top: 8px;
                    right: 8px;
                    background: rgba(255, 255, 255, 0.95);
                    border: 1px solid #e0e0e0;
                    border-radius: 6px;
                    width: 36px;
                    height: 36px;
                    cursor: pointer;
                    font-size: 18px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    transition: all 0.2s ease;
                    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
                `;

                deleteBtn.onclick = (e) => {
                    e.stopPropagation();
                    
                    let confirmMessage = 'この画像を削除しますか？';
                    if (usage.length > 0) {
                        confirmMessage = `この画像は${usage.length}箇所で使用されています。\n削除すると表示が崩れる可能性があります。\n\n本当に削除しますか？`;
                    }
                    
                    if (confirm(confirmMessage)) {
                        window.imageUploader.compressedImages.delete(imageId);
                        window.imageUploader.originalImages.delete(imageId);
                        card.remove();
                        
                        // 空になったらセクションを削除
                        const uploadGrid = card.parentElement;
                        if (uploadGrid && uploadGrid.children.length === 0) {
                            const uploadSection = uploadGrid.parentElement;
                            if (uploadSection) uploadSection.remove();
                        }
                    }
                };

                card.appendChild(deleteBtn);
                
                // ホバー時の効果
                deleteBtn.onmouseover = () => {
                    deleteBtn.style.background = 'rgba(255, 107, 107, 0.9)';
                    deleteBtn.style.borderColor = '#FF6B6B';
                    deleteBtn.style.transform = 'scale(1.1)';
                    deleteBtn.style.boxShadow = '0 4px 8px rgba(255, 107, 107, 0.3)';
                };
                
                deleteBtn.onmouseout = () => {
                    deleteBtn.style.background = 'rgba(255, 255, 255, 0.95)';
                    deleteBtn.style.borderColor = '#e0e0e0';
                    deleteBtn.style.transform = 'scale(1)';
                    deleteBtn.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.1)';
                };
            }

            card.onmouseover = () => {
                card.style.borderColor = '#2196F3';
                card.style.transform = 'translateY(-2px)';
                card.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.1)';
            };

            card.onmouseout = () => {
                card.style.borderColor = '#e0e0e0';
                card.style.transform = 'translateY(0)';
                card.style.boxShadow = 'none';
            };

            card.onclick = () => onSelect();

            return card;
        }

        /**
         * 背景エフェクトモーダルを表示
         */
        showBackgroundEffectsModal(imageUrl, onApply) {
            const modal = document.createElement('div');
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 100015;
                animation: fadeIn 0.2s ease;
            `;

            const dialog = document.createElement('div');
            const isMobile = window.innerWidth <= 768;
            dialog.style.cssText = `
                background: white;
                border-radius: 8px;
                padding: ${isMobile ? '12px' : '16px'};
                max-width: ${isMobile ? '280px' : '320px'};
                width: 90%;
                max-height: ${isMobile ? '450px' : '500px'};
                overflow-y: auto;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
                animation: slideIn 0.2s ease;
                position: relative;
            `;

            const header = document.createElement('div');
            header.style.cssText = `
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: ${isMobile ? '12px' : '16px'};
                padding-bottom: ${isMobile ? '8px' : '12px'};
                border-bottom: 1px solid #e0e0e0;
            `;

            const title = document.createElement('h3');
            title.textContent = '背景エフェクト';
            title.style.cssText = `margin: 0; color: #333; font-size: ${isMobile ? '16px' : '18px'};`;

            const closeBtn = document.createElement('button');
            closeBtn.textContent = '×';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 24px;
                color: #999;
                cursor: pointer;
                padding: 0;
                width: 32px;
                height: 32px;
            `;
            closeBtn.onclick = () => modal.remove();

            header.appendChild(title);
            header.appendChild(closeBtn);
            dialog.appendChild(header);

            // プレビューエリア
            const preview = document.createElement('div');
            preview.style.cssText = `
                width: 100%;
                height: ${isMobile ? '80px' : '100px'};
                border-radius: 6px;
                margin-bottom: ${isMobile ? '12px' : '16px'};
                position: relative;
                overflow: hidden;
                background-image: url('${imageUrl}');
                background-size: cover;
                background-position: center;
                border: 1px solid #e0e0e0;
            `;

            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: absolute;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.5);
                pointer-events: none;
            `;
            preview.appendChild(overlay);

            dialog.appendChild(preview);

            // コントロール
            const controls = document.createElement('div');
            controls.style.cssText = `display: flex; flex-direction: column; gap: ${isMobile ? '10px' : '12px'};`;

            // 透過レイヤーカラー
            const overlayColorGroup = document.createElement('div');
            overlayColorGroup.style.cssText = 'display: flex; flex-direction: column; gap: 8px;';
            
            const overlayColorLabel = document.createElement('label');
            overlayColorLabel.textContent = 'オーバーレイ';
            overlayColorLabel.style.cssText = `font-size: ${isMobile ? '13px' : '14px'}; color: #555; font-weight: 500;`;
            
            const overlayColorInput = document.createElement('input');
            overlayColorInput.type = 'color';
            overlayColorInput.value = '#000000';
            overlayColorInput.style.cssText = `
                width: 100%;
                height: ${isMobile ? '32px' : '36px'};
                border: 1px solid #e0e0e0;
                border-radius: 4px;
                cursor: pointer;
            `;

            overlayColorGroup.appendChild(overlayColorLabel);
            overlayColorGroup.appendChild(overlayColorInput);
            controls.appendChild(overlayColorGroup);

            // 透明度
            const opacityGroup = document.createElement('div');
            opacityGroup.style.cssText = 'display: flex; flex-direction: column; gap: 8px;';
            
            const opacityLabel = document.createElement('label');
            opacityLabel.textContent = '透明度';
            opacityLabel.style.cssText = `font-size: ${isMobile ? '13px' : '14px'}; color: #555; font-weight: 500;`;
            
            const opacityContainer = document.createElement('div');
            opacityContainer.style.cssText = 'display: flex; gap: 12px; align-items: center;';
            
            const opacitySlider = document.createElement('input');
            opacitySlider.type = 'range';
            opacitySlider.min = '0';
            opacitySlider.max = '100';
            opacitySlider.value = '50';
            opacitySlider.style.cssText = 'flex: 1;';
            
            const opacityValue = document.createElement('span');
            opacityValue.textContent = '50%';
            opacityValue.style.cssText = 'font-size: 14px; color: #666; min-width: 40px;';

            opacityContainer.appendChild(opacitySlider);
            opacityContainer.appendChild(opacityValue);
            opacityGroup.appendChild(opacityLabel);
            opacityGroup.appendChild(opacityContainer);
            controls.appendChild(opacityGroup);

            // プリセットパターン
            const presetGroup = document.createElement('div');
            presetGroup.style.cssText = 'display: flex; flex-direction: column; gap: 8px;';
            
            const presetLabel = document.createElement('label');
            presetLabel.textContent = 'プリセット';
            presetLabel.style.cssText = `font-size: ${isMobile ? '13px' : '14px'}; color: #555; font-weight: 500;`;
            
            const presetButtons = document.createElement('div');
            presetButtons.style.cssText = `display: grid; grid-template-columns: repeat(3, 1fr); gap: ${isMobile ? '4px' : '6px'};`;
            
            const presets = [
                { name: 'ダーク', color: '#000000', opacity: 60 },
                { name: 'ライト', color: '#ffffff', opacity: 40 },
                { name: 'ブルー', color: '#1e3a8a', opacity: 50 },
                { name: 'グリーン', color: '#14532d', opacity: 50 },
                { name: 'パープル', color: '#581c87', opacity: 50 },
                { name: 'グラデーション', color: 'gradient', opacity: 50 }
            ];
            
            presets.forEach(preset => {
                const btn = document.createElement('button');
                btn.textContent = preset.name;
                btn.style.cssText = `
                    padding: ${isMobile ? '4px 6px' : '6px 8px'};
                    border: 1px solid #e0e0e0;
                    border-radius: 4px;
                    background: white;
                    cursor: pointer;
                    font-size: ${isMobile ? '10px' : '11px'};
                    transition: all 0.2s ease;
                `;
                
                btn.onclick = () => {
                    if (preset.color === 'gradient') {
                        overlay.style.background = 'linear-gradient(180deg, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.2) 50%, rgba(0,0,0,0.6) 100%)';
                    } else {
                        overlayColorInput.value = preset.color;
                        opacitySlider.value = preset.opacity;
                        opacityValue.textContent = `${preset.opacity}%`;
                        updateOverlay();
                    }
                };
                
                presetButtons.appendChild(btn);
            });
            
            presetGroup.appendChild(presetLabel);
            presetGroup.appendChild(presetButtons);
            controls.appendChild(presetGroup);

            dialog.appendChild(controls);

            // リアルタイム更新
            const updateOverlay = () => {
                const color = overlayColorInput.value;
                const opacity = opacitySlider.value / 100;
                const r = parseInt(color.slice(1, 3), 16);
                const g = parseInt(color.slice(3, 5), 16);
                const b = parseInt(color.slice(5, 7), 16);
                overlay.style.background = `rgba(${r}, ${g}, ${b}, ${opacity})`;
            };

            overlayColorInput.oninput = updateOverlay;
            opacitySlider.oninput = () => {
                opacityValue.textContent = `${opacitySlider.value}%`;
                updateOverlay();
            };

            // アクションボタン
            const actions = document.createElement('div');
            actions.style.cssText = `display: flex; gap: 8px; margin-top: ${isMobile ? '12px' : '16px'};`;

            const cancelBtn = document.createElement('button');
            cancelBtn.textContent = 'キャンセル';
            cancelBtn.style.cssText = `
                flex: 1;
                padding: ${isMobile ? '8px 12px' : '10px 16px'};
                border: 1px solid #e0e0e0;
                border-radius: 6px;
                background: white;
                cursor: pointer;
                font-size: ${isMobile ? '13px' : '14px'};
            `;
            cancelBtn.onclick = () => modal.remove();

            const applyBtn = document.createElement('button');
            applyBtn.textContent = '適用';
            applyBtn.style.cssText = `
                flex: 1;
                padding: ${isMobile ? '8px 12px' : '10px 16px'};
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 600;
            `;
            
            applyBtn.onclick = () => {
                const color = overlayColorInput.value;
                const opacity = opacitySlider.value / 100;
                const r = parseInt(color.slice(1, 3), 16);
                const g = parseInt(color.slice(3, 5), 16);
                const b = parseInt(color.slice(5, 7), 16);
                
                let bgStyle;
                if (overlay.style.background.includes('gradient')) {
                    bgStyle = `linear-gradient(180deg, rgba(0,0,0,0.8) 0%, rgba(0,0,0,0.2) 50%, rgba(0,0,0,0.6) 100%), url('${imageUrl}')`;
                } else {
                    bgStyle = `linear-gradient(rgba(${r}, ${g}, ${b}, ${opacity}), rgba(${r}, ${g}, ${b}, ${opacity})), url('${imageUrl}')`;
                }
                
                onApply(bgStyle);
                modal.remove();
            };

            actions.appendChild(cancelBtn);
            actions.appendChild(applyBtn);
            dialog.appendChild(actions);

            modal.appendChild(dialog);
            document.body.appendChild(modal);
        }
        
        /**
         * 画像の使用状況をスキャン
         */
        scanImageUsage() {
            const usage = {};
            
            // すべての要素をスキャン
            const allElements = document.querySelectorAll('*');
            
            allElements.forEach(element => {
                // 背景画像をチェック
                const bgImage = window.getComputedStyle(element).backgroundImage;
                if (bgImage && bgImage !== 'none') {
                    const matches = bgImage.match(/url\(["']?([^"'\)]+)["']?\)/g);
                    if (matches) {
                        matches.forEach(match => {
                            const url = match.replace(/url\(["']?|["']?\)/g, '');
                            if (!usage[url]) usage[url] = [];
                            
                            const section = this.getElementSection(element);
                            usage[url].push({
                                element: element,
                                property: 'background-image',
                                section: section
                            });
                        });
                    }
                }
                
                // imgタグのsrcをチェック
                if (element.tagName === 'IMG' && element.src) {
                    const src = element.getAttribute('src') || element.src;
                    if (!usage[src]) usage[src] = [];
                    
                    const section = this.getElementSection(element);
                    usage[src].push({
                        element: element,
                        property: 'src',
                        section: section
                    });
                }
            });
            
            // 相対パスを統一
            const normalizedUsage = {};
            Object.entries(usage).forEach(([url, items]) => {
                // URLを正規化
                const normalizedUrl = this.normalizeImageUrl(url);
                if (!normalizedUsage[normalizedUrl]) {
                    normalizedUsage[normalizedUrl] = [];
                }
                normalizedUsage[normalizedUrl].push(...items);
            });
            
            return normalizedUsage;
        }
        
        /**
         * 要素が属するセクションを取得
         */
        getElementSection(element) {
            let current = element;
            while (current && current !== document.body) {
                if (current.id) {
                    // セクション名を日本語に変換
                    const sectionNames = {
                        'hero': 'ヒーロー',
                        'header': 'ヘッダー',
                        'footer': 'フッター',
                        'about': 'アバウト',
                        'programs': 'プログラム',
                        'pricing': '料金',
                        'access': 'アクセス',
                        'schedule': 'スケジュール',
                        'contents': 'コンテンツ'
                    };
                    return sectionNames[current.id] || current.id;
                }
                if (current.tagName === 'SECTION' || current.className.includes('section')) {
                    return current.className.split(' ')[0];
                }
                current = current.parentElement;
            }
            return 'その他';
        }
        
        /**
         * 画像URLを正規化
         */
        normalizeImageUrl(url) {
            // data:URLの場合はそのまま返す
            if (url.startsWith('data:')) {
                return url;
            }
            
            // フルパスのURLからパス部分のみ取得
            try {
                const urlObj = new URL(url, window.location.href);
                return urlObj.pathname;
            } catch (e) {
                return url;
            }
        }
        
        /**
         * URL入力を作成
         */
        createUrlInput(item) {
            const input = document.createElement('input');
            input.type = 'url';
            input.value = item.value;
            input.placeholder = item.type === 'image' ? '画像URL' : 'リンクURL';
            input.style.cssText = `
                padding: 12px 16px;
                border: 1px solid rgba(0, 0, 0, 0.15);
                border-radius: 8px;
                font-size: 16px;
                background: white;
                color: #333;
                transition: all 0.2s ease;
                outline: none;
            `;

            input.onfocus = () => {
                input.style.borderColor = '#2196F3';
                input.style.boxShadow = '0 0 0 3px rgba(33, 150, 243, 0.1)';
                input.style.background = '#ffffff';
            };

            input.onblur = () => {
                input.style.borderColor = '#e0e0e0';
                input.style.boxShadow = 'none';
                input.style.background = '#fafafa';
            };

            input.oninput = () => {
                this.handleChange(item.property, input.value, item.type);
            };

            return input;
        }

        /**
         * 変更を処理
         */
        handleChange(property, value, type) {
            console.log('QuickEditMenu.handleChange:', { property, value, type });
            console.log('QuickEditMenu.handleChange - element:', this.element);
            console.log('QuickEditMenu.handleChange - analysis:', this.analysis);
            
            if (this.options.onSave) {
                console.log('onSave実行中...', this.options.onSave);
                this.options.onSave(property, value, type);
            } else {
                console.error('onSaveコールバックが設定されていません');
            }
        }

        /**
         * メニューを表示
         */
        show() {
            document.body.appendChild(this.menu);

            // 位置を調整
            const x = this.options.x || 0;
            const y = this.options.y || 0;

            // モバイル判定
            const isMobile = window.innerWidth <= 768;
            
            if (isMobile) {
                // モバイルでは画面の左右端から10pxの位置に固定
                this.menu.style.left = '10px';
                this.menu.style.right = '10px';
                this.menu.style.width = 'calc(100vw - 20px)';
                this.menu.style.maxWidth = 'calc(100vw - 20px)';
                this.menu.style.transform = 'none';
                
                // 上下位置の調整 - 少し待ってからサイズを取得
                setTimeout(() => {
                    const menuRect = this.menu.getBoundingClientRect();
                    const windowHeight = window.innerHeight;
                    
                    // メニューが画面に収まるかチェック
                    if (menuRect.height > windowHeight - 40) {
                        // 画面に収まらない場合は上端から配置してスクロール可能にする
                        this.menu.style.top = '10px';
                        this.menu.style.bottom = '10px';
                        this.menu.style.height = 'calc(100vh - 20px)';
                        this.menu.style.overflowY = 'auto';
                        this.menu.style.maxHeight = 'calc(100vh - 20px)';
                    } else {
                        // 画面下半分の場合は下から配置
                        if (y > windowHeight / 2) {
                            this.menu.style.bottom = '10px';
                            this.menu.style.top = 'auto';
                            this.menu.classList.add('bottom-positioned');
                        } else {
                            this.menu.style.top = `${Math.max(10, y)}px`;
                            this.menu.style.bottom = 'auto';
                            this.menu.classList.remove('bottom-positioned');
                        }
                    }
                }, 10);
            } else {
                // デスクトップでは従来の位置調整ロジック
                const menuRect = this.menu.getBoundingClientRect();
                const windowWidth = window.innerWidth;
                const windowHeight = window.innerHeight;

                // 編集対象要素の位置とサイズを取得
                const elementRect = this.element.getBoundingClientRect();
                
                // メニューが要素と重ならないようにオフセットを追加
                const offsetDistance = 40; // メニューと要素の間隔
                
                let finalX = x;
                let finalY = y;
                
                // デフォルトは右側に配置
                if (x + menuRect.width + offsetDistance < windowWidth - 20) {
                    finalX = x + offsetDistance;
                } else {
                    // 右側に入らない場合は左側に配置
                    finalX = x - menuRect.width - offsetDistance;
                }
                
                // 垂直位置の調整
                if (y + menuRect.height > windowHeight - 20) {
                    // 下に入らない場合は上に配置
                    finalY = y - menuRect.height + elementRect.height;
                } else {
                    // 要素の上端に合わせる
                    finalY = y;
                }
                
                // 画面外にはみ出す場合の調整
                if (finalX < 10) {
                    finalX = 10;
                }
                if (finalX + menuRect.width > windowWidth - 10) {
                    finalX = windowWidth - menuRect.width - 10;
                }
                if (finalY < 10) {
                    finalY = 10;
                }
                if (finalY + menuRect.height > windowHeight - 10) {
                    finalY = windowHeight - menuRect.height - 10;
                }

                this.menu.style.left = `${finalX}px`;
                this.menu.style.top = `${finalY}px`;
                this.menu.style.right = 'auto';
                this.menu.style.bottom = 'auto';
                this.menu.style.width = '';
                this.menu.classList.remove('bottom-positioned');
            }

            // 外側クリックで閉じる
            setTimeout(() => {
                this.setupCloseHandler();
            }, 100);
        }

        /**
         * 外側クリックハンドラーをセットアップ
         */
        setupCloseHandler() {
            this.closeHandler = (e) => {
                if (!this.menu.contains(e.target) && e.target !== this.element) {
                    this.close();
                }
            };
            document.addEventListener('click', this.closeHandler);
        }

        /**
         * 編集タブのコンテンツを作成
         */
        createEditTabContent(panel) {
            const isMobile = window.innerWidth <= 768;
            
            // 自動保存の設定
            const autoSaveField = document.createElement('div');
            autoSaveField.style.cssText = `
                margin-bottom: 20px;
                padding: 16px;
                background: #f8f9fa;
                border-radius: 8px;
                border: 1px solid #e9ecef;
            `;
            
            const autoSaveLabel = document.createElement('label');
            autoSaveLabel.style.cssText = `
                display: flex;
                align-items: center;
                gap: 12px;
                cursor: pointer;
                font-size: 14px;
                color: #333;
                font-weight: 500;
            `;
            
            const autoSaveToggle = document.createElement('input');
            autoSaveToggle.type = 'checkbox';
            autoSaveToggle.checked = window.elementEditManager ? window.elementEditManager.autoSaveEnabled : true;
            autoSaveToggle.style.cssText = `
                width: 18px;
                height: 18px;
                cursor: pointer;
            `;
            
            const autoSaveText = document.createElement('span');
            autoSaveText.textContent = '編集を自動保存する';
            
            autoSaveToggle.onchange = () => {
                if (window.elementEditManager) {
                    const enabled = window.elementEditManager.toggleAutoSave();
                    this.showNotification(
                        `自動保存を${enabled ? '有効' : '無効'}にしました`,
                        'info'
                    );
                }
            };
            
            autoSaveLabel.appendChild(autoSaveToggle);
            autoSaveLabel.appendChild(autoSaveText);
            autoSaveField.appendChild(autoSaveLabel);
            
            // 説明文
            const description = document.createElement('div');
            description.textContent = '有効にすると、編集内容が自動的に保存されます。';
            description.style.cssText = `
                margin-top: 8px;
                font-size: 12px;
                color: #666;
                line-height: 1.4;
            `;
            autoSaveField.appendChild(description);
            
            panel.appendChild(autoSaveField);
            
            // 保存メニューボタンを追加
            const saveMenuSection = document.createElement('div');
            saveMenuSection.style.cssText = `
                margin-top: 20px;
                padding: 16px;
                background: #f0f8ff;
                border-radius: 8px;
                border: 1px solid #e0f0ff;
            `;
            
            const saveMenuLabel = document.createElement('div');
            saveMenuLabel.textContent = '全体保存メニュー';
            saveMenuLabel.style.cssText = `
                font-size: 14px;
                color: #333;
                font-weight: 500;
                margin-bottom: 8px;
            `;
            
            const saveMenuButton = document.createElement('button');
            saveMenuButton.textContent = '保存メニューを開く';
            saveMenuButton.style.cssText = `
                width: 100%;
                padding: 12px 16px;
                background: var(--accent-color, #64748b);
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 14px;
                cursor: pointer;
                font-weight: 500;
                transition: all 0.2s ease;
            `;
            
            saveMenuButton.onmouseover = () => {
                saveMenuButton.style.opacity = '0.9';
                saveMenuButton.style.transform = 'translateY(-1px)';
            };
            
            saveMenuButton.onmouseout = () => {
                saveMenuButton.style.opacity = '1';
                saveMenuButton.style.transform = 'translateY(0)';
            };
            
            saveMenuButton.onclick = () => {
                console.log('保存メニューボタンクリック');
                this.openSaveMenu();
            };
            
            const saveMenuDescription = document.createElement('div');
            saveMenuDescription.textContent = '編集内容の保存・デフォルト設定・リセットなどが行えます。';
            saveMenuDescription.style.cssText = `
                margin-top: 8px;
                font-size: 12px;
                color: #666;
                line-height: 1.4;
            `;
            
            saveMenuSection.appendChild(saveMenuLabel);
            saveMenuSection.appendChild(saveMenuButton);
            saveMenuSection.appendChild(saveMenuDescription);
            
            panel.appendChild(saveMenuSection);
        }

        /**
         * AIタブのコンテンツを作成
         */
        createAITabContent(panel) {
            // AIタブ以外のパネルの場合は何もしない
            if (panel.dataset.tabKey !== 'ai') {
                return;
            }
            
            // パネルをクリア
            panel.innerHTML = '';
            
            // AIEditInterfaceの初期化
            if (!this.aiInterface) {
                if (window.AIEditInterface) {
                    this.aiInterface = new window.AIEditInterface();
                } else {
                    // AIEditInterface.jsが読み込まれていない場合は動的に読み込む
                    const script = document.createElement('script');
                    script.src = 'js/AIEditInterface.js';
                    script.onload = () => {
                        this.aiInterface = new window.AIEditInterface();
                        this.createAITabContent(panel); // 再度呼び出し
                    };
                    document.head.appendChild(script);
                    
                    // ローディング表示
                    panel.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;">AI機能を読み込み中...</div>';
                    return;
                }
            }
            
            // AIインターフェースのコンテンツを作成（要素解析データを渡す）
            const elementAnalysis = {
                element: this.element,
                selector: this.getSelectorForElement(this.element),
                content: this.element.textContent ? this.element.textContent.trim() : '',
                editable: this.analysis.editable,
                styles: this.getCurrentStyles(this.element)
            };
            this.aiInterface.createContent(panel, elementAnalysis);
        }

        /**
         * 履歴タブのコンテンツを作成
         */
        createHistoryTabContent(panel) {
            // 履歴タブ以外のパネルの場合は何もしない
            if (panel.dataset.tabKey !== 'history') {
                return;
            }
            
            // パネルをクリア
            panel.innerHTML = '';
            
            // Git履歴管理の初期化
            if (!this.gitHistoryManager) {
                if (window.GitHistoryManager) {
                    const workingDir = this.getCurrentSiteDirectory();
                    this.gitHistoryManager = new window.GitHistoryManager(workingDir);
                } else {
                    panel.innerHTML = '<div style="text-align: center; padding: 20px; color: #666;">履歴機能を読み込み中...</div>';
                    return;
                }
            }

            // 履歴UIコンテナ
            const container = document.createElement('div');
            container.style.cssText = 'padding: 15px;';

            const header = document.createElement('div');
            header.style.cssText = `
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 15px;
            `;
            header.innerHTML = `
                <h4 style="margin: 0; font-size: 14px; color: #333;">編集履歴</h4>
                <button id="refresh-history" style="
                    padding: 6px 12px;
                    background: #2196F3;
                    color: white;
                    border: none;
                    border-radius: 4px;
                    font-size: 12px;
                    cursor: pointer;
                ">🔄 更新</button>
            `;

            const historyList = document.createElement('div');
            historyList.id = 'history-list';
            historyList.style.cssText = `
                display: flex;
                flex-direction: column;
                gap: 8px;
                max-height: 400px;
                overflow-y: auto;
            `;

            container.appendChild(header);
            container.appendChild(historyList);
            panel.appendChild(container);

            // 更新ボタンのイベント
            header.querySelector('#refresh-history').onclick = () => this.loadHistory(historyList);

            // 初回読み込み
            this.loadHistory(historyList);
        }

        /**
         * 現在のサイトディレクトリを取得
         */
        getCurrentSiteDirectory() {
            const currentPath = window.location.pathname;
            if (currentPath.startsWith('site/')) {
                return 'public/' + currentPath.replace(/\/$/, '');
            }
            return 'public/site/next/project';
        }

        /**
         * 履歴を読み込む
         */
        async loadHistory(historyList) {
            if (!this.gitHistoryManager) return;

            try {
                const commits = await this.gitHistoryManager.getHistory(10);
                
                if (commits.length === 0) {
                    historyList.innerHTML = '<div style="color: #999; text-align: center; padding: 20px;">履歴がありません</div>';
                    return;
                }

                historyList.innerHTML = commits.map(commit => `
                    <div style="
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        padding: 10px;
                        background: #f5f5f5;
                        border: 1px solid #e0e0e0;
                        border-radius: 6px;
                        cursor: pointer;
                    " data-hash="${commit.fullHash}">
                        <div>
                            <div style="font-size: 13px; font-weight: 500; color: #333;">${commit.description}</div>
                            <div style="font-size: 11px; color: #666; margin-top: 4px;">${commit.relativeTime}</div>
                        </div>
                        <button class="restore-btn" style="
                            padding: 6px 12px;
                            background: #64748b;
                            color: white;
                            border: none;
                            border-radius: 4px;
                            font-size: 12px;
                            cursor: pointer;
                        " onclick="event.stopPropagation();">復元</button>
                    </div>
                `).join('');

                // 復元ボタンのイベント
                historyList.querySelectorAll('.restore-btn').forEach(btn => {
                    btn.onclick = async (e) => {
                        e.stopPropagation();
                        const hash = e.target.parentElement.dataset.hash;
                        await this.restoreCommit(hash);
                    };
                });
            } catch (error) {
                console.error('履歴読み込みエラー:', error);
                historyList.innerHTML = '<div style="color: #f44336; text-align: center; padding: 20px;">履歴の読み込みに失敗しました</div>';
            }
        }

        /**
         * コミットを復元
         */
        async restoreCommit(commitHash) {
            if (!this.gitHistoryManager) return;
            
            if (!confirm('この時点の状態に復元しますか？')) return;

            try {
                await this.gitHistoryManager.restoreCommit(commitHash);
                alert('復元が完了しました。ページを再読み込みします。');
                
                // ページをリロード
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
            } catch (error) {
                console.error('復元エラー:', error);
                alert('復元に失敗しました: ' + error.message);
            }
        }

        /**
         * 要素のセレクタを生成
         */
        getSelectorForElement(element) {
            if (!element) return '';
            
            // IDがある場合
            if (element.id) {
                return `#${element.id}`;
            }
            
            // クラスがある場合
            if (element.className) {
                const classes = element.className.split(' ').filter(c => c).join('.');
                return `.${classes}`;
            }
            
            // タグ名のみ
            return element.tagName.toLowerCase();
        }

        /**
         * 要素の現在のスタイルを取得
         */
        getCurrentStyles(element) {
            if (!element) return {};
            
            const computed = window.getComputedStyle(element);
            return {
                backgroundColor: computed.backgroundColor,
                color: computed.color,
                fontSize: computed.fontSize,
                padding: computed.padding,
                margin: computed.margin,
                borderRadius: computed.borderRadius
            };
        }

        /**
         * タブデータを整理
         */
        organizeTabData() {
            const tabs = {
                basic: {
                    label: '基本',
                    items: []
                },
                background: {
                    label: '背景',
                    items: []
                },
                style: {
                    label: 'スタイル',
                    items: []
                },
                edit: {
                    label: '編集',
                    items: []
                },
                ai: {
                    label: 'AI',
                    items: [],
                    customContent: true
                },
                history: {
                    label: '履歴',
                    items: [],
                    customContent: true
                }
            };
            
            // 編集可能アイテムをタブに振り分け
            if (this.analysis && this.analysis.editable && Array.isArray(this.analysis.editable)) {
                console.log('📋 アイテム分類開始:', this.analysis.editable);
                this.analysis.editable.forEach(item => {
                    console.log(`📌 アイテム分類中:`, { type: item.type, property: item.property, item });
                    if (item.type === 'background' || item.property === 'backgroundColor' || item.property === 'backgroundImage') {
                        console.log('🎨 背景タブに追加:', item);
                        tabs.background.items.push(item);
                    } else if ((item.type === 'color' && item.property !== 'backgroundColor') || item.type === 'size' || item.property === 'borderColor' || item.property === 'borderWidth' || item.property === 'borderRadius' || item.property === 'padding' || item.property === 'boxShadow') {
                        console.log('🎭 スタイルタブに追加:', item);
                        tabs.style.items.push(item);
                    } else {
                        console.log('📝 基本タブに追加:', item);
                        tabs.basic.items.push(item);
                    }
                });
            } else {
                console.warn('Analysis data is missing or invalid:', this.analysis);
            }
            
            // タブ内容の最終確認
            console.log('📊 最終タブ構成:', {
                background: tabs.background.items.length,
                basic: tabs.basic.items.length,
                style: tabs.style.items.length,
                ai: tabs.ai.customContent
            });
            
            // 空のタブを削除（AIタブなどカスタムコンテンツタブは保持）
            const filteredTabs = {};
            Object.entries(tabs).forEach(([key, tab]) => {
                if (tab.items.length > 0 || tab.customContent) {
                    filteredTabs[key] = tab;
                }
            });
            
            return filteredTabs;
        }
        
        /**
         * タブ切り替え
         */
        switchTab(selectedKey, tabs, panels) {
            tabs.forEach(tab => {
                if (tab.key === selectedKey) {
                    tab.element.style.color = '#2196F3';
                    tab.element.style.borderBottomColor = '#2196F3';
                    tab.element.style.fontWeight = '600';
                } else {
                    tab.element.style.color = '#666';
                    tab.element.style.borderBottomColor = 'transparent';
                    tab.element.style.fontWeight = '500';
                }
            });
            
            panels.forEach(panel => {
                if (panel.key === selectedKey) {
                    panel.element.style.display = 'flex';
                } else {
                    panel.element.style.display = 'none';
                }
            });
        }
        
        /**
         * メニューを閉じる
         */
        close() {
            if (this.closeHandler) {
                document.removeEventListener('click', this.closeHandler);
            }

            this.menu.style.animation = 'quickEditSlideOut 0.2s ease';
            
            setTimeout(() => {
                if (this.menu && this.menu.parentNode) {
                    this.menu.remove();
                }
                
                if (this.options.onClose) {
                    this.options.onClose();
                }
            }, 200);
        }

        /**
         * 色を正規化
         */
        normalizeColor(color) {
            if (color.startsWith('#')) return color;
            
            if (color.startsWith('rgb')) {
                const matches = color.match(/\d+/g);
                if (matches && matches.length >= 3) {
                    const r = parseInt(matches[0]).toString(16).padStart(2, '0');
                    const g = parseInt(matches[1]).toString(16).padStart(2, '0');
                    const b = parseInt(matches[2]).toString(16).padStart(2, '0');
                    return `#${r}${g}${b}`;
                }
            }
            
            return '#000000';
        }

        /**
         * アニメーションスタイルを追加
         */
        addAnimationStyles() {
            if (!document.querySelector('#quick-edit-menu-styles')) {
                const style = document.createElement('style');
                style.id = 'quick-edit-menu-styles';
                style.textContent = `
                    @keyframes quickEditSlideIn {
                        from {
                            opacity: 0;
                            transform: scale(0.95) translateY(-10px);
                        }
                        to {
                            opacity: 1;
                            transform: scale(1) translateY(0);
                        }
                    }
                    
                    @keyframes quickEditSlideOut {
                        from {
                            opacity: 1;
                            transform: scale(1) translateY(0);
                        }
                        to {
                            opacity: 0;
                            transform: scale(0.95) translateY(-10px);
                        }
                    }
                    
                    .quick-edit-menu input[type="range"] {
                        -webkit-appearance: none;
                        appearance: none;
                        height: 6px;
                        background: #e0e0e0;
                        border-radius: 3px;
                        outline: none;
                    }
                    
                    .quick-edit-menu input[type="range"]::-webkit-slider-thumb {
                        -webkit-appearance: none;
                        appearance: none;
                        width: 20px;
                        height: 20px;
                        background: var(--accent-color, #64748b);
                        border-radius: 50%;
                        cursor: pointer;
                        transition: all 0.2s ease;
                    }
                    
                    .quick-edit-menu input[type="range"]::-webkit-slider-thumb:hover {
                        transform: scale(1.2);
                        box-shadow: 0 2px 8px rgba(100, 116, 139, 0.3);
                    }
                `;
                document.head.appendChild(style);
            }
        }
        
        /**
         * オリジナル状態を復元
         */
        async restoreOriginalState() {
            try {
                // 現在のページのパスを取得
                const currentPath = window.location.pathname;
                const sitePath = currentPath.replace(/^\/site\//, '').replace(/\/$/, '');
                
                // サーバーからオリジナル状態を取得
                const response = await fetch(`/api/site-state/get-original?path=${encodeURIComponent(sitePath)}`);
                
                if (!response.ok) {
                    throw new Error('オリジナルの状態を取得できませんでした');
                }
                
                const data = await response.json();
                const originalHTML = data.html;
                
                // 現在の編集内容を一時保存
                if (window.elementEditManager) {
                    await window.elementEditManager.saveEdits();
                }
                
                // ページ全体を一時的に更新
                // 現在のスクリプトやスタイルを保持
                const currentScripts = Array.from(document.querySelectorAll('script[src*="js/"]'));
                const currentStyles = Array.from(document.querySelectorAll('link[rel="stylesheet"], style'));
                
                // bodyの内容を置き換え
                const parser = new DOMParser();
                const originalDoc = parser.parseFromString(originalHTML, 'text/html');
                document.body.innerHTML = originalDoc.body.innerHTML;
                
                // 編集用のスクリプトとスタイルを再追加
                currentScripts.forEach(script => {
                    if (script.src.includes('ElementEditManager') || 
                        script.src.includes('QuickEditMenu') || 
                        script.src.includes('SectionClickEditor') ||
                        script.src.includes('FloatingControls')) {
                        const newScript = document.createElement('script');
                        newScript.src = script.src;
                        document.body.appendChild(newScript);
                    }
                });
                
                // スタイルも保持
                currentStyles.forEach(style => {
                    if (style.id && (style.id.includes('edit') || style.id.includes('floating'))) {
                        if (!document.getElementById(style.id)) {
                            document.head.appendChild(style.cloneNode(true));
                        }
                    }
                });
                
                return true;
            } catch (error) {
                console.error('オリジナル状態の復元エラー:', error);
                this.showNotification('オリジナル状態の復元に失敗しました', 'error');
                return false;
            }
        }
        
        /**
         * 要素のセレクターを取得
         */
        getElementSelector() {
            if (this.element.id) {
                return `#${this.element.id}`;
            }
            
            const classes = Array.from(this.element.classList).join('.');
            const tag = this.element.tagName.toLowerCase();
            return classes ? `${tag}.${classes}` : tag;
        }
        
        /**
         * 通知を表示
         */
        showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.className = `quick-edit-notification ${type}`;
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                padding: 12px 20px;
                background: ${type === 'success' ? '#64748b' : type === 'error' ? '#f44336' : type === 'warning' ? '#FF9800' : '#2196F3'};
                color: white;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                z-index: 100005;
                animation: slideIn 0.3s ease;
                font-size: 14px;
            `;
            
            notification.textContent = message;
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => notification.remove(), 300);
            }, 3000);
        }
        
        /**
         * やり直し機能
         */
        handleUndo() {
            // やり直しボタンを押されたときの処理
            if (window.elementEditManager) {
                // 現在の要素を元に戻す
                const elementId = window.elementEditManager.getElementId(this.element);
                const editedElementsData = window.elementEditManager.editedElements.get(elementId);
                
                if (editedElementsData) {
                    // 元のスタイルに戻す
                    Object.entries(editedElementsData.originalStyles).forEach(([property, value]) => {
                        if (property === 'textContent') {
                            this.element.textContent = value;
                        } else if (property === 'innerHTML') {
                            this.element.innerHTML = value;
                        } else if (property === 'src' || property === 'href') {
                            this.element[property] = value;
                        } else {
                            this.element.style[property] = value;
                        }
                    });
                    
                    // 編集履歴から削除
                    window.elementEditManager.editedElements.delete(elementId);
                    
                    // 通知
                    this.showNotification('変更を元に戻しました', 'info');
                    
                    // メニューを更新
                    setTimeout(() => {
                        this.close();
                    }, 1000);
                } else {
                    this.showNotification('元に戻す変更がありません', 'warning');
                }
            } else {
                this.showNotification('やり直し機能が利用できません', 'error');
            }
        }
        
        /**
         * 詳細編集を開く
         */
        openDetailedEdit() {
            // 詳細編集ボタンが押されたときの処理
            console.log('詳細編集を開きます');
            
            try {
                // 既存の詳細編集システムを使用
                if (window.sectionClickEditor && window.sectionClickEditor.openDetailEditor) {
                    console.log('SectionClickEditorを使用');
                    this.close();
                    setTimeout(() => {
                        window.sectionClickEditor.openDetailEditor(this.element);
                    }, 100);
                } else if (window.UniversalEditor) {
                    console.log('UniversalEditorを使用');
                    this.close();
                    setTimeout(() => {
                        new window.UniversalEditor(this.element);
                    }, 100);
                } else {
                    // 手動で詳細編集画面を作成
                    console.log('手動で詳細編集画面を作成');
                    this.createDetailedEditInterface();
                }
            } catch (error) {
                console.error('詳細編集の開始エラー:', error);
                this.showNotification('詳細編集の開始に失敗しました', 'error');
            }
        }

        /**
         * 保存メニューを開く
         */
        openSaveMenu() {
            console.log('保存メニューを開きます');
            
            // ElementEditManagerの初期化確認
            this.checkElementEditManager();
            
            try {
                // FloatingControlsの保存メニューを呼び出し
                if (window.floatingControls && window.floatingControls.showSaveMenu) {
                    console.log('FloatingControls.showSaveMenuを使用');
                    // QuickEditMenuを一旦閉じてから保存メニューを開く
                    this.close();
                    setTimeout(() => {
                        window.floatingControls.showSaveMenu();
                    }, 200);
                } else if (window.elementEditManager) {
                    // ElementEditManagerが直接利用できる場合の代替処理
                    console.log('ElementEditManagerを直接使用した保存処理');
                    this.close();
                    setTimeout(() => {
                        this.showDirectSaveMenu();
                    }, 200);
                } else {
                    console.error('FloatingControlsとElementEditManagerが利用できません');
                    this.showNotification('保存機能を初期化中です。少し待ってからお試しください。', 'warning');
                }
            } catch (error) {
                console.error('保存メニューの開始エラー:', error);
                this.showNotification('保存メニューの開始に失敗しました', 'error');
            }
        }
        
        /**
         * ElementEditManagerの初期化確認
         */
        checkElementEditManager() {
            if (!window.elementEditManager && window.ElementEditManager) {
                console.log('ElementEditManagerを手動初期化');
                window.elementEditManager = new window.ElementEditManager();
            }
        }
        
        /**
         * 直接保存メニューを表示
         */
        showDirectSaveMenu() {
            if (!window.elementEditManager) {
                this.showNotification('保存機能が利用できません', 'error');
                return;
            }
            
            // 簡易保存メニューを作成
            const overlay = document.createElement('div');
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.5);
                z-index: 100050;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            
            const menu = document.createElement('div');
            menu.style.cssText = `
                background: white;
                padding: 30px;
                border-radius: 12px;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
                min-width: 300px;
                text-align: center;
            `;
            
            const title = document.createElement('h3');
            title.textContent = '保存メニュー';
            title.style.cssText = 'margin: 0 0 20px 0; color: #333;';
            
            const saveBtn = document.createElement('button');
            saveBtn.textContent = '変更を保存';
            saveBtn.style.cssText = `
                background: #64748b;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                margin: 10px;
                cursor: pointer;
            `;
            
            const cancelBtn = document.createElement('button');
            cancelBtn.textContent = 'キャンセル';
            cancelBtn.style.cssText = `
                background: #ccc;
                color: #333;
                border: none;
                padding: 12px 24px;
                border-radius: 6px;
                margin: 10px;
                cursor: pointer;
            `;
            
            saveBtn.onclick = () => {
                try {
                    if (window.elementEditManager.getControlButtons) {
                        window.elementEditManager.getControlButtons().save();
                        this.showNotification('編集内容を保存しました', 'success');
                    }
                } catch (error) {
                    console.error('保存エラー:', error);
                    this.showNotification('保存に失敗しました', 'error');
                }
                overlay.remove();
            };
            
            cancelBtn.onclick = () => overlay.remove();
            overlay.onclick = (e) => {
                if (e.target === overlay) overlay.remove();
            };
            
            menu.appendChild(title);
            menu.appendChild(saveBtn);
            menu.appendChild(cancelBtn);
            overlay.appendChild(menu);
            document.body.appendChild(overlay);
        }
        
        /**
         * 手動で詳細編集インターフェースを作成
         */
        createDetailedEditInterface() {
            // 現在のクイックメニューを閉じる
            this.close();
            
            // 少し遅延してから詳細編集を開く
            setTimeout(() => {
                // フルスクリーンの編集インターフェースを作成
                const overlay = document.createElement('div');
                overlay.style.cssText = `
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    bottom: 0;
                    background: rgba(0, 0, 0, 0.8);
                    z-index: 100010;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                `;
                
                const editPanel = document.createElement('div');
                editPanel.style.cssText = `
                    background: white;
                    border-radius: 12px;
                    padding: 24px;
                    max-width: 600px;
                    width: 90vw;
                    max-height: 80vh;
                    overflow-y: auto;
                    position: relative;
                `;
                
                const title = document.createElement('h2');
                title.textContent = '詳細編集';
                title.style.cssText = 'margin: 0 0 20px 0; color: #333;';
                
                const closeBtn = document.createElement('button');
                closeBtn.textContent = '×';
                closeBtn.style.cssText = `
                    position: absolute;
                    top: 12px;
                    right: 16px;
                    background: none;
                    border: none;
                    font-size: 24px;
                    cursor: pointer;
                    color: #666;
                `;
                
                closeBtn.onclick = () => overlay.remove();
                
                editPanel.appendChild(title);
                editPanel.appendChild(closeBtn);
                
                // 要素の基本情報を表示
                const info = document.createElement('div');
                info.innerHTML = `
                    <p><strong>要素:</strong> ${this.element.tagName.toLowerCase()}</p>
                    <p><strong>クラス:</strong> ${this.element.className || '(なし)'}</p>
                    <p><strong>ID:</strong> ${this.element.id || '(なし)'}</p>
                `;
                info.style.cssText = 'margin-bottom: 20px; color: #666;';
                editPanel.appendChild(info);
                
                // より高度な編集が必要な場合の説明
                const message = document.createElement('div');
                message.innerHTML = `
                    <p>この要素の詳細編集には、より高度なエディターが必要です。</p>
                    <p>基本的な編集は、要素を右クリックしてクイック編集メニューからお試しください。</p>
                `;
                message.style.cssText = 'color: #666; line-height: 1.6;';
                editPanel.appendChild(message);
                
                overlay.appendChild(editPanel);
                document.body.appendChild(overlay);
                
                // ESCキーでも閉じる
                const handleKeyPress = (e) => {
                    if (e.key === 'Escape') {
                        overlay.remove();
                        document.removeEventListener('keydown', handleKeyPress);
                    }
                };
                document.addEventListener('keydown', handleKeyPress);
                
            }, 100);
        }
    }

    // グローバルに公開
    window.QuickEditMenu = QuickEditMenu;

})();

// 読み込み完了を通知
console.log('QuickEditMenu.js loaded');