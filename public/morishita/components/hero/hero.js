(function() {
    'use strict';

    function initHero() {
        const heroSection = document.querySelector('.hero-section');
        const heroButtons = document.querySelectorAll('.hero-actions .btn');
        
        if (!heroSection) return;

        // 設定の適用
        if (window.heroConfig) {
            applyHeroConfig(window.heroConfig);
        }

        // ボタンクリックイベント
        heroButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                if (this.classList.contains('btn-primary')) {
                    handlePrimaryAction(e);
                } else if (this.classList.contains('btn-secondary')) {
                    handleSecondaryAction(e);
                }
            });
        });

        // パララックス効果
        if (window.heroConfig && window.heroConfig.effects && window.heroConfig.effects.parallax) {
            window.addEventListener('scroll', () => {
                const scrolled = window.pageYOffset;
                const parallaxSpeed = 0.5;
                heroSection.style.transform = `translateY(${scrolled * parallaxSpeed}px)`;
            });
        }

        // アニメーション再生
        observeHeroAnimations();
        
        // スライドショーの初期化
        initSlideshow();
    }

    function applyHeroConfig(config) {
        if (!config) return;

        // タイトルとサブタイトルの更新
        if (config.title) {
            const title = document.querySelector('.hero-title');
            if (title) title.textContent = config.title;
        }

        if (config.subtitle) {
            const subtitle = document.querySelector('.hero-subtitle');
            if (subtitle) subtitle.textContent = config.subtitle;
        }

        if (config.description) {
            const description = document.querySelector('.hero-description');
            if (description) description.innerHTML = config.description;
        }

        // ボタンテキストの更新
        if (config.buttons) {
            const primaryBtn = document.querySelector('.btn-primary');
            const secondaryBtn = document.querySelector('.btn-secondary');

            if (primaryBtn && config.buttons.primary) {
                primaryBtn.textContent = config.buttons.primary.text;
            }

            if (secondaryBtn && config.buttons.secondary) {
                secondaryBtn.textContent = config.buttons.secondary.text;
            }
        }

        // 画像の更新
        if (config.image && config.image.src) {
            const imagePlaceholder = document.querySelector('.hero-image-placeholder');
            if (imagePlaceholder) {
                const img = document.createElement('img');
                img.src = config.image.src;
                img.alt = config.image.alt || 'Hero Image';
                img.style.width = '100%';
                img.style.height = 'auto';
                imagePlaceholder.innerHTML = '';
                imagePlaceholder.appendChild(img);
            }
        }
    }

    function handlePrimaryAction(e) {
        e.preventDefault();
        
        // configから動作を取得
        if (window.heroConfig && window.heroConfig.buttons && window.heroConfig.buttons.primary) {
            const action = window.heroConfig.buttons.primary.action;
            
            if (action.type === 'scroll') {
                const target = document.querySelector(action.target);
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            } else if (action.type === 'link') {
                window.location.href = action.target;
            }
        }
    }

    function handleSecondaryAction(e) {
        e.preventDefault();
        
        // configから動作を取得
        if (window.heroConfig && window.heroConfig.buttons && window.heroConfig.buttons.secondary) {
            const action = window.heroConfig.buttons.secondary.action;
            
            if (action.type === 'scroll') {
                const target = document.querySelector(action.target);
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            } else if (action.type === 'link') {
                window.location.href = action.target;
            }
        }
    }

    function observeHeroAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -100px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, observerOptions);

        const animatedElements = document.querySelectorAll('.hero-content, .hero-image');
        animatedElements.forEach(el => observer.observe(el));
    }

    function initSlideshow() {
        const slides = document.querySelectorAll('.hero-slide');
        if (slides.length === 0) return;
        
        let currentSlide = 0;
        
        // 自動スライドショー（5秒ごと）
        setInterval(() => {
            // 現在のスライドを非表示
            slides[currentSlide].classList.remove('active');
            
            // 次のスライドへ
            currentSlide = (currentSlide + 1) % slides.length;
            
            // 新しいスライドを表示
            slides[currentSlide].classList.add('active');
        }, 5000);
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initHero);
    } else {
        initHero();
    }
})();