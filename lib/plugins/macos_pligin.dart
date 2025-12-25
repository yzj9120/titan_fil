import 'dart:io';

import '../channelService/defineMethodChannel.dart';
import '../services/log_service.dart';

class MacOsPlugin {
  static final _logUtils = LoggerFactory.createLogger(LoggerName.t3);

  static Future<bool> isSupportAgents() async {
    final arch =
        Platform.version.contains('arm64') ? 'Apple Silicon (M系列)' : 'Intel';
    // print('当前 Mac 处理器架构: $arch');
    return arch == "Intel";
  }

  /// 检查 Multipass 是否已安装
  static Future<bool> checkAndInstallMultipass() async {
    return await DefineMethodChannel.isMultipassInstalled();
  }

  /// 检查 Multipass 版本号
  // static Future<void> checkMultipassVersion() async {
  //   final logBuffer = StringBuffer();
  //   logBuffer.clear();
  //   try {
  //     logBuffer.writeln('checkout Multipass version');
  //     final result = await Process.run('multipass', ['--version']);
  //     logBuffer.writeln(
  //         'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');
  //   } on ProcessException catch (e) {
  //     // 处理找不到 multipass 命令的情况
  //     logBuffer.writeln('not found: $e');
  //   } catch (e) {
  //     logBuffer.writeln('Unexpected error: $e');
  //   } finally {
  //     _log(logBuffer.toString());
  //     logBuffer.clear();
  //   }
  // }

  /// 检查并安装 Multipass
  static Future<bool> installMultipassPkg() async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    if (!await DefineMethodChannel.isMultipassInstalled()) {
      final success = await DefineMethodChannel.installMultipass();
      if (success) {
        logBuffer.writeln("Multipass installed successfully");
        _log(logBuffer.toString());
        return true;
      } else {
        logBuffer.writeln("Failed to install Multipass");
        _log(logBuffer.toString());
        return false;
      }
    } else {
      return true;
    }
  }

  static void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logUtils.info('[MacOsPlugin] : $message');
    } else {
      _logUtils.warning('[MacOsPlugin Error] : $message');
    }
  }
}
