class ActivityRecord {
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> details;

  ActivityRecord({
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_name': appName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'details': details,
    };
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      appName: json['app_name'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      details: json['details'],
    );
  }
}
