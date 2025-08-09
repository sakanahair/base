#!/bin/bash

# Mutagen直接インストールスクリプト（Xcode不要）

set -e

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔄 Mutagen直接インストール（Xcode不要）"
echo ""

# アーキテクチャを判定
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    MUTAGEN_ARCH="arm64"
    echo "📍 Apple Silicon (M1/M2/M3) を検出"
else
    MUTAGEN_ARCH="amd64"
    echo "📍 Intel Mac を検出"
fi

# 最新バージョンを取得
echo -e "${YELLOW}最新バージョンを確認中...${NC}"
MUTAGEN_VERSION=$(curl -s https://api.github.com/repos/mutagen-io/mutagen/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$MUTAGEN_VERSION" ]; then
    # フォールバック
    MUTAGEN_VERSION="0.18.1"
    echo -e "${YELLOW}⚠️ 最新バージョンを取得できませんでした。v${MUTAGEN_VERSION}を使用します${NC}"
else
    echo -e "${GREEN}✅ 最新バージョン: v${MUTAGEN_VERSION}${NC}"
fi

# ダウンロードURL
DOWNLOAD_URL="https://github.com/mutagen-io/mutagen/releases/download/v${MUTAGEN_VERSION}/mutagen_darwin_${MUTAGEN_ARCH}_v${MUTAGEN_VERSION}.tar.gz"

echo -e "${YELLOW}ダウンロード中...${NC}"
echo "URL: $DOWNLOAD_URL"

# ダウンロードと展開
cd /tmp
curl -fsSL -o mutagen.tar.gz "$DOWNLOAD_URL" || {
    echo -e "${RED}❌ ダウンロードに失敗しました${NC}"
    exit 1
}

echo -e "${YELLOW}展開中...${NC}"
tar -xzf mutagen.tar.gz

# インストール
echo -e "${YELLOW}インストール中...${NC}"
if [ -w /usr/local/bin ]; then
    mv mutagen /usr/local/bin/
    chmod +x /usr/local/bin/mutagen
else
    echo -e "${YELLOW}管理者権限が必要です${NC}"
    sudo mv mutagen /usr/local/bin/
    sudo chmod +x /usr/local/bin/mutagen
fi

# クリーンアップ
rm -f mutagen.tar.gz

# 確認
echo ""
if command -v mutagen &> /dev/null; then
    echo -e "${GREEN}✅ Mutagenインストール完了！${NC}"
    echo ""
    mutagen version
    echo ""
    echo "使用可能なコマンド:"
    echo "  mutagen sync list    - 同期セッション一覧"
    echo "  mutagen sync create  - 新規同期作成"
    echo "  mutagen daemon start - デーモン起動"
else
    echo -e "${RED}❌ インストールに失敗しました${NC}"
    echo "パスを確認してください:"
    echo "  export PATH=\"\$PATH:/usr/local/bin\""
    exit 1
fi