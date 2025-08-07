# Flutter + Next.js マルチプラットフォームアプリ

iOS、Android、Webに対応したFlutterアプリケーションとNext.jsの統合環境です。

## 🚀 プロジェクト構成

```
.
├── flutter/           # Flutterアプリケーション
│   ├── lib/           # Flutterソースコード
│   ├── ios/           # iOS設定
│   ├── android/       # Android設定
│   └── web/           # Web設定
├── next/              # Next.jsアプリケーション
│   ├── app/           # Next.js App Router
│   ├── public/        # 静的ファイル
│   │   └── app/       # Flutter Webビルド出力
│   └── dist/          # Next.jsビルド出力
├── script/            # ビルド・開発用スクリプト
│   ├── build.sh       # 統合ビルドスクリプト
│   ├── dev.sh         # 開発サーバー起動
│   └── update-flutter.sh # Flutter更新
└── doc/               # ドキュメント
    └── README.md      # 詳細ドキュメント
```

## 📋 前提条件

- Flutter SDK (3.0以上)
- Node.js (18.0以上)
- Xcode (iOS開発用)
- Android Studio (Android開発用)

## 🛠️ セットアップ

### 1. 依存関係のインストール

```bash
# Flutterの依存関係
cd flutter
flutter pub get

# Next.jsの依存関係
cd ../next
npm install
```

## 🎮 開発

### 開発サーバーの起動

```bash
# ルートディレクトリから
./script/dev.sh
```

これにより：
- Flutter Webの初回ビルド（必要な場合）
- Next.js開発サーバーの起動
- http://localhost:3000 でアクセス可能

### Flutter開発（モバイル）

```bash
cd flutter

# iOS
flutter run -d ios

# Android
flutter run -d android

# Web (スタンドアロン)
flutter run -d chrome
```

### Flutter Webの更新

開発中にFlutter Webを更新する場合：

```bash
./script/update-flutter.sh
```

## 🏗️ ビルド

### 全体ビルド（Flutter + Next.js）

```bash
# ルートディレクトリから
./script/build.sh
```

または

```bash
cd next
npm run build:all
```

### 個別ビルド

#### Flutter
```bash
cd flutter

# iOS
flutter build ios

# Android
flutter build apk
flutter build appbundle

# Web
flutter build web
```

#### Next.js
```bash
cd next
npm run build
```

## 📦 デプロイ

### 静的ホスティング（Vercel、Netlify等）

1. 全体ビルドを実行
```bash
./script/build.sh
```

2. `next/dist`ディレクトリをデプロイ

### Docker

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY . .
RUN ./script/build.sh

FROM nginx:alpine
COPY --from=builder /app/next/dist /usr/share/nginx/html
```

## 🧪 テスト

### Flutter
```bash
cd flutter
flutter test
```

### Next.js
```bash
cd next
npm test
```

## 📝 スクリプト一覧

| スクリプト | 説明 |
|-----------|------|
| `./script/build.sh` | Flutter WebとNext.jsを統合ビルド |
| `./script/dev.sh` | 開発サーバーを起動 |
| `./script/update-flutter.sh` | Flutter Webを再ビルドして更新 |
| `npm run build:all` | Next.js内から統合ビルド |
| `npm run build:flutter` | Flutter Webのみビルド |
| `npm run clean` | ビルドキャッシュをクリア |

## 🌐 アクセスURL

- **Next.jsホーム**: http://localhost:3000
- **Flutter Web**: http://localhost:3000/app/
- **開発ツール**: http://localhost:3000/\_\_nextjs_dev

## 🔧 トラブルシューティング

### Flutter Webが表示されない
```bash
# Flutter Webを再ビルド
./script/update-flutter.sh

# キャッシュクリア
cd next
npm run clean
npm install
./script/dev.sh
```

### ビルドエラー
```bash
# Flutter環境の確認
flutter doctor

# Node.jsバージョン確認
node --version  # 18.0以上

# クリーンビルド
cd flutter
flutter clean
flutter pub get

cd ../next
npm run clean
npm install
```

## 📚 関連ドキュメント

- [Flutter Documentation](https://flutter.dev/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Flutter Web](https://flutter.dev/web)
- [Next.js Deployment](https://nextjs.org/docs/deployment)