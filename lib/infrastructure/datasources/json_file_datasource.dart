import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:active_app_monitor/domain/entities/daily_activity.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';

class JsonFileDataSource {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getMonthlyFile(int year, int month) async {
    final path = await _localPath;
    return File('$path/${year}_${month.toString().padLeft(2, '0')}.json');
  }

  Future<void> saveActivity(ActivityRecord record, DateTime date) async {
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
