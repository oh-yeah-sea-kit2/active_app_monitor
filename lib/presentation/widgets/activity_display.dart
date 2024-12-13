import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';
import 'activity_chart_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityDisplay extends StatelessWidget {
  final AppActivity activity;
  final GlobalKey _chartKey = GlobalKey();

  ActivityDisplay({Key? key, required this.activity}) : super(key: key);

  Future<void> _shareToTwitter(BuildContext context) async {
    final workDuration = activity.formattedWorkDuration;

    // アプリの内訳を取得
    final sortedApps = activity.appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位3つを取得し、文字列に変換
    final topApps = sortedApps.take(3);
    final appBreakdown = topApps.map((entry) {
      return '- ${entry.key}: ${activity.formatDuration(entry.value)}';
    }).join('\n');

    // 3つ以上ある場合は「etc...」を追加
    final hasMore = sortedApps.length > 3;
    final breakdownText = hasMore ? '$appBreakdown\netc...' : appBreakdown;

    final text = '''今日の作業時間📊: $workDuration

【内訳】
$breakdownText

#ActiveAppMonitor''';

    final encodedText = Uri.encodeComponent(text);
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText';

    if (await canLaunchUrl(Uri.parse(twitterUrl))) {
      await launchUrl(Uri.parse(twitterUrl));
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Twitterを開けませんでした'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(),
          _buildSummaryCard(),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton.icon(
                onPressed: () => _shareToTwitter(context),
                icon: Icon(
                  Icons.share,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  'Twitterで共有',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1DA1F2), // Twitterブランドカラー
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
          RepaintBoundary(
            key: _chartKey,
            child: ActivityChartImage(activity: activity),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              activity.isUserActive ? Icons.person : Icons.person_off,
              color: activity.isUserActive ? Colors.green : Colors.grey,
              size: 24,
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ユーザー状態',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  activity.isUserActive ? 'アクティブ' : 'アイドル',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: activity.isUserActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '現在のアプリ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                // Chromeの場合のドメイン表示用
                if (activity.appName == 'Google Chrome' &&
                    activity.chromeUrl.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        activity.appName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        activity.chromeUrl,
                        style: TextStyle(
                          fontSize: 12, // ドメインの文字サイズを小さく
                          color: Colors.grey.shade600, // 色も薄くして区別しやすく
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  )
                else
                  Text(
                    activity.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.end,
                  ),
              ],
            ),
          ],
        ),
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
}
