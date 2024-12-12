import 'package:flutter/material.dart';
import '../../domain/entities/monitor_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsRepository settingsRepository;

  const SettingsScreen({Key? key, required this.settingsRepository})
      : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  MonitorSettings? _settings;
  final _appNameController = TextEditingController();
  final _domainController = TextEditingController();
  String? _appDirectoryPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppDirectory();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _loadAppDirectory() async {
    final directory = await widget.settingsRepository.getAppDirectory();
    setState(() {
      _appDirectoryPath = directory.path;
    });
  }

  void _showAppSettingsDialog(AppMonitorSetting? app) {
    final isNewApp = app == null;
    final appNameController = TextEditingController(text: app?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNewApp ? 'アプリを追加' : 'アプリ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: appNameController,
              decoration: InputDecoration(labelText: 'アプリ名'),
              enabled: isNewApp, // 既存のアプリ名は編集不可
            ),
            if (isNewApp) ...[
              SizedBox(height: 8),
              Text(
                '※ アプリ名は正確に入力してください\n例: Code, Google Chrome',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (appNameController.text.isNotEmpty) {
                if (isNewApp) {
                  final newSettings = _settings!.addApp(appNameController.text);
                  await widget.settingsRepository.saveSettings(newSettings);
                }
                await _loadSettings();
                Navigator.pop(context);
              }
            },
            child: Text(isNewApp ? '追加' : '保存'),
          ),
        ],
      ),
    );
  }

  void _showAddDomainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('監視ドメインを追加'),
        content: TextField(
          controller: _domainController,
          decoration: InputDecoration(labelText: 'ドメイン (例: github.com)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (_domainController.text.isNotEmpty) {
                final chromeApp = _settings!.targetApps.firstWhere(
                  (app) => app.name == 'Google Chrome',
                );
                final newDomains = [
                  ...chromeApp.targetDomains,
                  _domainController.text
                ];
                final updatedApp = chromeApp.copyWithDomains(newDomains);
                final newSettings = _settings!.updateApp(updatedApp);
                await widget.settingsRepository.saveSettings(newSettings);
                await _loadSettings();
                _domainController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('追加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) {
      return Scaffold(
        appBar: AppBar(title: Text('監視設定')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('監視設定'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppSettingsDialog(null),
        child: Icon(Icons.add),
        tooltip: '監視アプリを追加',
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '監視アプリ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._settings!.targetApps.map((app) => ExpansionTile(
                initiallyExpanded: app.name == 'Google Chrome',
                title: Text(app.name),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final newSettings = _settings!.removeApp(app.name);
                    await widget.settingsRepository.saveSettings(newSettings);
                    await _loadSettings();
                  },
                ),
                children: [
                  if (app.name == 'Google Chrome') ...[
                    Container(
                      color: Colors.grey.withOpacity(0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '監視ドメイン設定',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.web),
                            title: Text('監視ドメインを追加'),
                            trailing: IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _showAddDomainDialog(),
                            ),
                          ),
                          ...app.targetDomains.map((domain) => ListTile(
                                leading: SizedBox(width: 32),
                                title: Text(domain),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () async {
                                    final newDomains = app.targetDomains
                                        .where((d) => d != domain)
                                        .toList();
                                    final updatedApp =
                                        app.copyWithDomains(newDomains);
                                    final newSettings =
                                        _settings!.updateApp(updatedApp);
                                    await widget.settingsRepository
                                        .saveSettings(newSettings);
                                    await _loadSettings();
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              )),
          if (_appDirectoryPath != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ファイル保存場所',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '設定ファイル:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text('$_appDirectoryPath/settings.json'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'アクティビティログ:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text('$_appDirectoryPath/activities/'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _domainController.dispose();
    super.dispose();
  }
}
