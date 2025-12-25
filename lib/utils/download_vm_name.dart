import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';
import '../network/http_client.dart';
import 'file_helper.dart';

class DownLoadVmName {
  static Future<void> download() async {
    try {
      final HttpClientUtils _httpClient = HttpClientUtils();
      final workingDir = await FileHelper.getWorkAgentPath();
      final String savePath = path.join(workingDir, "check_vm_names");
      if (Platform.isMacOS) {
        final file = File(savePath);
        if (await file.exists()) {
          debugPrint('文件已存在，无需下载: $savePath');
          return;
        }
        final downUrl = AppConfig.downCheckVmNames;
        await _httpClient.downloadFile(
          fileUrl: downUrl,
          savePath: savePath,
          extractToPath: workingDir,
          saveEtag: false,
          hasZip: false,
          onProgress: (received, total) async {
            final _currentProgress = received / total;
            if (_currentProgress >= 1) {
              try {
                final result = await Process.run('chmod', ['+x', savePath]);
                if (result.exitCode == 0) {
                  debugPrint('✅ 文件已赋予可执行权限！');
                } else {
                  debugPrint('❌ 失败: ${result.stderr}');
                }
              } catch (e) {
                debugPrint('❌ 执行出错: $e');
              }
            }
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
