import Cocoa
import FlutterMacOS
import ApplicationServices

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
            case "checkAccessibilityPermission":
                result(self.checkAccessibilityPermission())
            case "requestAccessibilityPermission":
                self.requestAccessibilityPermission()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // アクセシビリティ権限をチェック
        if checkAccessibilityPermission() {
            // 権限がある場合のみ監視を開始
            startMonitoringUserActivity()
        } else {
            // 権限がない場合は権限を要求
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestAccessibilityPermission()
            }
        }

        // FlutterAppDelegateの初期化を最初に呼び出す
        super.applicationDidFinishLaunching(notification)
    }

    override func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func startMonitoringUserActivity() {
        // アクセシビリティ権限がある場合のみ監視を開始
        guard checkAccessibilityPermission() else {
            print("Accessibility permission not granted")
            return
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .mouseMoved]) { event in
            self.lastUserActivity = Date()
        }
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func requestAccessibilityPermission() {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            // 権限が付与されていない場合、システム環境設定へ誘導
            showAccessibilityAlert()
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ権限が必要です"
        alert.informativeText = """
            Active App Monitorがアプリケーションの使用状況を記録するには、システム環境設定でアクセシビリティ権限を付与してください。
            
            1. システム環境設定を開く
            2. セキュリティとプライバシー > プライバシー > アクセシビリティ
            3. Active App Monitorにチェックを入れる
            4. アプリを再起動する
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "システム環境設定を開く")
        alert.addButton(withTitle: "後で")
        
        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
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

    private func isChromeRunning() -> Bool {
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.google.Chrome"
        }
    }

    private func getActiveChromeTabURL() -> String {
        // Chromeが起動していない状態でAppleEventを送ると、AppleScriptの仕様で
        // Chromeが自動起動してしまう。起動中のときだけ問い合わせる。
        guard isChromeRunning() else { return "" }

        // AppleScript側でも is running でガードする（起動と起動判定の間に
        // Chromeが終了した場合の保険）。ウィンドウ0個のときのエラーも避ける。
        let script = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    get URL of active tab of first window
                end if
            end tell
        end if
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
