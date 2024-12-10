import 'package:flutter/services.dart';

class PlatformChannelDataSource {
  static const platform = MethodChannel('com.example.active_app_display');

  Future<String> getActiveApp() async {
    try {
      final result = await platform.invokeMethod('getActiveApp');
      return result ?? 'Unknown';
    } on PlatformException catch (e) {
      return "Failed to get active app: ${e.message}";
    }
  }

  Future<String> getChromeURL() async {
    try {
      final result = await platform.invokeMethod('getChromeURL');
      return result ?? 'Not active';
    } on PlatformException catch (e) {
      return "Failed to get Chrome URL: ${e.message}";
    }
  }

  Future<double> getLastActivity() async {
    try {
      final result = await platform.invokeMethod('getLastActivity');
      return (result as double?) ?? 0.0;
    } on PlatformException {
      return 0.0;
    }
  }
}
