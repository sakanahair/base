(function() {
    'use strict';

    class SectionAnalyzer {
        constructor() {
            this.editableSelectors = {
                texts: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'span', 'li', 'td', 'th', 'label', 'button', '.title', '.subtitle', '.description', '.text'],
                links: ['a[href]', 'button[onclick]', '[data-link]'],
                images: ['img[src]', 'svg', '.image-placeholder', '[data-image]', 'picture source'],
                prices: ['.price', '.amount', '.cost', '[data-price]', '.price-amount', '.option-price'],
                icons: ['.icon', '.emoji', '[data-icon]', '.feature-icon']
            };

            this.styleProperties = [
                'background-color',
                'color',
                'border-color',
                'font-size',
                'padding',
                'margin',
                'border-radius'
            ];

            this.cssVariables = [
                '--accent-color',
                '--primary-color',
                '--secondary-color',
                '--heading-color',
                '--text-color',
                '--bg-color',
                '--border-color'
            ];
        }

        /**
         * セクションを解析して編集可能な要素を抽出
         * @param {HTMLElement} section - 解析対象のセクション
         * @returns {Object} 編集可能な要素の構造化データ
         */
        analyze(section) {
            if (!section) return null;

            const analysisResult = {
                sectionId: section.id,
                sectionName: this.getSectionName(section),
                timestamp: new Date().toISOString(),
                elements: {
                    texts: [],
                    links: [],
                    images: [],
                    colors: [],
                    styles: []
                },
                stats: {
                    totalElements: 0,
                    editableElements: 0
                }
            };

            // テキスト要素の解析
            this.analyzeTextElements(section, analysisResult);
            
            // リンク要素の解析
            this.analyzeLinkElements(section, analysisResult);
            
            // 画像要素の解析
            this.analyzeImageElements(section, analysisResult);
            
            // スタイル・色の解析
            this.analyzeStyles(section, analysisResult);

            // 統計情報の更新
            this.updateStats(analysisResult);

            return analysisResult;
        }

        /**
         * テキスト要素を解析
         */
        analyzeTextElements(section, result) {
            this.editableSelectors.texts.forEach(selector => {
                const elements = section.querySelectorAll(selector);
                elements.forEach(element => {
                    // 既に処理済みまたは空の要素はスキップ
                    if (element.dataset.analyzed || !element.textContent.trim()) return;
                    
                    // 価格要素は別カテゴリで処理
                    if (this.isPriceElement(element)) {
                        this.analyzePriceElement(element, result);
                        return;
                    }

                    const textData = {
                        id: this.generateElementId(element),
                        type: element.tagName.toLowerCase(),
                        selector: this.generateSelector(element),
                        content: element.textContent.trim(),
                        editable: !element.hasAttribute('contenteditable') || element.contentEditable === 'true',
                        path: this.getElementPath(element),
                        styles: this.getComputedStyles(element)
                    };

                    result.elements.texts.push(textData);
                    element.dataset.analyzed = 'true';
                });
            });
        }

        /**
         * リンク要素を解析
         */
        analyzeLinkElements(section, result) {
            this.editableSelectors.links.forEach(selector => {
                const elements = section.querySelectorAll(selector);
                elements.forEach(element => {
                    if (element.dataset.analyzed) return;

                    const linkData = {
                        id: this.generateElementId(element),
                        type: 'link',
                        selector: this.generateSelector(element),
                        text: element.textContent.trim(),
                        href: element.href || element.getAttribute('data-link') || '#',
                        target: element.target || '_self',
                        path: this.getElementPath(element)
                    };

                    result.elements.links.push(linkData);
                    element.dataset.analyzed = 'true';
                });
            });
        }

        /**
         * 画像要素を解析
         */
        analyzeImageElements(section, result) {
            this.editableSelectors.images.forEach(selector => {
                const elements = section.querySelectorAll(selector);
                elements.forEach(element => {
                    if (element.dataset.analyzed) return;

                    const imageData = {
                        id: this.generateElementId(element),
                        type: element.tagName.toLowerCase(),
                        selector: this.generateSelector(element),
                        src: element.src || element.getAttribute('data-image') || '',
                        alt: element.alt || '',
                        width: element.width || 'auto',
                        height: element.height || 'auto',
                        path: this.getElementPath(element)
                    };

                    // SVGの場合は内容も保存
                    if (element.tagName.toLowerCase() === 'svg') {
                        imageData.svgContent = element.outerHTML;
                    }

                    result.elements.images.push(imageData);
                    element.dataset.analyzed = 'true';
                });
            });
        }

        /**
         * スタイルと色を解析
         */
        analyzeStyles(section, result) {
            // セクション自体のスタイル
            const sectionStyles = this.extractEditableStyles(section);
            if (Object.keys(sectionStyles).length > 0) {
                result.elements.styles.push({
                    id: 'section-styles',
                    selector: `#${section.id}`,
                    styles: sectionStyles,
                    type: 'section'
                });
            }

            // 主要な子要素のスタイル
            const styledElements = section.querySelectorAll('[style], [class]');
            const processedSelectors = new Set();

            styledElements.forEach(element => {
                const selector = this.generateSelector(element);
                
                // 同じセレクタは一度だけ処理
                if (processedSelectors.has(selector)) return;
                processedSelectors.add(selector);

                const elementStyles = this.extractEditableStyles(element);
                if (Object.keys(elementStyles).length > 0) {
                    result.elements.styles.push({
                        id: this.generateElementId(element),
                        selector: selector,
                        styles: elementStyles,
                        type: 'element'
                    });
                }
            });

            // CSS変数の抽出
            this.extractCSSVariables(section, result);
        }

        /**
         * 編集可能なスタイルを抽出
         */
        extractEditableStyles(element) {
            const computedStyles = window.getComputedStyle(element);
            const editableStyles = {};

            // 背景色
            const bgColor = computedStyles.backgroundColor;
            if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
                editableStyles['background-color'] = bgColor;
            }

            // 文字色
            const color = computedStyles.color;
            if (color && color !== 'rgb(0, 0, 0)') {
                editableStyles['color'] = color;
            }

            // ボーダー色
            const borderColor = computedStyles.borderColor;
            if (borderColor && borderColor !== 'rgb(0, 0, 0)') {
                editableStyles['border-color'] = borderColor;
            }

            // フォントサイズ
            editableStyles['font-size'] = computedStyles.fontSize;

            // パディング
            const padding = computedStyles.padding;
            if (padding && padding !== '0px') {
                editableStyles['padding'] = padding;
            }

            return editableStyles;
        }

        /**
         * CSS変数を抽出
         */
        extractCSSVariables(section, result) {
            const rootStyles = window.getComputedStyle(document.documentElement);
            const usedVariables = {};

            this.cssVariables.forEach(varName => {
                const value = rootStyles.getPropertyValue(varName).trim();
                if (value) {
                    usedVariables[varName] = value;
                }
            });

            if (Object.keys(usedVariables).length > 0) {
                result.elements.colors = Object.entries(usedVariables).map(([name, value]) => ({
                    id: `var-${name.replace('--', '')}`,
                    name: name,
                    value: value,
                    type: 'css-variable'
                }));
            }
        }

        /**
         * 価格要素かどうかを判定
         */
        isPriceElement(element) {
            const text = element.textContent;
            const className = element.className;
            return /¥|円|price|cost|amount/i.test(className) || /¥[\d,]+|[\d,]+円/.test(text);
        }

        /**
         * 価格要素を解析
         */
        analyzePriceElement(element, result) {
            const priceMatch = element.textContent.match(/¥?([\d,]+)円?/);
            const priceData = {
                id: this.generateElementId(element),
                type: 'price',
                selector: this.generateSelector(element),
                content: element.textContent.trim(),
                value: priceMatch ? priceMatch[1].replace(/,/g, '') : '0',
                currency: '¥',
                path: this.getElementPath(element)
            };

            result.elements.texts.push(priceData);
        }

        /**
         * 要素のIDを生成
         */
        generateElementId(element) {
            const tag = element.tagName.toLowerCase();
            const className = element.className ? element.className.split(' ')[0] : '';
            const index = Array.from(element.parentNode.children).indexOf(element);
            return `${tag}-${className}-${index}`.replace(/[^\w-]/g, '');
        }

        /**
         * CSSセレクタを生成
         */
        generateSelector(element) {
            if (element.id) {
                return `#${element.id}`;
            }

            let selector = element.tagName.toLowerCase();
            if (element.className) {
                selector += `.${element.className.split(' ').join('.')}`;
            }

            // 親要素の情報も含める
            let parent = element.parentElement;
            let parentSelector = '';
            if (parent && parent.id) {
                parentSelector = `#${parent.id} > `;
            } else if (parent && parent.className) {
                parentSelector = `${parent.tagName.toLowerCase()}.${parent.className.split(' ')[0]} > `;
            }

            return parentSelector + selector;
        }

        /**
         * 要素のパスを取得
         */
        getElementPath(element) {
            const path = [];
            let current = element;

            while (current && current !== document.body) {
                let selector = current.tagName.toLowerCase();
                if (current.id) {
                    selector = `#${current.id}`;
                } else if (current.className) {
                    selector += `.${current.className.split(' ')[0]}`;
                }
                path.unshift(selector);
                current = current.parentElement;
            }

            return path.join(' > ');
        }

        /**
         * 要素の計算済みスタイルを取得
         */
        getComputedStyles(element) {
            const computed = window.getComputedStyle(element);
            return {
                fontSize: computed.fontSize,
                fontWeight: computed.fontWeight,
                color: computed.color,
                backgroundColor: computed.backgroundColor,
                lineHeight: computed.lineHeight
            };
        }

        /**
         * セクション名を取得
         */
        getSectionName(section) {
            const sectionId = section.id.replace('-component', '');
            const sectionNames = {
                'header': 'ヘッダー',
                'hero': 'ヒーロー',
                'about': 'スタジオ紹介',
                'programs': 'プログラム',
                'pricing': '料金プラン',
                'schedule': 'スケジュール',
                'access': 'アクセス',
                'footer': 'フッター'
            };
            return sectionNames[sectionId] || sectionId;
        }

        /**
         * 統計情報を更新
         */
        updateStats(result) {
            let totalEditableElements = 0;
            Object.values(result.elements).forEach(category => {
                if (Array.isArray(category)) {
                    totalEditableElements += category.length;
                }
            });

            result.stats.editableElements = totalEditableElements;
            result.stats.totalElements = result.elements.texts.length + 
                                        result.elements.links.length + 
                                        result.elements.images.length;
        }

        /**
         * 解析をリセット（再解析前に実行）
         */
        resetAnalysis(section) {
            const analyzedElements = section.querySelectorAll('[data-analyzed]');
            analyzedElements.forEach(element => {
                delete element.dataset.analyzed;
            });
        }
    }

    // グローバルに公開
    window.SectionAnalyzer = SectionAnalyzer;

})();

// 読み込み完了を通知
console.log('SectionAnalyzer.js loaded');