import 'dart:io';

import 'package:active_app_monitor/domain/entities/monitor_settings.dart';

abstract class SettingsRepository {
  Future<MonitorSettings> getSettings();
  Future<void> saveSettings(MonitorSettings settings);
  Future<Directory> getAppDirectory();
  Future<Set<String>> getUsedAppNames();
  Future<Set<String>> getUsedDomains();
}
