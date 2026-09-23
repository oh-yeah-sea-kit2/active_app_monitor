import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'base_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/daily_activity.dart';
import 'package:active_app_monitor/domain/entities/monthly_activity.dart';
import 'package:active_app_monitor/domain/entities/activity_record.dart';

typedef FileReader = Future<String> Function(File file);
typedef FileWriter = Future<void> Function(File file, String contents);

class JsonFileDataSource extends BaseFileDataSource {
  final FileReader _readFile;
  final FileWriter _writeFile;
  final Map<String, MonthlyActivity?> _monthlyCache = {};
  Future<void> _saveQueue = Future.value();

  JsonFileDataSource({
    super.appDirectory,
    FileReader? readFile,
    FileWriter? writeFile,
  })  : _readFile = readFile ?? ((file) => file.readAsString()),
        _writeFile = writeFile ??
            ((file, contents) => file.writeAsString(contents, flush: true)),
        super();

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
    final scheduledSave = _saveQueue.then((_) => _saveActivity(record, date));
    _saveQueue =
        scheduledSave.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Failed to save activity: $error\n$stackTrace');
    });
    return scheduledSave;
  }

  Future<void> _saveActivity(ActivityRecord record, DateTime date) async {
    final file = await _getMonthlyFile(date.year, date.month);
    final monthlyActivity = await getMonthlyActivity(date.year, date.month) ??
        MonthlyActivity(
          year: date.year,
          month: date.month,
          records: [],
        );

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

    _monthlyCache[_cacheKey(date.year, date.month)] = monthlyActivity;
    await _writeMonthlyActivityAtomically(file, monthlyActivity);
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
    final cacheKey = _cacheKey(year, month);
    if (_monthlyCache.containsKey(cacheKey)) {
      return _monthlyCache[cacheKey];
    }

    final file = await _getMonthlyFile(year, month);
    MonthlyActivity? monthlyActivity;

    if (await file.exists()) {
      try {
        final jsonString = await _readFile(file);
        final jsonObject = _extractFirstJsonObject(jsonString);
        if (jsonObject != null) {
          final decoded = json.decode(jsonObject);
          if (decoded is Map<String, dynamic>) {
            monthlyActivity = MonthlyActivity.fromJson(decoded);
          }
        }
      } catch (e, stackTrace) {
        debugPrint(
            'Failed to load monthly activity $year-$month: $e\n$stackTrace');
        monthlyActivity = null;
      }
    }

    _monthlyCache[cacheKey] = monthlyActivity;
    return monthlyActivity;
  }

  String _cacheKey(int year, int month) => '$year-$month';

  String? _extractFirstJsonObject(String contents) {
    final start = contents.indexOf(RegExp(r'\S'));
    if (start == -1) {
      return null;
    }
    if (contents[start] != '{') {
      throw const FormatException('Monthly activity must start with an object');
    }

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = start; index < contents.length; index++) {
      final character = contents[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (character == '\\') {
          escaped = true;
        } else if (character == '"') {
          inString = false;
        }
        continue;
      }

      if (character == '"') {
        inString = true;
      } else if (character == '{') {
        depth++;
      } else if (character == '}') {
        depth--;
        if (depth == 0) {
          return contents.substring(start, index + 1);
        }
      }
    }

    throw const FormatException('Monthly activity object is incomplete');
  }

  Future<void> _writeMonthlyActivityAtomically(
      File file, MonthlyActivity monthlyActivity) async {
    final temporaryFile = File('${file.path}.tmp');
    await _writeFile(temporaryFile, json.encode(monthlyActivity.toJson()));
    await temporaryFile.rename(file.path);
  }
}
