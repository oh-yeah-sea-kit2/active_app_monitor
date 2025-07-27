# Active App Monitor セキュリティガイドライン

## 概要

本ドキュメントは、Active App Monitorの開発・運用におけるセキュリティに関する推奨事項とベストプラクティスをまとめたものです。

## macOSセキュリティ要件

### 1. 必要な権限と実装方法

#### 1.1 Accessibility API権限
アプリケーションがキーボード・マウスイベントを監視するために必要です。

**実装例:**
```swift
// AppDelegate.swift
import Cocoa
import ApplicationServices

private func requestAccessibilityPermission() {
    let options: NSDictionary = [
        kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
    ]
    
    let accessEnabled = AXIsProcessTrustedWithOptions(options)
    
    if !accessEnabled {
        // 権限が付与されていない場合の処理
        showAccessibilityAlert()
    }
}

private func showAccessibilityAlert() {
    let alert = NSAlert()
    alert.messageText = "アクセシビリティ権限が必要です"
    alert.informativeText = "Active App Monitorがアプリケーションの使用状況を記録するには、" +
                           "システム環境設定でアクセシビリティ権限を付与してください。"
    alert.addButton(withTitle: "システム環境設定を開く")
    alert.addButton(withTitle: "後で")
    
    if alert.runModal() == .alertFirstButtonReturn {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
```

#### 1.2 AppleScript権限
ChromeのURLを取得するために必要です。

**Info.plistへの追加:**
```xml
<key>NSAppleEventsUsageDescription</key>
<string>Active App MonitorがChromeで開いているページのドメインを記録するために必要です。</string>
```

### 2. エンタイトルメント設定

#### 2.1 必須エンタイトルメント
```xml
<!-- Release.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- AppleScript実行権限 -->
    <key>com.apple.security.automation.apple-events</key>
    <true/>
    
    <!-- ネットワーククライアント権限（将来の同期機能用） -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- ファイル読み書き権限 -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- アプリサンドボックス（推奨） -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- 一時的な例外（必要に応じて） -->
    <key>com.apple.security.temporary-exception.apple-events</key>
    <array>
        <string>com.google.Chrome</string>
    </array>
</dict>
</plist>
```

### 3. コード署名

#### 3.1 開発者証明書の設定
```bash
# 証明書の確認
security find-identity -v -p codesigning

# コード署名
codesign --force --deep --sign "Developer ID Application: Your Name (TEAM_ID)" \
         --options runtime \
         --entitlements Release.entitlements \
         "build/macos/Build/Products/Release/Active App Monitor.app"

# 署名の検証
codesign --verify --deep --strict --verbose=2 "build/macos/Build/Products/Release/Active App Monitor.app"
```

#### 3.2 Notarization（公証）
```bash
# アプリをzipに圧縮
ditto -c -k --keepParent "Active App Monitor.app" "ActiveAppMonitor.zip"

# Notarizationの実行
xcrun notarytool submit "ActiveAppMonitor.zip" \
                 --apple-id "your-apple-id@example.com" \
                 --team-id "TEAM_ID" \
                 --password "app-specific-password" \
                 --wait

# ステープルの適用
xcrun stapler staple "Active App Monitor.app"
```

## データセキュリティ

### 1. データ保存のセキュリティ

#### 1.1 ファイルパーミッション
```dart
// 保存時にファイルパーミッションを設定
Future<void> saveSecureFile(File file, String content) async {
  await file.writeAsString(content);
  
  // macOSでのファイルパーミッション設定
  if (Platform.isMacOS) {
    await Process.run('chmod', ['600', file.path]);
  }
}
```

#### 1.2 データ暗号化（推奨実装）
```dart
import 'package:cryptography/cryptography.dart';

class SecureDataStorage {
  final _algorithm = AesGcm.with256bits();
  
  Future<String> encryptData(String plainText, SecretKey key) async {
    final secretBox = await _algorithm.encryptString(
      plainText,
      secretKey: key,
    );
    
    return base64Encode(secretBox.concatenation());
  }
  
  Future<String> decryptData(String encryptedData, SecretKey key) async {
    final secretBox = SecretBox.fromConcatenation(
      base64Decode(encryptedData),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macLength,
    );
    
    return await _algorithm.decryptString(secretBox, secretKey: key);
  }
}
```

### 2. 機密情報の取り扱い

#### 2.1 ログ出力の制御
```dart
// デバッグ情報の適切な管理
class SecureLogger {
  static void log(String message, {bool includeDetails = false}) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    } else if (!includeDetails) {
      // プロダクションでは詳細情報を含めない
      print('[INFO] ${_sanitizeMessage(message)}');
    }
  }
  
  static String _sanitizeMessage(String message) {
    // URLやパスなどの機密情報を除去
    return message.replaceAll(RegExp(r'https?://[^\s]+'), '[URL]')
                  .replaceAll(RegExp(r'/Users/[^/]+'), '/Users/[USER]');
  }
}
```

#### 2.2 メモリ内データの保護
```dart
// 機密データのクリーンアップ
class SensitiveDataManager {
  final List<String> _sensitiveData = [];
  
  void addSensitiveData(String data) {
    _sensitiveData.add(data);
  }
  
  void clearSensitiveData() {
    // メモリから機密データをクリア
    for (var i = 0; i < _sensitiveData.length; i++) {
      _sensitiveData[i] = String.fromCharCodes(
        List.generate(_sensitiveData[i].length, (_) => 0)
      );
    }
    _sensitiveData.clear();
  }
}
```

## プライバシー保護

### 1. データ収集の最小化

#### 1.1 必要最小限の情報のみ記録
- アプリケーション名のみ記録（ウィンドウタイトルは記録しない）
- ChromeはドメインのみでURLパスは記録しない
- キーストロークの内容は記録しない

#### 1.2 個人識別情報の除外
```dart
class PrivacyFilter {
  static String filterAppName(String appName) {
    // 個人名を含む可能性のあるアプリ名をフィルタリング
    if (appName.contains('@') || appName.contains('personal')) {
      return 'Filtered App';
    }
    return appName;
  }
  
  static String filterDomain(String url) {
    // URLからドメインのみを抽出
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      // サブドメインも除去してプライバシーを保護
      final parts = uri.host.split('.');
      if (parts.length >= 2) {
        return '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
      }
    }
    return '';
  }
}
```

### 2. データの自動削除

#### 2.1 古いデータの自動削除機能
```dart
class DataRetentionManager {
  static const int retentionDays = 365; // 1年間
  
  static Future<void> cleanOldData() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    // 古いファイルを削除
    final dir = await getApplicationDocumentsDirectory();
    final activitiesDir = Directory(path.join(dir.path, 'activities'));
    
    if (await activitiesDir.exists()) {
      await for (final file in activitiesDir.list()) {
        if (file is File) {
          final fileName = path.basename(file.path);
          final match = RegExp(r'(\d{4})_(\d{2})\.json').firstMatch(fileName);
          
          if (match != null) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final fileDate = DateTime(year, month);
            
            if (fileDate.isBefore(cutoffDate)) {
              await file.delete();
            }
          }
        }
      }
    }
  }
}
```

## セキュリティチェックリスト

### 開発時
- [ ] 権限要求の実装とユーザーへの説明
- [ ] エラーメッセージに機密情報が含まれていないか確認
- [ ] デバッグログがプロダクションで無効化されているか確認
- [ ] ファイルパーミッションが適切に設定されているか確認

### リリース前
- [ ] コード署名の実施
- [ ] Notarizationの完了
- [ ] エンタイトルメントの最小権限原則に従った設定
- [ ] セキュリティ関連のドキュメント更新

### 運用時
- [ ] セキュリティアップデートの定期的な確認
- [ ] 依存パッケージの脆弱性スキャン
- [ ] ユーザーからのセキュリティ報告への対応プロセス

## インシデント対応

### セキュリティ問題が発見された場合
1. 問題の影響範囲を特定
2. 修正パッチの開発とテスト
3. ユーザーへの通知と更新の案内
4. 問題の原因分析と再発防止策の実施

### 連絡先
セキュリティに関する問題を発見した場合は、以下に報告してください：
- Email: security@your-domain.com
- 緊急度: 高い場合は件名に[SECURITY]を含めてください