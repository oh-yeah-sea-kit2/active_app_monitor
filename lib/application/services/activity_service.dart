import '../../domain/entities/app_activity.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityService {
  final ActivityRepository repository;

  ActivityService(this.repository);

  Future<AppActivity> getCurrentActivity() async {
    final appName = await repository.getActiveApp();
    final chromeUrl = await repository.getChromeURL();
    final isUserActive = await repository.getUserActivity();

    return AppActivity(
      appName: appName,
      chromeUrl: chromeUrl,
      isUserActive: isUserActive,
      timestamp: DateTime.now(),
    );
  }
}
