#!/bin/bash

# 統一されたビルドスクリプト（Web & iOS）

echo "🔨 Building Flutter app for Web and iOS..."

# Flutter クリーンビルド
echo "📦 Cleaning previous builds..."
flutter clean
flutter pub get

# Web ビルド
echo "🌐 Building for Web..."
flutter build web --base-href /admin/ --release

# iOS ビルド（Mac環境でのみ実行）
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Building for iOS..."
    flutter build ios --release
    
    echo "✅ iOS build completed!"
    echo "📍 iOS build location: build/ios/iphoneos/"
fi

# Next.jsのpublicディレクトリにコピー
echo "📂 Copying Web build to Next.js..."
rm -rf ../next/public/admin/*
cp -r build/web/* ../next/public/admin/

echo "✅ Build completed!"
echo ""
echo "📊 Build Summary:"
echo "  - Web: build/web/ → ../next/public/admin/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "  - iOS: build/ios/iphoneos/"
fi
echo ""
echo "🎨 Design is unified across all platforms:"
echo "  - Material Design 3"
echo "  - Same theme colors"
echo "  - Same font sizes and weights"
echo "  - Same component styles"