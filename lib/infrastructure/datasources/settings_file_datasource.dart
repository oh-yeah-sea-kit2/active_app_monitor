import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'base_file_datasource.dart';
import 'package:active_app_monitor/domain/entities/monitor_settings.dart';

class SettingsFileDataSource extends BaseFileDataSource {
  static const String settingsFileName = 'settings.json';

  Future<File> get _settingsFile async {
    final dir = await appDir;
    return File(path.join(dir.path, settingsFileName));
  }

  Future<MonitorSettings> getSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return MonitorSettings.fromJson(json.decode(jsonString));
      }
      // ファイルが存在しない場合はデフォルト設定を返す
      final defaultSettings = MonitorSettings.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      return MonitorSettings.defaultSettings();
    }
  }

  Future<void> saveSettings(MonitorSettings settings) async {
    final file = await _settingsFile;
    await file.writeAsString(json.encode(settings.toJson()));
  }
}
