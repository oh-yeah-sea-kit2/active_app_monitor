import 'package:flutter/material.dart';
import 'settings_path_item.dart';

class SettingsFilePaths extends StatelessWidget {
  final String appDirectoryPath;
  final String activitiesDirectoryPath;

  const SettingsFilePaths({
    Key? key,
    required this.appDirectoryPath,
    required this.activitiesDirectoryPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ファイル保存場所',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 16),
            SettingsPathItem(
              label: '設定ファイル',
              path: '$appDirectoryPath/settings.json',
            ),
            SizedBox(height: 12),
            SettingsPathItem(
              label: 'アクティビティログ',
              path: '$activitiesDirectoryPath/',
            ),
          ],
        ),
      ),
    );
  }
}
