#!/bin/bash

# Flutter Web開発サーバー起動スクリプト

echo "🔥 Flutter開発サーバー起動中..."
echo "📝 ホットリロード有効"
echo ""

# ポート指定（デフォルト: 5000）
PORT=${1:-5000}

# Chrome で開発サーバー起動
flutter run -d chrome --web-port=$PORT --web-hostname=localhost

# 終了時メッセージ
echo ""
echo "👋 開発サーバーを終了しました"