#!/bin/bash

# Flutter + Next.js ビルドのみスクリプト（サーバー起動なし）

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
echo "📝 静的ファイルは next/dist に出力されています"
echo ""
echo "サーバーを起動する場合:"
echo "  cd next && npx serve dist -l 3900"