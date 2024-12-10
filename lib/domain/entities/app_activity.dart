class AppActivity {
  final String appName;
  final String chromeUrl;
  final bool isUserActive;
  final DateTime timestamp;

  AppActivity({
    required this.appName,
    required this.chromeUrl,
    required this.isUserActive,
    required this.timestamp,
  });
}
