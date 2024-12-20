import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'base_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/daily_activity.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';

class JsonFileDataSource extends BaseFileDataSource {
  Future<File> _getMonthlyFile(int year, int month) async {
    final dir = await appDir;
    final activitiesDir = Directory(path.join(dir.path, 'activities'));
    if (!await activitiesDir.exists()) {
      await activitiesDir.create(recursive: true);
    }
    return File(path.join(activitiesDir.path,
        '${year}_${month.toString().padLeft(2, '0')}.json'));
  }

  Future<void> saveActivity(ActivityRecord record, DateTime date) async {
    Map<String, dynamic> details = record.details;
    if (record.appName == 'Google Chrome' && details.containsKey('open_url')) {
      final url = details['open_url'] as String;
      final uri = Uri.tryParse(url);
      if (uri != null) {
        details = {'open_url': uri.host};
      }
    }

    final file = await _getMonthlyFile(date.year, date.month);
    MonthlyActivity monthlyActivity;

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      monthlyActivity = MonthlyActivity.fromJson(json.decode(jsonString));

      final dateString = date.toIso8601String().split('T')[0];
      final dailyIndex = monthlyActivity.records.indexWhere(
          (daily) => daily.date.toIso8601String().split('T')[0] == dateString);

      if (dailyIndex >= 0) {
        final activities = monthlyActivity.records[dailyIndex].activities;
        if (activities.isNotEmpty) {
          final lastActivity = activities.last;

          if (lastActivity.appName == record.appName &&
              _isSameActivityContext(lastActivity, record)) {
            activities[activities.length - 1] = ActivityRecord(
              appName: lastActivity.appName,
              startTime: lastActivity.startTime,
              endTime: record.endTime,
              details: record.details,
            );
          } else {
            activities.add(record);
          }
        } else {
          activities.add(record);
        }
      } else {
        monthlyActivity.records.add(
          DailyActivity(
            date: date,
            activities: [record],
          ),
        );
      }
    } else {
      monthlyActivity = MonthlyActivity(
        year: date.year,
        month: date.month,
        records: [
          DailyActivity(
            date: date,
            activities: [record],
          ),
        ],
      );
    }

    print(file.path);
    await file.writeAsString(json.encode(monthlyActivity.toJson()));
  }

  bool _isSameActivityContext(ActivityRecord last, ActivityRecord current) {
    final lastIsActive = last.details['is_active'] as bool? ?? true;
    final currentIsActive = current.details['is_active'] as bool? ?? true;
    if (lastIsActive != currentIsActive) {
      return false;
    }

    if (last.appName == 'Google Chrome') {
      return last.details['open_url'] == current.details['open_url'];
    }
    return true;
  }

  Future<MonthlyActivity?> getMonthlyActivity(int year, int month) async {
    final file = await _getMonthlyFile(year, month);

    if (await file.exists()) {
      final jsonString = await file.readAsString();
      return MonthlyActivity.fromJson(json.decode(jsonString));
    }

    return null;
  }
}
