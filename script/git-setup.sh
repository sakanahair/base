#!/bin/bash

# GitHub認証設定スクリプト
# セキュアなGitHub認証を設定します

set -e

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔐 GitHub認証設定"
echo ""

# 現在のリモート設定を表示
echo -e "${YELLOW}現在のリモート設定:${NC}"
git remote -v
echo ""

# トークンを環境変数から読み込むか、入力を求める
if [ -f ".env" ]; then
    source .env
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}GitHub Personal Access Tokenを入力してください:${NC}"
    echo "（トークンは画面に表示されません）"
    read -s GITHUB_TOKEN
    echo ""
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ トークンが入力されませんでした${NC}"
    exit 1
fi

# リポジトリ名を取得
REPO_URL=$(git remote get-url origin | sed 's/https:\/\/.*@/https:\/\//')
REPO_NAME=$(echo $REPO_URL | sed 's/.*github.com\///' | sed 's/\.git$//')

echo -e "${YELLOW}リポジトリ: $REPO_NAME${NC}"

# 認証付きURLを設定
echo -e "${GREEN}✅ GitHub認証を設定中...${NC}"
git remote set-url origin "https://${GITHUB_TOKEN}@github.com/${REPO_NAME}.git"

echo -e "${GREEN}✅ 設定完了！${NC}"
echo ""

# .envファイルに保存するか確認
if [ ! -f ".env" ] || ! grep -q "GITHUB_TOKEN" ".env"; then
    echo -e "${YELLOW}.envファイルにトークンを保存しますか？ (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "GITHUB_TOKEN=${GITHUB_TOKEN}" >> .env
        echo -e "${GREEN}✅ .envファイルに保存しました${NC}"
        echo -e "${YELLOW}⚠️  .envファイルは絶対にコミットしないでください！${NC}"
    fi
fi

# テスト
echo ""
echo -e "${YELLOW}接続テスト中...${NC}"
if git ls-remote &>/dev/null; then
    echo -e "${GREEN}✅ GitHubへの接続成功！${NC}"
else
    echo -e "${RED}❌ GitHubへの接続に失敗しました${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}GitHub認証設定が完了しました！${NC}"
echo ""
echo "使用可能なGitコマンド:"
echo "  git pull   - 最新の変更を取得"
echo "  git push   - 変更をプッシュ"
echo "  git status - 状態確認"
echo ""
echo -e "${YELLOW}⚠️  重要: トークンは機密情報です。外部に漏らさないでください。${NC}"