import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:active_app_monitor/domain/entities/activity_record.dart';
import 'package:active_app_monitor/infrastructure/datasources/json_file_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;
  late JsonFileDataSource dataSource;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('activity-test-');
    dataSource = JsonFileDataSource(appDirectory: temporaryDirectory);
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test('Extra data付きJSONは先頭の月次オブジェクトを読む', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    const validJson =
        '{"year":2026,"month":9,"records":[{"date":"2026-09-21","activities":[]}]}';
    await file.writeAsString('$validJson trailing bytes');

    final monthlyActivity = await dataSource.getMonthlyActivity(2026, 9);

    expect(monthlyActivity, isNotNull);
    expect(monthlyActivity!.records.single.date, DateTime(2026, 9, 21));
  });

  test('文字列内のエスケープされた引用符を含むExtra dataも先頭オブジェクトだけ読む', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    const validJson =
        r'{"year":2026,"month":9,"records":[{"date":"2026-09-21","activities":[{"app_name":"Say \"hi\"","start_time":"2026-09-21T10:00:00.000","end_time":"2026-09-21T10:01:00.000","details":{"is_active":true}}]}]}';
    await file.writeAsString('$validJson trailing {garbage}');

    final monthlyActivity = await dataSource.getMonthlyActivity(2026, 9);

    expect(monthlyActivity, isNotNull);
    expect(
      monthlyActivity!.records.single.activities.single.appName,
      'Say "hi"',
    );
  });

  test('空ファイルはデータなしとして扱う', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    await file.writeAsString('   \n\t');

    expect(await dataSource.getMonthlyActivity(2026, 9), isNull);
  });

  test('同じ年月は一度だけディスクから読む', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    await file.writeAsString(_emptyMonthlyJson(2026, 9));
    var readCount = 0;
    final cachedDataSource = JsonFileDataSource(
      appDirectory: temporaryDirectory,
      readFile: (target) async {
        readCount++;
        return target.readAsString();
      },
    );

    await cachedDataSource.getMonthlyActivity(2026, 9);
    await cachedDataSource.getMonthlyActivity(2026, 9);

    expect(readCount, 1);
  });

  test('Chromeのドメインはそのまま保存する', () async {
    final record = ActivityRecord(
      appName: 'Google Chrome',
      startTime: DateTime(2026, 9, 21, 10),
      endTime: DateTime(2026, 9, 21, 10, 1),
      details: const {'is_active': true, 'open_url': 'github.com'},
    );

    await dataSource.saveActivity(record, record.startTime);
    final monthlyActivity = await dataSource.getMonthlyActivity(2026, 9);

    expect(
      monthlyActivity!.records.single.activities.single.details['open_url'],
      'github.com',
    );
  });

  test('save後のgetはキャッシュの内容を返す', () async {
    final record = _record();

    await dataSource.saveActivity(record, record.startTime);
    final monthlyActivity = await dataSource.getMonthlyActivity(2026, 9);

    expect(monthlyActivity!.records.single.activities.single.appName, 'Code');
  });

  test('壊れたJSONの後のsaveは有効JSONだけを書き込む', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    await file.writeAsString('{not valid');
    final record = _record();

    await dataSource.saveActivity(record, record.startTime);

    final decoded = json.decode(await file.readAsString());
    expect(decoded, isA<Map<String, dynamic>>());
    expect((decoded as Map<String, dynamic>)['records'], hasLength(1));
  });

  test('アトミック保存は途中のtmp書き込み中も本ファイルを有効JSONに保つ', () async {
    final file = await _monthlyFile(temporaryDirectory, 2026, 9);
    await file.writeAsString(_emptyMonthlyJson(2026, 9));
    final record = _record();
    final temporaryWriteStarted = Completer<void>();
    final allowTemporaryWriteToFinish = Completer<void>();
    final atomicDataSource = JsonFileDataSource(
      appDirectory: temporaryDirectory,
      writeFile: (temporaryFile, contents) async {
        await temporaryFile.writeAsString(contents.substring(0, 8));
        temporaryWriteStarted.complete();
        await allowTemporaryWriteToFinish.future;
        await temporaryFile.writeAsString(contents, flush: true);
      },
    );

    final save = atomicDataSource.saveActivity(record, record.startTime);
    await temporaryWriteStarted.future;

    expect(json.decode(await file.readAsString()), isA<Map<String, dynamic>>());
    expect(
        (json.decode(await file.readAsString())
            as Map<String, dynamic>)['records'],
        isEmpty);

    allowTemporaryWriteToFinish.complete();
    await save;

    expect(
        (json.decode(await file.readAsString())
            as Map<String, dynamic>)['records'],
        hasLength(1));
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });
}

Future<File> _monthlyFile(Directory appDirectory, int year, int month) async {
  final activitiesDirectory =
      Directory(path.join(appDirectory.path, 'activities'));
  await activitiesDirectory.create(recursive: true);
  return File(path.join(activitiesDirectory.path,
      '${year}_${month.toString().padLeft(2, '0')}.json'));
}

String _emptyMonthlyJson(int year, int month) =>
    json.encode({'year': year, 'month': month, 'records': []});

ActivityRecord _record() => ActivityRecord(
      appName: 'Code',
      startTime: DateTime(2026, 9, 21, 10),
      endTime: DateTime(2026, 9, 21, 10, 1),
      details: const {'is_active': true},
    );
