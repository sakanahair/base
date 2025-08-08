#!/bin/bash

# Mutagen同期停止スクリプト
# Usage: ./script/sync-stop.sh

echo "⏸️  Mutagen同期を停止します..."

if mutagen sync list | grep -q sakana; then
    mutagen sync pause sakana
    echo "✅ 同期が停止されました。"
    echo ""
    echo "同期を再開するには: ./script/sync-start.sh"
    echo "同期を完全に削除するには: mutagen sync terminate sakana"
else
    echo "⚠️  アクティブな同期セッションが見つかりません。"
fi

echo ""
mutagen sync list