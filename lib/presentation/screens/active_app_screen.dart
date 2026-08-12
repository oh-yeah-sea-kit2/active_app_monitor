import 'package:flutter/material.dart';
import 'dart:async';
import '../../application/services/activity_service.dart';
import '../../domain/entities/app_activity.dart';
import '../widgets/activity_display.dart';
import '../widgets/permission_status_widget.dart';
import '../screens/settings_screen.dart';
import '../screens/work_duration_report_screen.dart';

class ActiveAppScreen extends StatefulWidget {
  final ActivityService activityService;

  const ActiveAppScreen({Key? key, required this.activityService})
      : super(key: key);

  @override
  _ActiveAppScreenState createState() => _ActiveAppScreenState();
}

class _ActiveAppScreenState extends State<ActiveAppScreen> {
  AppActivity? _currentActivity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    // 2秒ごとにアクティビティを取得
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final activity = await widget.activityService.getCurrentActivity();
      setState(() {
        _currentActivity = activity;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active App Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkDurationReportScreen(
                    activityService: widget.activityService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    settingsRepository:
                        widget.activityService.settingsRepository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const PermissionStatusWidget(),
          Expanded(
            child: Center(
              child: _currentActivity == null
                  ? const CircularProgressIndicator()
                  : ActivityDisplay(activity: _currentActivity!),
            ),
          ),
        ],
      ),
    );
  }
}
