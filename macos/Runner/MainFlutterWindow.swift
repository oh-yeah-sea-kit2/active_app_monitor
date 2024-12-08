import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // ウィンドウのデリゲート設定
    self.delegate = self

    super.awakeFromNib()
  }

  // ウィンドウを閉じた際にDockアイコンを非表示にする
  func windowWillClose(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory) // Dockアイコンを非表示
  }
}
