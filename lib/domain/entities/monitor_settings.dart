class AppMonitorSetting {
  final String name;
  final Map<String, dynamic> details;

  AppMonitorSetting({
    required this.name,
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  Map<String, dynamic> toJson() => {
        'name': name,
        'details': details,
      };

  factory AppMonitorSetting.fromJson(Map<String, dynamic> json) {
    return AppMonitorSetting(
      name: json['name'],
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  // Chromeの場合の便利メソッド
  List<String> get targetDomains {
    if (name != 'Google Chrome') return [];
    final domains = details['target_domains'];
    if (domains == null) return [];
    return List<String>.from(domains);
  }

  // Chromeの場合のドメイン設定用メソッド
  AppMonitorSetting copyWithDomains(List<String> domains) {
    if (name != 'Google Chrome') return this;
    return AppMonitorSetting(
      name: name,
      details: {
        ...details,
        'target_domains': domains,
      },
    );
  }
}

class MonitorSettings {
  final List<AppMonitorSetting> targetApps;

  MonitorSettings({
    required this.targetApps,
  });

  Map<String, dynamic> toJson() => {
        'target_apps': targetApps.map((app) => app.toJson()).toList(),
      };

  factory MonitorSettings.fromJson(Map<String, dynamic> json) {
    return MonitorSettings(
      targetApps: (json['target_apps'] as List)
          .map((app) => AppMonitorSetting.fromJson(app))
          .toList(),
    );
  }

  // デフォルト設定
  factory MonitorSettings.defaultSettings() {
    return MonitorSettings(
      targetApps: [
        AppMonitorSetting(name: 'Code'),
        AppMonitorSetting(name: 'Cursor'),
        AppMonitorSetting(name: 'Slack'),
        AppMonitorSetting(
          name: 'Google Chrome',
          details: {
            'target_domains': [
              'github.com',
              'stackoverflow.com',
              "qiita.com",
            ],
          },
        ),
        AppMonitorSetting(name: 'iTerm2'),
      ],
    );
  }

  // 便利メソッド
  bool isTargetApp(String appName) {
    return targetApps.any((app) => app.name == appName);
  }

  bool isTargetDomain(String url) {
    final chromeApp = targetApps.firstWhere(
      (app) => app.name == 'Google Chrome',
      orElse: () => AppMonitorSetting(name: 'Google Chrome'),
    );

    // URLがhttpsまたはhttpで始まっていない場合は、ドメインとして直接比較
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final isTarget = chromeApp.targetDomains.any((domain) {
        final matches = url.endsWith(domain);
        return matches;
      });
      return isTarget;
    }

    // 完全なURLの場合は従来通りの処理
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }

    final isTarget = chromeApp.targetDomains.any((domain) {
      final matches = uri.host.endsWith(domain);
      return matches;
    });

    return isTarget;
  }

  // アプリ設定の更新
  MonitorSettings updateApp(AppMonitorSetting updatedApp) {
    final updatedApps = targetApps.map((app) {
      if (app.name == updatedApp.name) {
        return updatedApp;
      }
      return app;
    }).toList();

    return MonitorSettings(targetApps: updatedApps);
  }

  // アプリの追加
  MonitorSettings addApp(String appName) {
    if (isTargetApp(appName)) return this;

    return MonitorSettings(
      targetApps: [
        ...targetApps,
        AppMonitorSetting(name: appName),
      ],
    );
  }

  // アプリの削除
  MonitorSettings removeApp(String appName) {
    return MonitorSettings(
      targetApps: targetApps.where((app) => app.name != appName).toList(),
    );
  }
}
