#!/bin/bash

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 現在のブランチを取得
CURRENT_BRANCH=$(git branch --show-current)

echo -e "${YELLOW}=== LINE管理くん統合システム Git Commit Script ===${NC}"
echo -e "Current branch: ${GREEN}$CURRENT_BRANCH${NC}"
echo -e "Project: ${GREEN}LINE管理くん + 電話管理くん + ショップ管理くん + 会計管理くん + 予約管理くん${NC}"
echo -e "Framework: ${GREEN}Next.js 15 + TypeScript + Tailwind CSS${NC}"
echo ""

# git status を表示
echo -e "${YELLOW}Git Status:${NC}"
git status --short

echo ""
echo -e "${YELLOW}Recent commits:${NC}"
git log --oneline -5

echo ""
# コミットメッセージを入力
echo -e "${YELLOW}Enter commit message:${NC}"
read -r COMMIT_MESSAGE

# コミットメッセージが空の場合は終了
if [ -z "$COMMIT_MESSAGE" ]; then
    echo -e "${RED}Error: Commit message cannot be empty${NC}"
    exit 1
fi

# 機密ファイルが含まれているかチェック
SENSITIVE_FILES=(".env.local" ".env" "firebase-service-account.json" "public/uploads/*")

for file in "${SENSITIVE_FILES[@]}"; do
    if git status --porcelain | grep -q "$file"; then
        echo -e "${RED}Warning: $file is staged or modified!${NC}"
        echo -e "${YELLOW}Removing $file from git...${NC}"
        git rm --cached "$file" 2>/dev/null || true
        git reset HEAD "$file" 2>/dev/null || true
    fi
done

# すべての変更をステージング
echo -e "${YELLOW}Staging all changes...${NC}"
git add -A

# 機密ファイルを除外
for file in "${SENSITIVE_FILES[@]}"; do
    git reset -- "$file" 2>/dev/null || true
done

# アップロードディレクトリを除外
git reset -- "public/uploads/" 2>/dev/null || true

# コミット
echo -e "${YELLOW}Committing...${NC}"
git commit -m "$COMMIT_MESSAGE

🤖 Generated with Claude Code (https://claude.ai/code)
📱 LINE管理くん統合システム開発

Co-Authored-By: Claude <noreply@anthropic.com>"

# コミット成功確認
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Commit successful!${NC}"
    echo ""
    
    # プッシュするか確認
    echo -e "${YELLOW}Push to remote? (y/n):${NC}"
    read -r PUSH_CONFIRM
    
    if [ "$PUSH_CONFIRM" = "y" ] || [ "$PUSH_CONFIRM" = "Y" ]; then
        echo -e "${YELLOW}Pushing to origin/$CURRENT_BRANCH...${NC}"
        git push origin "$CURRENT_BRANCH"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Push successful!${NC}"
        else
            echo -e "${RED}✗ Push failed${NC}"
            echo -e "${YELLOW}You may need to run: git push --set-upstream origin $CURRENT_BRANCH${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping push${NC}"
    fi
else
    echo -e "${RED}✗ Commit failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Done ===${NC}"