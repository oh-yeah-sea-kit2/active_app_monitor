# Active App Monitor テスト戦略

## 概要

本ドキュメントは、Active App Monitorの品質保証のためのテスト戦略と実装方法を定義します。

## テストピラミッド

```
        /\
       /  \  E2Eテスト (10%)
      /----\
     /      \ 統合テスト (20%)
    /--------\
   /          \ 単体テスト (70%)
  /____________\
```

## 1. 単体テスト

### 1.1 ドメイン層のテスト

#### エンティティのテスト
```dart
// test/domain/entities/activity_record_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';

void main() {
  group('ActivityRecord', () {
    test('should create valid activity record', () {
      final record = ActivityRecord(
        appName: 'VSCode',
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 10, 0),
        details: {'is_active': true},
      );
      
      expect(record.appName, 'VSCode');
      expect(record.duration, const Duration(hours: 1));
    });
    
    test('should handle Chrome activity with URL', () {
      final record = ActivityRecord(
        appName: 'Google Chrome',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        details: {
          'is_active': true,
          'open_url': 'github.com'
        },
      );
      
      expect(record.details['open_url'], 'github.com');
    });
  });
}
```

#### 設定管理のテスト
```dart
// test/domain/entities/monitor_settings_test.dart
void main() {
  group('MonitorSettings', () {
    test('should initialize with default settings', () {
      final settings = MonitorSettings.defaultSettings();
      
      expect(settings.targetApps, contains('Visual Studio Code'));
      expect(settings.targetApps, contains('Google Chrome'));
      expect(settings.chromeDomains, isEmpty);
    });
    
    test('should correctly identify target apps', () {
      final settings = MonitorSettings(
        targetApps: ['VSCode', 'iTerm'],
        chromeDomains: ['github.com'],
      );
      
      expect(settings.isTargetApp('VSCode'), true);
      expect(settings.isTargetApp('Safari'), false);
    });
    
    test('should correctly identify target domains', () {
      final settings = MonitorSettings(
        targetApps: ['Google Chrome'],
        chromeDomains: ['github.com', 'stackoverflow.com'],
      );
      
      expect(settings.isTargetDomain('github.com'), true);
      expect(settings.isTargetDomain('youtube.com'), false);
    });
  });
}
```

### 1.2 アプリケーション層のテスト

#### サービスのテスト
```dart
// test/application/services/activity_recording_service_test.dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([JsonFileDataSource])
void main() {
  late ActivityRecordingService service;
  late MockJsonFileDataSource mockDataSource;
  
  setUp(() {
    mockDataSource = MockJsonFileDataSource();
    service = ActivityRecordingService(mockDataSource);
  });
  
  group('ActivityRecordingService', () {
    test('should start new activity when user becomes active', () async {
      // Arrange
      when(mockDataSource.saveActivity(any, any))
          .thenAnswer((_) async => null);
      
      // Act
      await service.startNewActivity('VSCode', null, true);
      
      // Assert
      verify(mockDataSource.saveActivity(any, any)).called(1);
    });
    
    test('should not record when user is inactive', () async {
      // Act
      await service.startNewActivity('No active application', null, false);
      
      // Assert
      verifyNever(mockDataSource.saveActivity(any, any));
    });
    
    test('should handle app switching correctly', () async {
      // Arrange
      when(mockDataSource.saveActivity(any, any))
          .thenAnswer((_) async => null);
      
      // Act - First app
      await service.startNewActivity('VSCode', null, true);
      
      // Act - Switch to different app
      await service.startNewActivity('Chrome', 'github.com', true);
      
      // Assert - Should save both activities
      verify(mockDataSource.saveActivity(any, any)).called(2);
    });
  });
}
```

### 1.3 インフラストラクチャ層のテスト

#### データソースのテスト
```dart
// test/infrastructure/datasources/json_file_datasource_test.dart
void main() {
  late JsonFileDataSource dataSource;
  late Directory testDir;
  
  setUp(() async {
    testDir = await Directory.systemTemp.createTemp('test_');
    dataSource = JsonFileDataSource();
    // テスト用ディレクトリを使用するようにモック
  });
  
  tearDown(() async {
    await testDir.delete(recursive: true);
  });
  
  test('should save and retrieve monthly activity', () async {
    // Arrange
    final activity = ActivityRecord(
      appName: 'VSCode',
      startTime: DateTime(2024, 1, 1, 9, 0),
      endTime: DateTime(2024, 1, 1, 10, 0),
      details: {'is_active': true},
    );
    
    // Act
    await dataSource.saveActivity(activity, DateTime(2024, 1, 1));
    final result = await dataSource.getMonthlyActivity(2024, 1);
    
    // Assert
    expect(result, isNotNull);
    expect(result!.records.length, 1);
    expect(result.records.first.activities.length, 1);
    expect(result.records.first.activities.first.appName, 'VSCode');
  });
}
```

## 2. 統合テスト

### 2.1 プラットフォームチャネルのテスト
```dart
// test/integration/platform_channel_test.dart
void main() {
  testWidgets('Platform channel integration test', (tester) async {
    // プラットフォームチャネルのモック設定
    const channel = MethodChannel('com.oh-yeah-sea-kit2.activeAppMonitor');
    
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getActiveApp':
            return 'Test App';
          case 'getChromeURL':
            return 'test.com';
          case 'getLastActivity':
            return 5.0;
          default:
            return null;
        }
      },
    );
    
    // テストの実行
    final dataSource = PlatformChannelDataSource();
    final appName = await dataSource.getActiveApp();
    
    expect(appName, 'Test App');
  });
}
```

### 2.2 ファイルシステムとの統合テスト
```dart
// test/integration/file_system_test.dart
void main() {
  test('File system integration test', () async {
    // 実際のファイルシステムを使用したテスト
    final tempDir = await Directory.systemTemp.createTemp();
    
    try {
      // ファイルの作成・読み書きテスト
      final file = File('${tempDir.path}/test.json');
      await file.writeAsString('{"test": "data"}');
      
      final content = await file.readAsString();
      expect(content, '{"test": "data"}');
      
      // パーミッションのテスト
      if (Platform.isMacOS) {
        final result = await Process.run('ls', ['-la', file.path]);
        expect(result.stdout, contains('-rw-'));
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
```

## 3. ウィジェットテスト

### 3.1 画面のテスト
```dart
// test/presentation/screens/active_app_screen_test.dart
void main() {
  testWidgets('ActiveAppScreen displays current activity', (tester) async {
    // モックサービスの設定
    final mockService = MockActivityService();
    when(mockService.getCurrentActivity()).thenAnswer((_) async => AppActivity(
      appName: 'VSCode',
      chromeUrl: null,
      isUserActive: true,
      timestamp: DateTime.now(),
      todayWorkDuration: const Duration(hours: 2),
      todayTotalDuration: const Duration(hours: 3),
      appDurations: {'VSCode': const Duration(hours: 2)},
      allAppDurations: {},
      chromeDomainDurations: {},
    ));
    
    // ウィジェットのビルド
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveAppScreen(activityService: mockService),
      ),
    );
    
    // 表示の確認
    expect(find.text('VSCode'), findsOneWidget);
    expect(find.textContaining('2:00:00'), findsOneWidget);
  });
}
```

### 3.2 設定画面のテスト
```dart
// test/presentation/screens/settings_screen_test.dart
void main() {
  testWidgets('Settings screen allows adding apps', (tester) async {
    final mockRepository = MockSettingsRepository();
    when(mockRepository.getSettings()).thenAnswer(
      (_) async => MonitorSettings.defaultSettings(),
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(settingsRepository: mockRepository),
      ),
    );
    
    // アプリ追加ボタンをタップ
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // ダイアログが表示されることを確認
    expect(find.text('アプリを追加'), findsOneWidget);
  });
}
```

## 4. E2Eテスト

### 4.1 基本的なワークフローテスト
```dart
// test/e2e/basic_workflow_test.dart
void main() {
  testWidgets('Complete workflow test', (tester) async {
    // アプリの起動
    await tester.pumpWidget(MyApp(
      activityService: ActivityService(
        activityRepository,
        recordingService,
        settingsRepository,
      ),
    ));
    
    // 設定画面への遷移
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    
    // アプリの追加
    await tester.tap(find.byIcon(Icons.add));
    await tester.enterText(find.byType(TextField), 'Xcode');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    
    // メイン画面に戻る
    await tester.pageBack();
    await tester.pumpAndSettle();
    
    // アクティビティが記録されることを確認
    expect(find.textContaining('Xcode'), findsOneWidget);
  });
}
```

## 5. パフォーマンステスト

### 5.1 大量データ処理のテスト
```dart
// test/performance/large_data_test.dart
void main() {
  test('Performance with large dataset', () async {
    final stopwatch = Stopwatch()..start();
    
    // 1年分のデータを生成
    final activities = List.generate(10000, (index) => ActivityRecord(
      appName: 'App${index % 10}',
      startTime: DateTime.now().subtract(Duration(hours: index)),
      endTime: DateTime.now().subtract(Duration(hours: index - 1)),
      details: {'is_active': true},
    ));
    
    // データの処理時間を測定
    final service = ActivityRecordingService(JsonFileDataSource());
    for (final activity in activities) {
      await service.saveActivity(activity.appName, null, true);
    }
    
    stopwatch.stop();
    
    // 処理時間が妥当な範囲内であることを確認
    expect(stopwatch.elapsedMilliseconds, lessThan(5000));
  });
}
```

## 6. テスト自動化

### 6.1 GitHub Actions設定
```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.5.4'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
```

### 6.2 ローカルテスト実行スクリプト
```bash
#!/bin/bash
# scripts/run_tests.sh

echo "Running unit tests..."
flutter test test/domain/
flutter test test/application/
flutter test test/infrastructure/

echo "Running widget tests..."
flutter test test/presentation/

echo "Running integration tests..."
flutter test test/integration/

echo "Generating coverage report..."
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 7. テストカバレッジ目標

### 目標カバレッジ
- 全体: 80%以上
- ドメイン層: 95%以上
- アプリケーション層: 85%以上
- インフラストラクチャ層: 70%以上
- プレゼンテーション層: 60%以上

### カバレッジレポートの生成
```bash
# カバレッジレポートの生成
flutter test --coverage

# HTMLレポートの生成
brew install lcov  # macOS
genhtml coverage/lcov.info -o coverage/html

# レポートの表示
open coverage/html/index.html
```

## 8. テストのベストプラクティス

### 8.1 テストの命名規則
- `should_[期待される動作]_when_[条件]`
- 日本語での説明も可（チーム内で統一）

### 8.2 テストの構造
```dart
void main() {
  group('機能グループ', () {
    setUp(() {
      // 各テストの前に実行
    });
    
    tearDown(() {
      // 各テストの後に実行
    });
    
    test('具体的なテストケース', () {
      // Arrange - 準備
      // Act - 実行
      // Assert - 検証
    });
  });
}
```

### 8.3 モックの使用
- 外部依存はモック化
- ビジネスロジックは実装を使用
- モックは最小限に留める

## まとめ

このテスト戦略により、Active App Monitorの品質を継続的に保証し、リグレッションを防ぎ、新機能の安全な追加を可能にします。テストは開発プロセスの重要な一部として、常に最新の状態を保つ必要があります。