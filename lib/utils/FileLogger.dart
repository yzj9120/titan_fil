import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';

import 'file_helper.dart';

enum LogLevel { debug, info, warning, error, critical }

class FileLogger {
  static File? _logFile;
  static final _timeFormat = DateFormat('HH:mm:ss');

  // 初始化日志系统（可选）
  static Future<void> init() async {
    final logsPath = await FileHelper.getLogsPath();
    _logFile = File('${logsPath}/app_logs.log');

    log('init', tag: '');
  }

  // 写入日志
  static Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
  }) async {
    try {
      if (_logFile == null) await init();

      final time = _timeFormat.format(DateTime.now());
      final levelStr = level.toString().split('.').last.toUpperCase();
      final tagStr = tag != null ? '[$tag]' : '';

      final logMessage = '$time $levelStr$tagStr: $message\n';

      await _logFile!.writeAsString(logMessage, mode: FileMode.append);
      print(logMessage.trim()); // 控制台输出
    } catch (e) {
      print('日志写入失败: $e');
    }
  }

  // 读取日志
  static Future<String> readLogs() async {
    try {
      if (_logFile == null) await init();
      return await _logFile!.exists() ? await _logFile!.readAsString() : '暂无日志';
    } catch (e) {
      return '读取日志失败: $e';
    }
  }
}
