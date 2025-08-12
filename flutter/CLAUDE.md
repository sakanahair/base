# CLAUDE.md - AI Assistant Development Guide

このドキュメントは、SAKANA Admin Platformの開発をAIアシスタント（Claude）が効率的に行うためのガイドです。

## プロジェクト概要

- **プロジェクト名**: SAKANA Admin Platform
- **タイプ**: Flutter Web管理ダッシュボード
- **業界**: 美容室・サロン向け
- **デプロイ先**: Next.js (`/admin/` パス)

## 重要な設定・注意事項

### 1. Base Href 設定
```bash
# ビルド時は必ず --base-href を指定
flutter build web --base-href /admin/

# index.htmlの確認
<base href="/admin/">  # これが正しい設定
```

### 2. Firebase設定
- `firebase_options.dart`は自動生成ファイル
- Firebase Consoleで認証プロバイダーを有効化必要
- マルチテナント対応のため、tenantIdでデータを分離

### 3. ハイブリッドキャッシングシステム
- 全データはLocalStorage優先で高速表示
- Firebaseは永続化とデバイス間同期用
- オフライン対応必須
- 差分同期でFirebase読み取り回数を最小化

## アーキテクチャ

### データフロー
```
ユーザー操作
    ↓
LocalStorage（即座に保存）
    ↓
UI更新（即座に反映）
    ↓
Firebase同期（バックグラウンド）
    ↓
他端末へリアルタイム反映
```

### 権限階層
1. **Super Admin** - システム全体管理、王冠バッジ表示
2. **Site Admin** - 店舗管理
3. **End User** - スタッフ

## 開発コマンド

### 日常的に使うコマンド
```bash
# 開発サーバー起動
flutter run -d chrome

# ビルド＆デプロイ
flutter build web --base-href /admin/
cp -r build/web/* ../next/public/admin/

# クリーンビルド
flutter clean
flutter pub get
flutter build web --base-href /admin/

# テスト実行
flutter test
```

### トラブルシューティング
```bash
# キャッシュクリア
flutter clean
flutter pub cache clean
flutter pub get

# Firebase再設定
flutterfire configure
```

## コーディング規約

### 1. 日本語対応
- UIテキストは日本語
- コメントは日本語OK
- 変数名・関数名は英語

### 2. 状態管理
- Provider使用
- ChangeNotifierを継承
- notifyListeners()で更新通知

### 3. 非同期処理
```dart
// 必ずasync/awaitを使用
Future<void> saveData() async {
  await _saveToLocalStorage();  // ローカル保存
  await _saveToFirebase();       // Firebase同期
}
```

### 4. エラーハンドリング
```dart
try {
  // 処理
} catch (e) {
  print('Error: $e');
  // オフラインキューに追加など
}
```

## 主要ファイル構成

### サービスクラス（ビジネスロジック）
- `lib/core/services/hybrid_cache_service.dart` - 基底クラス
- `lib/core/services/customer_service.dart` - 顧客管理
- `lib/core/services/simplified_auth_service.dart` - 認証

### UIページ
- `lib/features/chat/presentation/pages/chat_list_page.dart` - チャット一覧
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` - ダッシュボード
- `lib/shared/layouts/admin_layout.dart` - 共通レイアウト

### ルーティング
- `lib/core/router/app_router.dart` - ルート定義

## 実装パターン

### 1. 新規サービス作成
```dart
class XxxService extends HybridCacheService<Model> {
  @override
  String get collectionName => 'xxx';
  
  @override
  String get localStorageKey => 'sakana_xxx';
  
  // 実装必須メソッド
}
```

### 2. UI更新パターン
```dart
Consumer<XxxService>(
  builder: (context, service, child) {
    return Widget(
      // serviceのデータを使用
    );
  },
)
```

### 3. 顧客タグ管理
- 「顧客」タグは自動付与
- 業種により「友だち」「お客様」に変更可能
- タグによる検索・フィルター対応

## よくあるタスク

### 新機能追加時のチェックリスト
- [ ] LocalStorage対応
- [ ] Firebase同期実装
- [ ] オフライン動作確認
- [ ] 権限チェック実装
- [ ] 日本語UI
- [ ] レスポンシブ対応
- [ ] エラーハンドリング

### デバッグ時の確認事項
1. Chrome DevToolsでLocalStorageを確認
2. Firebase Consoleでデータ確認
3. Network切断してオフライン動作確認
4. 複数タブで同期確認

## 現在の実装状況

### 完了済み
- ✅ Firebase認証（Email/Password）
- ✅ マルチテナント対応
- ✅ Super Admin機能（王冠バッジ）
- ✅ 顧客管理（ハイブリッドキャッシング）
- ✅ チャット機能（マルチチャンネル）
- ✅ タグ管理システム

### 実装予定
- ⏳ 予約管理システム
- ⏳ スタッフ管理
- ⏳ 売上分析
- ⏳ プッシュ通知
- ⏳ LINE連携

## トラブルシューティング

### Firebase認証が動作しない
1. `firebase_options.dart`を確認
2. Firebase Consoleで認証を有効化
3. `flutterfire configure`を再実行

### ビルドエラー
1. `flutter clean`
2. `flutter pub get`
3. Dart SDKバージョン確認

### データが保存されない
1. LocalStorageの容量確認
2. Firebase Security Rules確認
3. tenantIdが正しく設定されているか確認

## 連絡先・リソース

- Firebase Console: https://console.firebase.google.com
- Flutter Docs: https://docs.flutter.dev
- 開発環境: http://localhost:3000/admin/

---

最終更新: 2025年1月
バージョン: 1.0.0