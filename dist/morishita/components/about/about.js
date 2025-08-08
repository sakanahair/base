(function() {
    'use strict';

    // 高級感のあるスクロールアニメーション
    function initAbout() {
        const aboutSection = document.querySelector('.about-section');
        if (!aboutSection) return;

        // スクロール連動アニメーションの初期化
        initScrollAnimations();
        
        // パララックス効果の初期化
        initParallaxEffect();
        
        // 設定の適用
        if (window.aboutConfig) {
            applyAboutConfig(window.aboutConfig);
        }
    }

    // スクロール連動アニメーション
    function initScrollAnimations() {
        // セクションヘッダーのアニメーション
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

        const header = document.querySelector('.section-header');
        if (header) {
            headerObserver.observe(header);
        }

        // 各要素のアニメーション（スクロールするたびに動作）
        const elementObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    // ビューポートに入ったらアニメーション追加
                    entry.target.classList.add('in-view');
                    
                    // パララックス効果のためのデータ属性を設定
                    if (entry.target.classList.contains('slide-image')) {
                        entry.target.setAttribute('data-parallax', 'true');
                    }
                } else if (entry.boundingClientRect.top > 0) {
                    // ビューポートの上に出たらアニメーションリセット（下にスクロール時）
                    entry.target.classList.remove('in-view');
                    
                    // パララックス効果をリセット
                    if (entry.target.classList.contains('slide-image')) {
                        entry.target.removeAttribute('data-parallax');
                    }
                }
            });
        }, {
            threshold: 0.15,
            rootMargin: '0px 0px -100px 0px'
        });

        // テキストと画像要素を監視
        const animateElements = document.querySelectorAll('[data-animation]');
        animateElements.forEach(element => {
            elementObserver.observe(element);
        });

        // スライド全体の監視（より複雑なアニメーション用）
        const slideObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                const slide = entry.target;
                const slideText = slide.querySelector('.slide-text');
                const slideImage = slide.querySelector('.slide-image');
                
                if (entry.isIntersecting) {
                    // スライドの位置に基づいて異なるタイミングでアニメーション
                    const slideIndex = parseInt(slide.dataset.slide);
                    
                    // テキストアニメーション
                    if (slideText && !slideText.classList.contains('in-view')) {
                        setTimeout(() => {
                            slideText.classList.add('in-view');
                        }, slideIndex % 2 === 0 ? 100 : 0);
                    }
                    
                    // 画像アニメーション
                    if (slideImage && !slideImage.classList.contains('in-view')) {
                        setTimeout(() => {
                            slideImage.classList.add('in-view');
                        }, slideIndex % 2 === 0 ? 0 : 100);
                    }
                } else if (entry.boundingClientRect.top > 0) {
                    // リセット処理
                    if (slideText) slideText.classList.remove('in-view');
                    if (slideImage) slideImage.classList.remove('in-view');
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -50px 0px'
        });

        // 各スライドを監視
        const slides = document.querySelectorAll('.about-slide');
        slides.forEach(slide => {
            slideObserver.observe(slide);
        });
        
        // 資格認定セクションのアニメーション監視
        const certObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('in-view');
                } else if (entry.boundingClientRect.top > 0) {
                    entry.target.classList.remove('in-view');
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -50px 0px'
        });
        
        const certContainer = document.querySelector('.certifications-elegant');
        if (certContainer) {
            certObserver.observe(certContainer);
        }
    }

    // パララックス効果
    function initParallaxEffect() {
        let ticking = false;
        
        function updateParallax() {
            const scrolled = window.pageYOffset;
            const parallaxElements = document.querySelectorAll('[data-parallax="true"]');
            
            parallaxElements.forEach(element => {
                const rect = element.getBoundingClientRect();
                const speed = 0.5; // パララックススピード
                const yPos = -(rect.top * speed);
                
                // より滑らかなパララックス効果
                if (rect.top < window.innerHeight && rect.bottom > 0) {
                    const img = element.querySelector('.slide-img');
                    if (img) {
                        img.style.transform = `translateY(${yPos * 0.3}px) scale(1.1)`;
                    }
                }
            });
            
            ticking = false;
        }
        
        function requestTick() {
            if (!ticking) {
                window.requestAnimationFrame(updateParallax);
                ticking = true;
            }
        }
        
        // スクロールイベントの最適化
        window.addEventListener('scroll', requestTick, { passive: true });
    }

    // マウスムーブによる微細なパララックス効果（デスクトップのみ）
    function initMouseParallax() {
        if (window.innerWidth > 768) {
            document.addEventListener('mousemove', (e) => {
                const images = document.querySelectorAll('.slide-image.in-view .slide-img');
                const mouseX = e.clientX / window.innerWidth - 0.5;
                const mouseY = e.clientY / window.innerHeight - 0.5;
                
                images.forEach(img => {
                    const offsetX = mouseX * 20;
                    const offsetY = mouseY * 20;
                    
                    img.style.transform = `translate(${offsetX}px, ${offsetY}px) scale(1.05)`;
                });
            });
        }
    }

    // 設定の適用
    function applyAboutConfig(config) {
        if (!config) return;
        // 必要に応じて設定を適用
    }

    // スムーススクロール効果
    function smoothScrollTo(element) {
        element.scrollIntoView({
            behavior: 'smooth',
            block: 'center'
        });
    }

    // モバイル最適化
    function optimizeForMobile() {
        if (window.innerWidth <= 768) {
            // モバイルではパララックス効果を軽減
            const parallaxElements = document.querySelectorAll('[data-parallax]');
            parallaxElements.forEach(el => {
                el.removeAttribute('data-parallax');
            });
        }
    }

    // リサイズ時の処理
    let resizeTimer;
    window.addEventListener('resize', () => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => {
            optimizeForMobile();
        }, 250);
    });

    // ギャラリーのライトボックス機能
    function initGalleryLightbox() {
        const galleryItems = document.querySelectorAll('.gallery-item img');
        
        galleryItems.forEach((img, index) => {
            img.style.cursor = 'pointer';
            img.addEventListener('click', () => {
                openLightbox(img.src, index);
            });
        });
    }
    
    function openLightbox(imageSrc, currentIndex) {
        // ライトボックスコンテナを作成
        const lightbox = document.createElement('div');
        lightbox.className = 'gallery-lightbox';
        lightbox.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.95);
            z-index: 100000;
            display: flex;
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        `;
        
        // 画像コンテナ
        const imageContainer = document.createElement('div');
        imageContainer.style.cssText = `
            position: relative;
            max-width: 90vw;
            max-height: 90vh;
            transform: scale(0.9);
            transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        `;
        
        // 画像
        const image = document.createElement('img');
        image.src = imageSrc;
        image.style.cssText = `
            width: 100%;
            height: 100%;
            object-fit: contain;
        `;
        
        // 閉じるボタン
        const closeButton = document.createElement('button');
        closeButton.innerHTML = '×';
        closeButton.style.cssText = `
            position: absolute;
            top: 20px;
            right: 20px;
            width: 50px;
            height: 50px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            color: white;
            font-size: 30px;
            font-weight: 200;
            cursor: pointer;
            transition: all 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 100001;
        `;
        
        // ナビゲーションボタン
        const prevButton = document.createElement('button');
        prevButton.innerHTML = '‹';
        prevButton.style.cssText = `
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            width: 50px;
            height: 50px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            color: white;
            font-size: 30px;
            font-weight: 200;
            cursor: pointer;
            transition: all 0.3s ease;
        `;
        
        const nextButton = document.createElement('button');
        nextButton.innerHTML = '›';
        nextButton.style.cssText = `
            position: absolute;
            right: 20px;
            top: 50%;
            transform: translateY(-50%);
            width: 50px;
            height: 50px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 50%;
            color: white;
            font-size: 30px;
            font-weight: 200;
            cursor: pointer;
            transition: all 0.3s ease;
        `;
        
        // ホバーエフェクト
        [closeButton, prevButton, nextButton].forEach(btn => {
            btn.addEventListener('mouseenter', () => {
                btn.style.background = 'rgba(255, 255, 255, 0.2)';
                btn.style.transform = btn === closeButton ? 'scale(1.1)' : btn.style.transform.includes('translateY') ? 'translateY(-50%) scale(1.1)' : 'scale(1.1)';
            });
            btn.addEventListener('mouseleave', () => {
                btn.style.background = 'rgba(255, 255, 255, 0.1)';
                btn.style.transform = btn === closeButton ? 'scale(1)' : btn.style.transform.includes('translateY') ? 'translateY(-50%) scale(1)' : 'scale(1)';
            });
        });
        
        // 画像リスト
        const allImages = document.querySelectorAll('.gallery-item img');
        let currentIdx = currentIndex;
        
        // ナビゲーション機能
        prevButton.addEventListener('click', (e) => {
            e.stopPropagation();
            currentIdx = (currentIdx - 1 + allImages.length) % allImages.length;
            image.style.opacity = '0';
            setTimeout(() => {
                image.src = allImages[currentIdx].src;
                image.style.opacity = '1';
            }, 200);
        });
        
        nextButton.addEventListener('click', (e) => {
            e.stopPropagation();
            currentIdx = (currentIdx + 1) % allImages.length;
            image.style.opacity = '0';
            setTimeout(() => {
                image.src = allImages[currentIdx].src;
                image.style.opacity = '1';
            }, 200);
        });
        
        // 画像のトランジション
        image.style.transition = 'opacity 0.2s ease';
        
        // 閉じる機能
        const closeLightbox = () => {
            lightbox.style.opacity = '0';
            imageContainer.style.transform = 'scale(0.9)';
            setTimeout(() => {
                lightbox.remove();
            }, 300);
        };
        
        closeButton.addEventListener('click', closeLightbox);
        lightbox.addEventListener('click', (e) => {
            if (e.target === lightbox) {
                closeLightbox();
            }
        });
        
        // ESCキーで閉じる
        const handleEscape = (e) => {
            if (e.key === 'Escape') {
                closeLightbox();
                document.removeEventListener('keydown', handleEscape);
            }
        };
        document.addEventListener('keydown', handleEscape);
        
        // 矢印キーでナビゲーション
        const handleArrows = (e) => {
            if (e.key === 'ArrowLeft') {
                prevButton.click();
            } else if (e.key === 'ArrowRight') {
                nextButton.click();
            }
        };
        document.addEventListener('keydown', handleArrows);
        
        // DOMに追加
        imageContainer.appendChild(image);
        lightbox.appendChild(imageContainer);
        lightbox.appendChild(closeButton);
        lightbox.appendChild(prevButton);
        lightbox.appendChild(nextButton);
        document.body.appendChild(lightbox);
        
        // アニメーション開始
        requestAnimationFrame(() => {
            lightbox.style.opacity = '1';
            imageContainer.style.transform = 'scale(1)';
        });
    }
    
    // インストラクター画像の自動切り替え機能
    function initInstructorImageSlider() {
        const container = document.getElementById('instructor-image-container');
        if (!container) return;
        
        const images = container.querySelectorAll('.slide-img');
        const indicators = container.querySelectorAll('.indicator');
        let currentIndex = 0;
        let intervalId;
        
        // 画像を切り替える関数
        function switchImage(index) {
            // 全ての画像とインジケーターを非アクティブに
            images.forEach(img => img.classList.remove('active'));
            indicators.forEach(ind => ind.classList.remove('active'));
            
            // 指定のインデックスの画像とインジケーターをアクティブに
            if (images[index]) {
                images[index].classList.add('active');
            }
            if (indicators[index]) {
                indicators[index].classList.add('active');
            }
            
            currentIndex = index;
        }
        
        // 自動切り替え開始
        function startAutoSlide() {
            intervalId = setInterval(() => {
                const nextIndex = (currentIndex + 1) % images.length;
                switchImage(nextIndex);
            }, 4000); // 4秒ごとに切り替え
        }
        
        // 自動切り替え停止
        function stopAutoSlide() {
            if (intervalId) {
                clearInterval(intervalId);
            }
        }
        
        // インジケーターのクリックイベント
        indicators.forEach((indicator, index) => {
            indicator.addEventListener('click', () => {
                stopAutoSlide();
                switchImage(index);
                startAutoSlide();
            });
        });
        
        // ホバー時は自動切り替えを停止
        container.addEventListener('mouseenter', stopAutoSlide);
        container.addEventListener('mouseleave', startAutoSlide);
        
        // Intersection Observerで表示されているときのみ自動切り替え
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    startAutoSlide();
                } else {
                    stopAutoSlide();
                }
            });
        }, {
            threshold: 0.5
        });
        
        observer.observe(container);
        
        // 初期表示
        switchImage(0);
    }
    
    // 設備セクションのアニメーション
    function initEquipmentAnimation() {
        const equipmentSection = document.querySelector('.equipment-section');
        if (!equipmentSection) return;
        
        // ヘッダーのアニメーション
        const headerObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.animation = 'fadeInUp 1s ease forwards';
                }
            });
        }, { threshold: 0.2 });
        
        const equipmentHeader = document.querySelector('.equipment-header');
        if (equipmentHeader) {
            headerObserver.observe(equipmentHeader);
        }
        
        // 各アイテムのアニメーション
        const itemObserver = new IntersectionObserver((entries) => {
            entries.forEach((entry, index) => {
                if (entry.isIntersecting) {
                    setTimeout(() => {
                        entry.target.style.opacity = '1';
                        entry.target.style.transform = 'translateY(0)';
                    }, index * 100);
                }
            });
        }, { 
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });
        
        const equipmentItems = document.querySelectorAll('.equipment-item');
        equipmentItems.forEach(item => {
            item.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
            itemObserver.observe(item);
        });
        
        // ホバーエフェクトの強化
        equipmentItems.forEach(item => {
            const image = item.querySelector('.equipment-image');
            const overlay = item.querySelector('.equipment-overlay');
            
            item.addEventListener('mouseenter', () => {
                if (image) image.style.transform = 'scale(1.1)';
            });
            
            item.addEventListener('mouseleave', () => {
                if (image) image.style.transform = 'scale(1)';
            });
        });
    }
    
    // 初期化処理
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            initAbout();
            initMouseParallax();
            optimizeForMobile();
            initGalleryLightbox();
            initInstructorImageSlider();
            initEquipmentAnimation();
        });
    } else {
        initAbout();
        initMouseParallax();
        optimizeForMobile();
        initGalleryLightbox();
        initInstructorImageSlider();
        initEquipmentAnimation();
    }

    // パフォーマンス最適化：Intersection Observerのクリーンアップ
    window.addEventListener('beforeunload', () => {
        const observers = [headerObserver, elementObserver, slideObserver];
        observers.forEach(observer => {
            if (observer) observer.disconnect();
        });
    });
})();