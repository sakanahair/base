class ComponentLoader {
    constructor() {
        this.componentsPath = '/morishita/components.json';
        this.components = [];
    }

    async loadComponents() {
        try {
            const response = await fetch(this.componentsPath);
            const data = await response.json();
            this.components = data.components;
            
            for (const component of this.components) {
                if (component.enabled) {
                    await this.loadComponent(component);
                }
            }
        } catch (error) {
            console.error('コンポーネントの読み込みエラー:', error);
        }
    }

    async loadComponent(component) {
        const { name, path } = component;
        const container = document.getElementById(`${name}-component`);
        
        if (!container) {
            console.warn(`コンテナが見つかりません: ${name}-component`);
            return;
        }

        try {
            // キャッシュバスター用のタイムスタンプ
            const cacheKey = '?v=20250126001';
            
            // HTMLの読み込み
            const htmlResponse = await fetch(`${path}/${name}.html${cacheKey}`);
            const html = await htmlResponse.text();
            container.innerHTML = html;

            // CSSの読み込み
            const cssLink = document.createElement('link');
            cssLink.rel = 'stylesheet';
            cssLink.href = `${path}/${name}.css${cacheKey}`;
            document.head.appendChild(cssLink);

            // JavaScriptの読み込み
            const script = document.createElement('script');
            script.src = `${path}/${name}.js${cacheKey}`;
            script.defer = true;
            document.body.appendChild(script);

            // 設定の読み込みと適用
            try {
                const configResponse = await fetch(`${path}/${name}.config.json`);
                const config = await configResponse.json();
                
                // configデータをグローバルに保存（各コンポーネントから参照可能）
                window[`${name}Config`] = config;
                
                // データ属性として設定を保存
                container.dataset.config = JSON.stringify(config);
            } catch (configError) {
                console.warn(`設定ファイルが見つかりません: ${name}.config.json`);
            }

            console.log(`コンポーネント読み込み完了: ${name}`);
        } catch (error) {
            console.error(`コンポーネント読み込みエラー (${name}):`, error);
        }
    }

    // 動的にコンポーネントを追加
    async addComponent(name, targetId) {
        const component = this.components.find(c => c.name === name);
        if (component && component.enabled) {
            const container = document.createElement('div');
            container.id = `${name}-component`;
            document.getElementById(targetId).appendChild(container);
            await this.loadComponent(component);
        }
    }

    // コンポーネントを削除
    removeComponent(name) {
        const container = document.getElementById(`${name}-component`);
        if (container) {
            container.remove();
        }
    }

    // コンポーネントをリロード
    async reloadComponent(name) {
        const component = this.components.find(c => c.name === name);
        if (component && component.enabled) {
            this.removeComponent(name);
            await this.loadComponent(component);
        }
    }
    
    // すべてのコンポーネント読み込み完了後にローディングを非表示
    hideLoadingOverlay() {
        const loadingOverlay = document.getElementById('loadingOverlay');
        if (loadingOverlay) {
            setTimeout(() => {
                loadingOverlay.style.opacity = '0';
                setTimeout(() => {
                    loadingOverlay.style.display = 'none';
                }, 400);
            }, 500);
        }
    }
}