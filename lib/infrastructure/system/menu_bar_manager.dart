import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class MenuBarManager {
  static Future<void> initialize() async {
    // トレイアイコンの設定
    await trayManager.setIcon(
      'assets/icon.png',
      isTemplate: false,
    );

    // メニューの設定
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            label: 'アプリを表示',
            key: 'show_app',
            onClick: (_) async {
              await windowManager.show();
              await windowManager.focus();
            },
          ),
          MenuItem.separator(),
          MenuItem(
            label: '終了',
            key: 'quit',
            onClick: (_) {
              exit(0);
            },
          ),
        ],
      ),
    );

    // トレイのイベントリスナーを設定
    trayManager.addListener(_TrayListener());
  }
}

// TrayListenerの実装クラス
class _TrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }
}
