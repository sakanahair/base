(function() {
    'use strict';

    class GitHistoryManager {
        constructor(workingDirectory = null) {
            this.currentElement = null;
            this.changedProperties = [];
            this.historyCache = [];
            this.maxHistoryItems = 50;
            // 作業ディレクトリを設定（デフォルトは現在のパス）
            this.workingDirectory = workingDirectory || this.getDefaultWorkingDirectory();
        }

        /**
         * デフォルトの作業ディレクトリを取得
         */
        getDefaultWorkingDirectory() {
            // 現在のURLパスから作業ディレクトリを推定
            const currentPath = window.location.pathname;
            if (currentPath.startsWith('site/')) {
                // site/next/project/ -> public/site/next/project
                return 'public/' + currentPath;
            }
            // デフォルトはプロジェクトディレクトリ
            return 'public/site/next/project';
        }

        /**
         * Git操作を実行
         */
        async executeGitCommand(command) {
            try {
                const response = await fetch('api/git/execute', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ 
                        command,
                        workingDirectory: this.workingDirectory 
                    })
                });

                const result = await response.json();
                
                if (!response.ok || !result.success) {
                    throw new Error(result.error || 'Git操作に失敗しました');
                }

                return result.output;
            } catch (error) {
                console.error('Git command error:', error);
                throw error;
            }
        }

        /**
         * 変更を自動的にコミット
         */
        async autoCommit(changeDescription, elementInfo) {
            try {
                this.currentElement = elementInfo;
                
                // 1. 現在の状態を確認
                const status = await this.executeGitCommand('git status --porcelain');
                
                if (!status.trim()) {
                    console.log('コミットする変更がありません');
                    return null;
                }

                // 2. 変更をステージング
                await this.executeGitCommand('git add -A');

                // 3. コミットメッセージを構築
                const commitMessage = this.buildCommitMessage(changeDescription, elementInfo);

                // 4. コミット実行
                const commitResult = await this.executeGitCommand(
                    `git commit -m "${commitMessage.replace(/"/g, '\\"')}"`
                );

                // 5. コミットハッシュを取得
                const hashResult = await this.executeGitCommand('git rev-parse HEAD');
                const commitHash = hashResult.trim();

                // 6. 履歴キャッシュに追加
                this.addToHistoryCache({
                    hash: commitHash,
                    message: changeDescription,
                    element: elementInfo,
                    timestamp: new Date().toISOString()
                });

                return commitHash;
            } catch (error) {
                console.error('Auto commit error:', error);
                throw error;
            }
        }

        /**
         * コミットメッセージを構築
         */
        buildCommitMessage(description, elementInfo) {
            const lines = [`[QuickEdit] ${description}`];
            
            if (elementInfo) {
                lines.push('');
                lines.push('要素情報:');
                lines.push(`- タイプ: ${elementInfo.tagName || 'unknown'}`);
                lines.push(`- セレクタ: ${elementInfo.selector || 'unknown'}`);
                
                if (elementInfo.changedProperties && elementInfo.changedProperties.length > 0) {
                    lines.push(`- 変更プロパティ: ${elementInfo.changedProperties.join(', ')}`);
                }
                
                lines.push(`- 時刻: ${new Date().toLocaleString('ja-JP')}`);
            }

            return lines.join('\n');
        }

        /**
         * コミット履歴を取得
         */
        async getHistory(limit = 20) {
            try {
                // QuickEditタグのコミットのみ取得
                const logCommand = `git log --grep="\\[QuickEdit\\]" --pretty=format:"%H|%s|%ar|%ai" -n ${limit}`;
                const logOutput = await this.executeGitCommand(logCommand);

                if (!logOutput.trim()) {
                    return [];
                }

                const commits = logOutput.trim().split('\n').map(line => {
                    const [hash, subject, relativeTime, timestamp] = line.split('|');
                    const description = subject.replace('[QuickEdit] ', '');
                    
                    return {
                        hash: hash.substring(0, 7), // 短縮ハッシュ
                        fullHash: hash,
                        description,
                        relativeTime,
                        timestamp,
                        date: new Date(timestamp)
                    };
                });

                return commits;
            } catch (error) {
                console.error('Get history error:', error);
                return [];
            }
        }

        /**
         * 特定のコミットに復元
         */
        async restoreCommit(commitHash) {
            try {
                // 1. 現在の変更を確認
                const status = await this.executeGitCommand('git status --porcelain');
                
                if (status.trim()) {
                    // 未コミットの変更がある場合は一時保存
                    const stashResult = await this.executeGitCommand('git stash push -m "QuickEdit auto-stash before restore"');
                    console.log('変更を一時保存しました:', stashResult);
                }

                // 2. 指定のコミットの内容をチェックアウト
                await this.executeGitCommand(`git checkout ${commitHash} -- .`);

                // 3. 復元をコミット
                const restoreMessage = `[QuickEdit] Restored to: ${commitHash}`;
                await this.executeGitCommand('git add -A');
                await this.executeGitCommand(`git commit -m "${restoreMessage}" --allow-empty`);

                return true;
            } catch (error) {
                console.error('Restore commit error:', error);
                throw error;
            }
        }

        /**
         * 履歴キャッシュに追加
         */
        addToHistoryCache(item) {
            this.historyCache.unshift(item);
            
            // 最大数を超えたら古いものを削除
            if (this.historyCache.length > this.maxHistoryItems) {
                this.historyCache = this.historyCache.slice(0, this.maxHistoryItems);
            }
        }

        /**
         * 現在のブランチ名を取得
         */
        async getCurrentBranch() {
            try {
                const branch = await this.executeGitCommand('git branch --show-current');
                return branch.trim();
            } catch (error) {
                console.error('Get branch error:', error);
                return 'unknown';
            }
        }

        /**
         * 差分を取得
         */
        async getDiff(commitHash) {
            try {
                const diff = await this.executeGitCommand(`git show ${commitHash} --name-status`);
                return diff;
            } catch (error) {
                console.error('Get diff error:', error);
                return '';
            }
        }

        /**
         * リポジトリの初期化状態を確認
         */
        async checkGitRepo() {
            try {
                await this.executeGitCommand('git rev-parse --git-dir');
                return true;
            } catch (error) {
                // Gitリポジトリではない
                return false;
            }
        }

        /**
         * リポジトリを初期化
         */
        async initGitRepo() {
            try {
                await this.executeGitCommand('git init');
                await this.executeGitCommand('git config user.name "QuickEdit System"');
                await this.executeGitCommand('git config user.email "quickedit@ai-controller.local"');
                
                // 初回コミット
                await this.executeGitCommand('git add -A');
                await this.executeGitCommand('git commit -m "[QuickEdit] Initial commit" --allow-empty');
                
                return true;
            } catch (error) {
                console.error('Init git repo error:', error);
                throw error;
            }
        }
    }

    // グローバルに公開
    window.GitHistoryManager = GitHistoryManager;
})();