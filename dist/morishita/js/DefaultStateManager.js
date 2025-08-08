(function() {
    'use strict';

    class DefaultStateManager {
        constructor() {
            this.defaultStateKey = 'no0-pilates-default-state';
            this.currentStateKey = 'no0-pilates-element-edits';
        }

        // 現在の状態をデフォルトとして保存
        async saveAsDefault() {
            try {
                // サーバーから現在の状態を取得
                const response = await fetch('api/load-settings');
                const currentState = await response.json();
                
                // デフォルト状態として保存
                localStorage.setItem(this.defaultStateKey, JSON.stringify(currentState));
                
                // サーバーにもデフォルト状態を保存
                await fetch('api/save-default-settings', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(currentState)
                });

                console.log('現在の状態をデフォルトとして保存しました');
                return true;
            } catch (error) {
                console.error('デフォルト状態の保存に失敗:', error);
                return false;
            }
        }

        // デフォルト状態を読み込む
        async loadDefault() {
            try {
                // まずサーバーから取得を試みる
                const response = await fetch('api/load-default-settings');
                if (response.ok) {
                    const defaultState = await response.json();
                    return defaultState;
                }
            } catch (error) {
                console.log('サーバーからのデフォルト読み込みに失敗、ローカルストレージを確認');
            }

            // ローカルストレージから取得
            const localDefault = localStorage.getItem(this.defaultStateKey);
            if (localDefault) {
                return JSON.parse(localDefault);
            }

            // デフォルトが存在しない場合は空の状態を返す
            return {
                elementEdits: {},
                lastSaved: null,
                saveType: 'default'
            };
        }

        // デフォルト状態にリセット
        async resetToDefault() {
            try {
                const defaultState = await this.loadDefault();
                
                // 現在の状態をデフォルトで上書き
                await fetch('api/save-settings', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(defaultState)
                });

                // ローカルストレージも更新
                localStorage.setItem(this.currentStateKey, JSON.stringify(defaultState));

                console.log('デフォルト状態にリセットしました');
                
                // ページをリロードして変更を反映
                window.location.reload();
                
                return true;
            } catch (error) {
                console.error('デフォルト状態へのリセットに失敗:', error);
                return false;
            }
        }

        // デフォルト状態をクリア（真の初期状態に戻す）
        async clearDefault() {
            try {
                // ローカルストレージから削除
                localStorage.removeItem(this.defaultStateKey);
                
                // サーバー側のデフォルトも削除
                await fetch('api/clear-default-settings', {
                    method: 'POST'
                });

                console.log('デフォルト状態をクリアしました');
                return true;
            } catch (error) {
                console.error('デフォルト状態のクリアに失敗:', error);
                return false;
            }
        }

        // 現在の状態とデフォルトの差分を取得
        async getDifferences() {
            const currentState = await this.getCurrentState();
            const defaultState = await this.loadDefault();
            
            const differences = {
                added: {},
                modified: {},
                removed: {}
            };

            // 現在の状態にあってデフォルトにない、または変更されている要素
            for (const [key, value] of Object.entries(currentState.elementEdits || {})) {
                if (!defaultState.elementEdits[key]) {
                    differences.added[key] = value;
                } else if (JSON.stringify(value) !== JSON.stringify(defaultState.elementEdits[key])) {
                    differences.modified[key] = {
                        current: value,
                        default: defaultState.elementEdits[key]
                    };
                }
            }

            // デフォルトにあって現在の状態にない要素
            for (const [key, value] of Object.entries(defaultState.elementEdits || {})) {
                if (!currentState.elementEdits[key]) {
                    differences.removed[key] = value;
                }
            }

            return differences;
        }

        // 現在の状態を取得
        async getCurrentState() {
            try {
                const response = await fetch('api/load-settings');
                return await response.json();
            } catch (error) {
                console.error('現在の状態の取得に失敗:', error);
                return { elementEdits: {} };
            }
        }
    }

    // グローバルに公開
    window.DefaultStateManager = DefaultStateManager;

    // インスタンスを作成
    window.defaultStateManager = new DefaultStateManager();

})();