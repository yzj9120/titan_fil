/**
 * 处理文件存储
 */

import 'package:logger/logger.dart';

import '../config/app_config.dart';

class LogHelper {
  // Logger实例

  // 环境检查
  static bool isDebug = AppConfig.isDebug;

  // 静态方法访问Logger，确保仅初始化一次
  static Logger get logger {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 160,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
  }

  // Debug log
  static void d(String message) {
    if (isDebug) {
      logger.d(message);
    }
  }

  // 信息日志
  static void i(String message) {
    if (isDebug) {
      logger.i(message);
    }
  }

  // 警告日志
  static void w(String message) {
    if (isDebug) {
      logger.w(message);
    }
  }

  // 错误日志
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isDebug) {
      logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
