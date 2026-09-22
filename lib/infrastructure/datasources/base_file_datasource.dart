import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

abstract class BaseFileDataSource {
  static const String appDirName = 'active_app_monitor';
  final Directory? _appDirectory;

  BaseFileDataSource({Directory? appDirectory}) : _appDirectory = appDirectory;

  Future<String> get _basePath async {
    final appDirectory = _appDirectory;
    if (appDirectory != null) {
      return appDirectory.path;
    }
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, appDirName);
  }

  Future<Directory> get appDir async {
    final base = await _basePath;
    final dir = Directory(base);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
