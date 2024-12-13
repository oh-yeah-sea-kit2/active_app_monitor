import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';

class ActivityChartImage extends StatelessWidget {
  final AppActivity activity;

  const ActivityChartImage({Key? key, required this.activity})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedApps = activity.appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedDomains = activity.chromeDomainDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sortedAllApps = activity.allAppDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: 600,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedApps.isNotEmpty) ...[
            _buildChartSection(
              '監視対象アプリの内訳',
              sortedApps,
              activity.todayWorkDuration!,
              Colors.blue.shade100,
            ),
            SizedBox(height: 16),
          ],
          if (sortedDomains.isNotEmpty) ...[
            _buildChartSection(
              'Chromeの監視ドメイン内訳',
              sortedDomains,
              activity.todayWorkDuration!,
              Colors.green.shade100,
            ),
            SizedBox(height: 16),
          ],
          if (sortedAllApps.isNotEmpty)
            _buildChartSection(
              '全アプリの内訳',
              sortedAllApps,
              activity.todayTotalDuration!,
              Colors.grey.shade100,
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    String title,
    List<MapEntry<String, Duration>> items,
    Duration totalDuration,
    Color backgroundColor,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...items.map((item) {
            final percentage = totalDuration.inSeconds > 0
                ? item.value.inSeconds / totalDuration.inSeconds * 100
                : 0.0;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.key,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        activity.formatDuration(item.value),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                    minHeight: 8,
                  ),
                  SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
