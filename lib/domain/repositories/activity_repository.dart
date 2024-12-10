abstract class ActivityRepository {
  Future<String> getActiveApp();
  Future<String> getChromeURL();
  Future<bool> getUserActivity();
}
