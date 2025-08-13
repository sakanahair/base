# Firebase iOS/Android セットアップガイド

## iOS/AndroidでFirebaseを有効にする手順

### 1. Firebase Consoleでアプリを追加

1. [Firebase Console](https://console.firebase.google.com)にアクセス
2. プロジェクトを選択
3. 「アプリを追加」をクリック

### 2. iOS設定

```bash
# iOS Bundle IDを確認
open ios/Runner.xcworkspace
# Xcode > Runner > General > Bundle Identifier を確認
# 例: com.example.sakanaAdmin

# Firebase ConsoleでiOSアプリを追加
# 1. Appleアイコンをクリック
# 2. Bundle IDを入力
# 3. GoogleService-Info.plistをダウンロード

# ダウンロードしたファイルを配置
cp ~/Downloads/GoogleService-Info.plist ios/Runner/

# Xcodeで追加
# 1. Xcodeでios/Runner.xcworkspaceを開く
# 2. RunnerフォルダにGoogleService-Info.plistをドラッグ&ドロップ
# 3. "Copy items if needed"にチェック
```

### 3. Android設定

```bash
# Android Package Nameを確認
cat android/app/build.gradle | grep applicationId
# 例: com.example.sakana_admin

# Firebase ConsoleでAndroidアプリを追加
# 1. Androidアイコンをクリック
# 2. Package Nameを入力
# 3. google-services.jsonをダウンロード

# ダウンロードしたファイルを配置
cp ~/Downloads/google-services.json android/app/
```

### 4. FlutterFireの再設定

```bash
# FlutterFire CLIで設定
flutterfire configure

# プラットフォームを選択
# ✓ ios
# ✓ android
# ✓ web

# 自動的に設定ファイルが更新される
```

### 5. main.dartを更新

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // すべてのプラットフォームでFirebaseを初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully for ${Platform.operatingSystem}');
  } catch (e) {
    print('Firebase initialization error: $e');
    // エラーが発生してもアプリは続行（LocalStorageで動作）
  }
  
  runApp(const SakanaAdminApp());
}
```

---

## 選択肢2: Web専用アプリとして運用（現在の設定）

現在の実装では、**Webブラウザでのみ**Firebaseが動作します。

### メリット
- iOS/Android端末でもブラウザから利用可能
- PWA対応でアプリのような体験
- 設定がシンプル

### デメリット
- ネイティブアプリ特有の機能が使えない
- App Store/Google Playでの配布不可

---

## 選択肢3: ハイブリッド運用

```dart
// プラットフォーム別の処理
if (kIsWeb) {
  // WebではFirebase使用
  await _saveToFirebase(data);
} else {
  // モバイルではAPI経由でサーバーと通信
  await _saveToAPI(data);
}
```

---

## 推奨事項

**現在のプロジェクトの用途を考慮すると：**

1. **管理画面として使用** → Web専用で十分（現在の設定でOK）
2. **スタッフがモバイルアプリとして使用** → Firebase設定を追加
3. **開発・テスト用** → 現在の設定で問題なし

Firebase設定を追加したい場合は、上記の手順に従ってください。