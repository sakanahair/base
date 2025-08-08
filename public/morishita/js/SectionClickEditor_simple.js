// シンプルなアイコンピッカーのテスト実装
(function() {
    'use strict';

    // シンプルなアイコンセット
    const simpleIcons = {
        'Material Icons': [
            { type: 'material', icon: 'spa', name: 'スパ' },
            { type: 'material', icon: 'fitness_center', name: 'フィットネス' },
            { type: 'material', icon: 'self_improvement', name: '瞑想' },
            { type: 'material', icon: 'favorite', name: 'ハート' },
            { type: 'material', icon: 'star', name: '星' },
            { type: 'material', icon: 'home', name: 'ホーム' },
            { type: 'material', icon: 'person', name: '人物' },
            { type: 'material', icon: 'groups', name: 'グループ' },
            { type: 'material', icon: 'email', name: 'メール' },
            { type: 'material', icon: 'phone', name: '電話' },
            { type: 'material', icon: 'place', name: '場所' },
            { type: 'material', icon: 'schedule', name: 'スケジュール' },
            { type: 'material', icon: 'check', name: 'チェック' },
            { type: 'material', icon: 'close', name: 'クローズ' },
            { type: 'material', icon: 'settings', name: '設定' }
        ]
    };

    window.showSimpleIconPicker = function(onSelect) {
        // 既存のモーダルを削除
        const existing = document.querySelector('.simple-icon-picker-modal');
        if (existing) existing.remove();

        // モーダル作成
        const modal = document.createElement('div');
        modal.className = 'simple-icon-picker-modal';
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            z-index: 100000;
            display: flex;
            align-items: center;
            justify-content: center;
        `;

        // パネル
        const panel = document.createElement('div');
        panel.style.cssText = `
            background: white;
            border-radius: 8px;
            padding: 20px;
            max-width: 500px;
            max-height: 80vh;
            overflow: auto;
        `;

        // タイトル
        const title = document.createElement('h3');
        title.textContent = 'アイコンを選択';
        title.style.cssText = 'margin: 0 0 20px 0;';
        panel.appendChild(title);

        // Material Iconsのテスト
        const testDiv = document.createElement('div');
        testDiv.style.cssText = 'margin-bottom: 20px; padding: 10px; background: #f0f0f0; border-radius: 4px;';
        testDiv.innerHTML = `
            <p style="margin: 0 0 10px 0;">Material Iconsテスト:</p>
            <i class="material-icons" style="font-size: 24px;">spa</i>
            <i class="material-icons-outlined" style="font-size: 24px;">spa</i>
            <span style="margin-left: 10px; font-size: 14px;">（spaアイコンが表示されるはずです）</span>
        `;
        panel.appendChild(testDiv);

        // アイコングリッド
        const grid = document.createElement('div');
        grid.style.cssText = `
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            gap: 10px;
        `;

        simpleIcons['Material Icons'].forEach(item => {
            const btn = document.createElement('button');
            btn.style.cssText = `
                padding: 10px;
                border: 1px solid #ddd;
                border-radius: 4px;
                background: white;
                cursor: pointer;
                display: flex;
                flex-direction: column;
                align-items: center;
                gap: 5px;
            `;

            // アイコン要素
            const iconEl = document.createElement('i');
            if (item.type === 'material') {
                iconEl.className = 'material-icons-outlined';
                iconEl.textContent = item.icon;
                iconEl.style.fontSize = '24px';
            }

            // 名前
            const nameEl = document.createElement('span');
            nameEl.textContent = item.name;
            nameEl.style.cssText = 'font-size: 12px;';

            btn.appendChild(iconEl);
            btn.appendChild(nameEl);

            btn.onclick = () => {
                if (onSelect) {
                    const iconHTML = `<i class="material-icons-outlined">${item.icon}</i>`;
                    onSelect(iconHTML);
                }
                modal.remove();
            };

            grid.appendChild(btn);
        });

        panel.appendChild(grid);

        // 閉じるボタン
        const closeBtn = document.createElement('button');
        closeBtn.textContent = '閉じる';
        closeBtn.style.cssText = `
            margin-top: 20px;
            padding: 8px 16px;
            background: #666;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        `;
        closeBtn.onclick = () => modal.remove();
        panel.appendChild(closeBtn);

        modal.appendChild(panel);
        document.body.appendChild(modal);

        // 外側クリックで閉じる
        modal.onclick = (e) => {
            if (e.target === modal) modal.remove();
        };
    };
})();