(function() {
    'use strict';

    function initFooter() {
        const footer = document.querySelector('.site-footer');
        const socialLinks = document.querySelectorAll('.social-link');
        const footerLinks = document.querySelectorAll('.footer-links a, .footer-bottom-links a');

        if (!footer) return;

        // 設定の適用
        if (window.footerConfig) {
            applyFooterConfig(window.footerConfig);
        }

        // ソーシャルリンクのアニメーション
        socialLinks.forEach(link => {
            link.addEventListener('mouseenter', function() {
                this.style.transform = 'translateY(-5px) rotate(5deg)';
            });

            link.addEventListener('mouseleave', function() {
                this.style.transform = 'translateY(0) rotate(0)';
            });
        });

        // フッターリンクのスムーススクロール
        footerLinks.forEach(link => {
            const href = link.getAttribute('href');
            if (href && href.startsWith('#')) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const target = document.querySelector(href);
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth',
                            block: 'start'
                        });
                    }
                });
            }
        });

        // 現在の年を自動更新
        updateCopyrightYear();
    }

    function applyFooterConfig(config) {
        if (!config) return;

        // 会社情報の更新
        if (config.company) {
            if (config.company.name) {
                const title = document.querySelector('.footer-title');
                if (title) title.textContent = config.company.name;
            }

            if (config.company.description) {
                const desc = document.querySelector('.footer-description');
                if (desc) desc.textContent = config.company.description;
            }
        }

        // ソーシャルリンクの更新
        if (config.socialLinks && Array.isArray(config.socialLinks)) {
            const socialContainer = document.querySelector('.social-links');
            if (socialContainer) {
                socialContainer.innerHTML = '';
                config.socialLinks.forEach(social => {
                    const link = createSocialLink(social);
                    socialContainer.appendChild(link);
                });
            }
        }

        // フッターセクションの更新
        if (config.sections && Array.isArray(config.sections)) {
            const footerContent = document.querySelector('.footer-content');
            if (footerContent) {
                // 最初のセクション（会社情報）は保持
                const firstSection = footerContent.querySelector('.footer-section');
                footerContent.innerHTML = '';
                footerContent.appendChild(firstSection);

                // 残りのセクションを追加
                config.sections.forEach(section => {
                    const sectionEl = createFooterSection(section);
                    footerContent.appendChild(sectionEl);
                });
            }
        }

        // 著作権情報の更新
        if (config.copyright) {
            const copyright = document.querySelector('.copyright');
            if (copyright) {
                const year = new Date().getFullYear();
                copyright.innerHTML = config.copyright.replace('{year}', year);
            }
        }
    }

    function createSocialLink(social) {
        const link = document.createElement('a');
        link.href = social.url || '#';
        link.className = 'social-link';
        link.setAttribute('aria-label', social.name);
        
        if (social.icon) {
            link.innerHTML = social.icon;
        }

        return link;
    }

    function createFooterSection(section) {
        const div = document.createElement('div');
        div.className = 'footer-section';

        const title = document.createElement('h4');
        title.className = 'footer-subtitle';
        title.textContent = section.title;

        const list = document.createElement('ul');
        list.className = 'footer-links';

        section.links.forEach(link => {
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.href = link.url || '#';
            a.textContent = link.text;
            li.appendChild(a);
            list.appendChild(li);
        });

        div.appendChild(title);
        div.appendChild(list);

        return div;
    }

    function updateCopyrightYear() {
        const copyright = document.querySelector('.copyright');
        if (copyright) {
            const currentYear = new Date().getFullYear();
            copyright.innerHTML = copyright.innerHTML.replace(/\d{4}/, currentYear);
        }
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initFooter);
    } else {
        initFooter();
    }
})();