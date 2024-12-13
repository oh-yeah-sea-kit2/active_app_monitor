import 'package:active_app_monitor/infrastructure/datasources/json_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'dart:async';

class ActivityRecordingService {
  final JsonFileDataSource _dataSource;
  DateTime? _currentActivityStartTime;
  DateTime? _lastActiveTime;
  String? _currentAppName;
  String? _currentChromeUrl;
  bool _currentIsUserActive = true;

  ActivityRecordingService(this._dataSource);

  Future<void> startNewActivity(
      String appName, String? chromeUrl, bool isUserActive) async {
    final now = DateTime.now();

    // 非アクティブになった時
    if (!isUserActive || appName == "No active application") {
      if (_currentActivityStartTime != null && _currentAppName != null) {
        _lastActiveTime = now;
        _currentIsUserActive = false;
        await _saveCurrentActivity();
        // アクティビティをリセット
        _currentActivityStartTime = null;
        _currentAppName = null;
        _currentChromeUrl = null;
        _lastActiveTime = null;
      }
      return;
    }

    // 非アクティブ→アクティブの遷移時
    if (_currentActivityStartTime == null) {
      _currentActivityStartTime = now;
      _currentAppName = appName;
      _currentChromeUrl = chromeUrl;
      _currentIsUserActive = true;
      await _saveCurrentActivity();
      // 新しいアクティビティの開始時間を設定
      _currentActivityStartTime = now;
      return;
    }

    // アプリ切り替え時
    if (_currentAppName != appName ||
        (_currentAppName == 'Google Chrome' &&
            _currentChromeUrl != chromeUrl)) {
      _lastActiveTime = now;
      await _saveCurrentActivity();
      _currentActivityStartTime = now;
      _currentAppName = appName;
      _currentChromeUrl = chromeUrl;
      _currentIsUserActive = true;
    }
  }

  Future<void> _saveCurrentActivity() async {
    if (_currentActivityStartTime == null || _currentAppName == null) return;

    final endTime = _lastActiveTime ?? DateTime.now();
    final details = <String, dynamic>{
      'is_active': _currentIsUserActive,
    };
    // Chromeの場合はドメインを追加
    if (_currentAppName == 'Google Chrome') {
      if (_currentChromeUrl != null) {
        details['open_url'] = _currentChromeUrl;
      }
    }

    final record = ActivityRecord(
      appName: _currentAppName!,
      startTime: _currentActivityStartTime!,
      endTime: endTime,
      details: details,
    );

    await _dataSource.saveActivity(record, _currentActivityStartTime!);

    // 保存後、新しいアクティビティの開始時間を更新
    _currentActivityStartTime = DateTime.now();
  }

  Future<MonthlyActivity?> getMonthlyActivity(int year, int month) {
    return _dataSource.getMonthlyActivity(year, month);
  }

  Future<void> dispose() async {
    if (_currentActivityStartTime != null && _currentAppName != null) {
      await _saveCurrentActivity();
    }
  }

  Future<List<ActivityRecord>> getActivitiesByDateRange(
      DateTime start, DateTime end) async {
    final activities = <ActivityRecord>[];

    // 開始日から終了日までの各日のデータを取得
    for (var date = start;
        date.isBefore(end) || date.isAtSameMomentAs(end);
        date = DateTime(date.year, date.month + 1)) {
      final monthlyActivity = await getMonthlyActivity(date.year, date.month);
      if (monthlyActivity != null) {
        // その月の記録から指定範囲内のものだけを抽出
        final filteredRecords = monthlyActivity.records
            .where((daily) =>
                !daily.date.isBefore(start) && !daily.date.isAfter(end))
            .expand((daily) => daily.activities)
            .toList();

        activities.addAll(filteredRecords);
      }
    }

    return activities;
  }
}
