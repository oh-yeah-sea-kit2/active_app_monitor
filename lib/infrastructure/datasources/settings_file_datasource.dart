import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'base_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/monitor_settings.dart';

class SettingsFileDataSource extends BaseFileDataSource {
  static const String settingsFileName = 'settings.json';
  MonitorSettings? _cachedSettings;

  SettingsFileDataSource({super.appDirectory});

  Future<File> get _settingsFile async {
    final dir = await appDir;
    return File(path.join(dir.path, settingsFileName));
  }

  Future<MonitorSettings> getSettings() async {
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final settings = MonitorSettings.fromJson(json.decode(jsonString));
        _cachedSettings = settings;
        return settings;
      }
      // ファイルが存在しない場合はデフォルト設定を返す
      final defaultSettings = MonitorSettings.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    } catch (e, stackTrace) {
      debugPrint('Failed to load settings: $e\n$stackTrace');
      final defaultSettings = MonitorSettings.defaultSettings();
      _cachedSettings = defaultSettings;
      return defaultSettings;
    }
  }

  Future<void> saveSettings(MonitorSettings settings) async {
    _cachedSettings = settings;
    final file = await _settingsFile;
    await file.writeAsString(json.encode(settings.toJson()));
  }
}
