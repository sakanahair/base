(function() {
    'use strict';

    class ImageUploader {
        constructor() {
            this.originalImages = new Map(); // オリジナル画像を保存
            this.compressedImages = new Map(); // 圧縮画像を保存
            this.STORAGE_KEY = 'uploaded_images';
            this.ORIGINAL_KEY = 'original_images';
            this.QUALITY_SETTINGS_KEY = 'image_quality_settings';
            this.useLocalStorage = false; // localStorageを無効化
            
            // デフォルト画質設定
            this.qualitySettings = {
                jpeg: 0.9,  // JPEG画質 (0.1-1.0)
                png: 1.0,   // PNG画質 (現在は未使用)
                useWebP: false, // WebP形式を使用するか
                webp: 0.9   // WebP画質
            };
            
            this.init();
        }

        init() {
            console.log('ImageUploader初期化開始');
            // 画質設定を読み込み
            this.loadQualitySettings();
            // localStorageからの読み込みを無効化
            if (this.useLocalStorage) {
                this.loadSavedImages();
            }
        }

        /**
         * 画質設定を読み込み
         */
        loadQualitySettings() {
            try {
                const saved = localStorage.getItem(this.QUALITY_SETTINGS_KEY);
                if (saved) {
                    this.qualitySettings = { ...this.qualitySettings, ...JSON.parse(saved) };
                    console.log('画質設定を読み込みました:', this.qualitySettings);
                }
            } catch (error) {
                console.error('画質設定の読み込みエラー:', error);
            }
        }

        /**
         * 画質設定を保存
         */
        saveQualitySettings() {
            try {
                localStorage.setItem(this.QUALITY_SETTINGS_KEY, JSON.stringify(this.qualitySettings));
                console.log('画質設定を保存しました:', this.qualitySettings);
            } catch (error) {
                console.error('画質設定の保存エラー:', error);
            }
        }

        /**
         * 画像アップロードダイアログを表示
         */
        showUploadDialog(onSelect) {
            const modal = document.createElement('div');
            modal.className = 'image-upload-modal';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.7);
                z-index: 100060;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.3s ease;
            `;

            const content = document.createElement('div');
            const isMobile = window.innerWidth <= 768;
            content.style.cssText = `
                background: var(--card-bg, #ffffff);
                border-radius: ${isMobile ? '12px' : '16px'};
                padding: ${isMobile ? '16px' : '24px'};
                max-width: ${isMobile ? '350px' : '500px'};
                max-height: ${isMobile ? '85vh' : '80vh'};
                overflow-y: auto;
                overflow-x: hidden;
                box-shadow: var(--box-shadow-hover, 0 20px 60px rgba(0, 0, 0, 0.3));
                animation: slideIn 0.3s ease;
                width: 90%;
                font-family: var(--font-family);
                color: var(--text-color);
                -webkit-overflow-scrolling: touch;
                scrollbar-width: thin;
            `;

            // ヘッダー
            const header = document.createElement('div');
            header.style.cssText = 'display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;';
            
            const title = document.createElement('h3');
            title.textContent = '画像アップロード・管理';
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

            // 画質設定セクション
            const qualitySection = document.createElement('div');
            qualitySection.style.cssText = `
                background: #f5f5f5;
                padding: ${isMobile ? '10px' : '12px'};
                border-radius: 8px;
                margin-bottom: ${isMobile ? '12px' : '16px'};
                display: flex;
                flex-direction: column;
                gap: 8px;
            `;

            const qualityTitle = document.createElement('div');
            qualityTitle.textContent = '⚙️ 画質設定';
            qualityTitle.style.cssText = `
                font-size: ${isMobile ? '13px' : '14px'};
                font-weight: 600;
                color: #555;
                margin-bottom: 4px;
            `;
            qualitySection.appendChild(qualityTitle);

            // JPEG画質スライダー
            const jpegQualityContainer = document.createElement('div');
            jpegQualityContainer.style.cssText = 'display: flex; align-items: center; gap: 8px;';
            
            const jpegLabel = document.createElement('label');
            jpegLabel.textContent = 'JPEG画質:';
            jpegLabel.style.cssText = `font-size: ${isMobile ? '11px' : '12px'}; color: #666; min-width: 70px;`;
            
            const jpegSlider = document.createElement('input');
            jpegSlider.type = 'range';
            jpegSlider.min = '0.1';
            jpegSlider.max = '1.0';
            jpegSlider.step = '0.1';
            jpegSlider.value = this.qualitySettings.jpeg;
            jpegSlider.style.cssText = 'flex: 1;';
            
            const jpegValue = document.createElement('span');
            jpegValue.textContent = `${Math.round(this.qualitySettings.jpeg * 100)}%`;
            jpegValue.style.cssText = `font-size: ${isMobile ? '11px' : '12px'}; color: #444; min-width: 35px; text-align: right;`;
            
            jpegSlider.oninput = () => {
                this.qualitySettings.jpeg = parseFloat(jpegSlider.value);
                jpegValue.textContent = `${Math.round(this.qualitySettings.jpeg * 100)}%`;
                this.saveQualitySettings();
            };
            
            jpegQualityContainer.appendChild(jpegLabel);
            jpegQualityContainer.appendChild(jpegSlider);
            jpegQualityContainer.appendChild(jpegValue);
            qualitySection.appendChild(jpegQualityContainer);

            // WebP設定
            const webpContainer = document.createElement('div');
            webpContainer.style.cssText = 'display: flex; align-items: center; gap: 8px;';
            
            const webpCheckbox = document.createElement('input');
            webpCheckbox.type = 'checkbox';
            webpCheckbox.checked = this.qualitySettings.useWebP;
            webpCheckbox.style.cssText = 'width: 16px; height: 16px;';
            
            const webpLabel = document.createElement('label');
            webpLabel.textContent = 'WebP形式を使用（より高圧縮）';
            webpLabel.style.cssText = `font-size: ${isMobile ? '11px' : '12px'}; color: #666; cursor: pointer;`;
            
            webpCheckbox.onchange = () => {
                this.qualitySettings.useWebP = webpCheckbox.checked;
                this.saveQualitySettings();
            };
            
            webpLabel.onclick = () => {
                webpCheckbox.checked = !webpCheckbox.checked;
                webpCheckbox.onchange();
            };
            
            webpContainer.appendChild(webpCheckbox);
            webpContainer.appendChild(webpLabel);
            qualitySection.appendChild(webpContainer);

            content.appendChild(qualitySection);

            // 保存場所情報
            const storageInfo = document.createElement('div');
            storageInfo.style.cssText = `
                background: #f5f5f5;
                border-radius: 8px;
                padding: 12px;
                margin-bottom: 16px;
                font-size: ${isMobile ? '12px' : '13px'};
                color: #666;
                border: 1px solid #e0e0e0;
            `;
            storageInfo.innerHTML = `
                <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                    <span style="font-weight: 600; color: #333;">💾 保存場所:</span>
                    <span>ブラウザメモリ内（一時保存）</span>
                </div>
                <div style="font-size: ${isMobile ? '11px' : '12px'}; color: #888; margin-top: 4px;">
                    ※ ページをリロードすると画像は削除されます
                </div>
            `;
            content.appendChild(storageInfo);

            // アップロードエリア
            const uploadArea = this.createUploadArea(content);
            content.appendChild(uploadArea);

            // 既存画像ギャラリー
            const gallery = this.createImageGallery(onSelect, modal);
            content.appendChild(gallery);
            
            // モーダルにonSelectを保存（後で参照するため）
            modal.onSelectCallback = onSelect;

            modal.appendChild(content);
            document.body.appendChild(modal);

            // 外側クリックで閉じる
            modal.onclick = (e) => {
                if (e.target === modal) {
                    modal.remove();
                }
            };
        }

        /**
         * アップロードエリアを作成
         */
        createUploadArea(container) {
            const uploadSection = document.createElement('div');
            uploadSection.style.cssText = 'margin-bottom: 30px;';

            const uploadTitle = document.createElement('h4');
            uploadTitle.textContent = '新しい画像をアップロード';
            uploadTitle.style.cssText = 'margin: 0 0 15px 0; color: var(--heading-color, #333); font-size: 16px; font-family: var(--font-family);';
            uploadSection.appendChild(uploadTitle);

            // ドラッグ&ドロップエリア
            const dropArea = document.createElement('div');
            dropArea.style.cssText = `
                border: 2px dashed var(--border-color, #ddd);
                border-radius: 12px;
                padding: 40px 20px;
                text-align: center;
                background: var(--cta-bg, #fafafa);
                transition: all 0.3s ease;
                cursor: pointer;
                margin-bottom: 15px;
                font-family: var(--font-family);
            `;

            const dropText = document.createElement('div');
            dropText.innerHTML = `
                <div style="font-size: 48px; color: var(--border-color, #ccc); margin-bottom: 10px;">📁</div>
                <div style="font-size: 16px; color: var(--text-color, #666); margin-bottom: 8px; font-family: var(--font-family);">画像をドラッグ&ドロップ</div>
                <div style="font-size: 14px; color: var(--text-color, #999); font-family: var(--font-family);">または</div>
            `;
            dropArea.appendChild(dropText);

            // ファイル選択ボタン
            const fileInput = document.createElement('input');
            fileInput.type = 'file';
            fileInput.accept = 'image/*';
            fileInput.style.display = 'none';

            const selectBtn = document.createElement('button');
            selectBtn.textContent = 'ファイルを選択';
            selectBtn.style.cssText = `
                padding: 12px 24px;
                background: var(--accent-color, #2196F3);
                color: white;
                border: none;
                border-radius: 8px;
                font-size: 14px;
                font-family: var(--font-family);
                cursor: pointer;
                margin-top: 10px;
                transition: background 0.2s ease;
            `;
            selectBtn.onmouseover = () => selectBtn.style.background = 'var(--accent-hover, #1976D2)';
            selectBtn.onmouseout = () => selectBtn.style.background = 'var(--accent-color, #2196F3)';

            selectBtn.onclick = () => fileInput.click();
            dropArea.appendChild(selectBtn);
            uploadSection.appendChild(dropArea);
            uploadSection.appendChild(fileInput);

            // ドラッグ&ドロップイベント
            dropArea.ondragover = (e) => {
                e.preventDefault();
                dropArea.style.borderColor = 'var(--accent-color, #2196F3)';
                dropArea.style.background = 'var(--hero-bg, #f0f8ff)';
            };

            dropArea.ondragleave = () => {
                dropArea.style.borderColor = 'var(--border-color, #ddd)';
                dropArea.style.background = 'var(--cta-bg, #fafafa)';
            };

            dropArea.ondrop = (e) => {
                e.preventDefault();
                dropArea.style.borderColor = 'var(--border-color, #ddd)';
                dropArea.style.background = 'var(--cta-bg, #fafafa)';
                
                const files = e.dataTransfer.files;
                if (files.length > 0) {
                    this.handleFileUpload(files[0], container);
                }
            };

            fileInput.onchange = (e) => {
                if (e.target.files.length > 0) {
                    this.handleFileUpload(e.target.files[0], container);
                }
            };

            return uploadSection;
        }

        /**
         * ファイルアップロード処理
         */
        async handleFileUpload(file, container) {
            if (!file.type.startsWith('image/')) {
                alert('画像ファイルを選択してください。');
                return;
            }

            // プレビューを表示
            await this.showUploadPreview(file, container);
        }
        
        /**
         * アップロードプレビューを表示
         */
        async showUploadPreview(file, container) {
            const previewModal = document.createElement('div');
            previewModal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.9);
                z-index: 100070;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.3s ease;
            `;
            
            const previewContent = document.createElement('div');
            previewContent.style.cssText = `
                background: white;
                border-radius: 16px;
                padding: 24px;
                max-width: 600px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            `;
            
            // タイトル
            const title = document.createElement('h3');
            title.textContent = '画像アップロード設定';
            title.style.cssText = 'margin: 0 0 20px 0; color: #333; font-size: 20px;';
            previewContent.appendChild(title);
            
            // プレビュー画像
            const previewImg = document.createElement('img');
            const reader = new FileReader();
            reader.onload = (e) => {
                previewImg.src = e.target.result;
            };
            reader.readAsDataURL(file);
            
            previewImg.style.cssText = `
                width: 100%;
                max-height: 300px;
                object-fit: contain;
                border-radius: 8px;
                margin-bottom: 20px;
                background: #f5f5f5;
            `;
            previewContent.appendChild(previewImg);
            
            // ファイル情報
            const fileInfo = document.createElement('div');
            fileInfo.style.cssText = 'margin-bottom: 20px; padding: 12px; background: #f5f5f5; border-radius: 8px;';
            fileInfo.innerHTML = `
                <div style="font-size: 14px; color: #666;">
                    <strong>ファイル名:</strong> ${file.name}<br>
                    <strong>サイズ:</strong> ${(file.size / 1024 / 1024).toFixed(2)} MB<br>
                    <strong>形式:</strong> ${file.type}
                </div>
            `;
            previewContent.appendChild(fileInfo);
            
            // 設定オプション
            const optionsDiv = document.createElement('div');
            optionsDiv.style.cssText = 'margin-bottom: 20px;';
            
            // 配置設定
            const positionTitle = document.createElement('h4');
            positionTitle.textContent = '背景配置';
            positionTitle.style.cssText = 'margin: 0 0 10px 0; font-size: 16px; color: #333;';
            optionsDiv.appendChild(positionTitle);
            
            const positions = [
                { value: 'center', label: '中央' },
                { value: 'top', label: '上' },
                { value: 'bottom', label: '下' },
                { value: 'left', label: '左' },
                { value: 'right', label: '右' }
            ];
            
            const positionBtns = document.createElement('div');
            positionBtns.style.cssText = 'display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px;';
            
            let selectedPosition = 'center';
            positions.forEach(pos => {
                const btn = document.createElement('button');
                btn.textContent = pos.label;
                btn.style.cssText = `
                    padding: 8px 16px;
                    border: 2px solid #ddd;
                    background: ${pos.value === selectedPosition ? '#2196F3' : 'white'};
                    color: ${pos.value === selectedPosition ? 'white' : '#333'};
                    border-radius: 6px;
                    cursor: pointer;
                    transition: all 0.2s;
                `;
                
                btn.onclick = () => {
                    selectedPosition = pos.value;
                    positionBtns.querySelectorAll('button').forEach(b => {
                        b.style.background = 'white';
                        b.style.color = '#333';
                    });
                    btn.style.background = '#2196F3';
                    btn.style.color = 'white';
                    updatePreview();
                };
                
                positionBtns.appendChild(btn);
            });
            optionsDiv.appendChild(positionBtns);
            
            // サイズ設定
            const sizeTitle = document.createElement('h4');
            sizeTitle.textContent = '背景サイズ';
            sizeTitle.style.cssText = 'margin: 16px 0 10px 0; font-size: 16px; color: #333;';
            optionsDiv.appendChild(sizeTitle);
            
            const sizes = [
                { value: 'cover', label: '画面全体' },
                { value: 'contain', label: '全体表示' },
                { value: 'auto', label: '元サイズ' }
            ];
            
            const sizeBtns = document.createElement('div');
            sizeBtns.style.cssText = 'display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px;';
            
            let selectedSize = 'cover';
            sizes.forEach(size => {
                const btn = document.createElement('button');
                btn.textContent = size.label;
                btn.style.cssText = `
                    padding: 8px 16px;
                    border: 2px solid #ddd;
                    background: ${size.value === selectedSize ? '#64748b' : 'white'};
                    color: ${size.value === selectedSize ? 'white' : '#333'};
                    border-radius: 6px;
                    cursor: pointer;
                    transition: all 0.2s;
                `;
                
                btn.onclick = () => {
                    selectedSize = size.value;
                    sizeBtns.querySelectorAll('button').forEach(b => {
                        b.style.background = 'white';
                        b.style.color = '#333';
                    });
                    btn.style.background = '#64748b';
                    btn.style.color = 'white';
                    updatePreview();
                };
                
                sizeBtns.appendChild(btn);
            });
            optionsDiv.appendChild(sizeBtns);
            
            // オーバーレイ設定
            const overlayTitle = document.createElement('h4');
            overlayTitle.textContent = 'オーバーレイ';
            overlayTitle.style.cssText = 'margin: 16px 0 10px 0; font-size: 16px; color: #333;';
            optionsDiv.appendChild(overlayTitle);
            
            const overlayDiv = document.createElement('div');
            overlayDiv.style.cssText = 'display: flex; gap: 12px; align-items: center;';
            
            const overlayColor = document.createElement('input');
            overlayColor.type = 'color';
            overlayColor.value = '#000000';
            overlayColor.style.cssText = 'width: 50px; height: 36px; border: 1px solid #ddd; border-radius: 4px; cursor: pointer;';
            
            const overlayOpacity = document.createElement('input');
            overlayOpacity.type = 'range';
            overlayOpacity.min = '0';
            overlayOpacity.max = '100';
            overlayOpacity.value = '0';
            overlayOpacity.style.cssText = 'flex: 1;';
            
            const opacityLabel = document.createElement('span');
            opacityLabel.textContent = '0%';
            opacityLabel.style.cssText = 'width: 40px; text-align: right; font-size: 14px;';
            
            overlayOpacity.oninput = () => {
                opacityLabel.textContent = overlayOpacity.value + '%';
                updatePreview();
            };
            
            overlayColor.oninput = updatePreview;
            
            overlayDiv.appendChild(overlayColor);
            overlayDiv.appendChild(overlayOpacity);
            overlayDiv.appendChild(opacityLabel);
            optionsDiv.appendChild(overlayDiv);
            
            previewContent.appendChild(optionsDiv);
            
            // プレビュー更新関数
            function updatePreview() {
                const overlay = overlayOpacity.value > 0 ? 
                    `, linear-gradient(${overlayColor.value}${Math.round(overlayOpacity.value * 2.55).toString(16).padStart(2, '0')}, ${overlayColor.value}${Math.round(overlayOpacity.value * 2.55).toString(16).padStart(2, '0')})` : '';
                
                previewImg.style.objectPosition = selectedPosition;
                previewImg.style.objectFit = selectedSize;
            }
            
            // ボタン
            const buttonDiv = document.createElement('div');
            buttonDiv.style.cssText = 'display: flex; gap: 12px; justify-content: flex-end; margin-top: 24px;';
            
            const cancelBtn = document.createElement('button');
            cancelBtn.textContent = 'キャンセル';
            cancelBtn.style.cssText = `
                padding: 10px 20px;
                background: #f5f5f5;
                border: 1px solid #ddd;
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            `;
            cancelBtn.onclick = () => previewModal.remove();
            
            const uploadBtn = document.createElement('button');
            uploadBtn.textContent = 'この設定でアップロード';
            uploadBtn.style.cssText = `
                padding: 10px 20px;
                background: #2196F3;
                color: white;
                border: none;
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            `;
            
            uploadBtn.onclick = async () => {
                previewModal.remove();
                
                // 元のアップロード処理を実行
                const FILE_SIZE_LIMIT = 10 * 1024 * 1024; // 10MB
                if (file.size > FILE_SIZE_LIMIT) {
                    console.log('大きなファイル検出:', (file.size / 1024 / 1024).toFixed(2), 'MB - サーバーアップロードを使用');
                    await this.uploadToServer(file, container);
                } else {
                    await this.processLocalUpload(file, container, {
                        position: selectedPosition,
                        size: selectedSize,
                        overlayColor: overlayColor.value,
                        overlayOpacity: overlayOpacity.value
                    });
                }
            };
            
            buttonDiv.appendChild(cancelBtn);
            buttonDiv.appendChild(uploadBtn);
            previewContent.appendChild(buttonDiv);
            
            previewModal.appendChild(previewContent);
            document.body.appendChild(previewModal);
        }
        
        /**
         * ローカルアップロード処理
         */
        async processLocalUpload(file, container, settings) {
            try {
                // プログレス表示
                const progressDiv = this.showProgress(container);

                // オリジナル画像を読み込み
                const originalDataUrl = await this.fileToDataUrl(file);
                const imageId = 'img_' + Date.now();

                // ファイル形式を判定
                const fileType = file.type;
                const isTransparent = fileType === 'image/png' || fileType === 'image/gif' || fileType === 'image/webp';

                console.log('アップロードファイル情報:', {
                    fileName: file.name,
                    fileType: fileType,
                    isTransparent: isTransparent
                });

                // オリジナルを保存（設定付き）
                this.originalImages.set(imageId, {
                    dataUrl: originalDataUrl,
                    fileName: file.name,
                    fileSize: file.size,
                    fileType: fileType,
                    isTransparent: isTransparent,
                    uploadDate: new Date().toISOString(),
                    settings: settings
                });

                // 複数サイズで圧縮
                const compressionSizes = [40, 64, 100, 150, 200];
                const compressedVersions = {};

                for (const size of compressionSizes) {
                    progressDiv.textContent = `圧縮中... ${size}px`;
                    const compressed = await this.compressImage(originalDataUrl, size);
                    compressedVersions[size] = compressed;
                }

                // 圧縮画像を保存
                this.compressedImages.set(imageId, compressedVersions);

                // ローカルストレージに保存（無効化）
                if (this.useLocalStorage) {
                    this.saveImages();
                }

                // プログレス削除
                progressDiv.remove();

                // ギャラリーを更新
                const modal = container.closest('.image-upload-modal');
                if (modal) {
                    this.refreshGallery(modal);
                } else {
                    this.refreshGallery(container);
                }

                console.log(`画像アップロード完了: ${imageId}`);
                
                // コールバックがある場合は実行
                const uploadModal = container.closest('.image-upload-modal');
                if (uploadModal && uploadModal.onSelectCallback) {
                    // 設定を適用した背景スタイルを生成
                    const bgStyle = this.generateBackgroundStyle(originalDataUrl, settings);
                    uploadModal.onSelectCallback(bgStyle, 'custom', imageId);
                    uploadModal.remove();
                }

            } catch (error) {
                console.error('画像アップロードエラー:', error);
                alert('画像アップロードに失敗しました。');
            }
        }
        
        /**
         * 背景スタイルを生成
         */
        generateBackgroundStyle(imageUrl, settings) {
            let style = `url('${imageUrl}')`;
            
            // オーバーレイを追加
            if (settings && settings.overlayOpacity > 0) {
                const opacity = Math.round(settings.overlayOpacity * 2.55).toString(16).padStart(2, '0');
                style = `linear-gradient(${settings.overlayColor}${opacity}, ${settings.overlayColor}${opacity}), ${style}`;
            }
            
            // 位置とサイズの情報を保存（後でCSSで使用）
            if (settings) {
                style += ` /* position: ${settings.position}; size: ${settings.size}; */`;
            }
            
            return style;
        }

        /**
         * 画像圧縮
         */
        compressImage(dataUrl, maxSize) {
            return new Promise((resolve) => {
                const img = new Image();
                img.onload = () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');

                    // アスペクト比を保持してリサイズ
                    let { width, height } = img;
                    if (width > height) {
                        if (width > maxSize) {
                            height = (height * maxSize) / width;
                            width = maxSize;
                        }
                    } else {
                        if (height > maxSize) {
                            width = (width * maxSize) / height;
                            height = maxSize;
                        }
                    }

                    canvas.width = width;
                    canvas.height = height;

                    // 透明度を保持するため背景をクリア
                    ctx.clearRect(0, 0, width, height);

                    // 高品質リサイズ
                    ctx.imageSmoothingEnabled = true;
                    ctx.imageSmoothingQuality = 'high';
                    ctx.drawImage(img, 0, 0, width, height);

                    // 透過を保持するためPNG出力（元画像がPNG/透過の場合）
                    let outputFormat = 'image/png';
                    let quality = undefined; // PNGは品質指定なし
                    
                    // WebP形式が有効な場合
                    if (this.qualitySettings.useWebP) {
                        outputFormat = 'image/webp';
                        quality = this.qualitySettings.webp;
                    }
                    // 元画像がJPEGの場合のみJPEGで圧縮（透過画像は常にPNG）
                    else if (dataUrl.startsWith('data:image/jpeg')) {
                        outputFormat = 'image/jpeg';
                        quality = this.qualitySettings.jpeg;
                    } else if (!this.hasTransparency(canvas, ctx)) {
                        // 透過なしの場合はJPEGで圧縮してファイルサイズを削減
                        outputFormat = 'image/jpeg';
                        quality = this.qualitySettings.jpeg;
                    }

                    console.log('画像圧縮設定:', {
                        maxSize: maxSize,
                        outputFormat: outputFormat,
                        originalFormat: dataUrl.substring(0, 30) + '...',
                        hasTransparency: this.hasTransparency(canvas, ctx)
                    });

                    const compressedDataUrl = canvas.toDataURL(outputFormat, quality);
                    resolve(compressedDataUrl);
                };
                img.src = dataUrl;
            });
        }

        /**
         * 透明度があるかどうかを判定
         */
        hasTransparency(canvas, ctx) {
            try {
                const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                const data = imageData.data;
                
                // アルファチャンネルをチェック（4番目の値）
                for (let i = 3; i < data.length; i += 4) {
                    if (data[i] < 255) {
                        return true; // 透明または半透明のピクセルが見つかった
                    }
                }
                return false; // 完全不透明
            } catch (error) {
                console.warn('透明度判定エラー:', error);
                return true; // エラーの場合は安全側でPNGを選択
            }
        }

        /**
         * 画像ギャラリーを作成
         */
        createImageGallery(onSelect, modal) {
            const gallerySection = document.createElement('div');
            gallerySection.className = 'image-gallery-section';
            gallerySection.style.cssText = 'margin-top: 30px;';

            const galleryTitle = document.createElement('h4');
            galleryTitle.textContent = 'アップロード済み画像';
            galleryTitle.style.cssText = 'margin: 0 0 15px 0; color: var(--heading-color, #333); font-size: 16px; font-family: var(--font-family);';
            gallerySection.appendChild(galleryTitle);

            const gallery = document.createElement('div');
            const isMobile = window.innerWidth <= 768;
            gallery.className = 'image-gallery';
            gallery.style.cssText = `
                display: grid;
                grid-template-columns: repeat(auto-fill, minmax(${isMobile ? '80px' : '100px'}, 1fr));
                gap: ${isMobile ? '10px' : '15px'};
                max-height: ${isMobile ? '300px' : '350px'};
                overflow-y: auto;
                overflow-x: hidden;
                border: 1px solid #eee;
                border-radius: 8px;
                padding: ${isMobile ? '10px' : '15px'};
                -webkit-overflow-scrolling: touch;
                scrollbar-width: thin;
            `;

            // onSelectコールバックを保存
            gallery.onSelectCallback = onSelect;
            
            // 画像を表示
            this.populateGallery(gallery, onSelect, modal);

            gallerySection.appendChild(gallery);
            return gallerySection;
        }

        /**
         * ギャラリーに画像を追加
         */
        populateGallery(gallery, onSelect, modal) {
            gallery.innerHTML = '';

            this.compressedImages.forEach((compressedVersions, imageId) => {
                const imageItem = document.createElement('div');
                const isMobile = window.innerWidth <= 768;
                imageItem.style.cssText = `
                    border: 2px solid #eee;
                    border-radius: ${isMobile ? '6px' : '8px'};
                    padding: ${isMobile ? '6px' : '8px'};
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.2s ease;
                    background: white;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                `;

                // サムネイル表示（100pxサイズ）
                const thumbnail = document.createElement('img');
                thumbnail.src = compressedVersions[100] || compressedVersions[64];
                thumbnail.style.cssText = `
                    width: 100px;
                    height: 100px;
                    object-fit: cover;
                    border-radius: 4px;
                    margin-bottom: 8px;
                    cursor: pointer;
                `;
                
                // サムネイルクリックで選択
                thumbnail.onclick = () => {
                    console.log('画像選択: オリジナルサイズ');
                    if (onSelect) {
                        const originalImage = this.originalImages.get(imageId);
                        if (originalImage && originalImage.dataUrl) {
                            onSelect(originalImage.dataUrl, 'original', imageId);
                            if (modal && modal.remove) {
                                modal.remove();
                            }
                        }
                    }
                };

                const originalInfo = this.originalImages.get(imageId);
                const fileName = document.createElement('div');
                const shortName = originalInfo?.fileName || 'unknown';
                fileName.textContent = shortName.length > 15 ? shortName.substring(0, 12) + '...' : shortName;
                fileName.title = originalInfo?.fileName || 'unknown';
                fileName.style.cssText = 'font-size: 11px; color: var(--text-color, #666); margin-bottom: 4px; word-break: break-all; font-family: var(--font-family); cursor: pointer;';
                
                // サーバーアップロードの場合はアイコンを表示
                if (originalInfo?.isServerUpload) {
                    const serverIcon = document.createElement('span');
                    serverIcon.textContent = ' ☁️';
                    serverIcon.title = 'サーバーに保存済み';
                    fileName.appendChild(serverIcon);
                }

                // 選択ボタン
                const selectBtn = document.createElement('button');
                selectBtn.textContent = 'この画像を使う';
                selectBtn.style.cssText = `
                    padding: 6px 12px;
                    background: var(--accent-color, #2196F3);
                    color: white;
                    border: none;
                    border-radius: 4px;
                    font-size: 12px;
                    cursor: pointer;
                    margin-bottom: 4px;
                    width: 100%;
                `;
                
                selectBtn.onclick = (e) => {
                    e.stopPropagation();
                    console.log('画像選択ボタンクリック');
                    console.log('onSelect関数:', onSelect);
                    console.log('modal:', modal);
                    
                    if (onSelect && typeof onSelect === 'function') {
                        const selectedImage = compressedVersions[150] || compressedVersions[100] || compressedVersions[64];
                        console.log('選択された画像:', selectedImage ? '画像あり' : '画像なし');
                        
                        if (selectedImage) {
                            console.log('onSelect関数を呼び出します');
                            onSelect(selectedImage, '150', imageId);
                            if (modal && modal.remove) {
                                console.log('モーダルを閉じます');
                                modal.remove();
                            }
                        } else {
                            console.error('選択可能な画像が見つかりません');
                        }
                    } else {
                        console.error('onSelect関数が定義されていません');
                    }
                };


                // 削除ボタン
                const deleteBtn = document.createElement('button');
                deleteBtn.textContent = '削除';
                deleteBtn.style.cssText = `
                    padding: 6px 12px;
                    background: var(--primary-color, #f44336);
                    color: white;
                    border: none;
                    border-radius: 4px;
                    font-size: 11px;
                    cursor: pointer;
                `;
                
                deleteBtn.onclick = (e) => {
                    e.stopPropagation();
                    if (confirm('この画像を削除しますか？')) {
                        this.deleteImage(imageId);
                        this.refreshGallery(gallery.closest('.image-upload-modal'));
                    }
                };

                imageItem.appendChild(thumbnail);
                imageItem.appendChild(fileName);
                imageItem.appendChild(selectBtn);
                imageItem.appendChild(deleteBtn);

                // ホバーエフェクト
                imageItem.onmouseover = () => {
                    imageItem.style.borderColor = '#2196F3';
                    imageItem.style.transform = 'scale(1.05)';
                };
                imageItem.onmouseout = () => {
                    imageItem.style.borderColor = '#eee';
                    imageItem.style.transform = 'scale(1)';
                };

                gallery.appendChild(imageItem);
            });

            if (this.compressedImages.size === 0) {
                const emptyMsg = document.createElement('div');
                emptyMsg.textContent = 'アップロードされた画像がありません';
                emptyMsg.style.cssText = 'text-align: center; color: var(--text-color, #999); padding: 40px; font-family: var(--font-family);';
                gallery.appendChild(emptyMsg);
            }
        }

        /**
         * オリジナル画像プレビュー
         */
        showOriginalPreview(imageId) {
            const original = this.originalImages.get(imageId);
            if (!original) return;

            const previewModal = document.createElement('div');
            previewModal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.9);
                z-index: 100070;
                display: flex;
                align-items: center;
                justify-content: center;
                animation: fadeIn 0.3s ease;
            `;

            const previewContent = document.createElement('div');
            previewContent.style.cssText = `
                max-width: 90%;
                max-height: 90%;
                text-align: center;
            `;

            const previewImg = document.createElement('img');
            previewImg.src = original.dataUrl;
            previewImg.style.cssText = `
                max-width: 100%;
                max-height: 80vh;
                border-radius: 8px;
                box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            `;

            const info = document.createElement('div');
            info.style.cssText = 'color: white; margin-top: 15px; font-size: 14px;';
            info.innerHTML = `
                <div style="margin-bottom: 5px;"><strong>ファイル名:</strong> ${original.fileName}</div>
                <div style="margin-bottom: 5px;"><strong>サイズ:</strong> ${(original.fileSize / 1024).toFixed(1)} KB</div>
                <div style="margin-bottom: 5px;"><strong>形式:</strong> ${original.fileType || 'unknown'}</div>
                <div style="margin-bottom: 5px;"><strong>透過:</strong> ${original.isTransparent ? 'あり' : 'なし'}</div>
                <div><strong>アップロード日:</strong> ${new Date(original.uploadDate).toLocaleString('ja-JP')}</div>
            `;

            const closeBtn = document.createElement('button');
            closeBtn.textContent = '閉じる';
            closeBtn.style.cssText = `
                margin-top: 15px;
                padding: 10px 20px;
                background: rgba(255, 255, 255, 0.2);
                color: white;
                border: 1px solid rgba(255, 255, 255, 0.3);
                border-radius: 6px;
                cursor: pointer;
                font-size: 14px;
            `;
            closeBtn.onclick = () => previewModal.remove();

            previewContent.appendChild(previewImg);
            previewContent.appendChild(info);
            previewContent.appendChild(closeBtn);
            previewModal.appendChild(previewContent);

            previewModal.onclick = (e) => {
                if (e.target === previewModal) {
                    previewModal.remove();
                }
            };

            document.body.appendChild(previewModal);
        }

        /**
         * プログレス表示
         */
        showProgress(container) {
            const progressDiv = document.createElement('div');
            progressDiv.style.cssText = `
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: rgba(0, 0, 0, 0.8);
                color: white;
                padding: 20px;
                border-radius: 8px;
                z-index: 100061;
                font-size: 16px;
                text-align: center;
            `;
            progressDiv.textContent = 'アップロード中...';
            document.body.appendChild(progressDiv);
            return progressDiv;
        }

        /**
         * ギャラリー更新
         */
        refreshGallery(container) {
            const gallery = container.querySelector('.image-gallery');
            if (gallery) {
                const onSelect = gallery.onSelectCallback;
                const modal = container;
                console.log('ギャラリー更新 - onSelect:', onSelect);
                this.populateGallery(gallery, onSelect, modal);
            }
        }

        /**
         * 画像削除
         */
        deleteImage(imageId) {
            this.originalImages.delete(imageId);
            this.compressedImages.delete(imageId);
            // localStorage保存を無効化
            if (this.useLocalStorage) {
                this.saveImages();
            }
        }

        /**
         * ファイルをDataURLに変換
         */
        fileToDataUrl(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = (e) => resolve(e.target.result);
                reader.onerror = (e) => reject(e);
                reader.readAsDataURL(file);
            });
        }

        /**
         * 画像を保存（localStorageは使用しない）
         */
        saveImages() {
            // localStorageへの保存を無効化
            if (!this.useLocalStorage) {
                console.log('画像はlocalStorageに保存されません（メモリ上のみ）');
                return;
            }
            
            try {
                const originalData = {};
                this.originalImages.forEach((value, key) => {
                    originalData[key] = value;
                });

                const compressedData = {};
                this.compressedImages.forEach((value, key) => {
                    compressedData[key] = value;
                });

                localStorage.setItem(this.ORIGINAL_KEY, JSON.stringify(originalData));
                localStorage.setItem(this.STORAGE_KEY, JSON.stringify(compressedData));
            } catch (error) {
                console.error('画像保存エラー:', error);
                // エラーが発生しても処理を続行
                if (error.name === 'QuotaExceededError') {
                    alert('ストレージ容量が不足しています。画像はメモリ上でのみ利用可能です。');
                }
            }
        }

        /**
         * サーバーへのアップロード
         */
        async uploadToServer(file, container) {
            const progressModal = this.createProgressModal();
            document.body.appendChild(progressModal.modal);
            
            try {
                const formData = new FormData();
                formData.append('image', file);
                
                const xhr = new XMLHttpRequest();
                
                // プログレスイベント
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        const percentComplete = (e.loaded / e.total) * 100;
                        progressModal.updateProgress(percentComplete);
                    }
                });
                
                // 完了処理
                xhr.addEventListener('load', () => {
                    if (xhr.status === 200) {
                        const response = JSON.parse(xhr.responseText);
                        console.log('サーバーアップロード成功:', response);
                        
                        // アップロード成功後の処理
                        progressModal.setMessage('画像を処理中...');
                        
                        // サーバーから画像を取得してローカルで圧縮
                        this.processServerImage(response, file, container, progressModal);
                    } else {
                        throw new Error('アップロードに失敗しました');
                    }
                });
                
                // エラー処理
                xhr.addEventListener('error', () => {
                    throw new Error('ネットワークエラーが発生しました');
                });
                
                // リクエスト送信
                xhr.open('POST', 'upload/image');
                xhr.send(formData);
                
            } catch (error) {
                console.error('サーバーアップロードエラー:', error);
                alert('画像のアップロードに失敗しました: ' + error.message);
                progressModal.modal.remove();
            }
        }
        
        /**
         * サーバーからアップロードした画像を処理
         */
        async processServerImage(serverResponse, originalFile, container, progressModal) {
            try {
                progressModal.setMessage('サムネイル生成中...');
                
                // サーバーの画像URLを取得
                const imageUrl = serverResponse.url || serverResponse.path;
                const fullImageUrl = imageUrl.startsWith('http') ? imageUrl : window.location.origin + imageUrl;
                
                // 画像を読み込んでDataURLに変換
                const img = new Image();
                img.crossOrigin = 'anonymous';
                
                img.onload = async () => {
                    const canvas = document.createElement('canvas');
                    const ctx = canvas.getContext('2d');
                    canvas.width = img.width;
                    canvas.height = img.height;
                    ctx.drawImage(img, 0, 0);
                    
                    const originalDataUrl = canvas.toDataURL(originalFile.type || 'image/png');
                    const imageId = 'img_' + Date.now();
                    
                    // オリジナルを保存（サーバーパス付き）
                    this.originalImages.set(imageId, {
                        dataUrl: originalDataUrl,
                        serverPath: serverResponse.path,
                        serverUrl: fullImageUrl,
                        fileName: originalFile.name,
                        fileSize: originalFile.size,
                        fileType: originalFile.type,
                        isTransparent: originalFile.type === 'image/png' || originalFile.type === 'image/gif' || originalFile.type === 'image/webp',
                        uploadDate: new Date().toISOString(),
                        isServerUpload: true
                    });
                    
                    // 複数サイズで圧縮
                    const compressionSizes = [40, 64, 100, 150, 200];
                    const compressedVersions = {};
                    
                    for (let i = 0; i < compressionSizes.length; i++) {
                        const size = compressionSizes[i];
                        const progress = ((i + 1) / compressionSizes.length) * 100;
                        progressModal.setMessage(`サムネイル生成中... ${size}px`);
                        progressModal.updateProgress(progress);
                        
                        const compressed = await this.compressImage(originalDataUrl, size);
                        compressedVersions[size] = compressed;
                    }
                    
                    // 圧縮画像を保存
                    this.compressedImages.set(imageId, compressedVersions);
                    
                    // プログレスモーダルを削除
                    progressModal.modal.remove();
                    
                    // ギャラリーを更新
                    this.refreshGallery(container);
                    
                    console.log(`サーバー画像処理完了: ${imageId}`);
                    alert(`画像をサーバーにアップロードしました。\nサイズ: ${(originalFile.size / 1024 / 1024).toFixed(2)}MB`);
                };
                
                img.onerror = () => {
                    throw new Error('画像の読み込みに失敗しました');
                };
                
                img.src = fullImageUrl;
                
            } catch (error) {
                console.error('サーバー画像処理エラー:', error);
                alert('画像の処理に失敗しました: ' + error.message);
                progressModal.modal.remove();
            }
        }
        
        /**
         * プログレスモーダルを作成
         */
        createProgressModal() {
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
            `;
            
            const content = document.createElement('div');
            content.style.cssText = `
                background: white;
                border-radius: 16px;
                padding: 32px;
                max-width: 400px;
                width: 90%;
                text-align: center;
                box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            `;
            
            const title = document.createElement('h3');
            title.textContent = 'アップロード中';
            title.style.cssText = 'margin: 0 0 16px 0; font-size: 20px; color: #333;';
            content.appendChild(title);
            
            const message = document.createElement('div');
            message.textContent = 'ファイルをアップロードしています...';
            message.style.cssText = 'margin-bottom: 24px; color: #666; font-size: 14px;';
            content.appendChild(message);
            
            // プログレスバーコンテナ
            const progressContainer = document.createElement('div');
            progressContainer.style.cssText = `
                width: 100%;
                height: 8px;
                background: #f0f0f0;
                border-radius: 4px;
                overflow: hidden;
                margin-bottom: 16px;
            `;
            
            const progressBar = document.createElement('div');
            progressBar.style.cssText = `
                width: 0%;
                height: 100%;
                background: linear-gradient(90deg, #2196F3, #64748b);
                transition: width 0.3s ease;
            `;
            progressContainer.appendChild(progressBar);
            content.appendChild(progressContainer);
            
            const percentText = document.createElement('div');
            percentText.textContent = '0%';
            percentText.style.cssText = 'font-size: 24px; font-weight: bold; color: #2196F3;';
            content.appendChild(percentText);
            
            modal.appendChild(content);
            
            return {
                modal,
                updateProgress: (percent) => {
                    progressBar.style.width = percent + '%';
                    percentText.textContent = Math.round(percent) + '%';
                },
                setMessage: (text) => {
                    message.textContent = text;
                }
            };
        }

        /**
         * 保存された画像を読み込み
         */
        loadSavedImages() {
            // localStorageからの読み込みを無効化
            if (!this.useLocalStorage) {
                console.log('localStorageからの画像読み込みは無効化されています');
                return;
            }
            
            try {
                const originalData = localStorage.getItem(this.ORIGINAL_KEY);
                if (originalData) {
                    const parsed = JSON.parse(originalData);
                    Object.entries(parsed).forEach(([key, value]) => {
                        this.originalImages.set(key, value);
                    });
                }

                const compressedData = localStorage.getItem(this.STORAGE_KEY);
                if (compressedData) {
                    const parsed = JSON.parse(compressedData);
                    Object.entries(parsed).forEach(([key, value]) => {
                        this.compressedImages.set(key, value);
                    });
                }

                console.log(`保存された画像を読み込み: ${this.originalImages.size}個`);
            } catch (error) {
                console.error('画像読み込みエラー:', error);
            }
        }
    }

    // グローバルに公開
    window.ImageUploader = ImageUploader;

    // 自動初期化
    function initImageUploader() {
        if (!window.imageUploader) {
            console.log('ImageUploaderを初期化します');
            window.imageUploader = new ImageUploader();
            console.log('ImageUploader初期化完了:', window.imageUploader);
        }
    }
    
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initImageUploader);
    } else {
        // DOMがすでに読み込まれている場合は即座に初期化
        initImageUploader();
    }

    // アニメーションスタイル
    if (!document.querySelector('#image-uploader-animations')) {
        const style = document.createElement('style');
        style.id = 'image-uploader-animations';
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

})();

// 読み込み完了を通知
console.log('ImageUploader.js loaded');