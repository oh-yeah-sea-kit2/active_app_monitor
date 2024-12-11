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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.getSettings();
    setState(() {
      _settings = settings;
    });
  }

  void _showAddAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アプリを追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _appNameController,
              decoration: InputDecoration(labelText: 'アプリ名'),
            ),
            SizedBox(height: 8),
            Text(
              '※ アプリ名は正確に入力してください\n例: Visual Studio Code, Google Chrome',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (_appNameController.text.isNotEmpty) {
                final newSettings = _settings!.addApp(_appNameController.text);
                await widget.settingsRepository.saveSettings(newSettings);
                await _loadSettings();
                _appNameController.clear();
                Navigator.pop(context);
              }
            },
            child: Text('追加'),
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

    final chromeApp = _settings!.targetApps
        .where((app) => app.name == 'Google Chrome')
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('監視設定'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAppDialog,
        child: Icon(Icons.add),
        tooltip: '監視アプリを追加',
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '監視対象アプリ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._settings!.targetApps.map((app) => ListTile(
                title: Text(app.name),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    final newSettings = _settings!.removeApp(app.name);
                    await widget.settingsRepository.saveSettings(newSettings);
                    await _loadSettings();
                  },
                ),
              )),
          if (chromeApp != null) ...[
            Divider(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chrome監視ドメイン',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...chromeApp.targetDomains.map((domain) => ListTile(
                  title: Text(domain),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      final newDomains = chromeApp.targetDomains
                          .where((d) => d != domain)
                          .toList();
                      final updatedApp = chromeApp.copyWithDomains(newDomains);
                      final newSettings = _settings!.updateApp(updatedApp);
                      await widget.settingsRepository.saveSettings(newSettings);
                      await _loadSettings();
                    },
                  ),
                )),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('ドメインを追加'),
              onTap: _showAddDomainDialog,
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
