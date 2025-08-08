(function() {
    'use strict';

    function initPrograms() {
        const programsSection = document.querySelector('.programs-section');
        const reservationButton = document.querySelector('.reservation-button');

        if (!programsSection) return;

        // セクションヘッダーのアニメーション初期化（Aboutセクションと同様）
        initSectionHeaderAnimation();

        // 予約ボタンのスムーズアニメーション
        if (reservationButton) {
            reservationButton.addEventListener('mouseenter', function() {
                this.style.transform = 'scale(1.02)';
            });

            reservationButton.addEventListener('mouseleave', function() {
                this.style.transform = 'scale(1)';
            });
        }

        // カードのアニメーション監視
        observeProgramCards();
        
        // パララックスエフェクト for 画像
        const programImages = document.querySelectorAll('.program-image');
        programImages.forEach(img => {
            const card = img.closest('.program-card');
            card.addEventListener('mousemove', function(e) {
                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;
                const percentX = (x - centerX) / centerX;
                const percentY = (y - centerY) / centerY;
                
                img.style.transform = `scale(1.1) translate(${percentX * 10}px, ${percentY * 10}px)`;
            });
            
            card.addEventListener('mouseleave', function() {
                img.style.transform = 'scale(1)';
            });
        });

        // 価格アイテムのホバーエフェクト
        const priceItems = document.querySelectorAll('.price-item');
        priceItems.forEach((item, index) => {
            item.addEventListener('mouseenter', function() {
                this.style.transform = 'translateX(10px) scale(1.02)';
                this.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
                this.style.backgroundColor = 'rgba(139, 121, 98, 0.03)';
            });

            item.addEventListener('mouseleave', function() {
                this.style.transform = 'translateX(0) scale(1)';
                this.style.backgroundColor = '';
            });
            
            // 価格の数値アニメーション
            const priceValue = item.querySelector('.price-value');
            if (priceValue) {
                const originalText = priceValue.textContent;
                const number = parseInt(originalText.replace(/[^0-9]/g, ''));
                if (!isNaN(number)) {
                    item.addEventListener('mouseenter', function() {
                        animateValue(priceValue, 0, number, 500);
                    });
                }
            }
        });

        // プレミアムカードの特別なホバーエフェクト
        const premiumCard = document.querySelector('.program-card.premium');
        if (premiumCard) {
            premiumCard.addEventListener('mouseenter', function() {
                this.classList.add('premium-hover');
                // 光のエフェクトを追加
                createSparkle(this);
            });

            premiumCard.addEventListener('mouseleave', function() {
                this.classList.remove('premium-hover');
            });
        }
        
        // スパークルエフェクト関数
        function createSparkle(element) {
            const sparkle = document.createElement('div');
            sparkle.className = 'sparkle';
            sparkle.style.cssText = `
                position: absolute;
                width: 4px;
                height: 4px;
                background: #d4af37;
                border-radius: 50%;
                pointer-events: none;
                animation: sparkleAnim 1s ease-out forwards;
                left: ${Math.random() * 100}%;
                top: ${Math.random() * 100}%;
            `;
            element.appendChild(sparkle);
            setTimeout(() => sparkle.remove(), 1000);
        }
        
        // 数値アニメーション関数
        function animateValue(element, start, end, duration) {
            const startTimestamp = Date.now();
            const step = () => {
                const timestamp = Date.now();
                const progress = Math.min((timestamp - startTimestamp) / duration, 1);
                const current = Math.floor(progress * (end - start) + start);
                element.textContent = `¥${current.toLocaleString()}`;
                if (progress < 1) {
                    requestAnimationFrame(step);
                }
            };
            requestAnimationFrame(step);
        }
    }

    function observeProgramCards() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach((entry, index) => {
                if (entry.isIntersecting) {
                    setTimeout(() => {
                        entry.target.style.opacity = '0';
                        entry.target.style.transform = 'translateY(30px)';
                        
                        requestAnimationFrame(() => {
                            entry.target.style.transition = 'opacity 0.8s ease, transform 0.8s cubic-bezier(0.4, 0, 0.2, 1)';
                            entry.target.style.opacity = '1';
                            entry.target.style.transform = 'translateY(0)';
                        });
                    }, index * 100);
                    
                    observer.unobserve(entry.target);
                }
            });
        }, observerOptions);

        const cards = document.querySelectorAll('.program-card');
        cards.forEach(card => {
            card.style.opacity = '0';
            observer.observe(card);
        });

        // フッターセクションのアニメーション
        const footer = document.querySelector('.programs-footer');
        if (footer) {
            footer.style.opacity = '0';
            observer.observe(footer);
        }
    }

    // スムーズスクロールのためのヘルパー関数
    function smoothScrollTo(element) {
        if (element) {
            element.scrollIntoView({ 
                behavior: 'smooth', 
                block: 'start',
                inline: 'nearest'
            });
        }
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

        const header = document.querySelector('.programs-section .section-header');
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
            .programs-section .section-header.animate-in {
                opacity: 1 !important;
                transform: translateY(0) !important;
            }
        `;
        document.head.appendChild(style);
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initPrograms);
    } else {
        initPrograms();
    }
})();