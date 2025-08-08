(function() {
    'use strict';

    // キャンペーンバナー機能
    function initCampaignBanner() {
        const campaignBanner = document.getElementById('campaignBanner');
        const siteHeader = document.querySelector('.site-header');
        if (!campaignBanner) return;

        // ローカルストレージからバナーの表示状態を確認
        const bannerClosed = localStorage.getItem('campaignBannerClosed');
        if (bannerClosed === 'true') {
            campaignBanner.style.display = 'none';
            if (siteHeader) {
                siteHeader.style.top = '0';
            }
            return;
        }

        // バナーを表示
        campaignBanner.style.display = 'block';
        // バナーの高さ分ヘッダーを下げる
        if (siteHeader) {
            const bannerHeight = campaignBanner.offsetHeight;
            siteHeader.style.top = `${bannerHeight}px`;
            // body のpadding-topも調整
            document.body.style.paddingTop = `${bannerHeight + 80}px`;
        }
    }

    // グローバル関数として閉じる機能を追加
    window.closeCampaignBanner = function() {
        const campaignBanner = document.getElementById('campaignBanner');
        const siteHeader = document.querySelector('.site-header');
        if (!campaignBanner) return;

        // 閉じるアニメーション
        campaignBanner.classList.add('closing');
        
        setTimeout(() => {
            campaignBanner.style.display = 'none';
            // ローカルストレージに状態を保存
            localStorage.setItem('campaignBannerClosed', 'true');
            // ヘッダーの位置を戻す
            if (siteHeader) {
                siteHeader.style.top = '0';
                document.body.style.paddingTop = '80px';
            }
        }, 300);
    };

    function initHeader() {
        const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
        const mainNav = document.querySelector('.main-nav');
        const navLinks = document.querySelectorAll('.nav-link');
        const siteHeader = document.querySelector('.site-header');

        if (!mobileMenuToggle || !mainNav) return;

        // モバイルメニューのトグル
        mobileMenuToggle.addEventListener('click', function() {
            this.classList.toggle('active');
            mainNav.classList.toggle('active');
        });

        // ナビリンクがクリックされたらメニューを閉じる
        navLinks.forEach(link => {
            link.addEventListener('click', () => {
                mobileMenuToggle.classList.remove('active');
                mainNav.classList.remove('active');
            });
        });

        // スムーススクロール with アニメーション
        navLinks.forEach(link => {
            link.addEventListener('click', function(e) {
                const href = this.getAttribute('href');
                if (href.startsWith('#')) {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        // アニメーション開始
                        link.classList.add('clicking');
                        
                        const siteHeader = document.querySelector('.site-header');
                        const campaignBanner = document.getElementById('campaignBanner');
                        let totalHeaderHeight = siteHeader ? siteHeader.offsetHeight : 80;
                        
                        // キャンペーンバナーが表示されている場合はその高さも考慮
                        if (campaignBanner && campaignBanner.style.display !== 'none') {
                            totalHeaderHeight += campaignBanner.offsetHeight;
                        }
                        
                        // ターゲット要素の正確な位置を取得
                        const targetRect = target.getBoundingClientRect();
                        const absoluteTop = window.pageYOffset + targetRect.top;
                        const targetPosition = absoluteTop - totalHeaderHeight - 30; // 少し余白を追加
                        
                        // カスタムスムーススクロール
                        smoothScrollTo(targetPosition, 300, () => {
                            link.classList.remove('clicking');
                            // ターゲット要素にハイライトアニメーション
                            target.classList.add('section-highlight');
                            setTimeout(() => {
                                target.classList.remove('section-highlight');
                            }, 1000);
                        });
                        
                        // アクティブリンクの更新
                        navLinks.forEach(navLink => navLink.classList.remove('active'));
                        link.classList.add('active');
                    }
                }
            });
        });
        
        // カスタムスムーススクロール関数
        function smoothScrollTo(targetPosition, duration, callback) {
            const startPosition = window.pageYOffset;
            const distance = targetPosition - startPosition;
            const startTime = performance.now();
            
            function easeOutQuart(t) {
                return 1 - Math.pow(1 - t, 4);
            }
            
            function animation(currentTime) {
                const elapsed = currentTime - startTime;
                const progress = Math.min(elapsed / duration, 1);
                const ease = easeOutQuart(progress);
                
                window.scrollTo(0, startPosition + distance * ease);
                
                if (progress < 1) {
                    requestAnimationFrame(animation);
                } else if (callback) {
                    callback();
                }
            }
            
            requestAnimationFrame(animation);
        }

        // 設定の適用
        if (window.headerConfig) {
            applyHeaderConfig(window.headerConfig);
        }
        
        // スクロールベースのヘッダー切り替え（デスクトップ・モバイル両方）
        if (siteHeader) {
            // フローティングロゴの作成（モバイルのみ）
            function createFloatingLogo() {
                if (window.innerWidth > 768) return;
                
                const existingLogo = document.getElementById('floating-logo');
                if (existingLogo) return;
                
                const floatingLogo = document.createElement('div');
                floatingLogo.id = 'floating-logo';
                floatingLogo.style.cssText = `
                    position: fixed;
                    bottom: 20px;
                    right: 20px;
                    background: linear-gradient(135deg, rgba(26, 26, 26, 0.9) 0%, rgba(45, 45, 45, 0.85) 100%);
                    backdrop-filter: blur(20px) saturate(180%);
                    -webkit-backdrop-filter: blur(20px) saturate(180%);
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    border-radius: 50px;
                    padding: 12px 20px;
                    box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(255, 255, 255, 0.05) inset;
                    z-index: 10000;
                    cursor: pointer;
                    opacity: 0;
                    visibility: hidden;
                    transform: translateY(20px);
                    transition: all 0.4s cubic-bezier(0.25, 0.46, 0.45, 0.94);
                `;
                
                const logoText = document.createElement('div');
                logoText.style.cssText = `
                    font-size: 11px;
                    font-weight: 500;
                    color: rgba(255, 255, 255, 0.9);
                    letter-spacing: 2px;
                    white-space: nowrap;
                    text-transform: uppercase;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
                `;
                logoText.textContent = 'No.0 PILATES';
                
                floatingLogo.appendChild(logoText);
                document.body.appendChild(floatingLogo);
                
                // クリックでトップへスクロール
                floatingLogo.addEventListener('click', () => {
                    window.scrollTo({
                        top: 0,
                        behavior: 'smooth'
                    });
                });
                
                // ホバーエフェクト
                floatingLogo.addEventListener('mouseenter', () => {
                    floatingLogo.style.transform = 'translateY(0) scale(1.02)';
                    floatingLogo.style.background = 'linear-gradient(135deg, rgba(45, 45, 45, 0.95) 0%, rgba(60, 60, 60, 0.9) 100%)';
                    floatingLogo.style.boxShadow = '0 15px 50px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.1) inset';
                    logoText.style.color = 'rgba(255, 255, 255, 1)';
                });
                
                floatingLogo.addEventListener('mouseleave', () => {
                    floatingLogo.style.transform = 'translateY(0) scale(1)';
                    floatingLogo.style.background = 'linear-gradient(135deg, rgba(26, 26, 26, 0.9) 0%, rgba(45, 45, 45, 0.85) 100%)';
                    floatingLogo.style.boxShadow = '0 10px 40px rgba(0, 0, 0, 0.2), 0 0 0 1px rgba(255, 255, 255, 0.05) inset';
                    logoText.style.color = 'rgba(255, 255, 255, 0.9)';
                });
            }
            
            function updateHeaderStyle() {
                const heroSection = document.querySelector('.hero-section');
                if (!heroSection) return;
                
                const heroBottom = heroSection.offsetHeight - 80;
                const floatingLogo = document.getElementById('floating-logo');
                const isMobile = window.innerWidth <= 768;
                
                if (window.scrollY < heroBottom) {
                    siteHeader.classList.add('header-dark-mode');
                    
                    // モバイルの場合：ヘッダーを表示
                    if (isMobile) {
                        siteHeader.style.opacity = '1';
                        siteHeader.style.visibility = 'visible';
                        siteHeader.style.transform = 'translateY(0)';
                        
                        // フローティングロゴを非表示
                        if (floatingLogo) {
                            floatingLogo.style.opacity = '0';
                            floatingLogo.style.visibility = 'hidden';
                            floatingLogo.style.transform = 'translateY(20px)';
                        }
                    }
                } else {
                    siteHeader.classList.remove('header-dark-mode');
                    
                    // モバイルの場合：ヘッダーを非表示、フローティングロゴを表示
                    if (isMobile) {
                        siteHeader.style.opacity = '0';
                        siteHeader.style.visibility = 'hidden';
                        siteHeader.style.transform = 'translateY(-100%)';
                        
                        // フローティングロゴを表示
                        if (floatingLogo) {
                            floatingLogo.style.opacity = '1';
                            floatingLogo.style.visibility = 'visible';
                            floatingLogo.style.transform = 'translateY(0)';
                        }
                    }
                }
            }
            
            // モバイルの場合のみフローティングロゴを作成
            createFloatingLogo();
            
            // 初期状態を設定
            updateHeaderStyle();
            
            // イベントリスナー
            window.addEventListener('scroll', updateHeaderStyle);
            window.addEventListener('resize', () => {
                createFloatingLogo();
                updateHeaderStyle();
            });
        }
        
        // スクロール位置に応じてアクティブリンクを更新
        function updateActiveLink() {
            const sections = document.querySelectorAll('section[id]');
            const navLinks = document.querySelectorAll('.nav-link[href^="#"]');
            const scrollPosition = window.scrollY + 100;
            
            sections.forEach(section => {
                const sectionTop = section.offsetTop;
                const sectionHeight = section.offsetHeight;
                const sectionId = section.getAttribute('id');
                
                if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                    navLinks.forEach(link => {
                        link.classList.remove('active');
                        if (link.getAttribute('href') === `#${sectionId}`) {
                            link.classList.add('active');
                        }
                    });
                }
            });
        }
        
        window.addEventListener('scroll', updateActiveLink);
        updateActiveLink(); // 初期状態を設定
    }

    function applyHeaderConfig(config) {
        if (!config) return;

        // ロゴテキストの更新
        if (config.logoText) {
            const logo = document.querySelector('.logo h1');
            if (logo) logo.textContent = config.logoText;
        }

        // ナビゲーションアイテムの更新
        if (config.navigation && Array.isArray(config.navigation)) {
            const navList = document.querySelector('.nav-list');
            if (navList) {
                navList.innerHTML = '';
                config.navigation.forEach(item => {
                    const li = document.createElement('li');
                    li.className = 'nav-item';
                    const a = document.createElement('a');
                    a.href = item.href;
                    a.className = 'nav-link';
                    a.textContent = item.text;
                    li.appendChild(a);
                    navList.appendChild(li);
                });
            }
        }
    }

    // 即座にヘッダーのスタイルを設定する関数
    function setInitialHeaderStyle() {
        const siteHeader = document.querySelector('.site-header');
        if (siteHeader) {
            // 初期位置が0の場合、heroセクション内と判定
            siteHeader.classList.add('header-dark-mode');
        }
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            setInitialHeaderStyle();
            initCampaignBanner();
            initHeader();
        });
    } else {
        setInitialHeaderStyle();
        initCampaignBanner();
        initHeader();
    }
    
})();