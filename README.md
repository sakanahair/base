# 🐟 SAKANA AI

美容室・サロン向け統合管理システム（Flutter × Next.js × Firebase）

## 🚀 クイックスタート

### ワンライナーインストール（推奨）
```bash
git clone https://github.com/sakanahair/base.git SAKANA_AI && cd SAKANA_AI && ./setup.sh
```

30秒で開発環境が整います！

## 📋 目次

- [概要](#概要)
- [機能](#機能)
- [アーキテクチャ](#アーキテクチャ)
- [技術スタック](#技術スタック)
- [インストール](#インストール)
- [開発](#開発)
- [デプロイ](#デプロイ)
- [データ管理](#データ管理)
- [ドキュメント](#ドキュメント)

## 🎯 概要

SAKANA AIは、美容室・サロン向けの統合管理システムです。顧客管理、予約管理、サービス管理などを一元化し、業務効率を大幅に向上させます。

### 特徴
- **マルチプラットフォーム**: iOS/Android/Web対応
- **リアルタイム同期**: Firebaseによるデータの即時同期
- **オフライン対応**: ローカルキャッシュで快適な操作
- **マルチテナント**: 複数店舗の管理に対応
- **自動デプロイ**: ConoHa VPSへのワンコマンドデプロイ

## ✨ 機能

### 管理機能
- **顧客管理**: 顧客情報、施術履歴、タグ管理
- **サービス管理**: メニュー、価格、画像管理
- **予約管理**: スケジュール、リマインダー
- **スタッフ管理**: 権限管理、シフト管理
- **売上分析**: レポート、グラフ表示

### 技術的特徴
- **Firebase優先アーキテクチャ**: データの一貫性を保証
- **リアルタイム同期**: 複数デバイス間での即時反映
- **テーマ設定共有**: 同一アカウントで色設定を共通化
- **画像最適化**: 自動圧縮、CDN配信

## 🏗 アーキテクチャ

### システム構成
```
┌─────────────────────────────────────────────┐
│             ユーザーアクセス                 │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│        Cloudflare (CDN/WAF/Cache)           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      ConoHa VPS (dev.sakana.hair)          │
│  ┌─────────────────────────────────────┐   │
│  │     Nginx (Reverse Proxy)           │   │
│  └─────────────────────────────────────┘   │
│            ↓            ↓                   │
│  ┌──────────────┐  ┌──────────────┐       │
│  │   Next.js    │  │  Flutter Web │       │
│  │   (Port 3000)│  │   (/admin)   │       │
│  └──────────────┘  └──────────────┘       │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│              Firebase Services              │
│  ├─ Authentication (認証)                   │
│  ├─ Firestore (データベース)                │
│  └─ Storage (画像・ファイル)                │
└─────────────────────────────────────────────┘
```

### データフロー（2025年1月改訂）
```
ユーザー操作
    ↓
Firebase（真実の源）
    ↓
リアルタイムリスナー
    ↓
LocalStorage（キャッシュ）
    ↓
UI更新
```

**重要**: Firebaseが単一の真実の源（Single Source of Truth）です。

## 🛠 技術スタック

### フロントエンド
- **Flutter Web**: 管理画面（/admin）
- **Next.js 14**: ランディングページ、マーケティング
- **TypeScript**: 型安全性
- **Tailwind CSS**: スタイリング

### バックエンド
- **Firebase Auth**: 認証・権限管理
- **Cloud Firestore**: リアルタイムデータベース
- **Firebase Storage**: 画像・ファイル管理
- **Cloud Functions**: サーバーレス処理

### インフラ
- **ConoHa VPS**: ホスティング
- **Cloudflare**: CDN、WAF、キャッシュ
- **Nginx**: リバースプロキシ
- **PM2**: プロセス管理
- **Mutagen**: ファイル同期

## 💾 データ管理

### Firebase優先の原則（2025年1月実装）

#### 1. 読み取り
```dart
// Firebaseから直接読み込み
await loadFromFirebase();
// LocalStorageはフォールバックのみ
if (offline) await loadFromLocalStorage();
```

#### 2. 書き込み
```dart
// 必ずFirebaseに先に保存
await saveToFirebase(data);
// 成功後にLocalStorageを更新
await updateLocalCache(data);
```

#### 3. リアルタイム同期
```dart
// Firestoreリスナーで自動同期
FirebaseFirestore.instance
  .collection('data')
  .snapshots()
  .listen((snapshot) => updateLocalFromFirebase(snapshot));
```

### テナント構造
```
tenants/
  └── [uid]/
      ├── services/    # サービス情報
      ├── customers/   # 顧客情報
      └── settings/    # 設定情報
          └── theme/   # テーマ設定（共有）
```

## 🚀 インストール

### 必要要件
- Node.js 18+
- Flutter 3.0+
- Firebase プロジェクト
- ConoHa VPS（本番環境）

### セットアップ
```bash
# リポジトリのクローン
git clone https://github.com/yourusername/sakana-ai.git
cd sakana-ai

# 自動セットアップ
./setup.sh

# または手動セットアップ
cd flutter && flutter pub get
cd ../next && npm install
```

### 環境変数
```bash
# .env.local
NEXT_PUBLIC_FIREBASE_API_KEY=your_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your_auth_domain
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project_id
```

## 🔧 開発

### 開発サーバー起動
```bash
# Next.js
cd next && npm run dev

# Flutter
cd flutter && flutter run -d chrome --web-port=5001
```

### ビルド
```bash
# Flutter Web
cd flutter && flutter build web --base-href /admin/

# Next.js
cd next && npm run build
```

## 📦 デプロイ

### 自動デプロイ
```bash
./scripts/deploy.sh
```

### 手動デプロイ
```bash
# ビルド
cd flutter && flutter build web --base-href /admin/
cd ../next && npm run build

# Mutagen同期
mutagen sync create . root@your-server:/var/www/sakana

# サーバーでPM2起動
pm2 start ecosystem.config.js
```

## 📚 ドキュメント

### 開発者向け
- [CLAUDE.md](./CLAUDE.md) - AI開発ガイド、技術的決定事項
- [アーキテクチャ設計書](./docs/architecture.md)
- [API仕様書](./docs/api.md)

### 運用者向け
- [運用マニュアル](./docs/operation.md)
- [トラブルシューティング](./docs/troubleshooting.md)

## 🔐 セキュリティ

- Firebase Security Rules による厳格なアクセス制御
- Cloudflare WAF による攻撃防御
- 環境変数による機密情報管理
- HTTPS必須

## 📝 ライセンス

Proprietary - All Rights Reserved

## 🤝 貢献

プルリクエストを歓迎します。大きな変更の場合は、まずissueを開いて変更内容を議論してください。

## 📞 サポート

- GitHub Issues: バグ報告、機能リクエスト
- Email: support@sakana.hair

---

最終更新: 2025年1月14日
バージョン: 2.0.0