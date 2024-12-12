import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';

class ActivityDisplay extends StatelessWidget {
  final AppActivity activity;

  const ActivityDisplay({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedApps = activity.appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedAllApps = activity.allAppDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedDomains = activity.chromeDomainDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    print(sortedDomains);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '監視対象の作業時間',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
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
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '総作業時間',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          activity.formattedTotalDuration,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (sortedApps.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    '監視対象アプリの内訳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildAppList(sortedApps, activity.todayWorkDuration!),
                  if (sortedDomains.isNotEmpty) ...[
                    SizedBox(height: 24),
                    Text(
                      'Chromeの監視ドメイン内訳',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildAppList(sortedDomains, activity.todayWorkDuration!),
                  ],
                ],
                if (sortedAllApps.isNotEmpty) ...[
                  SizedBox(height: 24),
                  Text(
                    '全アプリの内訳',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildAppList(sortedAllApps, activity.todayTotalDuration!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(
      List<MapEntry<String, Duration>> apps, Duration totalDuration) {
    return Column(
      children: apps.map((entry) {
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
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
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
              SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
