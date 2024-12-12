import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'infrastructure/datasources/platform_channel_datasource.dart';
import 'infrastructure/datasources/json_file_datasource.dart';
import 'infrastructure/repositories/activity_repository_impl.dart';
import 'infrastructure/repositories/settings_repository_impl.dart';
import 'application/services/activity_service.dart';
import 'application/services/activity_recording_service.dart';
import 'presentation/screens/active_app_screen.dart';
import 'infrastructure/datasources/settings_file_datasource.dart';
import 'infrastructure/system/menu_bar_manager.dart';
import 'infrastructure/system/window_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WindowManagerの初期化
  await windowManager.ensureInitialized();

  final settingsDataSource = SettingsFileDataSource();
  final jsonFileDataSource = JsonFileDataSource();

  final settingsRepository = SettingsRepositoryImpl(
    settingsDataSource,
    jsonFileDataSource,
  );
  final activityRepository =
      ActivityRepositoryImpl(PlatformChannelDataSource());

  final recordingService = ActivityRecordingService(
    jsonFileDataSource,
    settingsRepository,
  );

  final activityService = ActivityService(
    activityRepository,
    recordingService,
    settingsRepository,
  );

  // メニューバーの初期化
  await MenuBarManager.initialize();

  // ウィンドウの初期設定
  await windowManager.setPreventClose(false);
  await windowManager.setSkipTaskbar(false);

  // ウィンドウイベントの設定
  windowManager.addListener(AppWindowListener());

  runApp(MyApp(activityService: activityService));
}

class MyApp extends StatelessWidget {
  final ActivityService activityService;

  const MyApp({Key? key, required this.activityService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Active App Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      home: ActiveAppScreen(activityService: activityService),
    );
  }
}
