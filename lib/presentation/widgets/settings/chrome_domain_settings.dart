import 'package:flutter/material.dart';
import '../../../domain/entities/monitor_settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class ChromeDomainSettings extends StatelessWidget {
  final AppMonitorSetting app;
  final MonitorSettings settings;
  final SettingsRepository settingsRepository;
  final Function() onSettingsChanged;
  final Function() onShowAddDomain;

  const ChromeDomainSettings({
    Key? key,
    required this.app,
    required this.settings,
    required this.settingsRepository,
    required this.onSettingsChanged,
    required this.onShowAddDomain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  icon: Icon(Icons.add_circle, color: Colors.blue.shade400),
                  onPressed: onShowAddDomain,
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
                icon: Icon(Icons.delete, color: Colors.red.shade300),
                onPressed: () => _removeDomain(domain),
              ),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _removeDomain(String domain) async {
    final newDomains = app.targetDomains.where((d) => d != domain).toList();
    final updatedApp = app.copyWithDomains(newDomains);
    final newSettings = settings.updateApp(updatedApp);
    await settingsRepository.saveSettings(newSettings);
    await onSettingsChanged();
  }
}
