import 'package:active_app_monitor/infrastructure/datasources/settings_file_datasource.dart';
import 'package:flutter/material.dart';
import 'infrastructure/datasources/platform_channel_datasource.dart';
import 'infrastructure/datasources/json_file_datasource.dart';
import 'infrastructure/repositories/activity_repository_impl.dart';
import 'infrastructure/repositories/settings_repository_impl.dart';
import 'application/services/activity_service.dart';
import 'application/services/activity_recording_service.dart';
import 'presentation/screens/active_app_screen.dart';

void main() {
  final platformDataSource = PlatformChannelDataSource();
  final jsonDataSource = JsonFileDataSource();
  final settingsRepository = SettingsRepositoryImpl(SettingsFileDataSource());
  final repository = ActivityRepositoryImpl(platformDataSource);
  final recordingService =
      ActivityRecordingService(jsonDataSource, settingsRepository);
  final service =
      ActivityService(repository, recordingService, settingsRepository);

  runApp(MyApp(activityService: service));
}

class MyApp extends StatelessWidget {
  final ActivityService activityService;

  const MyApp({Key? key, required this.activityService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Active App & Chrome URL Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ActiveAppScreen(activityService: activityService),
    );
  }
}
