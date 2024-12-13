# active_app_monitor

MacOSで1日の作業状況を記録したい

## アプリの仕様を考える

1. アプリ開発などを行っているときに開いているアプリを決める（追加出来るようにもしたほうが良さそう）
   - VSCode
   - iTerm2
   - Chrome
     - 開いているURLを限定する
2. 上記アプリ一覧のときの稼働を記録する。
3. メニューバーに常時起動
4. アプリを閉じてもバックグラウンドで稼働すること
5. どこかしらに今までの内容を記録。JSONとかSQLiteで保存。
6. アクティブなアプリを記録。キーボード、マウスの動きも検知して実際に作業中であることを確認。
7. その日の終わりや週の終わり、月の終わりに確認してどれくらい作業をしたか確認したい。
8. 基本的にすべてのアプリ、Chromeの開いているURLでの作業時間を記録する。

### Swiftでやること

- [x] アクティブなアプリを記録。キーボード、マウスの動きも検知して実際に作業中であることを確認。
- [x] メニューバーに常時起動
- [x] アプリを閉じてもバックグラウンドで稼働すること
- [x] ウィンドウのバツボタンを押したらDockから消えること

### Flutter でやること

- [ ] 監視対象のアプリ名の管理。追加削除
- [ ] ChromeのみURLまで管理。これも追加削除まで
- [ ] アプリの稼働を記録

## memo

```sh
flutter run -d macos
```

## build

```sh
flutter build macos --release
codesign -v "build/macos/Build/Products/Release/Active App Monitor.app"

open build/macos/Build/Products/Release/
ditto -c -k --keepParent "build/macos/Build/Products/Release/Active App Monitor.app" "ActiveAppMonitor.zip"
```

## バージョンを上げる

```sh
dart pub global activate cider

# バージョン確認
cider version

# バージョンアップ
cider bump major     # メジャーバージョンを上げる (1.0.0 → 2.0.0)
cider bump minor     # マイナーバージョンを上げる (1.0.0 → 1.1.0)
cider bump patch     # パッチバージョンを上げる (1.0.0 → 1.0.1)
cider bump build     # ビルド番号を上げる (1.0.0+1 → 1.0.0+2)

# 特定のバージョンに設定
cider version 1.2.3+4
```
