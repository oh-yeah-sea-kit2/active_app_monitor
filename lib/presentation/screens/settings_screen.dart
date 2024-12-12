import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../../domain/entities/monitor_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../widgets/settings/app_settings_dialog.dart';
import '../widgets/settings/add_domain_dialog.dart';
import '../widgets/settings/settings_header.dart';
import '../widgets/settings/monitor_app_list_item.dart';
import '../widgets/settings/settings_file_paths.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const SettingsScreen({Key? key, required this.settingsRepository})
      : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  MonitorSettings? _settings;
  final _domainController = TextEditingController();
  String? _appDirectoryPath;
  String? _activitiesDirectoryPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDirectoryPaths();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _loadDirectoryPaths() async {
    final directory = await widget.settingsRepository.getAppDirectory();
    final activitiesDir = Directory(path.join(directory.path, 'activities'));
    if (!await activitiesDir.exists()) {
      await activitiesDir.create(recursive: true);
    }

    setState(() {
      _appDirectoryPath = directory.path;
      _activitiesDirectoryPath = activitiesDir.path;
    });
  }

  void _showAppSettingsDialog(AppMonitorSetting? app) {
    showDialog(
      context: context,
      builder: (context) => AppSettingsDialog(
        app: app,
        settingsRepository: widget.settingsRepository,
        settings: _settings!,
        onSettingsChanged: _loadSettings,
      ),
    );
  }

  void _showAddDomainDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDomainDialog(
        domainController: _domainController,
        settingsRepository: widget.settingsRepository,
        settings: _settings!,
        onSettingsChanged: _loadSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('監視設定'),
          backgroundColor: Colors.blue.shade100,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('監視設定'),
        backgroundColor: Colors.blue.shade100,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppSettingsDialog(null),
        child: Icon(Icons.add),
        tooltip: '監視アプリを追加',
        backgroundColor: Colors.blue.shade400,
      ),
      body: Column(
        children: [
          SettingsHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                ..._settings!.targetApps.map(
                  (app) => MonitorAppListItem(
                    app: app,
                    settings: _settings!,
                    settingsRepository: widget.settingsRepository,
                    onSettingsChanged: _loadSettings,
                    onShowAppSettings: _showAppSettingsDialog,
                    onShowAddDomain: _showAddDomainDialog,
                  ),
                ),
                if (_appDirectoryPath != null &&
                    _activitiesDirectoryPath != null)
                  SettingsFilePaths(
                    appDirectoryPath: _appDirectoryPath!,
                    activitiesDirectoryPath: _activitiesDirectoryPath!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }
}
