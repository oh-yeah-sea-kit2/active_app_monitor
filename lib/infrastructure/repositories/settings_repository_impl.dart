import 'dart:io';

import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_file_datasource.dart';
import '../../domain/entities/monitor_settings.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsFileDataSource _dataSource;

  SettingsRepositoryImpl(this._dataSource);

  @override
  Future<MonitorSettings> getSettings() => _dataSource.getSettings();

  @override
  Future<void> saveSettings(MonitorSettings settings) =>
      _dataSource.saveSettings(settings);

  @override
  Future<Directory> getAppDirectory() => _dataSource.appDir;
}
