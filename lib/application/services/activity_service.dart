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

    recordingService.startNewActivity(
        appName, chromeUrl != 'Not active' ? chromeUrl : null);

    return AppActivity(
      appName: appName,
      chromeUrl: chromeUrl,
      isUserActive: isUserActive,
      timestamp: DateTime.now(),
    );
  }

  Future<void> dispose() async {
    await recordingService.dispose();
  }
}
