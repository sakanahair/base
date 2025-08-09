#!/bin/bash

# Git自動コミット＆プッシュスクリプト
# Flutter + Next.js マルチプラットフォームプロジェクト用

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# Gitリポジトリの確認
if [ ! -d .git ]; then
    echo -e "${RED}❌ Gitリポジトリが初期化されていません${NC}"
    echo "git init を実行してください"
    exit 1
fi

# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH="main"
fi

echo -e "${BLUE}📝 Git コミット＆プッシュを開始します${NC}"
echo -e "ブランチ: ${YELLOW}$CURRENT_BRANCH${NC}"
echo ""

# 変更状況を確認
echo -e "${BLUE}📊 変更状況を確認中...${NC}"
git status --short

# 変更がない場合
if [ -z "$(git status --short)" ]; then
    echo -e "${YELLOW}⚠️  変更がありません${NC}"
    exit 0
fi

# コミットメッセージを取得
if [ $# -eq 0 ]; then
    # 引数がない場合はデフォルトメッセージ
    COMMIT_MESSAGE="Update: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${YELLOW}ℹ️  デフォルトメッセージを使用: $COMMIT_MESSAGE${NC}"
else
    # 引数をコミットメッセージとして使用
    COMMIT_MESSAGE="$*"
fi

# すべての変更をステージング
echo -e "${BLUE}📦 変更をステージング中...${NC}"
git add -A

# コミット
echo -e "${BLUE}💾 コミット中...${NC}"
git commit -m "$COMMIT_MESSAGE"

# GitHubにプッシュ
echo -e "${BLUE}🚀 GitHubにプッシュ中...${NC}"

# originを使ってプッシュ（トークンは既にリモートURLに設定済み）
git push origin $CURRENT_BRANCH

echo ""
echo -e "${GREEN}✅ 正常に完了しました！${NC}"
echo ""
echo -e "${BLUE}📋 コミット情報:${NC}"
echo -e "  メッセージ: $COMMIT_MESSAGE"
echo -e "  ブランチ: $CURRENT_BRANCH"
echo -e "  リポジトリ: https://github.com/sakanahair/base"
echo ""
echo -e "${GREEN}🌐 GitHubで確認:${NC}"
echo -e "  https://github.com/sakanahair/base/commits/$CURRENT_BRANCH"