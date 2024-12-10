import '../../domain/repositories/activity_repository.dart';
import '../datasources/platform_channel_datasource.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final PlatformChannelDataSource dataSource;
  // アクティビティのタイムアウト値（秒）
  static const double activityTimeoutSeconds = 10.0;

  ActivityRepositoryImpl(this.dataSource);

  @override
  Future<String> getActiveApp() async {
    return await dataSource.getActiveApp();
  }

  @override
  Future<String> getChromeURL() async {
    return await dataSource.getChromeURL();
  }

  @override
  Future<bool> getUserActivity() async {
    final lastActivity = await dataSource.getLastActivity();
    return lastActivity < activityTimeoutSeconds;
  }
}
