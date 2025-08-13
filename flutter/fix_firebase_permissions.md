# Firebase権限エラーの修正手順

## 問題
Firebase Firestoreで以下のエラーが発生しています：
```
[cloud_firestore/permission-denied] Missing or insufficient permissions.
```

## 解決手順

### 1. Firebase Consoleにアクセス
https://console.firebase.google.com/project/sakana-76364/overview

### 2. Firestoreのルールを確認
左メニューから「Firestore Database」→「ルール」を選択

### 3. 一時的に権限を開放（開発環境のみ）
以下のルールをコピーして貼り付け、「公開」をクリック：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 一時的に全てのアクセスを許可（開発環境のみ）
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**重要**: これは開発環境でのテスト用です。本番環境では絶対に使用しないでください。

### 4. 本番環境用のルール（後で適用）
開発が完了したら、以下のルールに戻してください：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isSuperAdmin() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated() && (request.auth.uid == userId || isSuperAdmin());
      allow delete: if isSuperAdmin();
    }
    
    // UserTags collection  
    match /userTags/{tagId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Memos collection
    match /memos/{memoId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Customers collection
    match /customers/{customerId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // その他のコレクション
    match /{document=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

### 5. アプリケーションを再起動
ブラウザをリロードして、エラーが解消されたか確認してください。

## デバッグ情報

### 現在のユーザー情報を確認
ブラウザのコンソールで以下を実行：
```javascript
// Firebaseの認証状態を確認
firebase.auth().currentUser
```

### ユーザードキュメントの作成
もしユーザードキュメントが存在しない場合、手動で作成：
1. Firebase Console → Firestore Database
2. `users`コレクションを作成
3. ドキュメントIDは認証されたユーザーのUID
4. 以下のフィールドを追加：
   - email: ユーザーのメール
   - name: ユーザー名
   - role: "super_admin"
   - isActive: true

## テスト用アカウント
```
Email: admin@sakana.hair
Password: Pass12345
```

このアカウントでログインして動作確認してください。