class AppActivity {
  final String appName;
  final String chromeUrl;
  final bool isUserActive;
  final DateTime timestamp;
  final Duration? todayWorkDuration;
  final Map<String, Duration> appDurations;

  AppActivity({
    required this.appName,
    required this.chromeUrl,
    required this.isUserActive,
    required this.timestamp,
    this.todayWorkDuration,
    this.appDurations = const {},
  });

  String get formattedWorkDuration {
    if (todayWorkDuration == null) return '0時間0分';

    final hours = todayWorkDuration!.inHours;
    final minutes = todayWorkDuration!.inMinutes.remainder(60);
    return '${hours}時間${minutes}分';
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}時間${minutes}分';
    }
    return '${minutes}分';
  }
}
