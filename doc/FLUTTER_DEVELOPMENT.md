# 📱 Flutter マルチプラットフォーム開発ガイド

Mac/Ubuntu両環境でのFlutter開発を完全サポート

## 🌍 プラットフォーム別開発環境

### macOS環境
- ✅ **iOS開発**: 完全サポート（実機/シミュレータ）
- ✅ **Android開発**: 完全サポート（実機/エミュレータ）  
- ✅ **Web開発**: 完全サポート（Chrome/Safari/Firefox）

### Ubuntu/Linux環境
- ❌ **iOS開発**: 不可（Appleの制限により）
- ✅ **Android開発**: 完全サポート（実機/エミュレータ）
- ✅ **Web開発**: 完全サポート（Chrome/Firefox）

## 🚀 クイックスタート

### 1. 環境セットアップ

```bash
# 自動セットアップ（Flutter含む）
./setup.sh
```

### 2. Flutter開発ツールを起動

```bash
# インタラクティブな開発ツール
./script/flutter-dev.sh
```

このツールから以下が可能：
- Web開発サーバー起動
- Android/iOS開発
- 全プラットフォームビルド
- 環境診断（Flutter Doctor）

### 3. 統合ビルド（Flutter + Next.js）

```bash
# Flutter WebをNext.jsに統合してビルド
./script/build.sh
```

## 📋 開発ワークフロー

### Ubuntu環境での開発フロー

1. **開発環境構築**
   ```bash
   # Ubuntuでセットアップ
   ./setup.sh
   # → Flutter（Web/Android）がインストールされます
   ```

2. **Web開発**
   ```bash
   cd flutter
   flutter run -d chrome --web-port 5000
   ```

3. **Android開発**
   ```bash
   # Android Studioでエミュレータ起動後
   cd flutter
   flutter run -d android
   ```

4. **ビルド**
   ```bash
   # Web + Android APK
   ./script/build.sh
   ```

### Mac環境での開発フロー

1. **iOS開発**
   ```bash
   cd flutter
   # シミュレータ起動
   open -a Simulator
   # アプリ実行
   flutter run -d ios
   ```

2. **クロスプラットフォームビルド**
   ```bash
   # iOS/Android/Web全てビルド
   ./script/flutter-dev.sh
   # オプション4を選択
   ```

## 🔄 Mac ↔ Ubuntu 連携開発

### 推奨ワークフロー

1. **Ubuntu環境（主開発）**
   - Web UIの開発・テスト
   - Android版の開発・テスト
   - ビジネスロジックの実装
   - 単体テスト実行

2. **Mac環境（iOS専用）**
   - iOSビルド・テスト
   - App Store申請用ビルド
   - iOS固有の不具合修正

### 同期方法

```bash
# Ubuntuで開発後
git add .
git commit -m "Feature implementation on Ubuntu"
git push

# Macで取得
git pull
./script/build.sh
# iOS固有の作業を実施
```

## 🛠️ プラットフォーム別ビルドコマンド

### Web（Ubuntu/Mac両対応）
```bash
flutter build web --release --base-href /app/
```

### Android（Ubuntu/Mac両対応）
```bash
# APK（直接インストール用）
flutter build apk --release

# App Bundle（Google Play用）
flutter build appbundle --release
```

### iOS（Macのみ）
```bash
# 開発ビルド
flutter build ios --debug

# リリースビルド（要署名）
flutter build ios --release
```

## 📦 ビルド成果物の場所

| プラットフォーム | ビルドタイプ | 出力先 |
|--------------|------------|--------|
| Web | Release | `build/web/` |
| Android | APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Android | App Bundle | `build/app/outputs/bundle/release/app-release.aab` |
| iOS | Release | `build/ios/archive/` (Xcodeでアーカイブ後) |

## 🔍 トラブルシューティング

### Ubuntu環境

#### Android開発環境が動かない
```bash
# Android開発ツールをインストール
sudo apt-get install -y android-sdk

# ライセンス承認
flutter doctor --android-licenses

# 環境確認
flutter doctor
```

#### Chrome/Chromiumが見つからない
```bash
# Chromiumをインストール
sudo apt-get install chromium-browser

# または Google Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt-get update
sudo apt-get install google-chrome-stable
```

### Mac環境

#### iOS開発者証明書エラー
```bash
# Xcodeで証明書を設定
open ios/Runner.xcworkspace

# 自動署名を有効化
# Xcode > Signing & Capabilities > Automatically manage signing
```

#### CocoaPodsエラー
```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

## 📊 パフォーマンス最適化

### プロファイルモードでの実行
```bash
# パフォーマンス測定用
flutter run --profile

# リリースモードでのテスト
flutter run --release
```

### ビルドサイズ最適化
```bash
# Webビルド最適化
flutter build web --release --tree-shake-icons

# Android APKサイズ削減
flutter build apk --split-per-abi
```

## 🧪 テスト実行

```bash
# 単体テスト
flutter test

# ウィジェットテスト
flutter test test/widget_test.dart

# インテグレーションテスト
flutter drive --target=test_driver/app.dart
```

## 📚 参考リンク

- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [Flutter Web](https://flutter.dev/web)
- [Flutter on Ubuntu](https://flutter.dev/docs/get-started/install/linux)
- [Android Studio Setup](https://developer.android.com/studio/install)

---

最終更新: 2025年8月9日