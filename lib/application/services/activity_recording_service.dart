import 'package:active_app_monitor/infrastructure/datasources/json_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'dart:async';

class ActivityRecordingService {
  final JsonFileDataSource _dataSource;
  DateTime? _currentActivityStartTime;
  String? _currentAppName;
  String? _currentChromeUrl;
  Timer? _saveTimer;
  static const saveIntervalSeconds = 10;

  ActivityRecordingService(this._dataSource) {
    // 10秒ごとに現在のアクティビティを保存
    _saveTimer =
        Timer.periodic(Duration(seconds: saveIntervalSeconds), (timer) {
      if (_currentActivityStartTime != null && _currentAppName != null) {
        _saveCurrentActivity();
      }
    });
  }

  void startNewActivity(String appName, String? chromeUrl) {
    final now = DateTime.now();

    // アプリが変更された場合のみ新しいアクティビティを開始
    if (_currentAppName != appName ||
        (_currentAppName == 'Google Chrome' &&
            _currentChromeUrl != chromeUrl)) {
      if (_currentActivityStartTime != null && _currentAppName != null) {
        _saveCurrentActivity();
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
    _saveTimer?.cancel();
    if (_currentActivityStartTime != null && _currentAppName != null) {
      await _saveCurrentActivity();
    }
  }
}
