import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = self.mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.active_app_display",
                                           binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getActiveApp" {
                if let activeApp = NSWorkspace.shared.frontmostApplication {
                    result(activeApp.localizedName ?? "Unknown")
                } else {
                    result("No active application")
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        super.applicationDidFinishLaunching(notification)
    }
}
