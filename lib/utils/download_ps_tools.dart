import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';
import '../network/http_client.dart';
import 'file_helper.dart';

class DownLoadPSTools {
  static Future<void> download() async {
    try {
      final HttpClientUtils _httpClient = HttpClientUtils();

      /// todo:hhh
      // String libsPath = await FileHelper.getParentPath();
      // String workingDir = AppConfig.workingDir;
      // String savePath = path.join(libsPath, path.join(workingDir, "tools.zip"));
      // String extractToPath = path.join(libsPath, path.join(workingDir, "PSTools"));

      final workingDir = await FileHelper.getWorkAgentPath();
      String savePath = path.join(workingDir, "tools.zip");
      String extractToPath = path.join(workingDir, "PSTools");
      ///只支持设置win
      if (Platform.isWindows) {
        final file = File(savePath);
        if (await file.exists()) {
          debugPrint('文件已存在，无需下载: $savePath');
          return;
        }
        final downUrl = AppConfig.downPSTools;
        await _httpClient.downloadFile(
          fileUrl: downUrl,
          savePath: savePath,
          extractToPath: extractToPath,
          saveEtag: false,
          onProgress: (received, total) async {
            debugPrint('DownLoadPSTools: $received');
          },
        );
      } else {
        //内置进去的
      }
    } catch (e) {
      rethrow;
    } finally {}
  }
}
