import 'dart:io';
import 'package:path/path.dart' as path;
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
    final isNewApp = app == null;
    final appNameController = TextEditingController(text: app?.name ?? '');
    final selectedApp = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNewApp ? 'アプリを追加' : 'アプリ設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isNewApp) ...[
                FutureBuilder<Set<String>>(
                  future: widget.settingsRepository.getUsedAppNames(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    final usedApps = snapshot.data!
                        .where((app) => !_settings!.isTargetApp(app))
                        .toList()
                      ..sort();

                    return Column(
                      children: [
                        DropdownButton<String>(
                          hint: Text('使用したアプリから選択'),
                          value: selectedApp.value,
                          isExpanded: true,
                          items: usedApps
                              .map((app) => DropdownMenuItem(
                                    value: app,
                                    child: Text(app),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedApp.value = value;
                              appNameController.text = value ?? '';
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        Text(
                          'または新しいアプリ名を入力：',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              TextField(
                controller: appNameController,
                decoration: InputDecoration(
                  labelText: 'アプリ名',
                  hintText: '例: Visual Studio Code',
                ),
                enabled: isNewApp,
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
                if (appNameController.text.isNotEmpty) {
                  if (isNewApp) {
                    if (_settings!.isTargetApp(appNameController.text)) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('このアプリは既に追加されています'),
                          backgroundColor: Colors.red.shade400,
                        ),
                      );
                      return;
                    }
                    final newSettings =
                        _settings!.addApp(appNameController.text);
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
      ),
    );
  }

  void _showAddDomainDialog() {
    final selectedDomain = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('監視ドメインを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<Set<String>>(
                future: widget.settingsRepository.getUsedDomains(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  final chromeApp = _settings!.targetApps.firstWhere(
                    (app) => app.name == 'Google Chrome',
                  );

                  final usedDomains = snapshot.data!
                      .where(
                          (domain) => !chromeApp.targetDomains.contains(domain))
                      .toList()
                    ..sort();

                  return Column(
                    children: [
                      DropdownButton<String>(
                        hint: Text('使用したドメインから選択'),
                        value: selectedDomain.value,
                        isExpanded: true,
                        items: usedDomains
                            .map((domain) => DropdownMenuItem(
                                  value: domain,
                                  child: Text(domain),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDomain.value = value;
                            _domainController.text = value ?? '';
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Text(
                        'または新しいドメインを入力：',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              TextField(
                controller: _domainController,
                decoration: InputDecoration(labelText: 'ドメイン (例: github.com)'),
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
                if (_domainController.text.isNotEmpty) {
                  final chromeApp = _settings!.targetApps.firstWhere(
                    (app) => app.name == 'Google Chrome',
                  );

                  if (chromeApp.targetDomains
                      .contains(_domainController.text)) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('このドメインは既に追加されています'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                    return;
                  }

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
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor, color: Colors.blue.shade700),
                SizedBox(width: 12),
                Text(
                  '監視アプリ設定',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                ..._settings!.targetApps.map((app) => Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: app.name == 'Google Chrome',
                        title: Text(
                          app.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        leading: Icon(
                          app.name == 'Google Chrome'
                              ? Icons.web
                              : Icons.desktop_windows,
                          color: Colors.blue.shade400,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade300),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('アプリの削除'),
                                content: Text('${app.name}を監視対象から削除しますか'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      '削除',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final newSettings =
                                  _settings!.removeApp(app.name);
                              await widget.settingsRepository
                                  .saveSettings(newSettings);
                              await _loadSettings();
                            }
                          },
                        ),
                        children: [
                          if (app.name == 'Google Chrome')
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '監視ドメイン設定',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add_circle,
                                              color: Colors.blue.shade400),
                                          onPressed: () =>
                                              _showAddDomainDialog(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...app.targetDomains.map(
                                    (domain) => ListTile(
                                      title: Text(
                                        domain,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red.shade300),
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
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                        ],
                      ),
                    )),
                if (_appDirectoryPath != null)
                  Card(
                    margin: EdgeInsets.only(top: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ファイル保存場所',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildPathItem(
                            '設定ファイル',
                            '$_appDirectoryPath/settings.json',
                          ),
                          SizedBox(height: 12),
                          _buildPathItem(
                            'アクティビティログ',
                            '$_activitiesDirectoryPath/',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathItem(String label, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            path,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _domainController.dispose();
    super.dispose();
  }
}
