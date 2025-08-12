# SAKANA Admin Platform

Flutter Web管理ダッシュボード - 美容室・サロン向け統合管理システム

## 概要

SAKANA Admin Platformは、美容室やサロン向けの統合管理システムです。顧客管理、予約管理、チャット機能、スタッフ管理などを一元化し、効率的な店舗運営を支援します。

## 主な機能

### 🔐 認証・権限管理
- **マルチテナント対応** - 複数店舗の管理が可能
- **3階層の権限システム**
  - Super Admin（システム管理者）
  - Site Admin（店舗管理者）
  - End User（スタッフ）
- **Firebase Authentication** - セキュアな認証基盤

### 💬 チャット機能
- **マルチチャンネル対応** - LINE、SMS、WebChat、アプリ
- **リアルタイムメッセージング**
- **顧客タグ管理** - 効率的な顧客分類
- **グループチャット対応**

### 👥 顧客管理
- **顧客情報の一元管理**
- **来店履歴・利用金額の追跡**
- **タグによる顧客分類**
- **ハイブリッドキャッシング** - 高速表示とオフライン対応

### 📅 予約管理
- **カレンダービュー**
- **スタッフ別予約管理**
- **リマインダー機能**

### 📊 分析・レポート
- **売上分析**
- **顧客動向分析**
- **スタッフパフォーマンス**

### 🎨 カスタマイズ
- **テーマカラー変更**
- **業種別カスタマイズ** - 美容室、エステ、ネイルサロン対応
- **ロゴ・ブランディング設定**

## 技術スタック

### フロントエンド
- **Flutter 3.8.1+** - クロスプラットフォーム対応
- **Provider** - 状態管理
- **Go Router** - ナビゲーション
- **Material Design 3** - UIコンポーネント

### バックエンド
- **Firebase**
  - Firestore - NoSQLデータベース
  - Authentication - 認証
  - Cloud Messaging - プッシュ通知
- **Next.js** - Webホスティング（/admin/）

### データ管理
- **ハイブリッドキャッシングシステム**
  - LocalStorage - 高速読み込み
  - Firebase - データ永続化・同期
  - オフラインキュー - ネットワーク切断時対応

## セットアップ

### 必要環境
- Flutter SDK 3.8.1以上
- Node.js 18以上
- Firebase プロジェクト

### インストール手順

1. リポジトリのクローン
```bash
git clone [repository-url]
cd flutter
```

2. 依存関係のインストール
```bash
flutter pub get
```

3. Firebase設定
```bash
# Firebase CLIのインストール
npm install -g firebase-tools

# Firebaseログイン
firebase login

# FlutterFire CLIのインストール
dart pub global activate flutterfire_cli

# Firebase設定の生成
flutterfire configure
```

4. 開発サーバーの起動
```bash
flutter run -d chrome
```

### ビルド

Web用ビルド（Next.jsへのデプロイ）
```bash
flutter build web --base-href /admin/
cp -r build/web/* ../next/public/admin/
```

## プロジェクト構造

```
lib/
├── core/
│   ├── router/          # ルーティング設定
│   ├── services/        # ビジネスロジック
│   │   ├── hybrid_cache_service.dart  # ハイブリッドキャッシング基盤
│   │   ├── customer_service.dart      # 顧客管理
│   │   ├── auth_service.dart          # 認証
│   │   └── ...
│   ├── theme/           # テーマ設定
│   └── utils/           # ユーティリティ
├── features/
│   ├── auth/            # 認証機能
│   ├── chat/            # チャット機能
│   ├── customers/       # 顧客管理
│   ├── dashboard/       # ダッシュボード
│   ├── appointments/    # 予約管理
│   └── ...
├── shared/
│   ├── layouts/         # レイアウトコンポーネント
│   └── widgets/         # 共通ウィジェット
└── main.dart            # エントリーポイント
```

## 開発ガイドライン

### コード規約
- Flutter公式のlintルールに従う
- 日本語コメントを適切に使用
- コンポーネントは再利用可能に設計

### Git フロー
- main - 本番環境
- develop - 開発環境
- feature/* - 機能開発
- hotfix/* - 緊急修正

### テスト
```bash
# ユニットテスト
flutter test

# 統合テスト
flutter test integration_test
```

## デプロイ

### Next.js（本番環境）
```bash
# Flutter Webビルド
flutter build web --base-href /admin/

# Next.jsへコピー
cp -r build/web/* ../next/public/admin/

# Next.jsデプロイ
cd ../next
npm run build
npm run deploy
```

## トラブルシューティング

### よくある問題

1. **Firebase認証エラー**
   - Firebase Consoleで認証プロバイダーが有効になっているか確認
   - firebase_options.dartが正しく生成されているか確認

2. **ビルドエラー**
   - `flutter clean`を実行
   - `flutter pub get`で依存関係を再インストール

3. **base href問題**
   - index.htmlの`<base href="/admin/">`を確認
   - ビルド時に`--base-href /admin/`オプションを指定

## ライセンス

Proprietary - SAKANA AI

## サポート

- 技術的な質問: dev@sakana.ai
- バグ報告: GitHub Issues
- ドキュメント: docs.sakana.ai
