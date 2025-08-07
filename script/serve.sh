#!/bin/bash

# ビルド済みアプリケーションのサーバー起動スクリプト

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
NEXT_DIR="$ROOT_DIR/next"

# ポート番号（デフォルト: 3900）
PORT=${1:-3900}

# ビルドディレクトリの存在確認
if [ ! -d "$NEXT_DIR/dist" ]; then
    echo -e "${RED}❌ ビルドディレクトリが見つかりません${NC}"
    echo "先に ./script/build.sh または ./script/build-only.sh を実行してください"
    exit 1
fi

cd "$NEXT_DIR"

# serveパッケージがインストールされていない場合はインストール
if ! npm list serve >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 serve パッケージをインストールしています...${NC}"
    npm install --save-dev serve
fi

echo -e "${BLUE}🚀 ポート ${PORT} でサーバーを起動しています...${NC}"
echo ""
echo -e "${GREEN}✅ サーバーが起動しました！${NC}"
echo ""
echo "🌐 アクセス URL:"
echo "  http://localhost:${PORT}"
echo "  http://localhost:${PORT}/app/"
echo ""
echo "📝 サーバーを停止するには Ctrl+C を押してください"
echo ""

# サーバーを起動
npx serve dist -l $PORT