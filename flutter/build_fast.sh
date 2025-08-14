#!/bin/bash

# Flutter Web高速ビルドスクリプト

echo "🚀 Flutter Web高速ビルド開始..."

# ビルドモード選択
if [ "$1" = "prod" ]; then
    echo "📦 プロダクションビルド実行中..."
    flutter build web --release --base-href /admin/ --no-tree-shake-icons --web-renderer canvaskit
elif [ "$1" = "debug" ]; then
    echo "🐛 デバッグビルド実行中..."
    flutter build web --debug --base-href /admin/ --web-renderer html
else
    echo "⚡ 開発ビルド実行中（デフォルト）..."
    flutter build web --base-href /admin/ --web-renderer html --no-tree-shake-icons
fi

# ビルド成功確認
if [ $? -eq 0 ]; then
    echo "✅ ビルド成功！"
    
    # Next.jsへコピー
    echo "📂 Next.jsへファイルをコピー中..."
    rm -rf ../next/public/admin/*
    cp -r build/web/* ../next/public/admin/
    
    echo "✨ デプロイ完了！"
    echo "🌐 アクセス: http://localhost:3000/admin/"
else
    echo "❌ ビルドに失敗しました"
    exit 1
fi