import 'package:flutter/material.dart';
import '../../../domain/entities/monitor_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'chrome_domain_settings.dart';

class MonitorAppListItem extends StatelessWidget {
  final AppMonitorSetting app;
  final MonitorSettings settings;
  final SettingsRepository settingsRepository;
  final Function() onSettingsChanged;
  final Function(AppMonitorSetting?) onShowAppSettings;
  final Function() onShowAddDomain;

  const MonitorAppListItem({
    Key? key,
    required this.app,
    required this.settings,
    required this.settingsRepository,
    required this.onSettingsChanged,
    required this.onShowAppSettings,
    required this.onShowAddDomain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
          app.name == 'Google Chrome' ? Icons.web : Icons.desktop_windows,
          color: Colors.blue.shade400,
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade300),
          onPressed: () => _showDeleteConfirmDialog(context),
        ),
        children: [
          if (app.name == 'Google Chrome')
            ChromeDomainSettings(
              app: app,
              settings: settings,
              settingsRepository: settingsRepository,
              onSettingsChanged: onSettingsChanged,
              onShowAddDomain: onShowAddDomain,
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('アプリの削除'),
        content: Text('${app.name}を監視対象から削除しますか'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newSettings = settings.removeApp(app.name);
      await settingsRepository.saveSettings(newSettings);
      await onSettingsChanged();
    }
  }
}
