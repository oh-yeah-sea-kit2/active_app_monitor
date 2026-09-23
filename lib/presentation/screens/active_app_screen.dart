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

  const ActiveAppScreen({super.key, required this.activityService});

  @override
  State<ActiveAppScreen> createState() => _ActiveAppScreenState();
}

class _ActiveAppScreenState extends State<ActiveAppScreen> {
  AppActivity? _currentActivity;
  Timer? _timer;
  bool _isTicking = false;

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
    _tick();
    // 2秒ごとにアクティビティを取得
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_isTicking) return;

    _isTicking = true;
    try {
      final activity = await widget.activityService.getCurrentActivity();
      if (!mounted || _hasNoVisibleChange(activity)) return;

      setState(() {
        _currentActivity = activity;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to update current activity: $e\n$stackTrace');
    } finally {
      _isTicking = false;
    }
  }

  bool _hasNoVisibleChange(AppActivity activity) {
    final currentActivity = _currentActivity;
    if (currentActivity == null) return false;

    return currentActivity.appName == activity.appName &&
        currentActivity.chromeUrl == activity.chromeUrl &&
        currentActivity.isUserActive == activity.isUserActive &&
        currentActivity.todayWorkDuration?.inMinutes ==
            activity.todayWorkDuration?.inMinutes &&
        currentActivity.todayTotalDuration?.inMinutes ==
            activity.todayTotalDuration?.inMinutes;
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
