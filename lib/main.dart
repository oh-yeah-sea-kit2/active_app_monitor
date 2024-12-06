import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Active App & User Activity Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ActiveAppScreen(),
    );
  }
}

class ActiveAppScreen extends StatefulWidget {
  @override
  _ActiveAppScreenState createState() => _ActiveAppScreenState();
}

class _ActiveAppScreenState extends State<ActiveAppScreen> {
  static const platform = MethodChannel('com.example.active_app_display');
  String _activeApp = 'Unknown';
  String _userActivityStatus = 'Unknown';
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
      await _getActiveApp();
      await _getUserActivity();
    });
  }

  Future<void> _getActiveApp() async {
    try {
      final result = await platform.invokeMethod('getActiveApp');
      setState(() {
        _activeApp = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _activeApp = "Failed to get active app: ${e.message}";
      });
    }
  }

  Future<void> _getUserActivity() async {
    try {
      final lastActivity = await platform.invokeMethod('getLastActivity');
      final isUserActive = lastActivity < 5; // 5秒以内の操作をアクティブとみなす
      setState(() {
        _userActivityStatus = isUserActive ? 'User is active' : 'User is idle';
      });
    } on PlatformException catch (e) {
      setState(() {
        _userActivityStatus = "Failed to get user activity: ${e.message}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active App & User Activity Monitor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Active App:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              _activeApp,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'User Activity:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              _userActivityStatus,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Updating every second...',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
