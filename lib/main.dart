import 'package:flutter/material.dart';
import 'infrastructure/datasources/platform_channel_datasource.dart';
import 'infrastructure/repositories/activity_repository_impl.dart';
import 'application/services/activity_service.dart';
import 'presentation/screens/active_app_screen.dart';

void main() {
  final dataSource = PlatformChannelDataSource();
  final repository = ActivityRepositoryImpl(dataSource);
  final service = ActivityService(repository);

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
