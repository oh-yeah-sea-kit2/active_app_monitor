import 'package:active_app_monitor/domain/entities/activity_record.dart';

class DailyActivity {
  final DateTime date;
  final List<ActivityRecord> activities;

  DailyActivity({
    required this.date,
    required this.activities,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: DateTime.parse(json['date']),
      activities: (json['activities'] as List)
          .map((activity) => ActivityRecord.fromJson(activity))
          .toList(),
    );
  }
}
