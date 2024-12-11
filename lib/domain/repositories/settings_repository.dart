import 'package:active_app_monitor/domain/entities/monitor_settings.dart';

abstract class SettingsRepository {
  Future<MonitorSettings> getSettings();
  Future<void> saveSettings(MonitorSettings settings);
}
