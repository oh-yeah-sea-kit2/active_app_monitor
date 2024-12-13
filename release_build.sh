flutter clean
flutter build macos --release
codesign -v "build/macos/Build/Products/Release/Active App Monitor.app"
ditto -c -k --keepParent "build/macos/Build/Products/Release/Active App Monitor.app" "ActiveAppMonitor.zip"
