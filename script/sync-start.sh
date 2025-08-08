#!/bin/bash

# Mutagen同期開始スクリプト
# Usage: ./script/sync-start.sh

# スクリプトのディレクトリから相対的にプロジェクトルートを決定
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER="root@dev.sakana"
REMOTE_ROOT="/var/www/sakana"

echo "🔄 Mutagen同期を開始します..."

# 既存のセッションを確認
if mutagen sync list | grep -q sakana; then
    echo "既存のセッションが見つかりました。"
    echo "セッションを再開します..."
    mutagen sync resume sakana
else
    echo "新しい同期セッションを作成します..."
    mutagen sync create \
        $PROJECT_ROOT \
        $SERVER:$REMOTE_ROOT \
        --name=sakana \
        --mode=two-way-resolved \
        --ignore-vcs \
        --ignore="node_modules/" \
        --ignore=".next/" \
        --ignore="dist/" \
        --ignore=".git/" \
        --ignore="*.log" \
        --ignore=".env.local" \
        --ignore=".DS_Store"
fi

echo ""
echo "✅ 同期が開始されました！"
echo ""
echo "同期状態を確認: mutagen sync list"
echo "同期を監視: mutagen sync monitor sakana"
echo "同期を停止: ./script/sync-stop.sh"