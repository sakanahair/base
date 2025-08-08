(function() {
    'use strict';

    function initAccess() {
        const accessSection = document.querySelector('.access-section');
        const contactForm = document.querySelector('.form-wrapper');
        const mapButton = document.querySelector('.map-overlay .btn');

        if (!accessSection) return;

        // セクションヘッダーのアニメーション初期化
        initSectionHeaderAnimation();

        // 設定の適用
        if (window.accessConfig) {
            applyAccessConfig(window.accessConfig);
        }

        // フォーム送信処理
        if (contactForm) {
            contactForm.addEventListener('submit', handleFormSubmit);
        }

        // 地図表示ボタン
        if (mapButton) {
            mapButton.addEventListener('click', function() {
                // 実際の実装では、Google Maps APIを使用して地図を表示
                alert('Google Maps APIを設定してください');
            });
        }

        // フォームバリデーション
        setupFormValidation();
    }

    function applyAccessConfig(config) {
        if (!config) return;

        // スタジオ情報の更新
        if (config.studioInfo) {
            updateStudioInfo(config.studioInfo);
        }

        // アクセス方法の更新
        if (config.accessMethods) {
            updateAccessMethods(config.accessMethods);
        }

        // 地図設定
        if (config.map) {
            setupMap(config.map);
        }

        // フォーム設定
        if (config.form) {
            updateFormOptions(config.form);
        }
    }

    function updateStudioInfo(info) {
        const infoList = document.querySelector('.info-list');
        if (!infoList || !info) return;

        infoList.innerHTML = '';

        Object.entries(info).forEach(([key, value]) => {
            const dt = document.createElement('dt');
            dt.textContent = value.label;

            const dd = document.createElement('dd');
            
            if (value.type === 'tel') {
                const link = document.createElement('a');
                link.href = `tel:${value.value.replace(/-/g, '')}`;
                link.textContent = value.value;
                dd.appendChild(link);
            } else if (value.type === 'email') {
                const link = document.createElement('a');
                link.href = `mailto:${value.value}`;
                link.textContent = value.value;
                dd.appendChild(link);
            } else if (value.type === 'address') {
                dd.innerHTML = value.value.replace(/\n/g, '<br>');
            } else if (value.type === 'hours') {
                dd.innerHTML = value.value.replace(/\n/g, '<br>');
            } else {
                dd.textContent = value.value;
            }

            infoList.appendChild(dt);
            infoList.appendChild(dd);
        });
    }

    function updateAccessMethods(methods) {
        const methodsContainer = document.querySelector('.access-methods');
        if (!methodsContainer || !methods) return;

        methodsContainer.innerHTML = '';

        methods.forEach(method => {
            const item = document.createElement('div');
            item.className = 'method-item';

            const title = document.createElement('h4');
            title.textContent = method.title;
            item.appendChild(title);

            if (method.items && Array.isArray(method.items)) {
                const ul = document.createElement('ul');
                method.items.forEach(text => {
                    const li = document.createElement('li');
                    li.textContent = text;
                    ul.appendChild(li);
                });
                item.appendChild(ul);
            } else if (method.text) {
                const p = document.createElement('p');
                p.textContent = method.text;
                item.appendChild(p);
            }

            methodsContainer.appendChild(item);
        });
    }

    function setupMap(mapConfig) {
        if (!mapConfig || !mapConfig.apiKey) return;

        // Google Maps APIの実装
        // 実際の実装では、APIキーを使用して地図を初期化
    }

    function updateFormOptions(formConfig) {
        if (!formConfig || !formConfig.subjects) return;

        const subjectSelect = document.querySelector('#subject');
        if (!subjectSelect) return;

        subjectSelect.innerHTML = '<option value="">選択してください</option>';

        formConfig.subjects.forEach(subject => {
            const option = document.createElement('option');
            option.value = subject.value;
            option.textContent = subject.text;
            subjectSelect.appendChild(option);
        });
    }

    function handleFormSubmit(e) {
        e.preventDefault();

        const formData = new FormData(e.target);
        const data = {};

        formData.forEach((value, key) => {
            data[key] = value;
        });

        // 実際の実装では、ここでサーバーにデータを送信
        console.log('フォームデータ:', data);

        // 成功メッセージ表示
        showSuccessMessage();
    }

    function setupFormValidation() {
        const form = document.querySelector('.form-wrapper');
        if (!form) return;

        const inputs = form.querySelectorAll('input, textarea, select');

        inputs.forEach(input => {
            input.addEventListener('blur', function() {
                validateField(this);
            });
        });
    }

    function validateField(field) {
        if (field.hasAttribute('required') && !field.value.trim()) {
            field.classList.add('error');
            showFieldError(field, '必須項目です');
        } else if (field.type === 'email' && field.value && !isValidEmail(field.value)) {
            field.classList.add('error');
            showFieldError(field, '有効なメールアドレスを入力してください');
        } else {
            field.classList.remove('error');
            removeFieldError(field);
        }
    }

    function isValidEmail(email) {
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    }

    function showFieldError(field, message) {
        removeFieldError(field);
        
        const error = document.createElement('span');
        error.className = 'field-error';
        error.textContent = message;
        field.parentNode.appendChild(error);
    }

    function removeFieldError(field) {
        const error = field.parentNode.querySelector('.field-error');
        if (error) {
            error.remove();
        }
    }

    function showSuccessMessage() {
        const form = document.querySelector('.form-wrapper');
        const successMessage = document.createElement('div');
        successMessage.className = 'success-message';
        successMessage.innerHTML = `
            <h3>送信完了</h3>
            <p>お問い合わせありがとうございます。<br>
            内容を確認の上、2営業日以内にご連絡いたします。</p>
        `;

        form.innerHTML = '';
        form.appendChild(successMessage);
    }

    // セクションヘッダーのアニメーション
    function initSectionHeaderAnimation() {
        const headerObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -50px 0px'
        });

        const header = document.querySelector('.access-section .section-header');
        if (header) {
            // 初期状態を設定
            header.style.opacity = '0';
            header.style.transform = 'translateY(40px)';
            header.style.transition = 'opacity 1.2s cubic-bezier(0.25, 0.46, 0.45, 0.94), transform 1.2s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
            
            headerObserver.observe(header);
        }

        // animate-inクラスが追加されたときのスタイル適用
        const style = document.createElement('style');
        style.textContent = `
            .access-section .section-header.animate-in {
                opacity: 1 !important;
                transform: translateY(0) !important;
            }
        `;
        document.head.appendChild(style);
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAccess);
    } else {
        initAccess();
    }
})();