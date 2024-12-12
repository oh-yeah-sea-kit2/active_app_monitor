import '../../domain/entities/activity_record.dart';
import '../../domain/entities/app_activity.dart';
import '../../domain/repositories/activity_repository.dart';
import '../services/activity_recording_service.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/entities/monitor_settings.dart';

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
    final settings = await settingsRepository.getSettings();

    // 本日の作業時間を取得
    final now = DateTime.now();
    final monthlyActivity =
        await recordingService.getMonthlyActivity(now.year, now.month);

    Duration todayWorkDuration = Duration.zero;
    Duration todayTotalDuration = Duration.zero;
    Map<String, Duration> appDurations = {};
    Map<String, Duration> allAppDurations = {};

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

        // すべてのアプリの作業時間を集計
        allAppDurations.update(
          record.appName,
          (value) => value + duration,
          ifAbsent: () => duration,
        );
        todayTotalDuration += duration;

        // 監視対象アプリの作業時間を集計
        if (_isTargetActivity(record, settings)) {
          todayWorkDuration += duration;
          appDurations.update(
            record.appName,
            (value) => value + duration,
            ifAbsent: () => duration,
          );
        }
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
      todayTotalDuration: todayTotalDuration,
      appDurations: appDurations,
      allAppDurations: allAppDurations,
    );
  }

  bool _isTargetActivity(ActivityRecord activity, MonitorSettings settings) {
    if (!settings.isTargetApp(activity.appName)) {
      return false;
    }

    if (activity.appName == 'Google Chrome') {
      final url = activity.details['open_url'] as String?;
      if (url == null) return false;
      return settings.isTargetDomain(url);
    }

    return true;
  }

  Future<void> dispose() async {
    await recordingService.dispose();
  }

  Future<Map<String, Duration>> getWorkDurationsByDateRange(
      DateTime start, DateTime end) async {
    final activities =
        await recordingService.getActivitiesByDateRange(start, end);
    final settings = await settingsRepository.getSettings();

    // アプリごとの作業時間を集計（監視対象のみ）
    final Map<String, Duration> appDurations = {};
    for (var activity
        in activities.where((a) => _isTargetActivity(a, settings))) {
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
