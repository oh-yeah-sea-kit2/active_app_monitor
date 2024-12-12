import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var lastUserActivity: Date = Date()
    private var eventMonitor: Any?
    var statusItem: NSStatusItem?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = self.mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.active_app_display",
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
        // メニューバーアイコンの作成
        setupMenuBar()

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
            if let output = scriptObject.executeAndReturnError(&error).stringValue,
               let url = URL(string: output) {
                return url.host ?? output
            } else if let error = error {
                return "AppleScript Error: \(error)"
            }
        }
        return "Failed to execute script"
    }

    func setupMenuBar() {
        // メニューバーアイコンの作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if statusItem == nil {
            print("Failed to create status item")  // デバッグ用
            return
        }
        if let button = statusItem?.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "App Icon")
            } else {
                button.image = NSImage(named: NSImage.Name("NSApplicationIcon"))
            }
            button.action = #selector(menuBarIconClicked)
        } else {
            print("Failed to create button for status item")  // デバッグ用
        }

        // メニューを設定
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show App", action: #selector(showApp), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }


    @objc func menuBarIconClicked() {
        // メニューバーアイコンがクリックされたときの処理（現在は何もしない）
    }

    @objc func showApp() {
        // アプリのウィンドウを表示
        NSApp.activate(ignoringOtherApps: true)
        self.mainFlutterWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func quitApp() {
        // アプリを終了
        NSApp.terminate(nil)
    }

    // Secure Restorable Stateをサポートすることを明示
    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}
