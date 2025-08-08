(function() {
    'use strict';

    class SimpleFormBuilder {
        constructor() {
            this.formComponents = {
                text: this.createTextInput.bind(this),
                textarea: this.createTextarea.bind(this),
                color: this.createColorPicker.bind(this),
                link: this.createLinkInput.bind(this),
                image: this.createImageUploader.bind(this),
                price: this.createPriceInput.bind(this)
            };

            this.activeInputs = new Map();
        }

        /**
         * 解析結果からフォームを生成
         * @param {Object} analysisData - SectionAnalyzerの解析結果
         * @returns {HTMLElement} 生成されたフォーム
         */
        buildForm(analysisData) {
            try {
                if (!analysisData) {
                    throw new Error('解析データが提供されていません');
                }

                if (!analysisData.elements) {
                    throw new Error('解析データに要素情報が含まれていません');
                }

                const form = document.createElement('div');
                form.className = 'universal-edit-form';
                
                // セクションヘッダー
                const header = this.createFormHeader(analysisData);
                form.appendChild(header);

                // フォームコンテンツ
                const content = document.createElement('div');
                content.className = 'form-content';

                // カテゴリごとにセクションを作成
                if (analysisData.elements.texts && analysisData.elements.texts.length > 0) {
                    content.appendChild(this.createTextSection(analysisData.elements.texts));
                }

                if (analysisData.elements.links && analysisData.elements.links.length > 0) {
                    content.appendChild(this.createLinksSection(analysisData.elements.links));
                }

                if (analysisData.elements.images && analysisData.elements.images.length > 0) {
                    content.appendChild(this.createImagesSection(analysisData.elements.images));
                }

                if ((analysisData.elements.colors && analysisData.elements.colors.length > 0) || 
                    (analysisData.elements.styles && analysisData.elements.styles.length > 0)) {
                    content.appendChild(this.createStylesSection(analysisData.elements));
                }

                form.appendChild(content);

                // フォームフッター
                const footer = this.createFormFooter();
                form.appendChild(footer);

                return form;
            } catch (error) {
                console.error('フォーム生成エラー:', error);
                console.error('受信したデータ:', analysisData);
                
                // エラー時のフォールバック
                const errorForm = document.createElement('div');
                errorForm.className = 'universal-edit-form error';
                errorForm.innerHTML = `
                    <div class="form-header">
                        <h3 class="form-title">エラーが発生しました</h3>
                    </div>
                    <div class="form-content">
                        <p>フォームの生成中にエラーが発生しました。</p>
                        <p>詳細: ${error.message}</p>
                    </div>
                `;
                return errorForm;
            }
        }

        /**
         * フォームヘッダーを作成
         */
        createFormHeader(analysisData) {
            const header = document.createElement('div');
            header.className = 'form-header';
            
            const sectionName = analysisData.sectionName || 'セクション';
            const editableCount = analysisData.stats?.editableElements || 0;
            
            header.innerHTML = `
                <h3 class="form-title">${sectionName}を編集</h3>
                <div class="form-meta">
                    <span class="element-count">${editableCount}個の編集可能項目</span>
                    <button class="reanalyze-btn" type="button">
                        <span>再解析</span>
                    </button>
                </div>
            `;
            return header;
        }

        /**
         * テキストセクションを作成
         */
        createTextSection(texts) {
            const section = this.createSection('テキスト内容', 'text-section');
            
            texts.forEach(textData => {
                const field = document.createElement('div');
                field.className = 'form-field';

                const label = this.createLabel(this.getTextLabel(textData));
                field.appendChild(label);

                let input;
                if (textData.type === 'price') {
                    input = this.createPriceInput(textData);
                } else if (textData.content.length > 50) {
                    input = this.createTextarea(textData);
                } else {
                    input = this.createTextInput(textData);
                }

                field.appendChild(input);
                section.appendChild(field);

                // 入力値を保存
                this.activeInputs.set(textData.id, {
                    element: input,
                    data: textData
                });
            });

            return section;
        }

        /**
         * リンクセクションを作成
         */
        createLinksSection(links) {
            const section = this.createSection('リンク', 'links-section');
            
            links.forEach(linkData => {
                const field = this.createLinkInput(linkData);
                section.appendChild(field);

                // リンクの場合は複数の入力要素があるので、特別に処理
                const inputs = field.querySelectorAll('input');
                this.activeInputs.set(linkData.id, {
                    element: inputs,
                    data: linkData
                });
            });

            return section;
        }

        /**
         * 画像セクションを作成
         */
        createImagesSection(images) {
            const section = this.createSection('画像とメディア', 'images-section');
            
            images.forEach(imageData => {
                const field = this.createImageUploader(imageData);
                section.appendChild(field);

                const input = field.querySelector('input[type="url"]');
                this.activeInputs.set(imageData.id, {
                    element: input,
                    data: imageData
                });
            });

            return section;
        }

        /**
         * スタイルセクションを作成
         */
        createStylesSection(elements) {
            const section = this.createSection('色とスタイル', 'styles-section');
            
            // CSS変数（色）
            if (elements.colors && elements.colors.length > 0) {
                elements.colors.forEach(colorData => {
                    const field = document.createElement('div');
                    field.className = 'form-field color-field';

                    const label = this.createLabel(this.formatCSSVarName(colorData.name));
                    field.appendChild(label);

                    const input = this.createColorPicker(colorData);
                    field.appendChild(input);

                    section.appendChild(field);

                    this.activeInputs.set(colorData.id, {
                        element: input,
                        data: colorData
                    });
                });
            }

            // その他のスタイル
            if (elements.styles && elements.styles.length > 0) {
                const mainStyles = elements.styles.find(s => s.type === 'section');
                if (mainStyles) {
                    Object.entries(mainStyles.styles).forEach(([property, value]) => {
                        if (property.includes('color')) {
                            const colorData = {
                                id: `style-${property}`,
                                name: property,
                                value: value
                            };
                            const field = document.createElement('div');
                            field.className = 'form-field color-field';

                            const label = this.createLabel(this.formatPropertyName(property));
                            field.appendChild(label);

                            const input = this.createColorPicker(colorData);
                            field.appendChild(input);

                            section.appendChild(field);
                        }
                    });
                }
            }

            return section;
        }

        /**
         * セクションコンテナを作成
         */
        createSection(title, className) {
            const section = document.createElement('div');
            section.className = `form-section ${className}`;
            
            const sectionTitle = document.createElement('h4');
            sectionTitle.className = 'section-title';
            sectionTitle.textContent = title;
            
            section.appendChild(sectionTitle);
            return section;
        }

        /**
         * ラベルを作成
         */
        createLabel(text) {
            const label = document.createElement('label');
            label.className = 'form-label';
            label.textContent = text;
            return label;
        }

        /**
         * テキスト入力を作成
         */
        createTextInput(data) {
            const input = document.createElement('input');
            input.type = 'text';
            input.className = 'form-input text-input';
            input.value = data.content || '';
            input.dataset.elementId = data.id;
            input.dataset.selector = data.selector;
            
            // リアルタイムプレビュー
            input.addEventListener('input', (e) => {
                this.updatePreview(data.selector, e.target.value, 'text');
            });

            return input;
        }

        /**
         * テキストエリアを作成
         */
        createTextarea(data) {
            const textarea = document.createElement('textarea');
            textarea.className = 'form-input textarea-input';
            textarea.value = data.content || '';
            textarea.rows = 3;
            textarea.dataset.elementId = data.id;
            textarea.dataset.selector = data.selector;
            
            // 自動リサイズ
            textarea.addEventListener('input', (e) => {
                e.target.style.height = 'auto';
                e.target.style.height = e.target.scrollHeight + 'px';
                this.updatePreview(data.selector, e.target.value, 'text');
            });

            // 初期高さ設定
            setTimeout(() => {
                textarea.style.height = textarea.scrollHeight + 'px';
            }, 0);

            return textarea;
        }

        /**
         * カラーピッカーを作成
         */
        createColorPicker(data) {
            const container = document.createElement('div');
            container.className = 'color-picker-container';

            const colorInput = document.createElement('input');
            colorInput.type = 'color';
            colorInput.className = 'color-input';
            colorInput.value = this.normalizeColor(data.value);
            colorInput.dataset.elementId = data.id;

            const colorValue = document.createElement('input');
            colorValue.type = 'text';
            colorValue.className = 'color-value';
            colorValue.value = data.value;
            colorValue.pattern = '^#[0-9A-Fa-f]{6}$|^rgb\\(.*\\)$';

            // カラー変更イベント
            colorInput.addEventListener('input', (e) => {
                colorValue.value = e.target.value;
                if (data.name && data.name.startsWith('--')) {
                    this.updateCSSVariable(data.name, e.target.value);
                } else if (data.selector) {
                    this.updatePreview(data.selector, e.target.value, 'style', data.name || 'color');
                }
            });

            colorValue.addEventListener('input', (e) => {
                const normalized = this.normalizeColor(e.target.value);
                if (normalized) {
                    colorInput.value = normalized;
                    if (data.name && data.name.startsWith('--')) {
                        this.updateCSSVariable(data.name, e.target.value);
                    }
                }
            });

            container.appendChild(colorInput);
            container.appendChild(colorValue);

            return container;
        }

        /**
         * リンク入力を作成
         */
        createLinkInput(data) {
            const field = document.createElement('div');
            field.className = 'form-field link-field';

            const label = this.createLabel(data.text || 'リンク');
            field.appendChild(label);

            const linkContainer = document.createElement('div');
            linkContainer.className = 'link-input-container';

            // URL入力
            const urlInput = document.createElement('input');
            urlInput.type = 'url';
            urlInput.className = 'form-input url-input';
            urlInput.placeholder = 'URL';
            urlInput.value = data.href || '';
            urlInput.dataset.elementId = data.id;

            // テキスト入力
            const textInput = document.createElement('input');
            textInput.type = 'text';
            textInput.className = 'form-input link-text-input';
            textInput.placeholder = 'リンクテキスト';
            textInput.value = data.text || '';

            urlInput.addEventListener('input', (e) => {
                this.updateLinkPreview(data.selector, e.target.value, textInput.value);
            });

            textInput.addEventListener('input', (e) => {
                this.updateLinkPreview(data.selector, urlInput.value, e.target.value);
            });

            linkContainer.appendChild(urlInput);
            linkContainer.appendChild(textInput);
            field.appendChild(linkContainer);

            return field;
        }

        /**
         * 画像アップローダーを作成
         */
        createImageUploader(data) {
            const field = document.createElement('div');
            field.className = 'form-field image-field';

            const label = this.createLabel('画像');
            field.appendChild(label);

            const imageContainer = document.createElement('div');
            imageContainer.className = 'image-uploader-container';

            // プレビュー
            const preview = document.createElement('div');
            preview.className = 'image-preview';
            if (data.src) {
                preview.innerHTML = `<img src="${data.src}" alt="${data.alt || ''}">`;
            } else {
                preview.innerHTML = '<div class="no-image">画像なし</div>';
            }

            // URL入力
            const urlInput = document.createElement('input');
            urlInput.type = 'url';
            urlInput.className = 'form-input image-url-input';
            urlInput.placeholder = '画像URL';
            urlInput.value = data.src || '';
            urlInput.dataset.elementId = data.id;

            // Alt入力
            const altInput = document.createElement('input');
            altInput.type = 'text';
            altInput.className = 'form-input alt-input';
            altInput.placeholder = '代替テキスト';
            altInput.value = data.alt || '';

            urlInput.addEventListener('input', (e) => {
                this.updateImagePreview(data.selector, e.target.value, altInput.value);
                if (e.target.value) {
                    preview.innerHTML = `<img src="${e.target.value}" alt="${altInput.value}">`;
                } else {
                    preview.innerHTML = '<div class="no-image">画像なし</div>';
                }
            });

            imageContainer.appendChild(preview);
            imageContainer.appendChild(urlInput);
            imageContainer.appendChild(altInput);
            field.appendChild(imageContainer);

            return field;
        }

        /**
         * 価格入力を作成
         */
        createPriceInput(data) {
            const container = document.createElement('div');
            container.className = 'price-input-container';

            const currencySpan = document.createElement('span');
            currencySpan.className = 'currency';
            currencySpan.textContent = data.currency || '¥';

            const input = document.createElement('input');
            input.type = 'text';
            input.className = 'form-input price-input';
            input.value = data.value || '';
            input.pattern = '[0-9,]*';
            input.dataset.elementId = data.id;
            input.dataset.selector = data.selector;

            // 数値フォーマット
            input.addEventListener('input', (e) => {
                const value = e.target.value.replace(/[^0-9]/g, '');
                const formatted = this.formatPrice(value);
                e.target.value = formatted;
                
                const displayValue = `${currencySpan.textContent}${formatted}`;
                this.updatePreview(data.selector, displayValue, 'text');
            });

            container.appendChild(currencySpan);
            container.appendChild(input);

            return container;
        }

        /**
         * フォームフッターを作成
         */
        createFormFooter() {
            const footer = document.createElement('div');
            footer.className = 'form-footer';
            footer.innerHTML = `
                <button class="btn btn-primary save-btn" type="button">
                    <span>変更を保存</span>
                </button>
                <button class="btn btn-secondary cancel-btn" type="button">
                    <span>閉じる</span>
                </button>
            `;
            return footer;
        }

        /**
         * プレビュー更新
         */
        updatePreview(selector, value, type, property) {
            try {
                const element = document.querySelector(selector);
                if (!element) return;

                if (type === 'text') {
                    element.textContent = value;
                } else if (type === 'style') {
                    element.style[property] = value;
                }

                // 更新アニメーション
                element.classList.add('preview-updating');
                setTimeout(() => {
                    element.classList.remove('preview-updating');
                }, 300);
            } catch (error) {
                console.error('Preview update error:', error);
            }
        }

        /**
         * リンクプレビュー更新
         */
        updateLinkPreview(selector, href, text) {
            try {
                const element = document.querySelector(selector);
                if (!element) return;

                if (href) element.href = href;
                if (text) element.textContent = text;
            } catch (error) {
                console.error('Link preview update error:', error);
            }
        }

        /**
         * 画像プレビュー更新
         */
        updateImagePreview(selector, src, alt) {
            try {
                const element = document.querySelector(selector);
                if (!element) return;

                if (element.tagName === 'IMG') {
                    if (src) element.src = src;
                    if (alt) element.alt = alt;
                }
            } catch (error) {
                console.error('Image preview update error:', error);
            }
        }

        /**
         * CSS変数更新
         */
        updateCSSVariable(varName, value) {
            document.documentElement.style.setProperty(varName, value);
        }

        /**
         * ヘルパー関数
         */
        getTextLabel(textData) {
            const typeLabels = {
                'h1': '大見出し',
                'h2': '中見出し',
                'h3': '小見出し',
                'h4': '小見出し2',
                'p': '本文',
                'button': 'ボタン',
                'price': '価格'
            };

            return typeLabels[textData.type] || textData.type;
        }

        formatCSSVarName(varName) {
            const nameMap = {
                '--accent-color': 'アクセントカラー',
                '--primary-color': 'メインカラー',
                '--secondary-color': 'サブカラー',
                '--heading-color': '見出しの色',
                '--text-color': 'テキストカラー',
                '--bg-color': '背景色',
                '--border-color': '枠線の色'
            };
            return nameMap[varName] || varName.replace('--', '').replace(/-/g, ' ');
        }

        formatPropertyName(property) {
            const propMap = {
                'background-color': '背景色',
                'color': '文字色',
                'border-color': '枠線の色',
                'font-size': '文字サイズ'
            };
            return propMap[property] || property;
        }

        normalizeColor(color) {
            // rgb形式を16進数に変換
            if (color.startsWith('rgb')) {
                const matches = color.match(/\d+/g);
                if (matches && matches.length >= 3) {
                    const r = parseInt(matches[0]).toString(16).padStart(2, '0');
                    const g = parseInt(matches[1]).toString(16).padStart(2, '0');
                    const b = parseInt(matches[2]).toString(16).padStart(2, '0');
                    return `#${r}${g}${b}`;
                }
            }
            return color;
        }

        formatPrice(value) {
            return value.replace(/\B(?=(\d{3})+(?!\d))/g, ',');
        }

        /**
         * フォームの値を取得
         */
        getFormValues() {
            const values = {};
            this.activeInputs.forEach((inputData, id) => {
                const { element, data } = inputData;
                
                if (element instanceof NodeList) {
                    // リンクの場合
                    values[id] = {
                        href: element[0].value,
                        text: element[1].value
                    };
                } else if (element.type === 'color' || element.classList.contains('color-input')) {
                    // カラーの場合
                    const container = element.closest('.color-picker-container');
                    const textInput = container.querySelector('.color-value');
                    values[id] = textInput ? textInput.value : element.value;
                } else {
                    values[id] = element.value;
                }
            });
            return values;
        }

        /**
         * フォームをリセット
         */
        resetForm() {
            this.activeInputs.clear();
        }
    }

    // グローバルに公開
    window.SimpleFormBuilder = SimpleFormBuilder;

})();

// 読み込み完了を通知
console.log('SimpleFormBuilder.js loaded');