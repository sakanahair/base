#!/bin/bash

# Flutter Webアクセステストスクリプト

set -e

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PORT=${1:-3900}

echo -e "${BLUE}🔍 Flutter Web アプリケーションの確認...${NC}"
echo ""

# ファイルの存在確認
echo "📁 ビルドファイルの確認:"
if [ -f "/Users/apple/DEV/SAKANA_AI/next/dist/app/index.html" ]; then
    echo -e "${GREEN}✓${NC} dist/app/index.html が存在します"
else
    echo -e "${RED}✗${NC} dist/app/index.html が見つかりません"
fi

if [ -f "/Users/apple/DEV/SAKANA_AI/next/dist/app/main.dart.js" ]; then
    echo -e "${GREEN}✓${NC} dist/app/main.dart.js が存在します"
else
    echo -e "${RED}✗${NC} dist/app/main.dart.js が見つかりません"
fi

echo ""
echo "🌐 アクセステスト:"
echo ""

# サーバーが起動しているか確認
if curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/ | grep -q "200\|304"; then
    echo -e "${GREEN}✓${NC} サーバーは http://localhost:${PORT} で起動しています"
else
    echo -e "${RED}✗${NC} サーバーが起動していません"
    echo "  ./script/serve.sh を実行してください"
    exit 1
fi

# Flutter アプリへのアクセステスト
echo ""
echo "📱 Flutter アプリ URL:"
echo "  直接アクセス: http://localhost:${PORT}/app/index.html"
echo "  ルートアクセス: http://localhost:${PORT}/app/"
echo ""

# index.htmlの内容を確認
echo "📄 index.html の内容（最初の5行）:"
curl -s http://localhost:${PORT}/app/index.html | head -5 || echo "  アクセスできません"