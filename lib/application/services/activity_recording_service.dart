import 'package:active_app_monitor/infrastructure/datasources/json_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'dart:async';

class ActivityRecordingService {
  final JsonFileDataSource _dataSource;
  DateTime? _currentActivityStartTime;
  String? _currentAppName;
  String? _currentChromeUrl;

  ActivityRecordingService(this._dataSource);

  Future<void> startNewActivity(String appName, String? chromeUrl) async {
    final now = DateTime.now();

    // loginwindowまたはNo active applicationの場合は記録しない
    if (appName == "No active application") {
      return;
    }

    // アプリが変更された場合のみ新しいアクティビティを開始
    if (_currentAppName != appName ||
        (_currentAppName == 'Google Chrome' &&
            _currentChromeUrl != chromeUrl)) {
      if (_currentActivityStartTime != null && _currentAppName != null) {
        await _saveCurrentActivity();
      }
      _currentActivityStartTime = now;
      _currentAppName = appName;
      _currentChromeUrl = chromeUrl;
    }
  }

  Future<void> _saveCurrentActivity() async {
    if (_currentActivityStartTime == null || _currentAppName == null) return;

    final endTime = DateTime.now();
    final details = _currentChromeUrl != null
        ? {'open_url': _currentChromeUrl}
        : <String, dynamic>{};

    final record = ActivityRecord(
      appName: _currentAppName!,
      startTime: _currentActivityStartTime!,
      endTime: endTime,
      details: details,
    );

    await _dataSource.saveActivity(record, _currentActivityStartTime!);

    // 保存後、新しいアクティビティの開始時間を更新
    _currentActivityStartTime = endTime;
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

    // 開始日から終了日までの各月のデータを取得
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
