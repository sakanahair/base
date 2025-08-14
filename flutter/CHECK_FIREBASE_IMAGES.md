# Firebase画像同期チェックリスト

## 問題
- Flutter Webアプリで画像をアップロードしている
- サービス自体はiOSアプリと同期している
- しかし、画像がiOSアプリで「画像がありません」と表示される

## 確認事項

### 1. Firebase Console確認
1. Firebase Console (https://console.firebase.google.com) を開く
2. Firestoreデータベースを選択
3. `tenants` → `[tenantId]` → `services` コレクションを確認
4. 各サービスドキュメントの `images` フィールドを確認
   - 配列として Firebase Storage URLが保存されているか？
   - URLの形式: `https://firebasestorage.googleapis.com/...`

### 2. デバッグログ確認（Web側）
画像アップロード時:
```
Firebase upload successful: [URL]
Firebase URL will be used for service: [serviceId]
```

サービス保存時:
```
Saving service to Firebase: [serviceId]
Service images: [URLs]
Service saved to Firebase successfully
```

編集時:
```
Valid Firebase URLs: [URLs]
Number of valid Firebase URLs: [count]
Service synced with Firebase - images should be available on iOS app
```

### 3. iOS側の確認項目
1. **Firestore読み取り**
   - iOS側でFirestoreから `images` フィールドを正しく読み取っているか？
   - ServiceModelの実装でimagesフィールドがマッピングされているか？

2. **Firebase Storage権限**
   - iOS側でFirebase StorageのURLにアクセスできるか？
   - CORS設定は適用済み（すべてのオリジンを許可）

3. **iOS側のServiceModel実装例**
```swift
struct ServiceModel {
    let id: String
    let name: String
    let images: [String] // Firebase Storage URLs
    // ... other fields
    
    init(from document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.images = data["images"] as? [String] ?? []
        // ... other fields
    }
}
```

## トラブルシューティング

### 画像URLがFirestoreに保存されていない場合
1. Web側でサービスを編集
2. 画像を再アップロード
3. 保存ボタンをクリック
4. コンソールでログを確認

### 画像URLは保存されているがiOSで表示されない場合
1. iOS側のコードでimagesフィールドを正しく読み取っているか確認
2. iOS側でFirebase Storage URLを正しく処理しているか確認
3. ネットワーク権限やInfo.plistの設定を確認

### Firebase Storage CORS設定（適用済み）
```json
[{
  "origin": ["*"],
  "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
  "maxAgeSeconds": 3600,
  "responseHeader": ["*"]
}]
```

適用コマンド（実行済み）:
```bash
gsutil cors set cors.json gs://[YOUR_BUCKET_NAME]
```

## 現在の実装状況

### Web側（Flutter Web）
- ✅ 画像アップロード時にFirebase StorageにアップロードしてURLを取得
- ✅ サービス保存時にFirebase URLをFirestoreに保存
- ✅ 編集時にもFirebase URLを保持して保存
- ✅ 削除時にFirebaseから確実に削除
- ✅ Firebase同期時に削除済みサービスを反映

### 必要な対応（iOS側）
- ⚠️ iOS側のServiceModelでimagesフィールドを正しくマッピング
- ⚠️ Firebase Storage URLから画像を表示する実装
- ⚠️ キャッシュ機能の実装（オプション）

## テスト手順
1. Web側で新しいサービスを作成し、画像をアップロード
2. Firebase Consoleでサービスドキュメントを確認
3. `images`フィールドにFirebase Storage URLが含まれているか確認
4. iOS側でサービス一覧を更新
5. 画像が表示されるか確認