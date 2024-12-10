import 'package:flutter/material.dart';
import '../../domain/entities/app_activity.dart';

class ActivityDisplay extends StatelessWidget {
  final AppActivity activity;

  const ActivityDisplay({Key? key, required this.activity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Current Active App:',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        Text(
          activity.appName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        if (activity.chromeUrl != 'Not active')
          Column(
            children: [
              Text(
                'Chrome URL:',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Text(
                activity.chromeUrl,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        SizedBox(height: 20),
        Text(
          'User Activity:',
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(height: 10),
        Text(
          activity.isUserActive ? 'User is active' : 'User is idle',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
