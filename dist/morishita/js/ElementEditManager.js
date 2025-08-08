(function() {
    'use strict';

    class ElementEditManager {
        constructor() {
            this.editedElements = new Map(); // 編集された要素を記録
            this.defaultStyles = new Map(); // デフォルトスタイルを保存
            this.STORAGE_KEY = 'element_edits';
            this.DEFAULT_KEY = 'element_defaults';
            this.AUTO_SAVE_KEY = 'element_edits_autosave';
            this.AUTO_SAVE_ENABLED_KEY = 'element_edits_autosave_enabled';
            this.autoSaveEnabled = true; // デフォルトで自動保存有効
            this.gitHistoryManager = null; // Git履歴管理
            
            this.init();
        }

        init() {
            console.log('ElementEditManager初期化開始');
            
            // Git履歴管理の初期化（現在のサイトディレクトリを指定）
            if (window.GitHistoryManager) {
                const workingDir = this.getCurrentSiteDirectory();
                this.gitHistoryManager = new window.GitHistoryManager(workingDir);
                this.initializeGitRepo();
            }
            
            // 自動保存設定を読み込み
            this.loadAutoSaveSetting();
            
            // 編集イベントをリッスン
            document.addEventListener('quickEditChange', (event) => {
                this.handleElementEdit(event.detail);
            });
            
            // 色変更イベントをリッスン（グローバルテーマ変更）
            document.addEventListener('colorChanged', () => {
                // グローバルテーマが変更されたときの処理
                this.updateStatus('グローバルテーマが変更されました');
            });
            
            // DOM読み込み完了後に少し遅延してから編集内容を読み込み
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => {
                    setTimeout(() => this.loadSavedEdits(), 100);
                });
            } else {
                setTimeout(() => this.loadSavedEdits(), 100);
            }
        }

        /**
         * 自動保存設定を読み込み
         */
        loadAutoSaveSetting() {
            try {
                const savedSetting = localStorage.getItem(this.AUTO_SAVE_ENABLED_KEY);
                if (savedSetting !== null) {
                    this.autoSaveEnabled = savedSetting === 'true';
                }
                console.log('自動保存設定:', this.autoSaveEnabled ? '有効' : '無効');
            } catch (error) {
                console.error('自動保存設定の読み込みエラー:', error);
            }
        }

        /**
         * 自動保存設定を切り替え
         */
        toggleAutoSave() {
            this.autoSaveEnabled = !this.autoSaveEnabled;
            try {
                localStorage.setItem(this.AUTO_SAVE_ENABLED_KEY, this.autoSaveEnabled.toString());
                this.showNotification(
                    `自動保存を${this.autoSaveEnabled ? '有効' : '無効'}にしました`,
                    'info'
                );
            } catch (error) {
                console.error('自動保存設定の保存エラー:', error);
            }
            return this.autoSaveEnabled;
        }

        /**
         * 現在のサイトディレクトリを取得
         */
        getCurrentSiteDirectory() {
            // 現在のURLパスから作業ディレクトリを推定
            const currentPath = window.location.pathname;
            if (currentPath.startsWith('site/')) {
                // site/next/project/ -> public/site/next/project
                return 'public/' + currentPath.replace(/\/$/, '');
            }
            // デフォルトはプロジェクトディレクトリ
            return 'public/site/next/project';
        }

        /**
         * Gitリポジトリを初期化
         */
        async initializeGitRepo() {
            if (!this.gitHistoryManager) return;
            
            try {
                const isGitRepo = await this.gitHistoryManager.checkGitRepo();
                if (!isGitRepo) {
                    console.log('Gitリポジトリを初期化します...');
                    await this.gitHistoryManager.initGitRepo();
                    console.log('Gitリポジトリの初期化が完了しました');
                }
            } catch (error) {
                console.error('Gitリポジトリの初期化エラー:', error);
            }
        }

        /**
         * 要素の編集を記録
         */
        handleElementEdit(detail) {
            const { element, property, value, sectionId } = detail;
            const elementId = this.getElementId(element);
            
            console.log('ElementEditManager: 編集内容を記録', {
                elementId: elementId,
                property: property,
                value: value,
                sectionId: sectionId,
                autoSaveEnabled: this.autoSaveEnabled
            });
            
            // 編集内容を記録
            if (!this.editedElements.has(elementId)) {
                this.editedElements.set(elementId, {
                    element: element,
                    sectionId: sectionId,
                    originalStyles: {},
                    editedStyles: {}
                });
                console.log('新しい要素を記録:', elementId);
            }
            
            const elementData = this.editedElements.get(elementId);
            
            // 初回編集時は元のスタイルを保存
            if (!elementData.originalStyles[property]) {
                elementData.originalStyles[property] = window.getComputedStyle(element)[property];
            }
            
            // 編集内容を記録
            elementData.editedStyles[property] = value;
            
            this.updateStatus(`編集中: ${this.editedElements.size}個の要素`);
            
            // 自動保存が有効な場合は即座に保存
            if (this.autoSaveEnabled) {
                this.autoSave();
            }
        }

        /**
         * 自動保存（デバウンス付き）
         */
        autoSave() {
            // 既存のタイマーをクリア
            if (this.autoSaveTimer) {
                clearTimeout(this.autoSaveTimer);
            }
            
            // 500ms後に保存実行（連続編集時の負荷軽減）
            this.autoSaveTimer = setTimeout(() => {
                console.log('自動保存実行');
                this.saveEdits(true); // 自動保存フラグ付きで実行
            }, 500);
        }

        /**
         * 編集内容を保存（サーバー側に保存）
         */
        async saveEdits(isAutoSave = false) {
            console.log(isAutoSave ? '自動保存実行' : '手動保存実行');
            console.log('編集された要素数:', this.editedElements.size);
            
            const editsToSave = {};
            
            this.editedElements.forEach((data, elementId) => {
                console.log('保存対象要素:', elementId, data);
                editsToSave[elementId] = {
                    sectionId: data.sectionId,
                    editedStyles: data.editedStyles
                };
            });
            
            console.log('保存するデータ:', editsToSave);
            
            try {
                // まず既存のlocalStorageデータを移行（初回のみ）
                await this.migrateFromLocalStorage();
                
                const dataToSave = JSON.stringify(editsToSave);
                
                // データサイズを確認
                const dataSize = new Blob([dataToSave]).size;
                console.log(`保存データサイズ: ${(dataSize / 1024).toFixed(2)} KB`);
                
                // 大きすぎるデータは圧縮または制限
                let processedData = JSON.parse(JSON.stringify(editsToSave)); // Deep copy
                
                if (dataSize > 100 * 1024) { // 100KB以上の場合、画像を処理
                    console.warn('データサイズが大きいため、画像データを処理します。');
                    
                    // 画像データを分離して処理
                    const imagePromises = [];
                    
                    Object.keys(processedData).forEach(elementId => {
                        const styles = processedData[elementId].editedStyles;
                        
                        // 背景画像の処理
                        if (styles.backgroundImage && styles.backgroundImage.includes('data:')) {
                            const base64Match = styles.backgroundImage.match(/url\(['"]?(data:image\/[^;]+;base64,[^'"]+)['"]?\)/);
                            if (base64Match) {
                                const imageData = base64Match[1];
                                // サーバーに画像を保存
                                imagePromises.push(
                                    this.uploadImageToServer(imageData, `bg_${elementId}`)
                                        .then(url => {
                                            styles.backgroundImage = `url('${url}')`;
                                        })
                                        .catch(err => {
                                            console.error('背景画像のアップロードエラー:', err);
                                            // エラー時はデータURLをそのまま保持（ただしlocalStorageには保存しない）
                                        })
                                );
                            }
                        }
                        
                        // src属性の処理
                        if (styles.src && styles.src.startsWith('data:')) {
                            imagePromises.push(
                                this.uploadImageToServer(styles.src, `img_${elementId}`)
                                    .then(url => {
                                        styles.src = url;
                                    })
                                    .catch(err => {
                                        console.error('画像のアップロードエラー:', err);
                                    })
                            );
                        }
                    });
                    
                    // 全ての画像アップロードが完了してから保存
                    if (imagePromises.length > 0) {
                        await Promise.all(imagePromises);
                    }
                }
                
                // 処理済みデータを使用（画像URLに置換されている場合）
                const dataToStore = dataSize > 100 * 1024 ? processedData : editsToSave;
                
                // サーバーに保存（メイン処理）
                const saveType = isAutoSave ? 'autoSave' : 'manual';
                await this.saveToServer(dataToStore, saveType);
                
                console.log(`サーバー保存完了 (${isAutoSave ? '自動' : '手動'})`);
                
                // Git自動コミット（AIによる編集の場合のみ）
                if (this.gitHistoryManager && !isAutoSave) {
                    this.performGitCommit(editsToSave);
                }
                
                // ローカルキャッシュとしても保存（オプション）
                try {
                    const cacheKey = isAutoSave ? `${this.AUTO_SAVE_KEY}_cache` : `${this.STORAGE_KEY}_cache`;
                    localStorage.setItem(cacheKey, JSON.stringify(dataToStore));
                    localStorage.setItem(`${cacheKey}_timestamp`, new Date().toISOString());
                } catch (error) {
                    // キャッシュ失敗は無視（サーバー保存が成功していれば問題ない）
                    console.warn('ローカルキャッシュ保存エラー:', error);
                }
                
                if (isAutoSave) {
                    this.updateStatus('自動保存済み');
                } else {
                    this.updateStatus('保存完了');
                    this.showNotification('✓ 編集内容を保存しました', 'success');
                }
            } catch (error) {
                console.error('保存エラー:', error);
                if (isAutoSave) {
                    // 自動保存の場合はエラーを通知のみ
                    this.showNotification('自動保存に失敗しました', 'error');
                } else {
                    throw error; // 手動保存の場合はエラーを上位に伝播
                }
            }
        }
        
        /**
         * 画像をサーバーにアップロード
         */
        async uploadImageToServer(imageData, filename) {
            try {
                // Base64データからBlob作成
                const base64Data = imageData.split(',')[1];
                const mimeType = imageData.match(/data:([^;]+);/)[1];
                const byteCharacters = atob(base64Data);
                const byteNumbers = new Array(byteCharacters.length);
                
                for (let i = 0; i < byteCharacters.length; i++) {
                    byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                
                const byteArray = new Uint8Array(byteNumbers);
                const blob = new Blob([byteArray], { type: mimeType });
                
                // FormDataに追加
                const formData = new FormData();
                formData.append('image', blob, filename + '.' + mimeType.split('/')[1]);
                
                // サーバーに送信（Cloudflare経由でも動作するようにフルパスを使用）
                const uploadUrl = window.location.origin + '/upload/image';
                const response = await fetch(uploadUrl, {
                    method: 'POST',
                    body: formData
                });
                
                if (!response.ok) {
                    throw new Error('画像アップロードに失敗しました');
                }
                
                const result = await response.json();
                console.log('画像アップロード完了:', result.url);
                
                // 絶対URLを相対URLに変換（携帯からのアクセスに対応）
                let url = result.url;
                if (url.includes('localhost:3500')) {
                    // localhost URLを相対パスに変換
                    url = url.replace(/https?:\/\/localhost:3500/, '');
                }
                
                return url;
            } catch (error) {
                console.error('画像アップロードエラー:', error);
                throw error;
            }
        }

        /**
         * サーバーに編集内容を保存
         */
        async saveToServer(editsData) {
            try {
                const currentPath = window.location.pathname;
                const sitePath = currentPath.replace(/^\/site\//, '').replace(/\/$/, '');
                
                // 編集データのみ送信（HTMLは送信しない）
                const response = await fetch('api/site-edits/save', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        sitePath: sitePath,
                        edits: editsData,
                        timestamp: new Date().toISOString()
                        // htmlフィールドを削除
                    })
                });
                
                if (!response.ok) {
                    throw new Error('サーバー保存に失敗しました');
                }
                
                const result = await response.json();
                console.log('サーバー保存完了:', result);
            } catch (error) {
                console.error('サーバー保存エラー:', error);
                // エラーは呼び出し元で処理
                throw error;
            }
        }

        /**
         * 古い自動保存データを削除
         */
        clearOldAutoSaveData() {
            try {
                // localStorage内の全てのキーを確認
                const keysToRemove = [];
                for (let i = 0; i < localStorage.length; i++) {
                    const key = localStorage.key(i);
                    // 自動保存関連のキーを削除対象に追加
                    if (key && (key.includes('autosave') || key.includes('auto_save'))) {
                        keysToRemove.push(key);
                    }
                }
                
                // 削除実行
                keysToRemove.forEach(key => {
                    localStorage.removeItem(key);
                    console.log(`削除: ${key}`);
                });
                
                console.log(`${keysToRemove.length}個の古い自動保存データを削除しました`);
            } catch (error) {
                console.error('古いデータの削除エラー:', error);
            }
        }

        /**
         * デフォルトとして保存
         */
        saveAsDefault() {
            const defaultsToSave = {};
            
            this.editedElements.forEach((data, elementId) => {
                defaultsToSave[elementId] = {
                    sectionId: data.sectionId,
                    editedStyles: data.editedStyles
                };
            });
            
            try {
                localStorage.setItem(this.DEFAULT_KEY, JSON.stringify(defaultsToSave));
                this.defaultStyles = new Map(Object.entries(defaultsToSave));
                this.showNotification('デフォルトとして保存しました', 'success');
                this.updateStatus('デフォルト保存完了');
            } catch (error) {
                console.error('デフォルト保存エラー:', error);
                this.showNotification('デフォルト保存に失敗しました', 'error');
            }
        }

        /**
         * デフォルトに戻す
         */
        resetToDefault() {
            try {
                const defaultsJson = localStorage.getItem(this.DEFAULT_KEY);
                if (!defaultsJson) {
                    this.showNotification('デフォルト設定が見つかりません', 'warning');
                    return;
                }
                
                const defaults = JSON.parse(defaultsJson);
                
                // デフォルトスタイルを適用
                Object.entries(defaults).forEach(([elementId, data]) => {
                    const element = this.findElementById(elementId);
                    if (element) {
                        Object.entries(data.editedStyles).forEach(([property, value]) => {
                            if (property === 'textContent') {
                                element.textContent = value;
                            } else if (property === 'innerHTML') {
                                element.innerHTML = value;
                            } else if (property === 'src' || property === 'href') {
                                element[property] = value;
                            } else if (property === 'backgroundImage') {
                                // 背景画像の場合は特別な処理
                                // 既存のbackgroundプロパティをクリア
                                element.style.removeProperty('background');
                                // !importantで背景画像を設定
                                element.style.setProperty('background-image', value, 'important');
                            } else {
                                element.style[property] = value;
                            }
                        });
                    }
                });
                
                this.showNotification('デフォルト設定に戻しました', 'success');
                this.updateStatus('デフォルトに復元');
            } catch (error) {
                console.error('デフォルト復元エラー:', error);
                this.showNotification('デフォルトの復元に失敗しました', 'error');
            }
        }

        /**
         * 色設定をリセット
         */
        resetColors() {
            let resetCount = 0;
            
            this.editedElements.forEach((data, elementId) => {
                const element = this.findElementById(elementId);
                if (element) {
                    // 色関連のプロパティをリセット
                    const colorProperties = ['color', 'backgroundColor', 'borderColor'];
                    colorProperties.forEach(prop => {
                        if (data.editedStyles[prop]) {
                            element.style[prop] = '';
                            delete data.editedStyles[prop];
                            resetCount++;
                        }
                    });
                }
            });
            
            if (resetCount > 0) {
                this.showNotification(`${resetCount}個の色設定をリセットしました`, 'success');
                this.updateStatus('色設定リセット完了');
                
                // 編集内容を再保存
                this.saveEdits();
            } else {
                this.showNotification('リセットする色設定がありません', 'info');
            }
        }

        /**
         * 保存された編集内容を読み込み（サーバーから）
         */
        async loadSavedEdits() {
            console.log('=== loadSavedEdits 実行開始（サーバー版） ===');
            console.log('現在のURL:', window.location.href);
            console.log('プロジェクトパス:', this.getCurrentProjectPath());
            try {
                // サーバーから設定を読み込み
                const settings = await this.loadFromServer();
                
                let edits = null;
                let isAutoSaveData = false;
                
                if (settings && settings.elementEdits) {
                    // 新しい構造（フラット）と古い構造（ネスト）の両方に対応
                    if (settings.elementEdits.manual || settings.elementEdits.autoSave) {
                        // 古い構造
                        edits = settings.elementEdits.manual || settings.elementEdits.autoSave || null;
                        isAutoSaveData = !settings.elementEdits.manual && settings.elementEdits.autoSave;
                    } else {
                        // 新しい構造（フラット）
                        edits = settings.elementEdits;
                        isAutoSaveData = settings.saveType === 'autoSave';
                    }
                    
                    console.log('サーバーから読み込んだ編集データ:', edits);
                }
                
                if (edits) {
                    console.log('適用対象要素数:', Object.keys(edits).length);
                    
                    if (isAutoSaveData) {
                        this.showNotification('自動保存データから復元しました', 'info');
                    }
                    
                    // 保存された編集内容を適用
                    let appliedCount = 0;
                    Object.entries(edits).forEach(([elementId, data]) => {
                        console.log('要素ID検索中:', elementId);
                        const element = this.findElementById(elementId);
                        console.log('要素発見結果:', !!element, element);
                        
                        if (element) {
                            console.log('編集スタイル適用中:', data.editedStyles);
                            Object.entries(data.editedStyles).forEach(([property, value]) => {
                                console.log(`適用: ${property} = ${value}`);
                                if (property === 'textContent') {
                                    element.textContent = value;
                                } else if (property === 'innerHTML') {
                                    // Material Iconsの場合は遅延を入れて適用
                                    if (element.classList.contains('material-icons') || 
                                        element.classList.contains('material-icons-outlined')) {
                                        setTimeout(() => {
                                            element.innerHTML = value;
                                            console.log('Material Iconを遅延適用:', value);
                                        }, 500);
                                    } else {
                                        element.innerHTML = value;
                                    }
                                } else if (property === 'src' || property === 'href') {
                                    element[property] = value;
                                } else if (property === 'backgroundImage') {
                                    // 背景画像の場合は特別な処理
                                    // 既存のbackgroundプロパティをクリア
                                    element.style.removeProperty('background');
                                    // !importantで背景画像を設定
                                    element.style.setProperty('background-image', value, 'important');
                                } else {
                                    element.style[property] = value;
                                }
                            });
                            
                            // 編集済み要素として記録
                            this.editedElements.set(elementId, {
                                element: element,
                                sectionId: data.sectionId,
                                originalStyles: {},
                                editedStyles: data.editedStyles
                            });
                            appliedCount++;
                        } else {
                            console.warn('要素が見つからません:', elementId);
                        }
                    });
                    
                    console.log(`編集内容適用完了: ${appliedCount}/${Object.keys(edits).length} 個の要素`);
                } else {
                    console.log('保存された編集内容はありません');
                }
                
                // デフォルト設定も読み込み
                const defaultsJson = localStorage.getItem(this.DEFAULT_KEY);
                if (defaultsJson) {
                    const defaults = JSON.parse(defaultsJson);
                    this.defaultStyles = new Map(Object.entries(defaults));
                    console.log('デフォルト設定読み込み完了:', defaults);
                }
            } catch (error) {
                console.error('編集内容の読み込みエラー:', error);
            }
            console.log('=== loadSavedEdits 実行完了 ===');
        }

        /**
         * 要素のIDを生成
         */
        getElementId(element) {
            // 既存のIDがあればそれを使用
            if (element.id) return element.id;
            
            // なければセレクタベースのIDを生成
            const tag = element.tagName.toLowerCase();
            const classes = Array.from(element.classList).join('.');
            const parent = element.parentElement;
            const index = Array.from(parent.children).indexOf(element);
            
            return `${tag}${classes ? '.' + classes : ''}_${index}`;
        }

        /**
         * IDから要素を探す
         */
        findElementById(elementId) {
            // まずIDで検索
            let element = document.getElementById(elementId);
            if (element) return element;
            
            // セレクタベースのIDの場合
            // div.hero-gradient_0 -> div.hero-gradient の0番目
            const match = elementId.match(/^(.+)_(\d+)$/);
            if (match) {
                const [, selector, index] = match;
                const elements = document.querySelectorAll(selector);
                const element = elements[parseInt(index)];
                if (element) {
                    console.log(`セレクタ "${selector}" のインデックス ${index} で要素を発見`);
                    return element;
                }
            }
            
            return null;
        }

        /**
         * ステータスを更新
         */
        updateStatus(message) {
            const statusEl = document.querySelector('.status-text');
            if (statusEl) {
                statusEl.textContent = message;
            }
        }

        /**
         * 通知を表示
         */
        showNotification(message, type = 'info') {
            const notification = document.createElement('div');
            notification.className = `edit-notification ${type}`;
            notification.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                padding: 12px 20px;
                background: ${type === 'success' ? '#64748b' : type === 'error' ? '#f44336' : type === 'warning' ? '#FF9800' : '#2196F3'};
                color: white;
                border-radius: 8px;
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
                z-index: 100004;
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
         * Git自動コミットを実行
         */
        async performGitCommit(editsToSave) {
            if (!this.gitHistoryManager) return;
            
            try {
                // 変更された要素の情報を収集
                const changedElements = [];
                const changedProperties = new Set();
                
                Object.entries(editsToSave).forEach(([elementId, data]) => {
                    const element = document.querySelector(`[data-element-id="${elementId}"]`) || 
                                   document.getElementById(elementId);
                    
                    if (element) {
                        changedElements.push({
                            tagName: element.tagName,
                            selector: this.getElementSelector(element),
                            properties: Object.keys(data.editedStyles)
                        });
                        
                        Object.keys(data.editedStyles).forEach(prop => changedProperties.add(prop));
                    }
                });
                
                // コミットメッセージの構築
                const changeCount = Object.keys(editsToSave).length;
                const propertyList = Array.from(changedProperties).join(', ');
                const description = `${changeCount}個の要素を編集 (${propertyList})`;
                
                // 要素情報
                const elementInfo = {
                    tagName: changedElements.length > 0 ? changedElements[0].tagName : 'unknown',
                    selector: changedElements.length > 0 ? changedElements[0].selector : 'unknown',
                    changedProperties: Array.from(changedProperties)
                };
                
                // Git自動コミット
                await this.gitHistoryManager.autoCommit(description, elementInfo);
                console.log('Git自動コミット完了:', description);
                
                // AIEditInterfaceの履歴を更新
                const aiEditEvent = new CustomEvent('gitHistoryUpdated');
                document.dispatchEvent(aiEditEvent);
                
            } catch (error) {
                console.error('Git自動コミットエラー:', error);
                // エラーが発生してもUIの動作は継続
            }
        }

        /**
         * 要素のセレクタを生成
         */
        getElementSelector(element) {
            if (!element) return '';
            
            if (element.id) {
                return `#${element.id}`;
            }
            
            if (element.className) {
                const classes = element.className.split(' ').filter(c => c && !c.startsWith('edit-')).join('.');
                if (classes) {
                    return `.${classes}`;
                }
            }
            
            return element.tagName.toLowerCase();
        }

        /**
         * コントロールボタンを取得
         */
        getControlButtons() {
            return {
                save: () => this.saveEdits(),
                saveAsDefault: () => this.saveAsDefault(),
                resetToDefault: () => this.resetToDefault(),
                resetColors: () => this.resetColors()
            };
        }

        /**
         * 現在の状態をデフォルトとして保存
         */
        async saveAsDefault() {
            try {
                console.log('現在の状態をデフォルトとして保存します');
                
                // 現在の状態を取得
                const currentState = await this.loadFromServer() || {
                    elementEdits: this.elementEdits,
                    lastSaved: new Date().toISOString(),
                    saveType: 'manual'
                };

                // デフォルト状態として保存
                const response = await fetch('api/save-default-settings', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(currentState)
                });

                if (!response.ok) {
                    throw new Error('デフォルト設定の保存に失敗しました');
                }

                const result = await response.json();
                console.log('デフォルト設定を保存しました:', result);
                
                // 通知を表示
                this.showNotification('現在の状態をデフォルトとして保存しました', 'success');
                
                return result;
            } catch (error) {
                console.error('デフォルト保存エラー:', error);
                this.showNotification('デフォルト保存に失敗しました', 'error');
                throw error;
            }
        }

        /**
         * デフォルト状態に戻す
         */
        async resetToDefault() {
            try {
                console.log('デフォルト状態に戻します');
                
                // デフォルト状態を読み込む
                const response = await fetch('/api/load-default-settings');
                if (!response.ok) {
                    throw new Error('デフォルト設定の読み込みに失敗しました');
                }

                const defaultState = await response.json();
                
                // デフォルト状態を現在の設定として保存
                await this.saveToServer(defaultState.elementEdits || {}, 'reset');
                
                // メモリ上の状態も更新
                this.elementEdits = defaultState.elementEdits || {};
                
                // ページをリロードして変更を反映
                this.showNotification('デフォルト状態に戻しています...', 'info');
                
                setTimeout(() => {
                    window.location.reload();
                }, 1000);
                
            } catch (error) {
                console.error('デフォルトリセットエラー:', error);
                this.showNotification('デフォルト状態への復元に失敗しました', 'error');
            }
        }

        /**
         * 通知を表示
         */
        showNotification(message, type = 'info') {
            // UniversalEditorの通知機能を使用
            if (window.universalEditor && window.universalEditor.showNotification) {
                window.universalEditor.showNotification(message, type);
            } else {
                // フォールバック: シンプルな通知を表示
                const notification = document.createElement('div');
                notification.style.cssText = `
                    position: fixed;
                    top: 20px;
                    right: 20px;
                    padding: 12px 24px;
                    background: ${type === 'success' ? '#4CAF50' : type === 'error' ? '#f44336' : '#2196F3'};
                    color: white;
                    border-radius: 4px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                    z-index: 100050;
                    animation: slideIn 0.3s ease-out;
                `;
                notification.textContent = message;
                document.body.appendChild(notification);

                setTimeout(() => {
                    notification.style.animation = 'slideOut 0.3s ease-out';
                    setTimeout(() => notification.remove(), 300);
                }, 3000);
            }
        }
    
        /**
         * サーバーに設定を保存
         */
        async saveToServer(data, saveType = 'manual') {
            try {
                const projectPath = this.getCurrentProjectPath();
                
                // 現在の設定を取得
                const currentSettings = await this.loadFromServer() || {};
                
                // 要素編集データを更新
                const updatedSettings = {
                    ...currentSettings,
                    elementEdits: data,
                    lastSaved: new Date().toISOString(),
                    saveType: saveType
                };
                
                console.log('サーバーに保存する設定:', updatedSettings);
                
                // Cloudflare経由でもローカルでも同じように動作するようにフルパスを使用
                const apiUrl = window.location.origin + '/api/save-settings';
                console.log('保存APIのURL:', apiUrl);
                
                const response = await fetch(apiUrl, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        path: projectPath,
                        data: updatedSettings
                    })
                });
                
                if (!response.ok) {
                    throw new Error(`保存リクエストが失敗しました: ${response.status}`);
                }
                
                const result = await response.json();
                console.log('サーバー保存完了:', result);
                return result;
                
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
                
                // Cloudflare経由でもローカルでも同じように動作するようにフルパスを使用
                // キャッシュ回避のためタイムスタンプを追加
                const timestamp = new Date().getTime();
                const apiUrl = window.location.origin + `/api/load-settings?path=${encodeURIComponent(projectPath)}&t=${timestamp}`;
                
                const response = await fetch(apiUrl, {
                    method: 'GET'
                });
                
                if (!response.ok) {
                    if (response.status === 404) {
                        console.log('設定ファイルがまだ存在しません（初回）');
                        return null;
                    }
                    throw new Error(`設定読み込みが失敗しました: ${response.status}`);
                }
                
                const result = await response.json();
                console.log('サーバーから設定を読み込み:', result);
                
                // 絶対URLを相対URLに変換（携帯からのアクセスに対応）
                if (result.data && result.data.elementEdits) {
                    Object.values(result.data.elementEdits).forEach(edit => {
                        if (edit.editedStyles && edit.editedStyles.backgroundImage) {
                            edit.editedStyles.backgroundImage = edit.editedStyles.backgroundImage
                                .replace(/https?:\/\/localhost:3500/g, '');
                        }
                        if (edit.editedStyles && edit.editedStyles.src) {
                            edit.editedStyles.src = edit.editedStyles.src
                                .replace(/https?:\/\/localhost:3500/g, '');
                        }
                    });
                }
                
                return result.data;
                
            } catch (error) {
                console.error('サーバー読み込みエラー:', error);
                return null;
            }
        }
        
        /**
         * localStorageからサーバーへのデータ移行
         */
        async migrateFromLocalStorage() {
            try {
                console.log('localStorageからのデータ移行を開始...');
                
                // localStorageから既存データを取得
                const elementEdits = localStorage.getItem('element_edits');
                if (elementEdits) {
                    const editsData = JSON.parse(elementEdits);
                    
                    // サーバーに移行
                    await this.saveToServer(editsData, 'migration');
                    
                    // 移行後はlocalStorageから削除（オプション）
                    // localStorage.removeItem('element_edits');
                    
                    console.log('localStorage データの移行が完了しました');
                }
                
            } catch (error) {
                console.error('データ移行エラー:', error);
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
    window.ElementEditManager = ElementEditManager;

    // 自動初期化
    document.addEventListener('DOMContentLoaded', () => {
        window.elementEditManager = new ElementEditManager();
    });

    // アニメーションスタイル
    if (!document.querySelector('#element-edit-animations')) {
        const style = document.createElement('style');
        style.id = 'element-edit-animations';
        style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(100px); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            @keyframes slideOut {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(100px); opacity: 0; }
            }
        `;
        document.head.appendChild(style);
    }

})();

// 読み込み完了を通知
console.log('ElementEditManager.js loaded');