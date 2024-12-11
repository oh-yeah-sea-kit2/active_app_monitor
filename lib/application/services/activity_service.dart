import '../../domain/entities/app_activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../services/activity_recording_service.dart';
import '../../domain/repositories/settings_repository.dart';

class ActivityService {
  final ActivityRepository repository;
  final ActivityRecordingService recordingService;
  final SettingsRepository settingsRepository;

  ActivityService(
      this.repository, this.recordingService, this.settingsRepository);

  Future<AppActivity> getCurrentActivity() async {
    final appName = await repository.getActiveApp();
    final chromeUrl = await repository.getChromeURL();
    final isUserActive = await repository.getUserActivity();

    // 本日の作業時間を取得
    final now = DateTime.now();
    final monthlyActivity =
        await recordingService.getMonthlyActivity(now.year, now.month);

    Duration todayWorkDuration = Duration.zero;
    Map<String, Duration> appDurations = {};

    if (monthlyActivity != null) {
      final todayRecords = monthlyActivity.records
          .where((record) =>
              record.date.year == now.year &&
              record.date.month == now.month &&
              record.date.day == now.day)
          .expand((daily) => daily.activities)
          .toList();

      for (var record in todayRecords) {
        final duration = record.endTime.difference(record.startTime);
        todayWorkDuration += duration;

        // アプリごとの作業時間を集計
        appDurations.update(
          record.appName,
          (value) => value + duration,
          ifAbsent: () => duration,
        );
      }
    }

    recordingService.startNewActivity(
        appName, chromeUrl != 'Not active' ? chromeUrl : null);

    return AppActivity(
      appName: appName,
      chromeUrl: chromeUrl,
      isUserActive: isUserActive,
      timestamp: DateTime.now(),
      todayWorkDuration: todayWorkDuration,
      appDurations: appDurations,
    );
  }

  Future<void> dispose() async {
    await recordingService.dispose();
  }

  Future<Map<String, Duration>> getWorkDurationsByDateRange(
      DateTime start, DateTime end) async {
    final activities =
        await recordingService.getActivitiesByDateRange(start, end);

    // アプリごとの作業時間を集計
    final Map<String, Duration> appDurations = {};
    for (var activity in activities) {
      final duration = activity.endTime.difference(activity.startTime);
      appDurations.update(
        activity.appName,
        (value) => value + duration,
        ifAbsent: () => duration,
      );
    }

    return appDurations;
  }
}
