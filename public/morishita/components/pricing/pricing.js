(function() {
    'use strict';

    function initPricing() {
        const pricingSection = document.querySelector('.pricing-section');
        const pricingCards = document.querySelectorAll('.pricing-card');
        const buttons = document.querySelectorAll('.pricing-card .btn');

        if (!pricingSection) return;

        // 設定の適用
        if (window.pricingConfig) {
            applyPricingConfig(window.pricingConfig);
        }

        // ボタンクリックイベント
        buttons.forEach(button => {
            button.addEventListener('click', function() {
                const contactSection = document.querySelector('#contact');
                if (contactSection) {
                    contactSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        });

        // カードのアニメーション監視
        observePricingCards();

        // フィーチャードカードの強調
        const featuredCard = document.querySelector('.pricing-card.featured');
        if (featuredCard) {
            featuredCard.style.transform = 'scale(1.05)';
        }
    }

    function applyPricingConfig(config) {
        if (!config) return;

        // セクションヘッダーの更新
        if (config.header) {
            if (config.header.title) {
                const title = document.querySelector('.pricing-section .section-title');
                if (title) title.textContent = config.header.title;
            }

            if (config.header.subtitle) {
                const subtitle = document.querySelector('.pricing-section .section-subtitle');
                if (subtitle) subtitle.textContent = config.header.subtitle;
            }

            if (config.header.description) {
                const description = document.querySelector('.pricing-section .section-description');
                if (description) description.textContent = config.header.description;
            }
        }

        // 料金プランの更新
        if (config.plans && Array.isArray(config.plans)) {
            const pricingGrid = document.querySelector('.pricing-grid');
            if (pricingGrid) {
                pricingGrid.innerHTML = '';
                
                config.plans.forEach((plan, index) => {
                    const card = createPricingCard(plan, index);
                    pricingGrid.appendChild(card);
                });
            }
        }

        // 追加オプションの更新
        if (config.options && Array.isArray(config.options)) {
            const optionsGrid = document.querySelector('.options-grid');
            if (optionsGrid) {
                optionsGrid.innerHTML = '';
                
                config.options.forEach(option => {
                    const item = createOptionItem(option);
                    optionsGrid.appendChild(item);
                });
            }
        }

        // 注記の更新
        if (config.notes && Array.isArray(config.notes)) {
            const notesContainer = document.querySelector('.pricing-notes');
            if (notesContainer) {
                notesContainer.innerHTML = '';
                
                config.notes.forEach(note => {
                    const p = document.createElement('p');
                    p.textContent = note;
                    notesContainer.appendChild(p);
                });
            }
        }
    }

    function createPricingCard(plan, index) {
        const div = document.createElement('div');
        div.className = 'pricing-card';
        if (plan.featured) {
            div.className += ' featured';
        }

        if (plan.badge) {
            const badge = document.createElement('div');
            badge.className = 'badge';
            badge.textContent = plan.badge;
            div.appendChild(badge);
        }

        const header = document.createElement('div');
        header.className = 'plan-header';

        const name = document.createElement('h3');
        name.className = 'plan-name';
        name.textContent = plan.name;

        const price = document.createElement('div');
        price.className = 'plan-price';

        const amount = document.createElement('span');
        amount.className = 'price-amount';
        amount.textContent = plan.price;

        const unit = document.createElement('span');
        unit.className = 'price-unit';
        unit.textContent = plan.unit || '';

        price.appendChild(amount);
        price.appendChild(unit);

        header.appendChild(name);
        header.appendChild(price);

        const features = document.createElement('div');
        features.className = 'plan-features';

        const ul = document.createElement('ul');
        if (plan.features && Array.isArray(plan.features)) {
            plan.features.forEach(feature => {
                const li = document.createElement('li');
                li.textContent = feature;
                ul.appendChild(li);
            });
        }
        features.appendChild(ul);

        const button = document.createElement('button');
        button.className = plan.featured ? 'btn btn-primary' : 'btn btn-outline';
        button.textContent = plan.buttonText || 'このプランで始める';

        div.appendChild(header);
        div.appendChild(features);
        div.appendChild(button);

        return div;
    }

    function createOptionItem(option) {
        const div = document.createElement('div');
        div.className = 'option-item';

        const title = document.createElement('h4');
        title.textContent = option.title;

        const price = document.createElement('p');
        price.className = 'option-price';
        price.textContent = option.price;

        const desc = document.createElement('p');
        desc.className = 'option-desc';
        desc.textContent = option.description;

        div.appendChild(title);
        div.appendChild(price);
        div.appendChild(desc);

        return div;
    }

    function observePricingCards() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);

        const cards = document.querySelectorAll('.pricing-card, .option-item');
        cards.forEach(card => observer.observe(card));
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initPricing);
    } else {
        initPricing();
    }
})();