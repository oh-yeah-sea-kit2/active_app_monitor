import 'package:flutter/material.dart';
import '../../../domain/entities/monitor_settings.dart';
import '../../../domain/repositories/settings_repository.dart';

class AddDomainDialog extends StatelessWidget {
  final TextEditingController domainController;
  final SettingsRepository settingsRepository;
  final MonitorSettings settings;
  final Function() onSettingsChanged;

  const AddDomainDialog({
    super.key,
    required this.domainController,
    required this.settingsRepository,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDomain = ValueNotifier<String?>(null);

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('監視ドメインを追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<Set<String>>(
              future: settingsRepository.getUsedDomains(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final chromeApp = settings.targetApps
                    .firstWhere((app) => app.name == 'Google Chrome');

                final usedDomains = snapshot.data!
                    .where(
                        (domain) => !chromeApp.targetDomains.contains(domain))
                    .toList()
                  ..sort();

                return Column(
                  children: [
                    DropdownButton<String>(
                      hint: const Text('使用したドメインから選択'),
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
                          domainController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
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
              controller: domainController,
              decoration: const InputDecoration(labelText: 'ドメイン (例: github.com)'),
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
              if (domainController.text.isNotEmpty) {
                final chromeApp = settings.targetApps
                    .firstWhere((app) => app.name == 'Google Chrome');

                if (chromeApp.targetDomains.contains(domainController.text)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('このドメインは既に追加されています'),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                  return;
                }

                final newDomains = [
                  ...chromeApp.targetDomains,
                  domainController.text
                ];
                final updatedApp = chromeApp.copyWithDomains(newDomains);
                final newSettings = settings.updateApp(updatedApp);
                await settingsRepository.saveSettings(newSettings);
                await onSettingsChanged();
                domainController.clear();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}
