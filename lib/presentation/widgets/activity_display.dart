import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';

class ActivityDisplay extends StatelessWidget {
  final AppActivity activity;

  const ActivityDisplay({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedApps = activity.appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 合計作業時間を計算
    final totalDuration = sortedApps.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.value,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '本日の作業時間',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  activity.formattedWorkDuration,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 24),
                if (sortedApps.isNotEmpty) ...[
                  Text(
                    '内訳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...sortedApps.map((entry) {
                    final percentage = totalDuration.inSeconds > 0
                        ? entry.value.inSeconds / totalDuration.inSeconds * 100
                        : 0.0;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                activity.formatDuration(entry.value),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.withOpacity(0.7),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          Text(
            'Current Active App:',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          Text(
            activity.appName,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          if (activity.chromeUrl != 'Not active')
            Column(
              children: [
                Text(
                  'Chrome URL:',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  activity.chromeUrl,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          SizedBox(height: 20),
          Text(
            'User Activity:',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          Text(
            activity.isUserActive ? 'User is active' : 'User is idle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
