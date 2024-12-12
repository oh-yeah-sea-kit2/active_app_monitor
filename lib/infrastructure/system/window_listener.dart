import 'package:window_manager/window_manager.dart';

class AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // ウィンドウを非表示にする
    await windowManager.hide();
    // Dockアイコンを非表示にする
    await windowManager.setSkipTaskbar(true);
  }
}
