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

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSummaryCard(),
          SizedBox(height: 24),
          if (sortedApps.isNotEmpty) ...[
            _buildSectionCard(
              '監視対象アプリの内訳',
              sortedApps,
              activity.todayWorkDuration!,
              Colors.blue.shade100,
            ),
            SizedBox(height: 16),
          ],
          if (sortedDomains.isNotEmpty) ...[
            _buildSectionCard(
              'Chromeの監視ドメイン内訳',
              sortedDomains,
              activity.todayWorkDuration!,
              Colors.green.shade100,
            ),
            SizedBox(height: 16),
          ],
          if (sortedAllApps.isNotEmpty)
            _buildSectionCard(
              '全アプリの内訳',
              sortedAllApps,
              activity.todayTotalDuration!,
              Colors.grey.shade100,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              '監視対象の作業時間',
              activity.formattedWorkDuration,
              Colors.blue,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.grey.shade300,
            ),
            _buildSummaryItem(
              '総作業時間',
              activity.formattedTotalDuration,
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    List<MapEntry<String, Duration>> items,
    Duration totalDuration,
    Color backgroundColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final percentage = totalDuration.inSeconds > 0
                    ? item.value.inSeconds / totalDuration.inSeconds * 100
                    : 0.0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.key,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            activity.formatDuration(item.value),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade400,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
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
              },
            ),
          ],
        ),
      ),
    );
  }
}
