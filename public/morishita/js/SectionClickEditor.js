(function() {
    'use strict';

    class SectionClickEditor {
        constructor() {
            this.isActive = false;
            this.currentSection = null;
            this.editableElements = new Set();
            this.quickEditMenu = null;
            this.clickHandler = null;
            this.hoverHandler = null;
            this.currentEditingElement = null;
            
            this.init();
        }

        init() {
            console.log('🔧 SectionClickEditor初期化開始');
            
            // イベントハンドラーをバインド
            this.clickHandler = this.handleClick.bind(this);
            this.hoverHandler = this.handleHover.bind(this);
            this.mouseLeaveHandler = this.handleMouseLeave.bind(this);
            
            // セクション選択イベントをリッスン（優先度を高める）
            document.addEventListener('sectionSelected', (event) => {
                console.log('🎯 SectionClickEditor - sectionSelectedイベント受信:', event.detail);
                console.log('セクション要素:', event.detail?.section);
                console.log('セクションタグ名:', event.detail?.section?.tagName);
                console.log('セクションID:', event.detail?.section?.id);
                console.log('セクションクラス:', event.detail?.section?.className);
                
                if (event.detail && event.detail.section) {
                    // イベントの伝播を停止して他のリスナーとの競合を防ぐ
                    event.stopImmediatePropagation();
                    
                    // 少し遅延させてUniversalEditorとの競合を避ける
                    setTimeout(() => {
                        console.log('🎯 SectionClickEditor - activateForSection実行開始');
                        this.activateForSection(event.detail.section);
                    }, 100);
                } else {
                    console.error('❌ セクション情報が不完全です');
                }
            }, true); // capture フェーズで先に処理
            
            // セクション選択解除イベント（カスタム実装）
            document.addEventListener('sectionDeselected', () => {
                console.log('🔄 sectionDeselectedイベント受信');
                this.deactivate();
            });
            
            console.log('✅ SectionClickEditor初期化完了');
        }

        /**
         * セクション内クリック編集を有効化
         */
        activateForSection(section) {
            console.log('🎯 SectionClickEditor有効化開始:', section);
            console.log('セクション詳細:', {
                tagName: section.tagName,
                className: section.className,
                id: section.id,
                children: section.children.length,
                bounds: section.getBoundingClientRect(),
                visible: section.offsetWidth > 0 && section.offsetHeight > 0
            });
            
            // セクションが存在し有効かチェック
            if (!section || !section.tagName) {
                console.error('❌ 無効なセクション要素です');
                return;
            }
            
            // 既存のアクティブセクションがあれば無効化
            if (this.isActive && this.currentSection) {
                console.log('🔄 既存セクションを無効化');
                this.deactivate();
            }
            
            this.currentSection = section;
            this.isActive = true;
            
            // 編集可能な要素を検出
            console.log('🔍 編集可能要素の検出開始...');
            this.detectEditableElements();
            console.log('📝 編集可能な要素数:', this.editableElements.size);
            
            if (this.editableElements.size === 0) {
                console.warn('⚠️ このセクションには編集可能な要素がありません - 強制検出を実行');
                this.forceDetectElements();
                console.log('🔧 強制検出後の要素数:', this.editableElements.size);
            }
            
            // 編集可能要素をコンソールに表示
            console.log('📋 検出された編集可能要素一覧:');
            let elementIndex = 0;
            this.editableElements.forEach(element => {
                console.log(`  ${++elementIndex}. ${element.tagName}#${element.id || 'no-id'}.${element.className || 'no-class'} - "${element.textContent?.trim().substring(0, 30)}"`);
            });
            
            // イベントリスナーを追加
            console.log('🎪 イベントリスナーを追加中...');
            try {
                this.currentSection.addEventListener('click', this.clickHandler, true);
                this.currentSection.addEventListener('mouseover', this.hoverHandler);
                this.currentSection.addEventListener('mouseleave', this.mouseLeaveHandler);
                console.log('✅ イベントリスナー追加完了');
            } catch (error) {
                console.error('❌ イベントリスナー追加エラー:', error);
            }
            
            // 編集モードメッセージを表示
            this.showEditModeMessage();
            
            console.log('✅ SectionClickEditor有効化完了 - isActive:', this.isActive);
        }

        /**
         * 編集可能な要素を検出
         */
        detectEditableElements() {
            this.editableElements.clear();
            
            // 全ての要素を走査して編集可能かどうかを判定
            const allElements = this.currentSection.querySelectorAll('*');
            console.log('🔍 セクション内の全要素数:', allElements.length);
            
            allElements.forEach(element => {
                if (this.isElementEditable(element)) {
                    this.editableElements.add(element);
                }
            });
            
            console.log('📋 検出された編集可能要素:', Array.from(this.editableElements).map(el => ({
                tag: el.tagName,
                class: el.className || 'no-class',
                text: el.textContent?.trim().substring(0, 20),
                isIcon: this.isIconElement(el)
            })));
        }

        /**
         * 強制的に要素を検出（編集可能要素が見つからない場合）
         */
        forceDetectElements() {
            console.log('🔧 強制検出モード開始');
            
            // より緩い条件で要素を検出
            const allElements = this.currentSection.querySelectorAll('*');
            
            allElements.forEach(element => {
                const hasText = element.textContent && element.textContent.trim().length > 0;
                const tagName = element.tagName.toLowerCase();
                const isTextElement = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'span', 'div', 'a', 'button', 'li'].includes(tagName);
                
                if (hasText && isTextElement) {
                    this.editableElements.add(element);
                    console.log('➕ 強制追加:', {
                        tag: element.tagName,
                        class: element.className,
                        text: element.textContent.trim().substring(0, 30)
                    });
                }
            });
            
            console.log('🎯 強制検出結果:', this.editableElements.size, '個の要素を追加');
        }
        
        /**
         * 要素が編集可能かどうかを判定
         */
        isElementEditable(element) {
            const tagName = element.tagName.toLowerCase();
            const hasText = element.textContent && element.textContent.trim();
            const computed = window.getComputedStyle(element);
            const rect = element.getBoundingClientRect();
            
            // 基本的な除外条件
            if (rect.width < 5 || rect.height < 5) return false; // 極小要素は除外
            if (element.style.display === 'none') return false; // 非表示要素は除外
            if (computed.visibility === 'hidden') return false; // 不可視要素は除外
            
            // 1. 最高優先度：アイコン要素
            if (this.isIconElement(element)) {
                return true;
            }
            
            // 2. 高優先度：テキスト要素（最小単位）
            if (this.isTextElement(element)) {
                return true;
            }
            
            // 3. 画像要素
            if (tagName === 'img') {
                return true;
            }
            
            // 4. 背景やボーダーを持つ要素（ただし、サイズ制限あり）
            if (this.hasVisualStyles(element) && rect.width >= 30 && rect.height >= 15) {
                return true;
            }
            
            // 5. 特定のクラスを持つ要素
            if (this.hasEditableClasses(element)) {
                return true;
            }
            
            // 6. divやsectionなどのコンテナ要素で、特定の条件を満たすもの
            const containerTags = ['div', 'section', 'article', 'aside', 'header', 'footer', 'main'];
            if (containerTags.includes(tagName)) {
                // 子要素が少なく、直接テキストを含む場合
                if (element.children.length <= 2 && hasText) {
                    return true;
                }
                // 特定のrole属性を持つ場合
                const role = element.getAttribute('role');
                if (role && ['button', 'link', 'heading', 'banner', 'contentinfo'].includes(role)) {
                    return true;
                }
            }
            
            return false;
        }
        
        /**
         * テキスト要素かどうかを判定（最も重要）
         */
        isTextElement(element) {
            const tagName = element.tagName.toLowerCase();
            const hasText = element.textContent && element.textContent.trim();
            
            if (!hasText) return false;
            
            // インライン要素（最高優先度）
            const inlineElements = ['span', 'a', 'strong', 'em', 'b', 'i', 'small', 'mark', 'code', 'kbd', 'var', 'samp'];
            if (inlineElements.includes(tagName)) {
                return true;
            }
            
            // ブロック要素（高優先度）
            const blockElements = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'li', 'td', 'th', 'label', 'button', 'figcaption', 'dt', 'dd', 'caption', 'legend'];
            if (blockElements.includes(tagName)) {
                return true;
            }
            
            // 直接的なテキストノードを持つ要素
            const hasDirectText = Array.from(element.childNodes).some(node => 
                node.nodeType === Node.TEXT_NODE && node.textContent.trim()
            );
            
            if (hasDirectText) {
                // 子要素が少ない場合のみ対象とする
                const childElementCount = element.children.length;
                return childElementCount <= 3;
            }
            
            return false;
        }
        
        /**
         * 視覚的スタイルを持つかどうかを判定
         */
        hasVisualStyles(element) {
            const computed = window.getComputedStyle(element);
            
            // 背景色
            const bgColor = computed.backgroundColor;
            if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
                return true;
            }
            
            // 背景画像
            const bgImage = computed.backgroundImage;
            if (bgImage && bgImage !== 'none') {
                return true;
            }
            
            // ボーダー
            const borderWidth = computed.borderWidth;
            if (borderWidth && borderWidth !== '0px') {
                return true;
            }
            
            // ボックスシャドウ
            const boxShadow = computed.boxShadow;
            if (boxShadow && boxShadow !== 'none') {
                return true;
            }
            
            return false;
        }
        
        /**
         * 編集可能なクラスを持つかどうかを判定
         */
        hasEditableClasses(element) {
            const classList = (element.className || '').toString().toLowerCase();
            const editableClasses = [
                'card', 'panel', 'box', 'button', 'btn', 'link', 'title', 'heading', 
                'text', 'content', 'description', 'caption', 'label', 'tag', 'badge',
                'hero', 'banner', 'feature', 'highlight', 'accent', 'section',
                'program', 'pricing', 'schedule', 'access', 'footer', 'about',
                'service', 'price', 'plan', 'time', 'location', 'address', 'contact',
                'subtitle', 'intro', 'info', 'detail', 'item', 'list', 'stat',
                'number', 'value', 'metric', 'icon', 'image', 'logo', 'brand',
                'nav', 'menu', 'social', 'copyright', 'legal', 'policy',
                // 日本語関連のクラス名
                'catch', 'copy', 'lead', 'note', 'point', 'sub', 'main',
                'header', 'body', 'wrapper', 'inner', 'outer', 'container',
                'block', 'unit', 'module', 'component', 'widget', 'element'
            ];
            
            return editableClasses.some(cls => classList.includes(cls));
        }

        /**
         * クリックハンドラー
         */
        handleClick(event) {
            console.log('🖱️ クリックイベント発生:', {
                target: event.target.tagName,
                className: event.target.className,
                text: event.target.textContent?.trim().substring(0, 20)
            });
            
            if (!this.isActive) {
                console.log('❌ SectionClickEditorが非アクティブ');
                return;
            }
            
            if (!this.currentSection) {
                console.log('❌ 現在のセクションが設定されていません');
                return;
            }
            
            console.log('✅ アクティブ状態確認OK');
            event.preventDefault();
            event.stopPropagation();
            
            const target = event.target;
            
            // 既存のメニューを閉じる
            if (this.quickEditMenu) {
                console.log('🔄 既存メニューを閉じる');
                this.quickEditMenu.close();
            }
            
            // 編集可能な要素かチェック
            console.log('🔍 編集可能要素を検索中...');
            const editableElement = this.findEditableElement(target);
            console.log('🎯 編集可能な要素:', editableElement ? {
                tag: editableElement.tagName,
                class: editableElement.className,
                text: editableElement.textContent?.trim().substring(0, 30)
            } : 'なし');
            
            if (!editableElement) {
                console.log('❌ 編集可能な要素が見つかりません');
                console.log('利用可能な編集可能要素一覧:', Array.from(this.editableElements).map(el => ({
                    tag: el.tagName,
                    class: el.className
                })));
                return;
            }
            
            // 要素を解析
            console.log('📊 要素解析中...');
            const analysis = this.analyzeElement(editableElement);
            console.log('📋 要素の解析結果:', analysis);
            
            if (!analysis.editable.length) {
                console.log('❌ 編集可能なプロパティがありません');
                return;
            }
            
            // クイック編集メニューを表示
            console.log('🎪 クイック編集メニュー表示');
            this.showQuickEditMenu(event.pageX, event.pageY, editableElement, analysis);
        }

        /**
         * ホバーハンドラー
         */
        handleHover(event) {
            if (!this.isActive || this.quickEditMenu) return;
            
            const target = event.target;
            const editableElement = this.findEditableElement(target);
            
            if (editableElement) {
                editableElement.style.outline = '2px dashed var(--accent-color, #64748b)';
                editableElement.style.outlineOffset = '2px';
                editableElement.style.cursor = 'pointer';
            }
        }
        
        /**
         * ホバーハイライトをクリア
         */
        clearHoverHighlight() {
            if (this.currentHoveredElement && this.currentHoveredElement !== this.currentEditingElement) {
                this.currentHoveredElement.style.outline = '';
                this.currentHoveredElement.style.outlineOffset = '';
                this.currentHoveredElement.style.cursor = '';
                this.currentHoveredElement.style.position = '';
                this.currentHoveredElement.style.zIndex = '';
                this.currentHoveredElement = null;
            }
        }

        /**
         * マウス離脱ハンドラー
         */
        handleMouseLeave(event) {
            const target = event.target;
            if (this.editableElements.has(target) && target !== this.currentEditingElement) {
                target.style.outline = '';
                target.style.outlineOffset = '';
                target.style.cursor = '';
            }
        }

        /**
         * 編集可能な要素を探す（テキストノード基準）
         */
        findEditableElement(clickedElement) {
            console.log('クリック要素:', clickedElement, 'タグ:', clickedElement.tagName);
            
            // クリックされた要素が編集可能なら、それを返す
            if (this.editableElements.has(clickedElement)) {
                console.log('クリック要素自体が編集可能:', clickedElement.tagName);
                return clickedElement;
            }
            
            // テキストノードがクリックされた場合、その親要素を確認
            let current = clickedElement.parentElement;
            while (current && current !== this.currentSection) {
                if (this.editableElements.has(current)) {
                    // 親要素が直接テキストを持っているかチェック
                    const hasDirectText = Array.from(current.childNodes).some(node => 
                        node.nodeType === Node.TEXT_NODE && node.textContent.trim()
                    );
                    
                    if (hasDirectText) {
                        console.log('直接テキストを持つ親要素を選択:', current.tagName);
                        return current;
                    } else {
                        console.log('親要素を選択:', current.tagName);
                        return current;
                    }
                }
                current = current.parentElement;
            }
            
            console.log('編集可能な要素が見つかりません');
            return null;
        }
        
        /**
         * 要素の直接的なテキストのみを取得（子要素のテキストは除外）
         */
        getDirectText(element) {
            let directText = '';
            for (let node of element.childNodes) {
                if (node.nodeType === Node.TEXT_NODE) {
                    directText += node.textContent.trim();
                }
            }
            return directText;
        }
        
        /**
         * 要素のサイズを取得（面積）
         */
        getElementSize(element) {
            const rect = element.getBoundingClientRect();
            return rect.width * rect.height;
        }
        
        /**
         * 要素の特異性を計算（編集対象としての適切さ）
         */
        getElementSpecificity(element) {
            let specificity = 0;
            const tagName = element.tagName.toLowerCase();
            const hasText = element.textContent && element.textContent.trim();
            const computed = window.getComputedStyle(element);
            
            // テキスト要素の特異性
            if (['span', 'a', 'strong', 'em', 'b', 'i', 'small'].includes(tagName) && hasText) {
                specificity += 100; // 最高優先度：インライン要素
            } else if (['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'li', 'td', 'th', 'label', 'button'].includes(tagName) && hasText) {
                specificity += 80; // 高優先度：ブロック要素
            }
            
            // 画像要素
            if (tagName === 'img') {
                specificity += 90;
            }
            
            // リンク要素
            if (tagName === 'a') {
                specificity += 95;
            }
            
            // 直接的なテキストノードを持つ要素
            const hasDirectText = Array.from(element.childNodes).some(node => 
                node.nodeType === Node.TEXT_NODE && node.textContent.trim()
            );
            if (hasDirectText) {
                specificity += 50;
            }
            
            // 特定のスタイルがある要素
            if (computed.backgroundColor && computed.backgroundColor !== 'rgba(0, 0, 0, 0)') {
                specificity += 20;
            }
            if (computed.color && computed.color !== 'rgb(0, 0, 0)') {
                specificity += 15;
            }
            if (computed.fontSize && computed.fontSize !== '16px') {
                specificity += 10;
            }
            
            // 子要素の数による調整（子が少ないほど特異性が高い）
            const childCount = element.children.length;
            if (childCount === 0) {
                specificity += 30; // 葉要素は高優先度
            } else if (childCount <= 2) {
                specificity += 15;
            } else if (childCount <= 5) {
                specificity += 5;
            } else {
                specificity -= 10; // 多くの子を持つ要素は低優先度
            }
            
            return specificity;
        }
        
        /**
         * 要素のDOM階層の深さを取得
         */
        getDepth(element) {
            let depth = 0;
            let current = element;
            while (current && current !== this.currentSection) {
                depth++;
                current = current.parentElement;
            }
            return depth;
        }

        /**
         * アイコン要素かどうかを判定
         */
        isIconElement(element) {
            const tagName = element.tagName.toLowerCase();
            const textContent = element.textContent ? element.textContent.trim() : '';
            const classList = (element.className || '').toString().toLowerCase();
            
            // 絵文字は文字として扱うため、アイコン判定から除外
            // const emojiRegex = /[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1FA70}-\u{1FAFF}]/u;
            // if (emojiRegex.test(textContent)) {
            //     return true;
            // }
            
            // 2. Font Awesomeなどのアイコンクラス
            const iconClasses = [
                'fa-', 'fas-', 'far-', 'fab-', 'fal-', // Font Awesome
                'material-icons', 'mi-', // Material Icons
                'icon-', 'ico-', 'icon', // 一般的なアイコンクラス
                'logo-icon', // ロゴアイコン
                'feather-', // Feather Icons
                'bootstrap-icon', 'bi-', // Bootstrap Icons
                'lucide-', // Lucide Icons
                'heroicon-', // Hero Icons
                'tabler-icon' // Tabler Icons
            ];
            
            if (iconClasses.some(iconClass => classList.includes(iconClass))) {
                return true;
            }
            
            // 3. アイコンフォントやSVGアイコン
            if (tagName === 'i' && (!textContent || textContent.length <= 2)) {
                return true;
            }
            
            // 4. SVGアイコン
            if (tagName === 'svg') {
                return true;
            }
            
            // 5. アイコン的な特徴（小さいサイズ、正方形など）
            if (element.getBoundingClientRect) {
                const rect = element.getBoundingClientRect();
                const isSmallSquare = rect.width <= 50 && rect.height <= 50 && 
                                    Math.abs(rect.width - rect.height) <= 10;
                
                if (isSmallSquare && (classList.includes('icon') || classList.includes('ico'))) {
                    return true;
                }
            }
            
            return false;
        }

        /**
         * 要素を解析
         */
        analyzeElement(element) {
            const analysis = {
                element: element,
                type: element.tagName.toLowerCase(),
                editable: [],
                elementInfo: this.getElementInfo(element),
                isIcon: this.isIconElement(element)
            };
            
            const computed = window.getComputedStyle(element);
            const rect = element.getBoundingClientRect();
            
            // アイコン要素の場合
            if (analysis.isIcon) {
                analysis.editable.push({
                    type: 'icon',
                    property: 'textContent',
                    value: element.textContent.trim(),
                    label: 'アイコン'
                });
                
                // アイコンサイズ
                analysis.editable.push({
                    type: 'size',
                    property: 'fontSize',
                    value: computed.fontSize,
                    label: 'アイコンサイズ'
                });
                
                // アイコン色
                analysis.editable.push({
                    type: 'color',
                    property: 'color',
                    value: computed.color,
                    label: 'アイコン色'
                });
            }
            // テキスト要素の場合
            else {
                const textTags = ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p', 'span', 'a', 'li', 'td', 'th', 'label', 'button'];
                if (textTags.includes(element.tagName.toLowerCase()) && element.textContent && element.textContent.trim()) {
                    // 直接テキストのみを取得（子要素のテキストは除外）
                    const directText = this.getDirectText(element);
                    analysis.editable.push({
                        type: 'text',
                        property: 'textContent',
                        value: directText || element.textContent.trim(),
                        label: 'テキスト'
                    });
                    
                    // フォントサイズ
                    analysis.editable.push({
                        type: 'size',
                        property: 'fontSize',
                        value: computed.fontSize,
                        label: 'フォントサイズ'
                    });
                    
                    // 文字色
                    analysis.editable.push({
                        type: 'color',
                        property: 'color',
                        value: computed.color,
                        label: '文字色'
                    });
                }
            }
            
            // リンクの場合
            if (element.tagName.toLowerCase() === 'a') {
                analysis.editable.push({
                    type: 'link',
                    property: 'href',
                    value: element.href,
                    label: 'リンク先'
                });
            }
            
            // 画像の場合
            if (element.tagName.toLowerCase() === 'img') {
                analysis.editable.push({
                    type: 'image',
                    property: 'src',
                    value: element.src,
                    label: '画像URL'
                });
            }
            
            // 背景色（必ず含める）
            const bgColor = computed.backgroundColor;
            if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
                analysis.editable.push({
                    type: 'color',
                    property: 'backgroundColor',
                    value: bgColor,
                    label: '背景色'
                });
            } else {
                // 背景色が透明な場合も編集可能にする
                analysis.editable.push({
                    type: 'color',
                    property: 'backgroundColor',
                    value: 'rgba(255, 255, 255, 0)',
                    label: '背景色（現在: 透明）'
                });
            }
            
            // 背景画像（常に含める）
            const bgImage = computed.backgroundImage;
            if (bgImage && bgImage !== 'none') {
                analysis.editable.push({
                    type: 'background',
                    property: 'backgroundImage',
                    value: bgImage,
                    label: '背景画像'
                });
            } else {
                // 背景画像がなくても編集可能に
                analysis.editable.push({
                    type: 'background',
                    property: 'backgroundImage',
                    value: '',
                    label: '背景画像（現在: なし）'
                });
            }
            
            // ボーダー色
            const borderColor = computed.borderColor;
            const borderWidth = computed.borderWidth;
            if (borderWidth && borderWidth !== '0px' && borderColor) {
                analysis.editable.push({
                    type: 'color',
                    property: 'borderColor',
                    value: borderColor,
                    label: '枠線の色'
                });
                
                analysis.editable.push({
                    type: 'size',
                    property: 'borderWidth',
                    value: borderWidth,
                    label: '枠線の太さ'
                });
            }
            
            // パディング（内側の余白）
            const padding = computed.padding;
            if (padding && padding !== '0px') {
                analysis.editable.push({
                    type: 'size',
                    property: 'padding',
                    value: padding,
                    label: '内側の余白'
                });
            }
            
            // ボーダーRadius（角の丸み）
            const borderRadius = computed.borderRadius;
            if (borderRadius && borderRadius !== '0px') {
                analysis.editable.push({
                    type: 'size',
                    property: 'borderRadius',
                    value: borderRadius,
                    label: '角の丸み'
                });
            }
            
            // ボックスシャドウ
            const boxShadow = computed.boxShadow;
            if (boxShadow && boxShadow !== 'none') {
                analysis.editable.push({
                    type: 'text',
                    property: 'boxShadow',
                    value: boxShadow,
                    label: '影の効果'
                });
            }
            
            return analysis;
        }

        /**
         * クイック編集メニューを表示
         */
        showQuickEditMenu(x, y, element, analysis) {
            this.currentEditingElement = element;
            
            // QuickEditMenuが存在するか確認
            if (window.QuickEditMenu) {
                this.quickEditMenu = new window.QuickEditMenu(element, analysis, {
                    x: x,
                    y: y,
                    onSave: (property, value, type) => this.handleQuickEdit(element, property, value),
                    onClose: () => {
                        console.log('QuickEditMenu onClose呼び出し');
                        // 少し遅延させてからクリア（編集処理完了を待つ）
                        setTimeout(() => {
                            this.currentEditingElement = null;
                            element.style.outline = '';
                            element.style.outlineOffset = '';
                            element.classList.remove('element-editing');
                        }, 100);
                        
                        // ステータス表示を削除
                        if (this.statusDisplay) {
                            this.statusDisplay.remove();
                            this.statusDisplay = null;
                        }
                    }
                });
            } else {
                // フォールバック：シンプルなメニュー
                this.showSimpleEditMenu(x, y, element, analysis);
            }
        }

        /**
         * シンプルな編集メニュー（フォールバック）
         */
        showSimpleEditMenu(x, y, element, analysis) {
            const menu = document.createElement('div');
            menu.className = 'quick-edit-menu-fallback';
            menu.style.cssText = `
                position: fixed;
                left: ${x}px;
                top: ${y}px;
                background: white;
                border: 1px solid #ddd;
                border-radius: 8px;
                padding: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                z-index: 100002;
                min-width: 200px;
            `;
            
            analysis.editable.forEach(item => {
                const row = document.createElement('div');
                row.style.cssText = 'padding: 4px; display: flex; align-items: center; gap: 8px;';
                
                const label = document.createElement('span');
                label.textContent = `${item.label}:`;
                label.style.cssText = 'font-size: 12px; color: #666; min-width: 60px;';
                
                let input;
                if (item.type === 'color') {
                    input = document.createElement('input');
                    input.type = 'color';
                    input.value = this.rgbToHex(item.value);
                    input.style.cssText = 'border: 1px solid #ddd; cursor: pointer;';
                } else if (item.type === 'icon') {
                    input = this.createIconPicker(item.value);
                } else {
                    input = document.createElement('input');
                    input.type = 'text';
                    input.value = item.value;
                    input.style.cssText = 'flex: 1; padding: 4px; border: 1px solid #ddd; border-radius: 4px; font-size: 12px;';
                }
                
                input.addEventListener('change', () => {
                    this.handleQuickEdit(element, item.property, input.value);
                });
                
                row.appendChild(label);
                row.appendChild(input);
                menu.appendChild(row);
            });
            
            // 詳細編集ボタン
            const detailEditBtn = document.createElement('button');
            detailEditBtn.textContent = '詳細編集';
            detailEditBtn.style.cssText = `
                padding: 8px 12px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 12px;
                cursor: pointer;
                margin-top: 8px;
                width: 100%;
                font-weight: 500;
            `;
            detailEditBtn.onclick = () => {
                this.openDetailEditor(element);
                menu.remove();
                this.currentEditingElement = null;
            };
            menu.appendChild(detailEditBtn);
            
            // 閉じるボタン
            const closeBtn = document.createElement('button');
            closeBtn.textContent = '✕';
            closeBtn.style.cssText = `
                position: absolute;
                top: 4px;
                right: 4px;
                background: none;
                border: none;
                cursor: pointer;
                font-size: 16px;
                color: #999;
            `;
            closeBtn.onclick = () => {
                menu.remove();
                this.currentEditingElement = null;
                element.classList.remove('element-editing');
                
                // ステータス表示を削除
                if (this.statusDisplay) {
                    this.statusDisplay.remove();
                    this.statusDisplay = null;
                }
            };
            menu.appendChild(closeBtn);
            
            document.body.appendChild(menu);
            
            // 外側クリックで閉じる
            setTimeout(() => {
                const closeHandler = (e) => {
                    if (!menu.contains(e.target)) {
                        menu.remove();
                        this.currentEditingElement = null;
                        element.classList.remove('element-editing');
                        
                        // ステータス表示を削除
                        if (this.statusDisplay) {
                            this.statusDisplay.remove();
                            this.statusDisplay = null;
                        }
                        
                        document.removeEventListener('click', closeHandler);
                    }
                };
                document.addEventListener('click', closeHandler);
            }, 100);
            
            this.quickEditMenu = { close: () => menu.remove() };
        }

        /**
         * クイック編集を処理
         */
        handleQuickEdit(element, property, value, type) {
            console.log('SectionClickEditor.handleQuickEdit:', { element, property, value, type });
            console.log('SectionClickEditor.handleQuickEdit - currentSection:', this.currentSection);
            console.log('SectionClickEditor.handleQuickEdit - currentEditingElement:', this.currentEditingElement);
            
            // currentEditingElementが失われている場合は復元
            if (!this.currentEditingElement && element) {
                console.log('currentEditingElementを復元:', element);
                this.currentEditingElement = element;
            }
            
            try {
                // アイコンの特別な処理
                if (property === 'icon' || (property === 'textContent' && value && (value.includes('<svg') || value.includes('<i class="material-icons')))) {
                    console.log('アイコンの更新処理:', value);
                    // SVGまたはMaterial Iconsのタグが含まれている場合
                    if (value.includes('<svg') || value.includes('<i class="material-icons')) {
                        element.innerHTML = value;
                        console.log('アイコンをHTMLとして設定');
                    } else {
                        // テキストとして扱う
                        element.textContent = value;
                    }
                    this.notifyChange(element, 'innerHTML', value);
                    return;
                }
                
                if (property === 'src') {
                    // img要素のsrc属性
                    if (element.tagName.toLowerCase() === 'img') {
                        element.src = value;
                        console.log('img要素のsrcを更新:', value);
                    } else {
                        // img要素でない場合は背景画像として設定
                        // 既存のグラデーションを保持
                        const currentBg = window.getComputedStyle(element).backgroundImage;
                        let newBg = `url(${value})`;
                        
                        // 既存のグラデーションがある場合は保持
                        if (currentBg && currentBg.includes('gradient')) {
                            const gradientMatch = currentBg.match(/(linear-gradient\([^)]+\))/);
                            if (gradientMatch) {
                                newBg = `${gradientMatch[1]}, url(${value})`;
                            }
                        }
                        
                        element.style.backgroundImage = newBg;
                        element.style.backgroundSize = 'cover';
                        element.style.backgroundRepeat = 'no-repeat';
                        element.style.backgroundPosition = 'center';
                        console.log('背景画像として設定:', newBg);
                    }
                    this.notifyChange(element, property, value);
                } else if (property === 'textContent') {
                    // 画像データURLの場合、背景画像として設定
                    if (value && value.startsWith('data:image/')) {
                        // 既存のグラデーションを保持
                        const currentBg = window.getComputedStyle(element).backgroundImage;
                        let newBg = `url(${value})`;
                        
                        // 既存のグラデーションがある場合は保持
                        if (currentBg && currentBg.includes('gradient')) {
                            const gradientMatch = currentBg.match(/(linear-gradient\([^)]+\))/);
                            if (gradientMatch) {
                                newBg = `${gradientMatch[1]}, url(${value})`;
                            }
                        }
                        
                        element.style.backgroundImage = newBg;
                        element.style.backgroundSize = 'cover';
                        element.style.backgroundRepeat = 'no-repeat';
                        element.style.backgroundPosition = 'center';
                        // 元のテキストを隠す
                        element.style.color = 'transparent';
                        console.log('textContentに画像を背景として設定:', newBg.substring(0, 50) + '...');
                        this.notifyChange(element, 'backgroundImage', newBg);
                    } else {
                        // 通常のテキスト更新
                        this.updateTextContent(element, value);
                        this.notifyChange(element, property, value);
                    }
                } else if (property === 'href') {
                    element.href = value;
                    this.notifyChange(element, property, value);
                } else {
                    // CSSスタイル更新
                    console.log(`CSSスタイル更新: ${property} = ${value.substring ? value.substring(0, 100) + '...' : value}`);
                    
                    // 背景画像の場合は!importantを使用
                    if (property === 'backgroundImage') {
                        console.log('背景画像を設定中:', element);
                        element.style.setProperty('background-image', value, 'important');
                        
                        // 既存のbackgroundプロパティもクリア
                        element.style.setProperty('background', '', '');
                        
                        // hero-gradientの場合は特別処理
                        if (element.classList.contains('hero-gradient')) {
                            console.log('hero-gradientの背景画像を設定');
                            element.style.setProperty('background-size', 'cover', 'important');
                            element.style.setProperty('background-position', 'center', 'important');
                            element.style.setProperty('background-repeat', 'no-repeat', 'important');
                        }
                    } else {
                        element.style[property] = value;
                    }
                    
                    this.notifyChange(element, property, value);
                }
                
                console.log('handleQuickEdit完了');
            } catch (error) {
                console.error('handleQuickEditエラー:', error);
            }
        }
        
        /**
         * 子要素を保持しながらテキストを更新
         */
        updateTextContent(element, newText) {
            // 子要素を一時的に保存
            const childElements = Array.from(element.children);
            
            // テキストノードのみを更新
            let textNodeFound = false;
            Array.from(element.childNodes).forEach(node => {
                if (node.nodeType === Node.TEXT_NODE && node.textContent.trim()) {
                    if (!textNodeFound) {
                        node.textContent = newText;
                        textNodeFound = true;
                    } else {
                        // 追加のテキストノードは削除
                        node.remove();
                    }
                }
            });
            
            // テキストノードが見つからない場合は、最初に追加
            if (!textNodeFound) {
                const textNode = document.createTextNode(newText);
                if (childElements.length > 0) {
                    element.insertBefore(textNode, childElements[0]);
                } else {
                    element.appendChild(textNode);
                }
            }
            
            // 子要素を復元（必要に応じて）
            childElements.forEach(child => {
                if (!element.contains(child)) {
                    element.appendChild(child);
                }
            });
        }

        /**
         * アイコンピッカーモーダルを表示（シンプル版）
         */
        showIconPickerModal(targetElement, onSelect) {
            console.log('showIconPickerModal called');
            
            try {
                // 既存のモーダルがあれば削除
                const existingModal = document.querySelector('.icon-picker-modal');
                if (existingModal) {
                    existingModal.remove();
                }
            
            // モーダル作成
            const modal = document.createElement('div');
            modal.className = 'icon-picker-modal';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                z-index: 999999;
                display: flex;
                align-items: center;
                justify-content: center;
            `;

            // パネル
            const panel = document.createElement('div');
            panel.style.cssText = `
                background: white;
                border-radius: 8px;
                padding: 20px;
                max-width: 600px;
                max-height: 80vh;
                overflow: auto;
                position: relative;
                z-index: 999999;
            `;

            // タイトル
            const title = document.createElement('h3');
            title.textContent = 'アイコンを選択';
            title.style.cssText = 'margin: 0 0 20px 0; color: #333;';
            panel.appendChild(title);

            // フラットなSVGアイコンを使用
            const icons = [
                // 健康・フィットネス
                { icon: 'spa', label: 'スパ', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M15.49 9.63c-.16-2.42-1.03-4.79-2.64-6.76-1.61 1.97-2.48 4.34-2.64 6.76 1.98.87 4.1 1.37 6.29 1.37-.41-1.37-2.14-1.37-3.01-1.37zm-.47 3.87C14 13.5 13 13 12 13s-2 .5-3 1.5c0 0-6 5.5-6 8.5 0 2.76 2.24 5 5 5s5-2.24 5-5c0-.55-.11-1.07-.31-1.56C14.05 20.84 15 19.52 15 18c0-1.39-.78-2.6-1.93-3.22-.05.1-.05.16-.05.22zm-3.02 7c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>' },
                { icon: 'fitness_center', label: 'フィットネス', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20.57 14.86L22 13.43 20.57 12 17 15.57 8.43 7 12 3.43 10.57 2 9.14 3.43 7.71 2 5.57 4.14 4.14 2.71 2.71 4.14l1.43 1.43L2 7.71l1.43 1.43L2 10.57 3.43 12 7 8.43 15.57 17 12 20.57 13.43 22l1.43-1.43L16.29 22l2.14-2.14 1.43 1.43 1.43-1.43-1.43-1.43L22 16.29z"/></svg>' },
                { icon: 'self_improvement', label: '瞑想', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="6" r="2"/><path d="M21 16v-2c-2.24 0-4.16-.96-5.6-2.68l-1.34-1.6C13.68 9.26 13.12 9 12.53 9h-1.05c-.59 0-1.15.26-1.53.72l-1.34 1.6C7.16 13.04 5.24 14 3 14v2c2.77 0 5.19-1.17 7-3.25V15l-3.88 1.55c-.67.27-1.12.93-1.12 1.66C5 19.2 5.8 20 6.79 20H9v-.5c0-1.1.9-2 2-2h2c1.1 0 2 .9 2 2v.5h2.21c.99 0 1.79-.8 1.79-1.79 0-.73-.45-1.39-1.12-1.66L14 15v-2.25c1.81 2.08 4.23 3.25 7 3.25z"/></svg>' },
                { icon: 'favorite', label: 'ハート', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>' },
                { icon: 'favorite_border', label: 'ハート（線）', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M16.5 3c-1.74 0-3.41.81-4.5 2.09C10.91 3.81 9.24 3 7.5 3 4.42 3 2 5.42 2 8.5c0 3.78 3.4 6.86 8.55 11.54L12 21.35l1.45-1.32C18.6 15.36 22 12.28 22 8.5 22 5.42 19.58 3 16.5 3zm-4.4 15.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05z"/></svg>' },
                
                // 基本
                { icon: 'star', label: '星', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>' },
                { icon: 'star_border', label: '星（線）', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4l-3.76 2.27 1-4.28-3.32-2.88 4.38-.38L12 6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"/></svg>' },
                { icon: 'check_circle', label: 'チェック', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>' },
                { icon: 'check_circle_outline', label: 'チェック（線）', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M16.59 7.58L10 14.17l-3.59-3.58L5 12l5 5 8-8zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/></svg>' },
                { icon: 'radio_button_checked', label: 'ラジオボタン', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0-5C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/></svg>' },
                
                // 人・コミュニケーション
                { icon: 'person', label: '人物', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>' },
                { icon: 'groups', label: 'グループ', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zM8 17.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5zM9.5 8c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5S9.5 9.38 9.5 8zm6.5 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>' },
                { icon: 'psychology', label: '心理', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M13 8.57c-.79 0-1.43.64-1.43 1.43s.64 1.43 1.43 1.43 1.43-.64 1.43-1.43-.64-1.43-1.43-1.43z"/><path d="M13 3c-4.97 0-9 4.03-9 9H1l4 3.99L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42C8.27 19.99 10.51 21 13 21c4.97 0 9-4.03 9-9s-4.03-9-9-9zm-1 5v2h2V8h-2zm0 4v2h2v-2h-2z"/></svg>' },
                { icon: 'accessibility', label: 'アクセシビリティ', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2c1.1 0 2 .9 2 2s-.9 2-2 2-2-.9-2-2 .9-2 2-2zm9 7h-6v13h-2v-6h-2v6H9V9H3V7h18v2z"/></svg>' },
                { icon: 'face', label: '顔', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M9 11.75c-.69 0-1.25.56-1.25 1.25s.56 1.25 1.25 1.25 1.25-.56 1.25-1.25-.56-1.25-1.25-1.25zm6 0c-.69 0-1.25.56-1.25 1.25s.56 1.25 1.25 1.25 1.25-.56 1.25-1.25-.56-1.25-1.25-1.25zM12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8 0-.29.02-.58.05-.86 2.36-1.05 4.23-2.98 5.21-5.37C11.07 8.33 14.05 10 17.42 10c.78 0 1.53-.09 2.25-.26.21.71.33 1.47.33 2.26 0 4.41-3.59 8-8 8z"/></svg>' },
                
                // 場所・時間
                { icon: 'home', label: 'ホーム', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/></svg>' },
                { icon: 'place', label: '場所', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>' },
                { icon: 'schedule', label: 'スケジュール', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8z"/><path d="M12.5 7H11v6l5.25 3.15.75-1.23-4.5-2.67z"/></svg>' },
                { icon: 'event', label: 'イベント', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17 12h-5v5h5v-5zM16 1v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2h-1V1h-2zm3 18H5V8h14v11z"/></svg>' },
                { icon: 'today', label: '今日', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM7 10h5v5H7z"/></svg>' },
                
                // 連絡
                { icon: 'email', label: 'メール', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>' },
                { icon: 'phone', label: '電話', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z"/></svg>' },
                { icon: 'chat_bubble', label: 'チャット', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/></svg>' },
                { icon: 'message', label: 'メッセージ', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z"/></svg>' },
                { icon: 'forum', label: 'フォーラム', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M21 6h-2v9H6v2c0 .55.45 1 1 1h11l4 4V7c0-.55-.45-1-1-1zm-4 6V3c0-.55-.45-1-1-1H3c-.55 0-1 .45-1 1v14l4-4h10c.55 0 1-.45 1-1z"/></svg>' },
                
                // その他
                { icon: 'lightbulb', label: 'アイデア', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M9 21c0 .5.4 1 1 1h4c.6 0 1-.5 1-1v-1H9v1zm3-19C8.1 2 5 5.1 5 9c0 2.4 1.2 4.5 3 5.7V17c0 .5.4 1 1 1h6c.6 0 1-.5 1-1v-2.3c1.8-1.3 3-3.4 3-5.7 0-3.9-3.1-7-7-7z"/></svg>' },
                { icon: 'eco', label: 'エコ', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6.05 8.05c-2.73 2.73-2.73 7.15-.02 9.88 1.47-3.4 4.09-6.24 7.36-7.93-2.77 2.34-4.71 5.61-5.39 9.32 2.6 1.23 5.8.78 7.95-1.37C19.43 14.47 20 4 20 4S9.53 4.57 6.05 8.05z"/></svg>' },
                { icon: 'local_florist', label: '花', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22c4.97 0 9-4.03 9-9-4.97 0-9 4.03-9 9zM5.6 10.25c0 1.38 1.12 2.5 2.5 2.5.53 0 1.01-.16 1.42-.44l-.02.19c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5l-.02-.19c.4.28.89.44 1.42.44 1.38 0 2.5-1.12 2.5-2.5 0-1-.59-1.85-1.43-2.25.84-.4 1.43-1.25 1.43-2.25 0-1.38-1.12-2.5-2.5-2.5-.53 0-1.01.16-1.42.44l.02-.19C14.5 2.12 13.38 1 12 1S9.5 2.12 9.5 3.5l.02.19c-.4-.28-.89-.44-1.42-.44-1.38 0-2.5 1.12-2.5 2.5 0 1 .59 1.85 1.43 2.25-.84.4-1.43 1.25-1.43 2.25zM12 5.5c1.38 0 2.5 1.12 2.5 2.5s-1.12 2.5-2.5 2.5S9.5 9.38 9.5 8s1.12-2.5 2.5-2.5zM3 13c0 4.97 4.03 9 9 9 0-4.97-4.03-9-9-9z"/></svg>' },
                { icon: 'wb_sunny', label: '太陽', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6zm-1 16.95h2V19.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.8-1.41-1.41-1.79 1.8z"/></svg>' },
                { icon: 'directions_run', label: 'ランニング', svg: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M13.49 5.48c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm-3.6 13.9l1-4.4 2.1 2v6h2v-7.5l-2.1-2 .6-3c1.3 1.5 3.3 2.5 5.5 2.5v-2c-1.9 0-3.5-1-4.3-2.4l-1-1.6c-.4-.6-1-1-1.7-1-.3 0-.5.1-.8.1l-5.2 2.2v4.7h2v-3.4l1.8-.7-1.6 8.1-4.9-1-.4 2 7 1.4z"/></svg>' }
            ];

            // アイコングリッド - 3列に固定
            const grid = document.createElement('div');
            grid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(3, 1fr);
                gap: 10px;
                margin-bottom: 20px;
                max-width: 400px;
                margin-left: auto;
                margin-right: auto;
            `;

            icons.forEach(item => {
                const btn = document.createElement('button');
                btn.style.cssText = `
                    padding: 15px 10px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    background: white;
                    cursor: pointer;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    gap: 8px;
                    transition: all 0.2s;
                `;

                // アイコン要素 - SVGを使用
                const iconEl = document.createElement('div');
                iconEl.style.cssText = `
                    width: 32px;
                    height: 32px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                `;
                
                // SVGアイコンがある場合はそれを使用
                if (item.svg) {
                    iconEl.innerHTML = item.svg;
                    // SVG要素のスタイルを調整
                    const svg = iconEl.querySelector('svg');
                    if (svg) {
                        svg.style.width = '32px';
                        svg.style.height = '32px';
                    }
                } else {
                    // フォールバック: テキストとして表示
                    iconEl.textContent = item.icon;
                    iconEl.style.fontSize = '32px';
                    iconEl.style.color = '#666';
                }

                // 名前
                const nameEl = document.createElement('span');
                nameEl.textContent = item.label;
                nameEl.style.cssText = 'font-size: 12px; color: #666;';

                btn.appendChild(iconEl);
                btn.appendChild(nameEl);

                // ホバー効果
                btn.onmouseenter = () => {
                    btn.style.background = '#f0f0f0';
                    btn.style.borderColor = '#999';
                };
                btn.onmouseleave = () => {
                    btn.style.background = 'white';
                    btn.style.borderColor = '#ddd';
                };

                btn.onclick = () => {
                    if (onSelect) {
                        // SVGアイコンがある場合は優先的に使用
                        if (item.svg) {
                            // SVGのサイズを調整（1em相当）
                            const svgIcon = item.svg.replace(/width="24"/g, 'width="1em"').replace(/height="24"/g, 'height="1em"');
                            onSelect(svgIcon);
                        } else {
                            // フォールバック
                            onSelect(item.icon);
                        }
                    }
                    modal.remove();
                };

                grid.appendChild(btn);
            });

            panel.appendChild(grid);

            // 閉じるボタン
            const closeBtn = document.createElement('button');
            closeBtn.textContent = '閉じる';
            closeBtn.style.cssText = `
                padding: 10px 20px;
                background: #666;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-size: 14px;
            `;
            closeBtn.onclick = () => modal.remove();
            panel.appendChild(closeBtn);

            modal.appendChild(panel);
            document.body.appendChild(modal);

            // 外側クリックで閉じる
            modal.onclick = (e) => {
                if (e.target === modal) modal.remove();
            };
            
            console.log('Icon picker modal created successfully');
            
            } catch (error) {
                console.error('Error in showIconPickerModal:', error);
                alert('アイコン選択モーダルの表示中にエラーが発生しました: ' + error.message);
            }
        }

        // 古い実装は削除
        showIconPickerModal_old(targetElement, onSelect) {
            // アイコンスタイルの定義
            const iconStyles = {
                'fontawesome': {
                    name: 'Font Awesome',
                    categories: {
                        'ヨガ・フィットネス': [
                            { class: 'fa-solid fa-spa', name: 'スパ' },
                            { class: 'fa-solid fa-dumbbell', name: 'ダンベル' },
                            { class: 'fa-solid fa-person-running', name: 'ランニング' },
                            { class: 'fa-solid fa-person-walking', name: 'ウォーキング' },
                            { class: 'fa-solid fa-person-swimming', name: 'スイミング' },
                            { class: 'fa-solid fa-person-biking', name: 'サイクリング' },
                            { class: 'fas fa-heartbeat', name: 'ハートビート' },
                            { class: 'fas fa-medkit', name: '医療キット' },
                            { class: 'fas fa-user-md', name: '医師' },
                            { class: 'fas fa-weight', name: 'ウェイト' },
                            { class: 'fas fa-heart', name: 'ハート' },
                            { class: 'fas fa-leaf', name: '葉' },
                            { class: 'fas fa-seedling', name: '芽' },
                            { class: 'fas fa-fire', name: '炎' },
                            { class: 'fas fa-burn', name: '燃える' }
                        ],
                        'ビジネス・UI': [
                            { class: 'fas fa-home', name: 'ホーム' },
                            { class: 'fas fa-user', name: 'ユーザー' },
                            { class: 'fas fa-users', name: 'ユーザーグループ' },
                            { class: 'fas fa-envelope', name: 'メール' },
                            { class: 'fas fa-phone', name: '電話' },
                            { class: 'fas fa-map-marker-alt', name: '位置' },
                            { class: 'fas fa-calendar', name: 'カレンダー' },
                            { class: 'fas fa-clock', name: '時計' },
                            { class: 'fas fa-chart-line', name: 'チャート' },
                            { class: 'fas fa-cog', name: '設定' },
                            { class: 'fas fa-bars', name: 'メニュー' },
                            { class: 'fas fa-search', name: '検索' },
                            { class: 'fas fa-bell', name: 'ベル' },
                            { class: 'fas fa-shopping-cart', name: 'カート' },
                            { class: 'fas fa-check', name: 'チェック' },
                            { class: 'fas fa-times', name: 'クローズ' },
                            { class: 'fas fa-plus', name: 'プラス' },
                            { class: 'fas fa-minus', name: 'マイナス' },
                            { class: 'fas fa-arrow-right', name: '右矢印' },
                            { class: 'fas fa-arrow-left', name: '左矢印' }
                        ],
                        'ソーシャル': [
                            { class: 'fab fa-facebook', name: 'Facebook' },
                            { class: 'fab fa-twitter', name: 'Twitter' },
                            { class: 'fab fa-instagram', name: 'Instagram' },
                            { class: 'fab fa-youtube', name: 'YouTube' },
                            { class: 'fab fa-linkedin', name: 'LinkedIn' },
                            { class: 'fab fa-pinterest', name: 'Pinterest' },
                            { class: 'fab fa-tiktok', name: 'TikTok' },
                            { class: 'fab fa-whatsapp', name: 'WhatsApp' },
                            { class: 'fab fa-line', name: 'LINE' },
                            { class: 'fab fa-discord', name: 'Discord' }
                        ],
                        'アロー・図形': [
                            { class: 'fas fa-circle', name: '円' },
                            { class: 'fas fa-square', name: '四角' },
                            { class: 'fas fa-star', name: '星' },
                            { class: 'fas fa-heart', name: 'ハート' },
                            { class: 'fas fa-diamond', name: 'ダイヤ' },
                            { class: 'fas fa-arrow-up', name: '上矢印' },
                            { class: 'fas fa-arrow-down', name: '下矢印' },
                            { class: 'fas fa-arrow-circle-right', name: '円右矢印' },
                            { class: 'fas fa-chevron-right', name: 'シェブロン右' },
                            { class: 'fas fa-chevron-left', name: 'シェブロン左' }
                        ]
                    }
                },
                'material': {
                    name: 'Material Icons',
                    categories: {
                        'ヨガ・フィットネス': [
                            { class: 'material-icons', text: 'self_improvement', name: '瞑想' },
                            { class: 'material-icons', text: 'fitness_center', name: 'フィットネス' },
                            { class: 'material-icons', text: 'directions_run', name: 'ランニング' },
                            { class: 'material-icons', text: 'directions_walk', name: 'ウォーキング' },
                            { class: 'material-icons', text: 'pool', name: 'プール' },
                            { class: 'material-icons', text: 'sports', name: 'スポーツ' },
                            { class: 'material-icons', text: 'favorite', name: 'ハート' },
                            { class: 'material-icons', text: 'favorite_border', name: 'ハート（線）' },
                            { class: 'material-icons', text: 'health_and_safety', name: '健康' },
                            { class: 'material-icons', text: 'accessibility', name: 'アクセシビリティ' },
                            { class: 'material-icons', text: 'spa', name: 'スパ' },
                            { class: 'material-icons', text: 'eco', name: 'エコ' },
                            { class: 'material-icons', text: 'grass', name: '草' },
                            { class: 'material-icons', text: 'local_florist', name: '花' },
                            { class: 'material-icons', text: 'nature', name: '自然' }
                        ],
                        'ビジネス・UI': [
                            { class: 'material-icons', text: 'home', name: 'ホーム' },
                            { class: 'material-icons', text: 'person', name: '人物' },
                            { class: 'material-icons', text: 'people', name: 'グループ' },
                            { class: 'material-icons', text: 'email', name: 'メール' },
                            { class: 'material-icons', text: 'phone', name: '電話' },
                            { class: 'material-icons', text: 'place', name: '場所' },
                            { class: 'material-icons', text: 'event', name: 'イベント' },
                            { class: 'material-icons', text: 'schedule', name: 'スケジュール' },
                            { class: 'material-icons', text: 'trending_up', name: '上昇' },
                            { class: 'material-icons', text: 'settings', name: '設定' },
                            { class: 'material-icons', text: 'menu', name: 'メニュー' },
                            { class: 'material-icons', text: 'search', name: '検索' },
                            { class: 'material-icons', text: 'notifications', name: '通知' },
                            { class: 'material-icons', text: 'shopping_cart', name: 'カート' },
                            { class: 'material-icons', text: 'check', name: 'チェック' },
                            { class: 'material-icons', text: 'close', name: '閉じる' },
                            { class: 'material-icons', text: 'add', name: '追加' },
                            { class: 'material-icons', text: 'remove', name: '削除' },
                            { class: 'material-icons', text: 'arrow_forward', name: '進む' },
                            { class: 'material-icons', text: 'arrow_back', name: '戻る' }
                        ],
                        'アウトライン': [
                            { class: 'material-icons-outlined', text: 'self_improvement', name: '瞑想（線）' },
                            { class: 'material-icons-outlined', text: 'fitness_center', name: 'フィットネス（線）' },
                            { class: 'material-icons-outlined', text: 'favorite', name: 'ハート（線）' },
                            { class: 'material-icons-outlined', text: 'home', name: 'ホーム（線）' },
                            { class: 'material-icons-outlined', text: 'person', name: '人物（線）' },
                            { class: 'material-icons-outlined', text: 'email', name: 'メール（線）' },
                            { class: 'material-icons-outlined', text: 'phone', name: '電話（線）' },
                            { class: 'material-icons-outlined', text: 'place', name: '場所（線）' },
                            { class: 'material-icons-outlined', text: 'event', name: 'イベント（線）' },
                            { class: 'material-icons-outlined', text: 'settings', name: '設定（線）' }
                        ],
                        '図形・シンボル': [
                            { class: 'material-icons', text: 'circle', name: '円' },
                            { class: 'material-icons', text: 'square', name: '四角' },
                            { class: 'material-icons', text: 'star', name: '星' },
                            { class: 'material-icons', text: 'star_outline', name: '星（線）' },
                            { class: 'material-icons', text: 'grade', name: 'グレード' },
                            { class: 'material-icons', text: 'auto_awesome', name: 'キラキラ' },
                            { class: 'material-icons', text: 'lens', name: 'レンズ' },
                            { class: 'material-icons', text: 'panorama_fish_eye', name: '魚眼' },
                            { class: 'material-icons', text: 'crop_square', name: '正方形' },
                            { class: 'material-icons', text: 'change_history', name: '三角' }
                        ]
                    }
                }
            };
            
            let currentStyle = 'fontawesome';
            let iconCategories = iconStyles[currentStyle].categories;
            
            // モーダルオーバーレイ
            const modal = document.createElement('div');
            modal.className = 'icon-picker-modal';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.7);
                z-index: 100030;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.3s ease;
            `;
            
            // モーダルコンテンツ
            const content = document.createElement('div');
            content.style.cssText = `
                background: var(--card-bg, white);
                border-radius: 16px;
                padding: 24px;
                max-width: 600px;
                max-height: 80vh;
                overflow-y: auto;
                box-shadow: var(--box-shadow-hover, 0 20px 60px rgba(0, 0, 0, 0.3));
                animation: slideIn 0.3s ease;
                font-family: var(--font-family);
                color: var(--text-color);
            `;
            
            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;';
            
            const title = document.createElement('h3');
            title.textContent = 'アイコンを選択';
            title.style.cssText = 'margin: 0; font-size: 20px; color: var(--heading-color, #333); font-family: var(--font-family);';
            
            const closeBtn = document.createElement('button');
            closeBtn.innerHTML = '✕';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 24px;
                color: var(--text-color, #999);
                cursor: pointer;
                padding: 8px;
                border-radius: 6px;
                transition: all 0.2s ease;
            `;
            closeBtn.onmouseover = () => closeBtn.style.background = 'var(--border-color, #f0f0f0)';
            closeBtn.onmouseout = () => closeBtn.style.background = 'none';
            closeBtn.onclick = () => modal.remove();
            
            header.appendChild(title);
            header.appendChild(closeBtn);
            content.appendChild(header);
            
            // スタイル切り替えタブ
            const styleTabs = document.createElement('div');
            styleTabs.style.cssText = `
                display: flex;
                gap: 8px;
                margin-bottom: 20px;
                border-bottom: 2px solid var(--border-color, #e0e0e0);
                padding-bottom: 0;
            `;
            
            Object.entries(iconStyles).forEach(([styleKey, styleData]) => {
                const tab = document.createElement('button');
                tab.textContent = styleData.name;
                tab.style.cssText = `
                    padding: 8px 16px;
                    background: none;
                    border: none;
                    border-bottom: 3px solid transparent;
                    cursor: pointer;
                    font-size: 14px;
                    font-weight: 500;
                    color: ${styleKey === currentStyle ? 'var(--primary-color, #667eea)' : 'var(--text-color, #666)'};
                    transition: all 0.2s ease;
                    margin-bottom: -2px;
                `;
                
                if (styleKey === currentStyle) {
                    tab.style.borderBottomColor = 'var(--primary-color, #667eea)';
                }
                
                tab.onclick = () => {
                    currentStyle = styleKey;
                    iconCategories = iconStyles[currentStyle].categories;
                    
                    // 全てのタブをリセット
                    styleTabs.querySelectorAll('button').forEach(t => {
                        t.style.color = 'var(--text-color, #666)';
                        t.style.borderBottomColor = 'transparent';
                    });
                    
                    // 選択されたタブをハイライト
                    tab.style.color = 'var(--primary-color, #667eea)';
                    tab.style.borderBottomColor = 'var(--primary-color, #667eea)';
                    
                    // アイコングリッドを再生成
                    renderIconGrid();
                };
                
                styleTabs.appendChild(tab);
            });
            
            content.appendChild(styleTabs);
            
            console.log('アイコンピッカーモーダル作成中...');
            
            // 画像アップロードタブ
            const uploadTab = document.createElement('div');
            uploadTab.style.cssText = 'margin-bottom: 20px; border: 2px solid red;'; // デバッグ用の赤枠
            
            const uploadTabTitle = document.createElement('h4');
            uploadTabTitle.textContent = 'カスタム画像';
            uploadTabTitle.style.cssText = 'margin: 0 0 12px 0; font-size: 14px; color: var(--text-color, #666); font-weight: 600; font-family: var(--font-family);';
            uploadTab.appendChild(uploadTabTitle);
            
            const uploadButton = document.createElement('button');
            uploadButton.textContent = '📁 画像をアップロード';
            uploadButton.style.cssText = `
                width: 100%;
                padding: 15px;
                background: linear-gradient(135deg, var(--accent-color, #667eea) 0%, var(--primary-color, #764ba2) 100%);
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 16px;
                font-family: var(--font-family);
                cursor: pointer;
                transition: all 0.2s ease;
                margin-bottom: 15px;
            `;
            
            uploadButton.onmouseover = () => {
                uploadButton.style.transform = 'translateY(-2px)';
                uploadButton.style.boxShadow = '0 5px 15px rgba(102, 126, 234, 0.4)';
            };
            uploadButton.onmouseout = () => {
                uploadButton.style.transform = 'translateY(0)';
                uploadButton.style.boxShadow = 'none';
            };
            
            uploadButton.onclick = () => {
                console.log('アップロードボタンクリック', window.imageUploader);
                if (window.imageUploader) {
                    console.log('ImageUploaderが利用可能');
                    window.imageUploader.showUploadDialog((dataUrl, size, imageId) => {
                        console.log('画像選択:', { size, imageId });
                        if (onSelect) {
                            // 画像を要素に適用
                            onSelect(dataUrl);
                        }
                        modal.remove();
                    });
                } else {
                    console.error('ImageUploaderが初期化されていません');
                    alert('画像アップロード機能の初期化に失敗しました。ページをリロードしてください。');
                }
            };
            
            uploadTab.appendChild(uploadButton);
            
            // 既存のアップロード画像を表示
            const existingImagesGrid = document.createElement('div');
            existingImagesGrid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(50px, 1fr));
                gap: 8px;
                margin-top: 10px;
                min-height: 60px;
                border: 1px dashed #ddd;
                border-radius: 8px;
                padding: 10px;
                background: #fafafa;
            `;
            
            if (window.imageUploader && window.imageUploader.compressedImages.size > 0) {
                window.imageUploader.compressedImages.forEach((compressedVersions, imageId) => {
                    const imageBtn = document.createElement('button');
                    imageBtn.style.cssText = `
                        width: 50px;
                        height: 50px;
                        border: 2px solid #e0e0e0;
                        border-radius: 8px;
                        background: white;
                        cursor: pointer;
                        transition: all 0.2s ease;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        padding: 0;
                        overflow: hidden;
                    `;
                    
                    const img = document.createElement('img');
                    img.src = compressedVersions[40] || compressedVersions[64];
                    img.style.cssText = 'width: 100%; height: 100%; object-fit: cover;';
                    imageBtn.appendChild(img);
                    
                    imageBtn.onmouseover = () => {
                        imageBtn.style.borderColor = '#2196F3';
                        imageBtn.style.transform = 'scale(1.1)';
                    };
                    
                    imageBtn.onmouseout = () => {
                        imageBtn.style.borderColor = '#e0e0e0';
                        imageBtn.style.transform = 'scale(1)';
                    };
                    
                    imageBtn.onclick = () => {
                        if (onSelect) {
                            onSelect(compressedVersions[40] || compressedVersions[64]);
                        }
                        modal.remove();
                    };
                    
                    existingImagesGrid.appendChild(imageBtn);
                });
            } else {
                // 画像がない場合のメッセージ
                const emptyMsg = document.createElement('div');
                emptyMsg.textContent = 'アップロードした画像がここに表示されます';
                emptyMsg.style.cssText = `
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    height: 50px;
                    color: #999;
                    font-size: 14px;
                    text-align: center;
                `;
                existingImagesGrid.appendChild(emptyMsg);
            }
            
            uploadTab.appendChild(existingImagesGrid);
            
            content.appendChild(uploadTab);

            // アイコングリッドを生成するコンテナ
            const iconGridContainer = document.createElement('div');
            iconGridContainer.id = 'icon-grid-container';
            content.appendChild(iconGridContainer);
            
            // アイコングリッドをレンダリングする関数
            const renderIconGrid = () => {
                iconGridContainer.innerHTML = '';
                
                Object.entries(iconCategories).forEach(([categoryName, icons]) => {
                    const categoryDiv = document.createElement('div');
                    categoryDiv.style.cssText = 'margin-bottom: 20px;';
                    
                    const categoryTitle = document.createElement('h4');
                    categoryTitle.textContent = categoryName;
                    categoryTitle.style.cssText = 'margin: 0 0 12px 0; font-size: 14px; color: var(--text-color, #666); font-weight: 600; font-family: var(--font-family);';
                    categoryDiv.appendChild(categoryTitle);
                    
                    const iconsGrid = document.createElement('div');
                    iconsGrid.style.cssText = `
                        display: grid;
                        grid-template-columns: repeat(auto-fill, minmax(50px, 1fr));
                        gap: 8px;
                    `;
                    
                    icons.forEach(icon => {
                        const iconBtn = document.createElement('button');
                        
                        // 絵文字スタイル
                        if (currentStyle === 'emoji') {
                            iconBtn.textContent = icon;
                            iconBtn.style.cssText = `
                                width: 50px;
                                height: 50px;
                                border: 2px solid var(--border-color, #e0e0e0);
                                border-radius: 8px;
                                background: var(--card-bg, white);
                                font-size: 24px;
                                cursor: pointer;
                                transition: all 0.2s ease;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                            `;
                        }
                        // Font Awesomeスタイル
                        else if (currentStyle === 'fontawesome') {
                            iconBtn.innerHTML = `<i class="${icon.class}"></i>`;
                            iconBtn.title = icon.name;
                            console.log('Font Awesome icon:', icon.class, icon.name);
                            iconBtn.style.cssText = `
                                width: 50px;
                                height: 50px;
                                border: 2px solid var(--border-color, #e0e0e0);
                                border-radius: 8px;
                                background: var(--card-bg, white);
                                font-size: 20px;
                                cursor: pointer;
                                transition: all 0.2s ease;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                color: var(--text-color, #333);
                            `;
                        }
                        // Material Iconsスタイル
                        else if (currentStyle === 'material') {
                            iconBtn.innerHTML = `<i class="${icon.class}">${icon.text}</i>`;
                            iconBtn.title = icon.name;
                            iconBtn.style.cssText = `
                                width: 50px;
                                height: 50px;
                                border: 2px solid var(--border-color, #e0e0e0);
                                border-radius: 8px;
                                background: var(--card-bg, white);
                                font-size: 24px;
                                cursor: pointer;
                                transition: all 0.2s ease;
                                display: flex;
                                align-items: center;
                                justify-content: center;
                                color: var(--text-color, #333);
                            `;
                        }
                        
                        iconBtn.onmouseover = () => {
                            iconBtn.style.borderColor = 'var(--accent-color, #2196F3)';
                            iconBtn.style.background = 'var(--hero-bg, #f8f9ff)';
                            iconBtn.style.transform = 'scale(1.1)';
                        };
                        
                        iconBtn.onmouseout = () => {
                            iconBtn.style.borderColor = 'var(--border-color, #e0e0e0)';
                            iconBtn.style.background = 'var(--card-bg, white)';
                            iconBtn.style.transform = 'scale(1)';
                        };
                        
                        iconBtn.onclick = () => {
                            let selectedValue;
                            if (currentStyle === 'emoji') {
                                selectedValue = icon;
                            } else {
                                // Font AwesomeやMaterial Iconsの場合はHTML要素として返す
                                selectedValue = iconBtn.innerHTML;
                            }
                            
                            console.log('アイコン選択:', selectedValue, 'onSelect:', onSelect);
                            if (onSelect && typeof onSelect === 'function') {
                                onSelect(selectedValue);
                            }
                            modal.remove();
                        };
                        
                        iconsGrid.appendChild(iconBtn);
                    });
                    
                    categoryDiv.appendChild(iconsGrid);
                    iconGridContainer.appendChild(categoryDiv);
                });
            };
            
            // 初回レンダリング
            renderIconGrid();
            
            // フォントの読み込みを待ってから再レンダリング
            if (document.fonts && document.fonts.ready) {
                document.fonts.ready.then(() => {
                    console.log('Fonts loaded, re-rendering icons');
                    renderIconGrid();
                });
            }
            
            modal.appendChild(content);
            document.body.appendChild(modal);
            
            // 外側クリックで閉じる
            modal.onclick = (e) => {
                if (e.target === modal) {
                    modal.remove();
                }
            };
            
            // アニメーションスタイルを追加
            if (!document.querySelector('#icon-picker-animations')) {
                const style = document.createElement('style');
                style.id = 'icon-picker-animations';
                style.textContent = `
                    @keyframes fadeIn {
                        from { opacity: 0; }
                        to { opacity: 1; }
                    }
                    @keyframes slideIn {
                        from { transform: scale(0.9) translateY(-20px); opacity: 0; }
                        to { transform: scale(1) translateY(0); opacity: 1; }
                    }
                `;
                document.head.appendChild(style);
            }
        }

        /**
         * 変更を通知
         */
        notifyChange(element, property, value) {
            // セクションの存在確認 - elementパラメータも使用
            if (!this.currentSection && !this.currentEditingElement && !element) {
                console.warn('通知対象のセクションまたは要素が見つかりません');
                return;
            }
            
            // 通知対象の要素を決定（引数のelementを最優先）
            const targetElement = element || this.currentEditingElement || this.currentSection;
            
            // セクションIDを確実に取得
            const sectionId = targetElement.id || 
                              targetElement.className || 
                              targetElement.tagName + '_' + Date.now();
            
            console.log('編集変更を通知:', {
                element: element.tagName,
                property: property,
                value: value,
                sectionId: sectionId
            });
            
            // カスタムイベントを発火
            document.dispatchEvent(new CustomEvent('quickEditChange', {
                detail: {
                    element: element,
                    property: property,
                    value: value,
                    sectionId: sectionId
                }
            }));
            
            // 設定マネージャーに通知（該当する場合）
            if (window.settingsManager && property === 'color' && element.tagName.match(/^H[1-6]$/)) {
                // 見出しの色変更はグローバル設定として保存
                const customColors = window.settingsManager.getSetting('theme.customColors') || {};
                customColors[`--heading-color`] = value;
                window.settingsManager.updateSetting('theme.customColors', customColors);
            }
        }

        
        /**
         * 編集モードメッセージを表示
         */
        showEditModeMessage() {
            // 既存のメッセージを削除
            if (this.editModeMessage) {
                this.editModeMessage.remove();
            }
            
            const message = document.createElement('div');
            message.className = 'edit-mode-message';
            message.innerHTML = `
                <span>要素をクリックして編集 | 編集終了ボタンで保存メニュー表示</span>
            `;
            message.style.cssText = `
                position: fixed;
                top: 20px;
                left: 50%;
                transform: translateX(-50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 8px 16px;
                border-radius: 6px;
                font-size: 13px;
                z-index: 100001;
                pointer-events: none;
                animation: fadeIn 0.3s ease;
                backdrop-filter: blur(5px);
            `;
            
            document.body.appendChild(message);
            this.editModeMessage = message;
            
            // 3秒後に自動的に非表示にする
            setTimeout(() => {
                if (this.editModeMessage && this.editModeMessage === message) {
                    message.style.animation = 'fadeOut 0.3s ease';
                    setTimeout(() => {
                        if (message.parentNode) {
                            message.remove();
                        }
                        if (this.editModeMessage === message) {
                            this.editModeMessage = null;
                        }
                    }, 300);
                }
            }, 3000);
            
            // アニメーション用スタイル
            if (!document.querySelector('#click-edit-animations')) {
                const style = document.createElement('style');
                style.id = 'click-edit-animations';
                style.textContent = `
                    @keyframes fadeIn {
                        from { opacity: 0; transform: translateX(-50%) translateY(-10px); }
                        to { opacity: 1; transform: translateX(-50%) translateY(0); }
                    }
                    @keyframes fadeOut {
                        from { opacity: 1; transform: translateX(-50%) translateY(0); }
                        to { opacity: 0; transform: translateX(-50%) translateY(-10px); }
                    }
                    @keyframes slideIn {
                        from { opacity: 0; transform: translateX(20px); }
                        to { opacity: 1; transform: translateX(0); }
                    }
                    @keyframes slideOut {
                        from { opacity: 1; transform: translateX(0); }
                        to { opacity: 0; transform: translateX(20px); }
                    }
                `;
                document.head.appendChild(style);
            }
        }

        /**
         * 詳細編集エディタを開く（親要素対象）
         */
        openDetailEditor(element) {
            console.log('詳細編集エディタを開きます:', element);
            
            // 親要素を取得
            const parentElement = element.parentElement;
            
            // 編集対象を決定：親要素があり、かつ親要素がセクション自体でない場合は親要素、そうでなければ要素自体
            let targetElement;
            if (parentElement && parentElement !== this.currentSection) {
                targetElement = parentElement;
                console.log('対象親要素:', targetElement);
            } else {
                targetElement = element;
                console.log('対象要素（自身）:', targetElement);
            }
            
            // 詳細編集エディタを作成
            this.createDetailEditor(targetElement, element);
        }
        
        /**
         * 詳細編集エディタUIを作成
         */
        createDetailEditor(targetElement, originalElement) {
            // 既存のエディタがあれば削除
            const existingEditor = document.querySelector('.detail-text-editor');
            if (existingEditor) {
                existingEditor.remove();
            }
            
            // モバイル判定
            const isMobile = window.innerWidth <= 768;
            
            // エディタオーバーレイ
            const overlay = document.createElement('div');
            overlay.className = 'detail-text-editor';
            overlay.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                z-index: 100020;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: ${isMobile ? '10px' : '20px'};
                box-sizing: border-box;
            `;
            
            // エディタパネル
            const panel = document.createElement('div');
            panel.className = 'detail-editor-panel';
            panel.style.cssText = `
                background: var(--card-bg, white);
                border-radius: ${isMobile ? '8px' : '12px'};
                width: ${isMobile ? '100%' : '80%'};
                max-width: ${isMobile ? '100%' : '800px'};
                height: ${isMobile ? '100%' : '70%'};
                max-height: ${isMobile ? '100%' : '600px'};
                display: flex;
                flex-direction: column;
                box-shadow: var(--box-shadow-hover, 0 10px 30px rgba(0, 0, 0, 0.3));
                overflow: hidden;
                font-family: var(--font-family);
                color: var(--text-color);
            `;
            
            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = `
                padding: ${isMobile ? '15px' : '20px'};
                border-bottom: 1px solid #eee;
                display: flex;
                justify-content: space-between;
                align-items: center;
                background: #f8f9fa;
                flex-shrink: 0;
            `;
            
            const title = document.createElement('h3');
            title.textContent = `詳細編集: ${targetElement.tagName.toLowerCase()}`;
            title.style.cssText = 'margin: 0; color: var(--heading-color, #333); font-size: 18px; font-weight: 600; font-family: var(--font-family);';
            
            const closeBtn = document.createElement('button');
            closeBtn.textContent = '✕';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 24px;
                cursor: pointer;
                color: var(--text-color, #999);
                padding: 5px;
            `;
            closeBtn.onclick = () => overlay.remove();
            
            header.appendChild(title);
            header.appendChild(closeBtn);
            
            // エディタエリア
            const editorArea = document.createElement('div');
            editorArea.style.cssText = `
                flex: 1;
                padding: 20px;
                display: flex;
                flex-direction: column;
                overflow: auto;
            `;
            
            // テキストエリア
            const textarea = document.createElement('textarea');
            textarea.className = 'detail-editor-textarea';
            textarea.value = targetElement.innerHTML;
            textarea.style.cssText = `
                flex: 1;
                width: 100%;
                border: 1px solid #ddd;
                border-radius: 6px;
                padding: 15px;
                font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
                font-size: 14px;
                line-height: 1.5;
                resize: none;
                outline: none;
                background: #fafafa;
            `;
            
            // プレビューエリア
            const previewArea = document.createElement('div');
            previewArea.className = 'detail-editor-preview';
            previewArea.style.cssText = `
                margin-top: 15px;
                padding: 15px;
                border: 1px solid #ddd;
                border-radius: 6px;
                background: white;
                min-height: 100px;
                max-height: 150px;
                overflow: auto;
            `;
            
            // リアルタイムプレビュー
            const updatePreview = () => {
                previewArea.innerHTML = textarea.value;
            };
            textarea.addEventListener('input', updatePreview);
            updatePreview();
            
            // フッター（ボタンエリア）
            const footer = document.createElement('div');
            footer.style.cssText = `
                padding: 20px;
                border-top: 1px solid #eee;
                display: flex;
                gap: 12px;
                justify-content: flex-end;
                background: #f8f9fa;
            `;
            
            const cancelBtn = document.createElement('button');
            cancelBtn.textContent = 'キャンセル';
            cancelBtn.style.cssText = `
                padding: 10px 20px;
                border: 1px solid #ddd;
                border-radius: 6px;
                background: white;
                color: #666;
                cursor: pointer;
                font-size: 14px;
            `;
            cancelBtn.onclick = () => overlay.remove();
            
            const applyBtn = document.createElement('button');
            applyBtn.textContent = '適用';
            applyBtn.style.cssText = `
                padding: 10px 20px;
                border: none;
                border-radius: 6px;
                background: #2196F3;
                color: white;
                cursor: pointer;
                font-size: 14px;
                font-weight: 500;
            `;
            applyBtn.onclick = () => {
                this.applyDetailEdit(targetElement, textarea.value);
                overlay.remove();
            };
            
            footer.appendChild(cancelBtn);
            footer.appendChild(applyBtn);
            
            // 組み立て
            editorArea.appendChild(textarea);
            editorArea.appendChild(previewArea);
            panel.appendChild(header);
            panel.appendChild(editorArea);
            panel.appendChild(footer);
            overlay.appendChild(panel);
            document.body.appendChild(overlay);
            
            // フォーカス
            setTimeout(() => textarea.focus(), 100);
        }
        
        /**
         * 詳細編集の適用
         */
        applyDetailEdit(targetElement, newContent) {
            console.log('詳細編集を適用:', targetElement, newContent);
            
            // 元のHTMLを保存（undo用）
            if (!targetElement.dataset.originalHtml) {
                targetElement.dataset.originalHtml = targetElement.innerHTML;
            }
            
            // 新しいコンテンツを適用
            targetElement.innerHTML = newContent;
            
            // 変更を記録（ElementEditManagerに通知）
            this.notifyChange(targetElement, 'innerHTML', newContent);
            
            // 成功通知
            this.showNotification('詳細編集が適用されました', 'success');
        }
        
        /**
         * 通知表示
         */
        showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                padding: 12px 20px;
                background: ${type === 'success' ? '#64748b' : type === 'warning' ? '#FF9800' : '#2196F3'};
                color: white;
                border-radius: 6px;
                font-size: 14px;
                z-index: 100030;
                animation: slideIn 0.3s ease;
            `;
            notification.textContent = message;
            
            document.body.appendChild(notification);
            
            setTimeout(() => {
                notification.style.animation = 'slideOut 0.3s ease';
                setTimeout(() => notification.remove(), 300);
            }, 3000);
        }

        /**
         * 無効化
         */
        deactivate() {
            if (!this.isActive) {
                console.log('🔄 既に非アクティブ状態');
                return;
            }
            
            console.log('🔴 SectionClickEditor無効化開始');
            this.isActive = false;
            
            // イベントリスナーを削除
            if (this.currentSection) {
                console.log('🗑️ イベントリスナー削除');
                this.currentSection.removeEventListener('click', this.clickHandler, true);
                this.currentSection.removeEventListener('mouseover', this.hoverHandler);
                this.currentSection.removeEventListener('mouseleave', this.mouseLeaveHandler);
            }
            
            // ハイライトをクリア
            console.log('🎨 ハイライトクリア');
            this.clearHoverHighlight();
            this.editableElements.forEach(el => {
                el.style.outline = '';
                el.style.outlineOffset = '';
                el.style.cursor = '';
                el.style.position = '';
                el.style.zIndex = '';
            });
            
            // メニューを閉じる
            if (this.quickEditMenu) {
                console.log('📋 QuickEditMenu閉じる');
                this.quickEditMenu.close();
                this.quickEditMenu = null;
            }
            
            // 編集モードメッセージを削除
            if (this.editModeMessage) {
                this.editModeMessage.remove();
                this.editModeMessage = null;
            }
            
            this.currentSection = null;
            this.editableElements.clear();
            this.currentEditingElement = null;
            this.currentHoveredElement = null;
            
            console.log('✅ SectionClickEditor無効化完了');
        }

        /**
         * アイコンピッカーを作成
         */
        createIconPicker(currentValue) {
            const container = document.createElement('div');
            container.style.cssText = 'display: flex; flex-direction: column; gap: 8px; flex: 1;';
            
            // 現在のアイコン表示
            const currentIcon = document.createElement('div');
            currentIcon.style.cssText = `
                padding: 8px;
                border: 1px solid #ddd;
                border-radius: 4px;
                text-align: center;
                font-size: 16px;
                background: #f8f9fa;
                min-height: 32px;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            currentIcon.textContent = currentValue || '🔍';
            
            // アイコンピッカーボタン
            const pickerBtn = document.createElement('button');
            pickerBtn.textContent = 'アイコンを選択';
            pickerBtn.style.cssText = `
                padding: 6px 12px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                font-size: 11px;
                cursor: pointer;
                font-weight: 500;
            `;
            
            pickerBtn.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();
                this.showIconPickerModal((selectedIcon) => {
                    // HTMLタグが含まれている場合はinnerHTMLを使用
                    if (selectedIcon.includes('<') && selectedIcon.includes('>')) {
                        currentIcon.innerHTML = selectedIcon;
                    } else {
                        currentIcon.textContent = selectedIcon;
                    }
                    // 変更イベントを発火
                    const event = new CustomEvent('change');
                    container.dispatchEvent(event);
                });
            };
            
            container.appendChild(currentIcon);
            container.appendChild(pickerBtn);
            
            // 値を取得するためのメソッド
            Object.defineProperty(container, 'value', {
                get: function() {
                    return currentIcon.textContent;
                }
            });
            
            return container;
        }
        
        /**
         * アイコンピッカーモーダルを表示
         */
        showIconPickerModal_deprecated(targetElement, onSelect) {
            // 既存のモーダルがあれば削除
            const existingModal = document.querySelector('.icon-picker-modal');
            if (existingModal) {
                existingModal.remove();
            }
            
            // モーダルオーバーレイ
            const modal = document.createElement('div');
            modal.className = 'icon-picker-modal';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.7);
                z-index: 100030;
                display: flex;
                align-items: center;
                justify-content: center;
            `;
            
            // モーダルパネル
            const panel = document.createElement('div');
            // モバイル判定とサイズ調整
            const isMobile = window.innerWidth <= 768;
            
            panel.style.cssText = `
                background: var(--card-bg, white);
                border-radius: 12px;
                width: ${isMobile ? 'calc(100vw - 20px)' : '400px'};
                max-width: ${isMobile ? 'none' : '90vw'};
                max-height: ${isMobile ? 'calc(100vh - 40px)' : '500px'};
                overflow: hidden;
                box-shadow: var(--box-shadow-hover, 0 10px 30px rgba(0, 0, 0, 0.3));
                font-family: var(--font-family);
                color: var(--text-color);
            `;
            
            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = `
                padding: 16px 20px;
                border-bottom: 1px solid #eee;
                display: flex;
                justify-content: space-between;
                align-items: center;
                background: #f8f9fa;
            `;
            
            const title = document.createElement('h3');
            title.textContent = 'アイコンを選択';
            title.style.cssText = 'margin: 0; font-size: 16px; font-weight: 600; color: var(--heading-color, #333); font-family: var(--font-family);';
            
            const closeBtn = document.createElement('button');
            closeBtn.textContent = '✕';
            closeBtn.style.cssText = `
                background: none;
                border: none;
                font-size: 18px;
                cursor: pointer;
                color: var(--text-color, #999);
                padding: 4px;
            `;
            closeBtn.onclick = () => modal.remove();
            
            header.appendChild(title);
            header.appendChild(closeBtn);
            
            // アイコングリッド
            const iconGrid = document.createElement('div');
            iconGrid.style.cssText = `
                display: grid;
                grid-template-columns: repeat(8, 1fr);
                gap: 8px;
                padding: 20px;
                max-height: 350px;
                overflow-y: auto;
            `;
            
            // アイコンリスト
            const icons = [
                // 基本的なアイコン
                '🌿', '👥', '🎯', '✨', '💫', '🌟', '🔥', '⭐',
                '❤️', '💚', '💙', '💜', '🧡', '💛', '🖤', '🤍',
                '📍', '📎', '📋', '📝', '📄', '📊', '📈', '📉',
                '🏠', '🏢', '🏪', '🏫', '🏥', '🏨', '🏬', '🏭',
                '🚀', '✈️', '🚗', '🚕', '🚙', '🚌', '🚎', '🚐',
                '⚡', '🔋', '💡', '🔧', '🔨', '⚙️', '🛠️', '⚒️',
                '📱', '💻', '⌨️', '🖥️', '🖨️', '📹', '📷', '📺',
                '🎵', '🎶', '🎤', '🎧', '🔊', '📢', '📣', '📯',
                '🌍', '🌎', '🌏', '🗺️', '🧭', '🏔️', '🌋', '🏞️',
                '🍀', '🌱', '🌿', '🍃', '🌸', '🌺', '🌻', '🌹',
                '⏰', '⏱️', '⏲️', '🕐', '📅', '📆', '🗓️', '📋',
                '🎨', '🖌️', '🖍️', '✏️', '📐', '📏', '📝', '✒️',
                '🔍', '🔎', '🔬', '🔭', '📡', '💡', '🔦', '🕯️',
                '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥙',
                '☀️', '🌤️', '⛅', '🌦️', '🌧️', '⛈️', '🌩️', '❄️',
                '✅', '❌', '❓', '❗', '⚠️', '🚫', '💯', '🔄'
            ];
            
            icons.forEach(icon => {
                const iconBtn = document.createElement('button');
                iconBtn.textContent = icon;
                iconBtn.style.cssText = `
                    padding: 12px;
                    border: 1px solid var(--border-color, #ddd);
                    border-radius: 6px;
                    background: var(--card-bg, white);
                    cursor: pointer;
                    font-size: 20px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    transition: all 0.2s ease;
                `;
                
                iconBtn.onmouseover = () => {
                    iconBtn.style.background = 'var(--hero-bg, #f0f8ff)';
                    iconBtn.style.borderColor = 'var(--accent-color, #2196F3)';
                    iconBtn.style.transform = 'scale(1.1)';
                };
                
                iconBtn.onmouseout = () => {
                    iconBtn.style.background = 'var(--card-bg, white)';
                    iconBtn.style.borderColor = 'var(--border-color, #ddd)';
                    iconBtn.style.transform = 'scale(1)';
                };
                
                iconBtn.onclick = () => {
                    onSelect(icon);
                    modal.remove();
                };
                
                iconGrid.appendChild(iconBtn);
            });
            
            panel.appendChild(header);
            panel.appendChild(iconGrid);
            modal.appendChild(panel);
            document.body.appendChild(modal);
            
            // 外側クリックで閉じる
            modal.onclick = (e) => {
                if (e.target === modal) {
                    modal.remove();
                }
            };
        }

        /**
         * RGB色を16進数に変換
         */
        rgbToHex(rgb) {
            if (rgb.startsWith('#')) return rgb;
            
            const matches = rgb.match(/\d+/g);
            if (!matches || matches.length < 3) return '#000000';
            
            const r = parseInt(matches[0]).toString(16).padStart(2, '0');
            const g = parseInt(matches[1]).toString(16).padStart(2, '0');
            const b = parseInt(matches[2]).toString(16).padStart(2, '0');
            
            return `#${r}${g}${b}`;
        }
        
        /**
         * 親要素の情報を取得
         */
        getParentInfo(element) {
            const parent = element.parentElement;
            if (!parent || parent === this.currentSection) return null;
            
            return {
                tag: parent.tagName.toLowerCase(),
                classes: (parent.className || '').toString(),
                id: parent.id || '',
                text: (parent.textContent || '').substring(0, 50) + '...'
            };
        }
        
        /**
         * 要素の情報を取得
         */
        getElementInfo(element) {
            return {
                tag: element.tagName.toLowerCase(),
                classes: (element.className || '').toString(),
                id: element.id || '',
                parentInfo: this.getParentInfo(element)
            };
        }
        
        /**
         * 全体編集モードで有効化（全要素が編集対象）
         */
        activateGlobal() {
            console.log('🌍 全体編集モードを有効化');
            
            // 編集状態をクリア
            this.deactivate();
            
            // 全ての編集可能要素に対してイベントリスナーを追加
            const editableElements = document.querySelectorAll('h1, h2, h3, h4, h5, h6, p, span, div, a, button, li, td, th, label, img, video, iframe');
            
            editableElements.forEach(element => {
                // エディター関連要素は除外
                if (element.closest('#floating-controls') || 
                    element.closest('.quick-edit-menu') ||
                    element.closest('.save-menu-overlay') ||
                    element.closest('.section-boundary-label') ||
                    element.classList.contains('element-editing')) {
                    return;
                }
                
                // ホバーエフェクトを追加
                element.addEventListener('mouseenter', this.handleGlobalHover);
                element.addEventListener('mouseleave', this.handleGlobalHoverOut);
                element.addEventListener('click', this.handleGlobalClick);
            });
            
            this.isActive = true;
            console.log(`✅ ${editableElements.length}個の要素が編集対象になりました`);
        }
        
        /**
         * 全体編集モード用のホバー処理
         */
        handleGlobalHover = (event) => {
            const element = event.target;
            element.style.setProperty('background-color', 'rgba(var(--accent-color-rgb, 100, 116, 139), 0.1)', 'important');
            element.style.setProperty('outline', '1px solid var(--accent-color, #64748b)', 'important');
            element.style.setProperty('cursor', 'pointer', 'important');
        }
        
        /**
         * 全体編集モード用のホバーアウト処理
         */
        handleGlobalHoverOut = (event) => {
            const element = event.target;
            if (!element.classList.contains('element-editing')) {
                element.style.removeProperty('background-color');
                element.style.removeProperty('outline');
                element.style.removeProperty('cursor');
            }
        }
        
        /**
         * 全体編集モード用のクリック処理
         */
        handleGlobalClick = (event) => {
            event.preventDefault();
            event.stopPropagation();
            
            const element = event.target;
            console.log('🎯 全体編集モードでクリック:', element);
            
            // 要素解析
            const analysis = this.analyzeElement(element);
            
            if (analysis.editable.length > 0) {
                // QuickEditMenuを表示
                const rect = element.getBoundingClientRect();
                const x = rect.left + window.scrollX;
                const y = rect.top + window.scrollY;
                
                this.showQuickEditMenu(x, y, element, analysis);
            }
        }
    }

    // グローバルに公開
    window.SectionClickEditor = SectionClickEditor;

    // 即座に初期化（QuickEditMenuから使用できるように）
    window.sectionClickEditor = new SectionClickEditor();

})();

// 読み込み完了を通知
console.log('SectionClickEditor.js loaded');