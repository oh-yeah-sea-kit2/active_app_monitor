import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var lastUserActivity: Date = Date()
    private var eventMonitor: Any?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = self.mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.active_app_display",
                                           binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "getActiveApp":
                if let activeApp = NSWorkspace.shared.frontmostApplication {
                    result(activeApp.localizedName ?? "Unknown")
                } else {
                    result("No active application")
                }
            case "getChromeURL":
                result(self.getActiveChromeTabURL())
            case "getLastActivity":
                let timeInterval = -self.lastUserActivity.timeIntervalSinceNow
                result(timeInterval)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Start monitoring keyboard and mouse activity
        startMonitoringUserActivity()

        super.applicationDidFinishLaunching(notification)
    }

    override func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func startMonitoringUserActivity() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .mouseMoved]) { event in
            self.lastUserActivity = Date()
        }
    }

    private func getActiveChromeTabURL() -> String {
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
            activeApp.localizedName == "Google Chrome" else {
            return "Not active"
        }

        let script = """
        tell application "Google Chrome"
            if not (exists front window) then
                return "No active window"
            else
                return URL of active tab of front window
            end if
        end tell
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                return output
            } else if let error = error {
                // AppleScriptエラーを詳しく返す
                return "AppleScript Error: \(error)"
            }
        }
        return "Failed to execute script"
    }


}
