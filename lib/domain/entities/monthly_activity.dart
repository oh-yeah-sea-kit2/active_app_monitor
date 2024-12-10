import 'package:active_app_monitor/domain/entities/daily_activity.dart';

class MonthlyActivity {
  final int year;
  final int month;
  final List<DailyActivity> records;

  MonthlyActivity({
    required this.year,
    required this.month,
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'records': records.map((record) => record.toJson()).toList(),
    };
  }

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    return MonthlyActivity(
      year: json['year'],
      month: json['month'],
      records: (json['records'] as List)
          .map((record) => DailyActivity.fromJson(record))
          .toList(),
    );
  }
}
