import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../config/app_config.dart';
import '../network/http_client.dart';
import '../plugins/macos_pligin.dart';
import 'file_helper.dart';

class DownloadAgent {
  static Completer<void>? _downloadCompleter;
  static double _currentProgress = 0.0;

  static Future<DownloadResult> downloadAgent({
    required void Function(double progress) onProgress,
    Duration timeout = const Duration(seconds: 2 * 60),
    bool hasCheck = false,
  }) async {
    if (_downloadCompleter != null) {
      onProgress(_currentProgress);
      return _downloadCompleter!.future as Future<DownloadResult>;
    }

    final completer = Completer<DownloadResult>();
    _downloadCompleter = completer;
    _currentProgress = 0.0;
    try {
      final HttpClientUtils _httpClient = HttpClientUtils();

      /// todo :hhh
      String workingDir = await FileHelper.getWorkAgentPath();
      final hasArm64 = await MacOsPlugin.isSupportAgents();
      final String agentFileName = Platform.isMacOS
          ? hasArm64
              ? "agent-darwin.zip"
              : "agent-darwin-arm64.zip"
          : "agent-windows.zip";
      final String savePath = path.join(workingDir, agentFileName);
      if (hasCheck) {
        final String agentPath = await FileHelper.getAgentProcessPath();
        final agentFile = File(agentPath);
        if (await agentFile.exists()) {
          debugPrint('文件已存在，无需下载: $savePath');
          return DownloadResult(
            filePath: '',
            fileSize: 0,
            success: true,
          );
        }
      }
      final downUrl = Platform.isMacOS
          ? hasArm64
              ? AppConfig.downAgentDarwin
              : AppConfig.downAgentDarwinArm64
          : AppConfig.downAgentWindows;
      debugPrint("downAgent:$downUrl");
      await _httpClient
          .downloadFile(
            fileUrl: downUrl,
            savePath: savePath,
            extractToPath: workingDir,
            onProgress: (received, total) {
              _currentProgress = received / total;
              onProgress(_currentProgress);
            },
          )
          .timeout(timeout);

      final file = File(savePath);
      final fileSize = await file.exists() ? await file.length() : 0;

      final result = DownloadResult(
        filePath: savePath,
        fileSize: fileSize,
        success: true,
      );
      completer.complete(result);
      return result;
    } catch (e) {
      final result = DownloadResult(
        filePath: '',
        fileSize: 0,
        success: false,
      );
      _downloadCompleter!.completeError(result);
      rethrow;
    } finally {
      _downloadCompleter = null;
    }
  }
}

class DownloadResult {
  final String filePath;
  final int fileSize;
  final bool success;

  DownloadResult({
    required this.filePath,
    required this.fileSize,
    required this.success,
  });

  @override
  String toString() {
    return 'DownloadResult(filePath: $filePath, fileSize: $fileSize, success: $success)';
  }
}
