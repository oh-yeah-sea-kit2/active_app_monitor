import 'dart:io';

import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_file_datasource.dart';
import '../../domain/entities/monitor_settings.dart';
import '../datasources/json_file_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsFileDataSource _dataSource;
  final JsonFileDataSource _activityDataSource;

  SettingsRepositoryImpl(this._dataSource, this._activityDataSource);

  @override
  Future<MonitorSettings> getSettings() => _dataSource.getSettings();

  @override
  Future<void> saveSettings(MonitorSettings settings) =>
      _dataSource.saveSettings(settings);

  @override
  Future<Directory> getAppDirectory() => _dataSource.appDir;

  @override
  Future<Set<String>> getUsedAppNames() async {
    final now = DateTime.now();
    final usedApps = Set<String>();

    // 過去3ヶ月分のログを確認
    for (var i = 0; i < 3; i++) {
      final targetDate = DateTime(now.year, now.month - i);
      final monthlyActivity = await _activityDataSource.getMonthlyActivity(
        targetDate.year,
        targetDate.month,
      );

      if (monthlyActivity != null) {
        for (var daily in monthlyActivity.records) {
          for (var activity in daily.activities) {
            usedApps.add(activity.appName);
          }
        }
      }
    }

    return usedApps;
  }

  @override
  Future<Set<String>> getUsedDomains() async {
    final now = DateTime.now();
    final usedDomains = Set<String>();

    // 過去3ヶ月分のログを確認
    for (var i = 0; i < 3; i++) {
      final targetDate = DateTime(now.year, now.month - i);
      final monthlyActivity = await _activityDataSource.getMonthlyActivity(
        targetDate.year,
        targetDate.month,
      );

      if (monthlyActivity != null) {
        for (var daily in monthlyActivity.records) {
          for (var activity in daily.activities) {
            if (activity.appName == 'Google Chrome' &&
                activity.details.containsKey('open_url')) {
              usedDomains.add(activity.details['open_url'] as String);
            }
          }
        }
      }
    }

    return usedDomains;
  }
}
