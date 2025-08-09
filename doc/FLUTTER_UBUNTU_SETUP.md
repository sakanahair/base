# 🐧 Flutter Ubuntu完全セットアップガイド

UbuntuでFlutter開発環境を構築するための詳細ガイド

## 📋 前提条件

### システム要件
- **OS**: Ubuntu 20.04 LTS以上（22.04/24.04推奨）
- **メモリ**: 8GB以上（16GB推奨）
- **ディスク**: 10GB以上の空き容量
- **CPU**: 64ビットプロセッサ

### 開発可能なプラットフォーム
| プラットフォーム | Ubuntu対応 | 備考 |
|--------------|-----------|------|
| Flutter Web | ✅ 完全対応 | Chrome/Firefox必要 |
| Android | ✅ 完全対応 | Android Studio必要 |
| Linux Desktop | ✅ 完全対応 | GTK開発ライブラリ必要 |
| iOS | ❌ 非対応 | Macが必須 |
| macOS | ❌ 非対応 | Macが必須 |
| Windows | ⚠️ クロスコンパイル可能 | 制限あり |

## 🚀 インストール方法

### 方法1: 自動インストール（推奨）

```bash
# プロジェクトのセットアップスクリプトを使用
./setup.sh

# または専用インストーラーを使用
./script/install-flutter-ubuntu.sh
```

### 方法2: Snap版インストール（最も簡単）

```bash
# Snapパッケージでインストール
sudo snap install flutter --classic

# パスを通す
export PATH="$PATH:/snap/bin"
echo 'export PATH="$PATH:/snap/bin"' >> ~/.bashrc

# 確認
flutter --version
```

**メリット:**
- 自動更新
- 依存関係の自動管理
- アンインストールが簡単

**デメリット:**
- カスタマイズが制限される
- 一部の環境で動作が遅い場合がある

### 方法3: Git版インストール（推奨・柔軟性高）

```bash
# 1. 必要なパッケージをインストール
sudo apt-get update
sudo apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    clang cmake ninja-build pkg-config libgtk-3-dev

# 2. Flutterをクローン
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# 3. パスを設定
export PATH="$PATH:$HOME/flutter/bin"
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc

# 4. 確認
flutter doctor
```

### 方法4: 手動ダウンロード

```bash
# 1. 最新版をダウンロード
cd /tmp
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz

# 2. 展開
sudo tar -xf flutter_linux_*.tar.xz -C /opt/

# 3. 権限設定
sudo chown -R $USER:$USER /opt/flutter

# 4. パス設定
export PATH="$PATH:/opt/flutter/bin"
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
```

## 🔧 Android開発環境セットアップ

### Android Studioインストール

#### 方法A: Snap版（推奨）
```bash
sudo snap install android-studio --classic
```

#### 方法B: 手動インストール
```bash
# ダウンロード
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.26/android-studio-2023.1.1.26-linux.tar.gz

# 展開
sudo tar -xzf android-studio-*.tar.gz -C /opt/

# 起動
/opt/android-studio/bin/studio.sh
```

### Android SDK設定

1. **Android Studioを起動**
   ```bash
   android-studio  # Snap版
   # または
   /opt/android-studio/bin/studio.sh  # 手動版
   ```

2. **セットアップウィザード完了**
   - Standard設定を選択
   - Android SDKをインストール

3. **環境変数設定**
   ```bash
   # ~/.bashrcに追加
   export ANDROID_HOME=$HOME/Android/Sdk
   export PATH=$PATH:$ANDROID_HOME/emulator
   export PATH=$PATH:$ANDROID_HOME/platform-tools
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
   ```

4. **ライセンス承認**
   ```bash
   flutter doctor --android-licenses
   ```

## 🌐 Web開発環境セットアップ

### Chromeインストール

```bash
# Chromium（オープンソース版）
sudo apt-get install chromium-browser

# または Google Chrome（公式版）
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo apt-get update
sudo apt-get install google-chrome-stable
```

### Web開発の開始

```bash
# プロジェクトディレクトリへ移動
cd flutter

# Web開発サーバー起動
flutter run -d chrome --web-port 5000

# ホットリロード: 'r'キー
# ホットリスタート: 'R'キー
```

## 🖥️ Linux Desktop開発

### 必要なパッケージ

```bash
sudo apt-get install -y \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev libstdc++-12-dev
```

### Linux アプリ実行

```bash
# Linux desktop アプリとして実行
flutter run -d linux

# ビルド
flutter build linux
```

## 💻 VS Code設定

### インストール

```bash
# Snap版
sudo snap install code --classic

# または .deb版
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code
```

### 拡張機能インストール

```bash
# Flutter/Dart拡張機能
code --install-extension Dart-Code.flutter
code --install-extension Dart-Code.dart-code

# その他便利な拡張機能
code --install-extension usernamehw.errorlens
code --install-extension Gruntfuggly.todo-tree
```

### VS Code設定（settings.json）

```json
{
  "dart.flutterSdkPath": "$HOME/flutter",
  "dart.sdkPath": "$HOME/flutter/bin/cache/dart-sdk",
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "[dart]": {
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

## 🔍 トラブルシューティング

### よくある問題と解決方法

#### 1. "flutter: command not found"
```bash
# パスが通っていない
export PATH="$PATH:$HOME/flutter/bin"
source ~/.bashrc
```

#### 2. Chrome/Chromiumが認識されない
```bash
# CHROME_EXECUTABLE環境変数を設定
export CHROME_EXECUTABLE=/usr/bin/chromium-browser
# または
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
```

#### 3. Android SDKが見つからない
```bash
# ANDROID_HOME設定
export ANDROID_HOME=$HOME/Android/Sdk
flutter config --android-sdk $ANDROID_HOME
```

#### 4. "Unable to locate Android SDK"
```bash
# Android Studioから手動でSDKをインストール
# File > Settings > Appearance & Behavior > System Settings > Android SDK
```

#### 5. libstdc++.so.6エラー
```bash
# 32ビットライブラリをインストール
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386
```

## 📊 パフォーマンス最適化

### メモリ使用量削減

```bash
# gradle.propertiesに追加
echo "org.gradle.jvmargs=-Xmx1536M" >> android/gradle.properties
echo "org.gradle.daemon=false" >> android/gradle.properties
```

### ビルド高速化

```bash
# キャッシュ有効化
flutter config --enable-web
flutter config --enable-linux-desktop

# 並列ビルド
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=true
```

## 🧪 環境確認コマンド

```bash
# Flutter環境全体確認
flutter doctor -v

# インストール済みデバイス確認
flutter devices

# SDKバージョン確認
flutter --version
dart --version

# キャッシュクリア
flutter clean
flutter pub cache repair

# アップグレード
flutter upgrade
```

## 📚 参考リンク

- [Flutter公式: Linux install](https://docs.flutter.dev/get-started/install/linux)
- [Ubuntu Snap Store: Flutter](https://snapcraft.io/flutter)
- [Android Studio](https://developer.android.com/studio/install)
- [Chrome for Linux](https://www.google.com/chrome/)

## 🆘 サポート

問題が解決しない場合：

1. `flutter doctor -v`の出力を確認
2. [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)で検索
3. プロジェクトのIssueに報告

---

最終更新: 2025年8月9日