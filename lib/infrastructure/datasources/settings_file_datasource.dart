import 'dart:convert';
import 'dart:io';
import 'package:active_app_monitor/domain/entities/monitor_settings.dart';
import 'package:path_provider/path_provider.dart';

class SettingsFileDataSource {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _settingsFile async {
    final path = await _localPath;
    return File('$path/settings.json');
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
