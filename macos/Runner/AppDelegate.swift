import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var lastUserActivity: Date = Date()
    private var eventMonitor: Any?
    var statusItem: NSStatusItem?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = self.mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.oh-yeah-sea-kit2.activeAppMonitor",
                                           binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "getActiveApp":
                if let activeApp = NSWorkspace.shared.frontmostApplication {
                    let appName = activeApp.localizedName ?? "Unknown"
                    if appName == "loginwindow" {
                        result("No active application")  // loginwindowの場合は記録しない
                    } else {
                        result(appName)
                    }
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

        // FlutterAppDelegateの初期化を最初に呼び出す
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

    private func extractDomain(from url: String) -> String {
        guard let url = URL(string: url) else { return "" }
        
        // ホスト名（ドメイン）を取得
        guard let host = url.host else { return "" }
        
        // www.を除去（オプション）
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        
        return host
    }

    private func getActiveChromeTabURL() -> String {
        let script = """
        tell application "Google Chrome"
            get URL of active tab of first window
        end tell
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if !output.isEmpty && !output.contains("error") {
                    // URLからドメインを抽出
                    return extractDomain(from: output)
                }
            }
        } catch {
            print("Error executing script: \(error)")
        }
        
        return ""
    }

    // Secure Restorable Stateをサポートすることを明示
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}
