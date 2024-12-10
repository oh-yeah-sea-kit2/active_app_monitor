import 'package:flutter/material.dart';
import 'dart:async';
import '../../application/services/activity_service.dart';
import '../../domain/entities/app_activity.dart';
import '../widgets/activity_display.dart';

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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
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
        title: Text('Active App & Chrome URL Monitor'),
      ),
      body: Center(
        child: _currentActivity == null
            ? CircularProgressIndicator()
            : ActivityDisplay(activity: _currentActivity!),
      ),
    );
  }
}
