import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';

class ActivityChartImage extends StatelessWidget {
  final AppActivity activity;

  const ActivityChartImage({super.key, required this.activity});

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
      padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 16),
          ],
          if (sortedDomains.isNotEmpty) ...[
            _buildChartSection(
              'Chromeの監視ドメイン内訳',
              sortedDomains,
              activity.todayWorkDuration!,
              Colors.green.shade100,
            ),
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.3),
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
          const SizedBox(height: 12),
          ...items.map((item) {
            final percentage = totalDuration.inSeconds > 0
                ? item.value.inSeconds / totalDuration.inSeconds * 100
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.key,
                          style: const TextStyle(fontSize: 14),
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
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.shade400,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 2),
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
          }),
        ],
      ),
    );
  }
}
