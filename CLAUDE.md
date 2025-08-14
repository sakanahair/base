# 🤖 CLAUDE.md - 開発経緯と設計決定

このドキュメントは、SAKANA AIプロジェクトの開発過程で行われた重要な技術的決定と、その背景にある理由を記録したものです。

## 📖 開発ストーリー

### 第1章: Vercelからの脱却

#### 初期の構成
最初はVercelを使用した静的サイトホスティングを検討していました：
- Next.js (静的エクスポート)
- Flutter Web
- Vercel自動デプロイ

#### 問題点
- 404 NOT_FOUNDエラーの頻発
- 動的ルーティングの制限
- ビルド設定の複雑さ
- デバッグの困難さ

#### 決定
**「Vercelややこしいので conohaにデプロイしていきたい」**

この一言から、完全に制御可能な独自インフラへの移行が始まりました。

### 第2章: ConoHa VPS + Mutagenアーキテクチャ

#### 設計目標
1. **完全な制御**: サーバー環境を100%コントロール
2. **リアルタイム同期**: ローカルとサーバーの即座な同期
3. **柔軟性**: 任意の技術スタックを使用可能

#### 採用した構成
```
Mac (開発) ←→ Mutagen (双方向同期) ←→ ConoHa VPS (本番)
```

#### なぜMutagen？
- rsyncよりも高速で効率的
- 双方向同期のサポート
- ファイル変更の自動検出
- 接続切断時の自動再接続

### 第3章: standaloneモードへの転換

#### 当初の問題
```javascript
// next.config.ts (初期)
output: 'export',  // 静的エクスポート
```

静的エクスポートの制限：
- APIルートが使えない
- 動的ルーティングが制限される
- SSRの恩恵を受けられない

#### 解決策
```javascript
// next.config.ts (現在)
output: 'standalone',  // SSR対応
```

standaloneモードの利点：
- 完全なNext.js機能
- 自己完結型のビルド
- PM2での管理が容易
- APIルートの完全サポート

### 第4章: パス問題の解決

#### 問題1: /morishita/と/app/へのアクセス

**症状**: 
- `https://dev.sakana.hair/morishita/` → ✅ 動作
- `http://localhost:3000/morishita/` → ❌ 404

**原因**: 
Next.jsのstandaloneモードでは、publicフォルダのディレクトリインデックスが自動配信されない

**解決策**: middleware.tsの追加
```typescript
// /morishita/へのアクセスを/morishita/index.htmlにリダイレクト
if (pathname === '/morishita' || pathname === '/morishita/') {
  return NextResponse.rewrite(new URL('/morishita/index.html', request.url));
}
```

#### 問題2: Flutter Webの配信

**当初の設計**:
- Flutter build → `/flutter/build/web/`
- Nginxが直接配信

**問題**: 
Nginxの設定が複雑になり、パスの不一致が発生

**最終解決策**:
1. Flutter build → `next/public/app/`にコピー
2. Next.js経由で配信（middleware経由）
3. Nginxはプロキシとして動作

### 第5章: Mac/Ubuntu両対応の実現

#### 課題
- ハードコードされたパス（`/Users/apple/DEV/SAKANA_AI`）
- OS固有のコマンド（`sed -i ''` vs `sed -i`）
- パッケージマネージャーの違い（brew vs apt）

#### 解決策

1. **相対パスの使用**
```bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
```

2. **OS自動判定**
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="ubuntu"
fi
```

3. **条件分岐処理**
- Mac: Homebrew使用、Flutter含む
- Ubuntu: apt使用、Flutterオプション
- サーバー: ビルドのみ、Flutterスキップ

### 第6章: Firebase優先アーキテクチャへの転換（2025年1月）

#### 背景と問題
**ユーザーフィードバック**:
「そもそもなんですがローカルストレージが優先されてることがゴミです　ローカルにあるからfirebaseにあっぷがおかしいです全ての動作はまずはfirebaseそのごローカルストレージであるべきです」

**問題点**:
1. LocalStorage優先による無限同期ループ
2. 複数端末での同じアカウントログイン時のデータ不整合
3. 削除したデータが復活する現象
4. temp_IDの画像がFirebase Storageに蓄積

#### 解決策: Single Source of Truth

**変更前のフロー（問題あり）**:
```
LocalStorage（マスター）
    ↓ 同期
Firebase（コピー）
    ↓ 他端末
LocalStorage（コピー）
```

**変更後のフロー（正解）**:
```
Firebase（真実の源）
    ↓ リアルタイムリスナー
LocalStorage（キャッシュ）
    ↓
UI更新
```

#### 実装の詳細

1. **ServiceServiceの改修**:
```dart
// 初期化: Firebaseから直接読み込み
Future<void> initialize() async {
  if (_authService.currentUser != null) {
    await loadFromFirebase();
    _startRealtimeSync();
  }
}

// CRUD操作: Firebase優先
Future<ServiceModel> addService() async {
  await _saveToFirebase(service);  // まずFirebase
  // リアルタイムリスナーが自動的にローカルを更新
}
```

2. **リアルタイムリスナーの実装**:
```dart
FirebaseFirestore.instance
  .collection('tenants')
  .doc(tenantId)
  .collection('services')
  .snapshots()
  .listen((snapshot) {
    // Firebaseの変更をローカルに反映
    updateLocalFromFirebase(snapshot);
  });
```

3. **重複防止策**:
- StreamSubscriptionの管理
- 既存リスナーのキャンセル
- 一意性チェック

### 第7章: 画像管理の改善

#### 問題
1. テナントIDが'default'になる
2. 別アカウントで画像が表示されない
3. temp_IDでのアップロード

#### 解決策

1. **テナントID取得の修正**:
```dart
// 変更前: SharedPreferencesから取得
return prefs.getString('tenantId') ?? 'default';

// 変更後: AuthServiceから取得
return _authService.currentUser!.uid;
```

2. **画像表示の改善**:
- ServiceModelのimagesフィールドを直接使用
- LocalStorageからの読み込みを削除
- Firebase URLを優先

### 第8章: テーマ設定の共有化（2025年1月）

#### 要望
「色設定は同一アカウントでは共通化できないですか？」

#### 実装

1. **Firestore構造**:
```
users/
  └── [uid]/
      └── settings/
          └── theme/
              ├── primaryColor: "#5D9B9B"
              ├── isDarkMode: false
              ├── fontFamily: "M PLUS Rounded 1c"
              ├── fontSize: "m"
              └── customFontSizes: {}
```

2. **ThemeServiceの改修**:
```dart
class ThemeService extends ChangeNotifier {
  final SimplifiedAuthService _authService;
  StreamSubscription<DocumentSnapshot>? _themeSubscription;
  
  // 初期化: Firebase優先
  Future<void> _initializeTheme() async {
    await _loadFromLocalStorage();  // 即座の表示用
    if (_authService.currentUser != null) {
      await _loadFromFirebase();    // 真実の源
      _startRealtimeSync();          // リアルタイム同期
    }
  }
  
  // 設定変更時
  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    await _saveToLocalStorage();  // キャッシュ
    await _saveToFirebase();       // 永続化と共有
    notifyListeners();
  }
}
```

3. **利点**:
- 同一アカウントで全デバイス共通の設定
- リアルタイムで設定が同期
- オフラインでも最後の設定を維持

## 🎯 設計原則

### 1. Firebase First（2025年1月確立）
すべてのデータ操作はFirebaseを優先。LocalStorageは読み取りキャッシュとしてのみ使用。

### 2. シンプルさ優先
複雑な設定よりも、理解しやすく保守しやすい構成を選択

### 3. 自動化の徹底
手動作業を極力排除し、スクリプトで自動化

### 4. 環境非依存
Mac/Ubuntu/サーバーで同じワークフロー

### 5. 失敗からの学習
エラーは貴重な学習機会。問題解決の過程を記録

## 🔑 重要な技術的決定

### なぜNext.js？
- **App Router**: 最新のReact機能をフル活用
- **SSR/SSG**: SEOとパフォーマンスの両立
- **API Routes**: バックエンド機能の統合
- **TypeScript**: 型安全性

### なぜFlutter Web？
- **クロスプラットフォーム**: 一つのコードベースで全プラットフォーム対応
- **高性能**: ネイティブに近いパフォーマンス
- **豊富なウィジェット**: 美しいUIを簡単に構築

### なぜFirebase？（2025年1月再評価）
- **リアルタイム同期**: 複数デバイス間の即座な同期
- **Single Source of Truth**: データの一貫性を保証
- **オフライン対応**: 自動的なキャッシュとリトライ
- **スケーラビリティ**: 自動スケーリング

### なぜConoHa VPS？
- **日本のデータセンター**: 低レイテンシ
- **コストパフォーマンス**: 手頃な価格で高性能
- **完全なroot権限**: 自由な環境構築

### なぜMutagen？
- **リアルタイム同期**: 変更が即座に反映
- **双方向同期**: どちら側での変更も同期
- **効率的**: 差分のみを転送

### なぜPM2？
- **プロセス管理**: 自動再起動、ログ管理
- **クラスタリング**: マルチコア活用
- **監視**: メトリクスとヘルスチェック

## 💡 学んだ教訓

### 1. 「シンプルなはず」は罠
Vercelの「簡単デプロイ」も、複雑な要件では逆に困難に

### 2. 制御の重要性
完全に制御できる環境の価値は計り知れない

### 3. ドキュメントの重要性
問題解決の過程を記録することで、将来の問題解決が容易に

### 4. 自動化への投資
初期の自動化への時間投資は、長期的に大きなリターンを生む

### 5. ユーザーフィードバックの価値（2025年1月追加）
「ゴミ設計」という厳しいフィードバックも、根本的な改善のきっかけに

### 6. Single Source of Truthの重要性
データの真実の源を明確にすることで、同期問題を根本的に解決

## 🚀 今後の展望

### 短期目標
- [x] Firebase統合（認証、Firestore）- 完了
- [x] リアルタイム同期の実装 - 完了
- [ ] Cloudflare CDN最適化
- [ ] GitHub Actions CI/CD
- [ ] 監視ツール導入（UptimeRobot）

### 中期目標
- [ ] マイクロサービス化
- [ ] Kubernetes導入検討
- [ ] GraphQL API実装
- [ ] リアルタイム機能の拡充（WebSocket）
- [ ] 設定項目のFirebase同期拡大

### 長期目標
- [ ] マルチリージョン展開
- [ ] AI機能の統合
- [ ] ブロックチェーン連携
- [ ] IoTデバイス対応

## 📝 メモ

### デバッグのコツ
1. **PM2ログを確認**: `pm2 logs sakana-next`
2. **Nginx設定をテスト**: `nginx -t`
3. **Mutagen状態確認**: `mutagen sync list`
4. **Firebase Console確認**: データの整合性チェック
5. **Chrome DevTools**: LocalStorageとNetworkタブ

### パフォーマンス最適化
- standaloneビルドでサイズ削減
- 静的ファイルはCDN配信
- 画像は最適化済みフォーマット使用
- キャッシュヘッダーの適切な設定
- Firebaseクエリの最適化

### セキュリティ考慮事項
- 環境変数で機密情報管理
- HTTPS必須
- ファイアウォール設定
- 定期的なアップデート
- Firebase Security Rulesの適切な設定

## 🙏 謝辞

このプロジェクトは、多くの試行錯誤と学習の結果です。
特に以下の決定が転換点となりました：

1. **Vercelからの脱却** - 制約からの解放
2. **Mutagenの採用** - 開発体験の劇的な改善
3. **standaloneモード** - Next.jsの真の力を解放
4. **middleware.ts** - 静的ファイル配信の問題を解決
5. **Firebase First** - データ同期問題の根本的解決（2025年1月）

## 📚 参考資料

- [Next.js Standalone Mode](https://nextjs.org/docs/advanced-features/output-file-tracing)
- [Mutagen Documentation](https://mutagen.io/documentation/)
- [PM2 Documentation](https://pm2.keymetrics.io/)
- [Nginx as Reverse Proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [Firebase Realtime Listeners](https://firebase.google.com/docs/firestore/query-data/listen)
- [Single Source of Truth Pattern](https://en.wikipedia.org/wiki/Single_source_of_truth)

---

*このドキュメントは、開発過程での学びと決定を記録し、将来の開発者（未来の自分を含む）への指針となることを目的としています。*

**最終更新**: 2025年1月14日
**作成者**: SAKANA AI Team with Claude
**バージョン**: 2.0.0