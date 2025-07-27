# CLAUDE.md

このファイルは、このリポジトリでコードを扱う際のClaude Code (claude.ai/code) へのガイダンスを提供します。

**重要**: このプロジェクトでは日本語でコミュニケーションを取ってください。

## プロジェクト概要

Active App Monitorは、さまざまなアプリケーション間でのユーザーアクティビティを追跡するmacOS Flutterアプリケーションです。アクティブなアプリを監視し、ChromeのURLを追跡し、生産性分析のための作業時間を記録します。

## ビルドと開発コマンド

### アプリケーションの実行
```bash
flutter run -d macos
```

### リリースビルド
```bash
./release_build.sh
```

このスクリプトは以下を実行します：
1. `flutter clean`
2. `flutter build macos --release`
3. コード署名の検証
4. 配布用のzipファイルを作成

### バージョン管理
```bash
# 現在のバージョンを確認
cider version

# バージョンアップ
cider bump patch     # 1.0.0 → 1.0.1
cider bump minor     # 1.0.0 → 1.1.0
cider bump major     # 1.0.0 → 2.0.0
```

### コード解析
```bash
flutter analyze
```

## アーキテクチャ概要

このコードベースはクリーンアーキテクチャの原則に従い、関心事の明確な分離を実現しています：

### ドメイン層 (`lib/domain/`)
- **エンティティ**: コアビジネスオブジェクト (ActivityRecord, AppActivity, MonitorSettings)
- **リポジトリ**: データアクセスの抽象インターフェース

### インフラストラクチャ層 (`lib/infrastructure/`)
- **データソース**: ファイルI/Oとプラットフォーム通信の具体的な実装
  - `PlatformChannelDataSource`: Flutterプラットフォームチャネル経由でネイティブSwiftコードと通信
  - `JsonFileDataSource`: アクティビティレコードの永続化を処理
  - `SettingsFileDataSource`: アプリケーション設定を管理
- **システム**: プラットフォーム固有の統合（メニューバー、ウィンドウ管理）

### アプリケーション層 (`lib/application/`)
- **サービス**: ビジネスロジックのオーケストレーション
  - `ActivityService`: アクティビティトラッキングを調整するメインサービス
  - `ActivityRecordingService`: アクティビティデータの記録と保存を処理

### プレゼンテーション層 (`lib/presentation/`)
- **スクリーン**: メインUIビュー (ActiveAppScreen, SettingsScreen, WorkDurationReportScreen)
- **ウィジェット**: 再利用可能なUIコンポーネント

### ネイティブmacOS統合 (`macos/Runner/`)
- `AppDelegate.swift`: ネイティブ機能を処理
  - ユーザー存在検出のためのキーボード/マウスアクティビティを監視
  - アクティブなアプリケーション名を取得
  - AppleScript経由でChromeタブのURLを取得
  - プラットフォームチャネル実装: `com.oh-yeah-sea-kit2.activeAppMonitor`

## 重要な技術的詳細

### データストレージ
- アクティビティレコードは年/月で整理されたJSONファイルとして保存
- 設定は別のJSONファイルに永続化
- ファイルパスは`path_provider`を使用してプラットフォーム固有

### プラットフォーム通信
アプリはFlutterプラットフォームチャネルを使用してネイティブSwiftコードと通信：
- `getActiveApp`: 現在アクティブなアプリケーション名を返す
- `getChromeURL`: アクティブなChromeタブのドメインを返す
- `getLastActivity`: 最後のユーザー操作からの秒数を返す

### 監視ロジック
- すべてのアプリケーションを追跡するが、ユーザー定義の設定に基づいてフィルタリング
- ドメイン固有のアクティビティを追跡するためのChrome特別処理
- `loginwindow`システムプロセスを無視
- 開始/終了タイムスタンプ付きの時間ブロックでアクティビティを記録

### UI機能
- `tray_manager`を使用したメニューバー統合
- `window_manager`によるウィンドウ管理
- ウィンドウを閉じてもバックグラウンドで動作
- 日本語ローカライゼーションサポート

## 開発に関する注意事項

- Flutter SDKの要件: ^3.5.4
- macOS専用アプリケーション（iOS/Androidサポートなし）
- `flutter_lints`の標準的なFlutterリンティングルールを使用
- `flutter_launcher_icons`でアプリアイコンを生成