#!/bin/bash

# Flutter + Next.js 開発サーバー起動スクリプト

set -e

echo "🚀 開発環境を起動します..."

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"
NEXT_DIR="$ROOT_DIR/next"

# Flutter Web の初回ビルド（必要な場合）
if [ ! -d "$NEXT_DIR/public/app" ]; then
    echo -e "${YELLOW}⚠️  Flutter Web の初回ビルドが必要です...${NC}"
    cd "$FLUTTER_DIR"
    flutter pub get
    flutter build web --release --base-href /app/
    
    # ビルド成果物をコピー
    mkdir -p "$NEXT_DIR/public/app"
    cp -r "$FLUTTER_DIR/build/web/"* "$NEXT_DIR/public/app/"
    # index.htmlのbase hrefを修正（念のため）
    sed -i '' 's|<base href="/">|<base href="/app/">|g' "$NEXT_DIR/public/app/index.html" 2>/dev/null || true
    echo -e "${GREEN}✅ Flutter Web ビルドが完了しました${NC}"
fi

# Next.js 開発サーバーを起動
echo -e "${BLUE}⚡ Next.js 開発サーバーを起動しています...${NC}"
cd "$NEXT_DIR"

# 依存関係をインストール（必要な場合）
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 依存関係をインストールしています...${NC}"
    npm install
fi

echo -e "${GREEN}✅ 開発サーバーが起動しました！${NC}"
echo ""
echo "🌐 アクセス URL:"
echo "  Next.js: http://localhost:3000"
echo "  Flutter: http://localhost:3000/app/"
echo ""
echo "💡 Flutter アプリを更新する場合:"
echo "  1. cd flutter"
echo "  2. flutter build web"
echo "  3. ./script/update-flutter.sh (または手動でコピー)"
echo ""

# 開発サーバーを起動
npm run dev