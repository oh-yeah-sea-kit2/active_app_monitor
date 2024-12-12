class AppActivity {
  final String appName;
  final String chromeUrl;
  final bool isUserActive;
  final DateTime timestamp;
  final Duration? todayWorkDuration;
  final Duration? todayTotalDuration;
  final Map<String, Duration> appDurations;
  final Map<String, Duration> allAppDurations;

  AppActivity({
    required this.appName,
    required this.chromeUrl,
    required this.isUserActive,
    required this.timestamp,
    this.todayWorkDuration,
    this.todayTotalDuration,
    this.appDurations = const {},
    this.allAppDurations = const {},
  });

  String get formattedWorkDuration {
    if (todayWorkDuration == null) return '0時間0分';
    return _formatDuration(todayWorkDuration!);
  }

  String get formattedTotalDuration {
    if (todayTotalDuration == null) return '0時間0分';
    return _formatDuration(todayTotalDuration!);
  }

  String formatDuration(Duration duration) {
    return _formatDuration(duration);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}時間${minutes}分';
    }
    return '${minutes}分';
  }
}
