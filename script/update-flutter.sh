#!/bin/bash

# Flutter Web 更新スクリプト（開発中のホットアップデート用）

set -e

echo "🔄 Flutter Web を更新しています..."

# カラー定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトディレクトリから実行される場合も考慮
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER_DIR="$ROOT_DIR/flutter"
NEXT_DIR="$ROOT_DIR/next"

# Flutter Web をビルド
echo -e "${BLUE}📱 Flutter Web をビルドしています...${NC}"
cd "$FLUTTER_DIR"
flutter build web --release --base-href /app/

# 既存のファイルを削除して新しいビルドをコピー
echo -e "${BLUE}📂 ファイルを更新しています...${NC}"
rm -rf "$NEXT_DIR/public/app"
mkdir -p "$NEXT_DIR/public/app"
cp -r "$FLUTTER_DIR/build/web/"* "$NEXT_DIR/public/app/"

# index.htmlのbase hrefを修正（念のため）
sed -i '' 's|<base href="/">|<base href="/app/">|g' "$NEXT_DIR/public/app/index.html" 2>/dev/null || true

echo -e "${GREEN}✅ Flutter Web の更新が完了しました！${NC}"
echo "ブラウザをリロードして変更を確認してください。"