#!/bin/bash

# Flutter + Next.js ビルドスクリプト

set -e

echo "🚀 Flutter + Next.js ビルドを開始します..."

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"
NEXT_DIR="$ROOT_DIR/next"

# 1. Flutter Web ビルド
echo -e "${BLUE}📱 Flutter Web をビルドしています...${NC}"
cd "$FLUTTER_DIR"

# Flutter の依存関係を取得
flutter pub get

# Flutter Web をビルド（base-hrefを/app/に設定）
flutter build web --release --base-href /app/

# ビルド成果物を Next.js の public フォルダにコピー
echo -e "${YELLOW}📂 Flutter ビルドを Next.js に統合しています...${NC}"
rm -rf "$NEXT_DIR/public/app"
mkdir -p "$NEXT_DIR/public/app"
cp -r "$FLUTTER_DIR/build/web/"* "$NEXT_DIR/public/app/"

# index.htmlのbase hrefを修正（念のため）
sed -i '' 's|<base href="/">|<base href="/app/">|g' "$NEXT_DIR/public/app/index.html" 2>/dev/null || true

# 2. Next.js ビルド
echo -e "${BLUE}⚡ Next.js をビルドしています...${NC}"
cd "$NEXT_DIR"

# Next.js の依存関係を取得
npm install

# Next.js をビルド
npm run build

echo -e "${GREEN}✅ ビルドが完了しました！${NC}"
echo ""

# 3. 自動でサーバーを起動
echo -e "${BLUE}🚀 ポート 3900 でサーバーを起動しています...${NC}"
cd "$NEXT_DIR"

# serveパッケージがインストールされていない場合はインストール
if ! npm list serve >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 serve パッケージをインストールしています...${NC}"
    npm install --save-dev serve
fi

echo -e "${GREEN}✅ サーバーが起動しました！${NC}"
echo ""
echo "🌐 アクセス URL:"
echo "  http://localhost:3900"
echo "  http://localhost:3900/app/"
echo ""
echo "📝 サーバーを停止するには Ctrl+C を押してください"
echo ""

# サーバーを起動（ポート3900）
npx serve dist -l 3900