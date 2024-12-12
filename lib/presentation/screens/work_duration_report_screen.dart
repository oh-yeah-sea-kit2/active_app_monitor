import 'package:flutter/material.dart';
import '../../application/services/activity_service.dart';

class WorkDurationReportScreen extends StatefulWidget {
  final ActivityService activityService;

  const WorkDurationReportScreen({Key? key, required this.activityService})
      : super(key: key);

  @override
  _WorkDurationReportScreenState createState() =>
      _WorkDurationReportScreenState();
}

class _WorkDurationReportScreenState extends State<WorkDurationReportScreen> {
  DateTime _startDate = DateTime.now().subtract(Duration(days: 7));
  DateTime _endDate = DateTime.now();
  Map<String, Duration> _appDurations = {};
  Map<String, Duration> _domainDurations = {};
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
            appBarTheme: AppBarTheme(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            datePickerTheme: DatePickerThemeData(
              rangeSelectionBackgroundColor: Colors.blue.withOpacity(0.1),
              rangePickerHeaderHeadlineStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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

  Widget _buildDurationList(String title, Map<String, Duration> durations) {
    final sortedItems = durations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalDuration = sortedItems.fold<Duration>(
      Duration.zero,
      (total, entry) => total + entry.value,
    );

    if (sortedItems.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final entry = sortedItems[index];
            final percentage = totalDuration.inSeconds > 0
                ? entry.value.inSeconds / totalDuration.inSeconds * 100
                : 0.0;

            return ListTile(
              title: Text(entry.key),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Text(
                _formatDuration(entry.value),
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('作業時間レポート'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _startDate == _endDate
                        ? '${_formatDate(_startDate)}の作業時間'
                        : '期間: ${_formatDate(_startDate)} ~ ${_formatDate(_endDate)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: Icon(Icons.calendar_today),
                  label: Text('期間を選択'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            CircularProgressIndicator()
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildDurationList('アプリごとの作業時間', _appDurations),
                    _buildDurationList('Chromeのドメインごとの作業時間', _domainDurations),
                  ],
                ),
              ),
            ),
        ],
      ),
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
}
