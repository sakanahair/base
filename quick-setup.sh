#!/bin/bash

# ============================================
# SAKANA AI - クイックセットアップ
# ワンコマンドでセットアップ完了
# ============================================

set -e

# GitHubから直接セットアップスクリプトを実行
echo "🚀 SAKANA AI クイックセットアップを開始します..."

# 一時ディレクトリでセットアップ
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# setup.shをダウンロードして実行
curl -fsSL https://raw.githubusercontent.com/sakanahair/base/master/setup.sh -o setup.sh
chmod +x setup.sh
./setup.sh

# 一時ファイルを削除
cd ..
rm -rf "$TEMP_DIR"