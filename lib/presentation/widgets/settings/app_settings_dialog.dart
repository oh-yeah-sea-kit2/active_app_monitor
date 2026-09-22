import 'package:flutter/material.dart';
import '../../../domain/entities/monitor_settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class AppSettingsDialog extends StatelessWidget {
  final AppMonitorSetting? app;
  final SettingsRepository settingsRepository;
  final MonitorSettings settings;
  final Function() onSettingsChanged;

  const AppSettingsDialog({
    super.key,
    this.app,
    required this.settingsRepository,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isNewApp = app == null;
    final appNameController = TextEditingController(text: app?.name ?? '');
    final selectedApp = ValueNotifier<String?>(null);

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(isNewApp ? 'アプリを追加' : 'アプリ設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNewApp) ...[
              FutureBuilder<Set<String>>(
                future: settingsRepository.getUsedAppNames(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final usedApps = snapshot.data!
                      .where((app) => !settings.isTargetApp(app))
                      .toList()
                    ..sort();

                  return Column(
                    children: [
                      DropdownButton<String>(
                        hint: const Text('使用したアプリから選択'),
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
                      const SizedBox(height: 16),
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
              decoration: const InputDecoration(
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
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (appNameController.text.isNotEmpty) {
                if (isNewApp) {
                  if (settings.isTargetApp(appNameController.text)) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('このアプリは既に追加されています'),
                        backgroundColor: Colors.red.shade400,
                      ),
                    );
                    return;
                  }
                  final newSettings = settings.addApp(appNameController.text);
                  await settingsRepository.saveSettings(newSettings);
                }
                await onSettingsChanged();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text(isNewApp ? '追加' : '保存'),
          ),
        ],
      ),
    );
  }
}
