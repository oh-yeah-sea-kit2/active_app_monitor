import 'package:flutter/material.dart';
import '../../application/services/activity_service.dart';
import '../../domain/entities/app_activity.dart';
import '../../presentation/widgets/activity_chart_image.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkDurationReportScreen extends StatefulWidget {
  final ActivityService activityService;

  const WorkDurationReportScreen({super.key, required this.activityService});

  @override
  State<WorkDurationReportScreen> createState() =>
      _WorkDurationReportScreenState();
}

class _WorkDurationReportScreenState extends State<WorkDurationReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  Map<String, Duration> _appDurations = {};
  Map<String, Duration> _domainDurations = {};
  Map<String, Duration> _allAppDurations = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final result = await widget.activityService.getWorkDurationsByDateRange(
      _startDate,
      _endDate,
    );

    setState(() {
      _appDurations = result.appDurations;
      _domainDurations = result.domainDurations;
      _allAppDurations = result.allAppDurations;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      currentDate: DateTime.now(),
      saveText: '選択',
      cancelText: 'キャンセル',
      confirmText: '確定',
      locale: const Locale('ja', 'JP'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  @override
  Widget build(BuildContext context) {
    final totalWorkDuration = _calculateTotalDuration(_appDurations);
    final totalDuration = _calculateTotalDuration(_allAppDurations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('作業時間レポート'),
        elevation: 0,
        backgroundColor: Colors.blue.shade100,
        actions: [
          TextButton.icon(
            onPressed: () => _shareToTwitter(
              context,
              totalWorkDuration,
              totalDuration,
            ),
            icon: const Icon(
              Icons.share,
              color: Colors.blue,
              size: 18,
            ),
            label: const Text(
              'Twitterで共有',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _startDate == _endDate
                                ? '${_formatDate(_startDate)}の作業時間'
                                : '期間: ${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text('期間を選択'),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '監視対象アプリの作業時間',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatDuration(totalWorkDuration),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '全体の作業時間',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _formatDuration(totalDuration),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ActivityChartImage(
                      activity: AppActivity(
                        appName: '',
                        chromeUrl: '',
                        isUserActive: true,
                        timestamp: DateTime.now(),
                        appDurations: _appDurations,
                        chromeDomainDurations: _domainDurations,
                        allAppDurations: _allAppDurations,
                        todayWorkDuration: totalWorkDuration,
                        todayTotalDuration: totalDuration,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Duration _calculateTotalDuration(Map<String, Duration> durations) {
    return durations.values.fold(
      Duration.zero,
      (total, duration) => total + duration,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours時間$minutes分';
    }
    return '$minutes分';
  }

  Future<void> _shareToTwitter(
      BuildContext context, Duration workDuration, Duration totalDuration) async {
    final period = _startDate == _endDate
        ? '${_formatDate(_startDate)}の'
        : '${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}の';

    // アプリの内訳を取得
    final sortedApps = _appDurations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位3つを取得し、文字列に変換
    final topApps = sortedApps.take(3);
    final appBreakdown = topApps.map((entry) {
      return '- ${entry.key}: ${_formatDuration(entry.value)}';
    }).join('\n');

    // 3つ以上ある場合は「etc...」を追加
    final hasMore = sortedApps.length > 3;
    final breakdownText = hasMore ? '$appBreakdown\netc...' : appBreakdown;

    final text = '''$period作業時間📊:
${_formatDuration(workDuration)}

【内訳】
$breakdownText

#ActiveAppMonitor''';

    final encodedText = Uri.encodeComponent(text);
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedText';

    final uri = Uri.parse(twitterUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Twitterを開けませんでした'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
