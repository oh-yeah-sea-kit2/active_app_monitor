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

    await recordingService.startNewActivity(
        appName, chromeUrl != 'Not active' ? chromeUrl : null, isUserActive);

    // 本日の作業時間を取得
    final now = DateTime.now();
    final monthlyActivity =
        await recordingService.getMonthlyActivity(now.year, now.month);

    Duration todayWorkDuration = Duration.zero;
    Duration todayTotalDuration = Duration.zero;
    Map<String, Duration> appDurations = {};
    Map<String, Duration> allAppDurations = {};
    Map<String, Duration> chromeDomainDurations = {};

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

        // Chromeのドメイン別作業時間を集計
        if (record.appName == 'Google Chrome' &&
            record.details.containsKey('open_url')) {
          final domain = record.details['open_url'] as String;
          if (settings.isTargetDomain(domain)) {
            chromeDomainDurations.update(
              domain,
              (value) => value + duration,
              ifAbsent: () => duration,
            );
          }
        }
      }
    }

    return AppActivity(
      appName: appName,
      chromeUrl: chromeUrl,
      isUserActive: isUserActive,
      timestamp: DateTime.now(),
      todayWorkDuration: todayWorkDuration,
      todayTotalDuration: todayTotalDuration,
      appDurations: appDurations,
      allAppDurations: allAppDurations,
      chromeDomainDurations: chromeDomainDurations,
    );
  }

  bool _isTargetActivity(ActivityRecord activity, MonitorSettings settings) {
    // まずアプリが監視対象かチェック
    if (!settings.isTargetApp(activity.appName)) {
      return false;
    }

    // Chromeの場合は、URLが監視対象ドメインかもチェック
    if (activity.appName == 'Google Chrome' &&
        activity.details.containsKey('open_url')) {
      final url = activity.details['open_url'] as String;
      return settings.isTargetDomain(url);
    }

    // Chrome以外のアプリはここまで到達
    return true;
  }

  Future<void> dispose() async {
    await recordingService.dispose();
  }

  Future<WorkDurationResult> getWorkDurationsByDateRange(
      DateTime start, DateTime end) async {
    final activities =
        await recordingService.getActivitiesByDateRange(start, end);
    final settings = await settingsRepository.getSettings();

    final Map<String, Duration> appDurations = {};
    final Map<String, Duration> domainDurations = {};
    final Map<String, Duration> allAppDurations = {};

    for (var activity in activities) {
      final duration = activity.endTime.difference(activity.startTime);

      if (_isTargetActivity(activity, settings)) {
        appDurations.update(
          activity.appName,
          (value) => value + duration,
          ifAbsent: () => duration,
        );

        if (activity.appName == 'Google Chrome' &&
            activity.details.containsKey('open_url')) {
          final domain = activity.details['open_url'] as String;
          if (settings.isTargetDomain(domain)) {
            domainDurations.update(
              domain,
              (value) => value + duration,
              ifAbsent: () => duration,
            );
          }
        }

        allAppDurations.update(
          activity.appName,
          (value) => value + duration,
          ifAbsent: () => duration,
        );
      }
    }

    return WorkDurationResult(
      appDurations: appDurations,
      domainDurations: domainDurations,
      allAppDurations: allAppDurations,
    );
  }
}

class WorkDurationResult {
  final Map<String, Duration> appDurations;
  final Map<String, Duration> domainDurations;
  final Map<String, Duration> allAppDurations;

  WorkDurationResult({
    required this.appDurations,
    required this.domainDurations,
    required this.allAppDurations,
  });
}
