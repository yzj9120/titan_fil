import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:desktop_disk_space/desktop_disk_space.dart';
import 'package:titan_fil/extension/extension.dart';

import '../channelService/defineMethodChannel.dart';
import '../services/log_service.dart';
import 'bat_sh_runner.dart';

class DiskPlugins {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  ///获取磁盘最大可用空间：默认单位gb
  static Future<double> getMaxEnabledDiskSize(String path) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      logBuffer.writeln("DiskSpaceAnalyzer: $path");
      if (Platform.isMacOS) {
        final freeSpaceStr =
            await DefineMethodChannel.getFreeDiskSpaceReadable() ?? "";
        if (freeSpaceStr.isEmpty) {
          logBuffer.writeln("Failed call 0.0");
          return 0.0;
        }
        return freeSpaceStr.toGB(); // 假设 toGB() 已实现字符串转 GB
      } else {
        final drive = _extractDriveLetter(path); // 提取盘符（跨平台安全）
        if (drive.isEmpty) {
          logBuffer.writeln("Invalid drive letter in path: $path;call 0.0");
          return 0.0;
        }
        final freeSpaceBytes = await DesktopDiskSpace.instance.getFreeSpace(drive) ?? 0;
        if (freeSpaceBytes <= 0) {
          logBuffer.writeln("No free space available: $drive call 0.0");
          return 0.0;
        }
        final value = (freeSpaceBytes / (1024 * 1024 * 1024)).roundToDouble();
        // 转换为 GB 并四舍五入到小数点后 2 位
        return value;
      }
    } catch (e) {
      logBuffer.writeln(" Error: $e;call 0.0 ");
      return 0.0; // 返回默认值
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  /// 取磁盘可用大小
  static Future<double> getDiskSpace(String filePath) async {
    double diskSpaceInfo = 0.0;
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      logBuffer.writeln("DiskSpace : $filePath");
      if (Platform.isMacOS) {
        ProcessResult result = await Process.run('df', ['-h', filePath]);
        if (result.exitCode == 0) {
          List<String> lines =
              LineSplitter.split(result.stdout as String).toList();
          if (lines.length > 1) {
            List<String> columns = lines[1].split(RegExp(r'\s+'));
            if (columns.length >= 6) {
              double bytes = _parseSizeString(columns[3]);
              double gb = bytes / (1024 * 1024 * 1024);
              diskSpaceInfo = gb.toFixedTwo();
              logBuffer.writeln("DiskSpace=gb: $gb..${gb.toFixedTwo()}");
            }
          }
        } else {
          logBuffer.writeln(
              "DiskSpace=gb: Failed to retrieve disk space information.");
          diskSpaceInfo = 0.0;
        }
      } else if (Platform.isWindows) {
        final drive = _extractDriveLetter(filePath); // 提取盘符（跨平台安全）
        if (drive.isEmpty) {
          logBuffer.writeln("Invalid drive letter in path: $filePath");
          return diskSpaceInfo;
        }
        final freeSpaceBytes =
            await DesktopDiskSpace.instance.getFreeSpace(drive) ?? 0;
        final value = (freeSpaceBytes / (1024 * 1024 * 1024)).roundToDouble();
        // 转换为 GB 并四舍五入到小数点后 2 位
        return value;
      } else {
        diskSpaceInfo = 0.0;
      }
    } catch (e) {
      diskSpaceInfo = 0.0;
      logBuffer.writeln('Error: $e');
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
    return diskSpaceInfo;
  }

  /// 取文件夹大小
  static Future<double> getFolderSize(String folderPath,
      {String format = "gb"}) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    logBuffer.writeln("FolderSize:path:$folderPath}");

    if (Platform.isMacOS) {
      try {
        ProcessResult result = await Process.run('du', ['-shl', folderPath]);
        logBuffer.writeln(
            'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');

        if (result.exitCode == 0) {
          String output = (result.stdout as String).trim();
          List<String> parts = output.split('\t');
          if (parts.isNotEmpty) {
            String sizeString = parts.first;
            double bytes = _parseSizeString(sizeString);
            logBuffer.writeln("bytes:$bytes");
            if (format == "gb") {
              double gb = bytes / (1024 * 1024 * 1024);
              return gb > 2 ? gb.toFixedTwo() : 2;
            } else if (format == "bytes") {
              return bytes;
            } else {
              double gb = bytes / (1024 * 1024 * 1024);
              return gb.toFixedTwo();
            }
          } else {
            return 2.0;
          }
        } else {
          return 2.0;
        }
      } catch (e) {
        logBuffer.writeln("Process result error::$e}");
        return 2.0;
      } finally {
        _log(logBuffer.toString());
        logBuffer.clear();
      }
    } else if (Platform.isWindows) {
      try {
        final size = await BatShRunner().getFileSize(folderPath);
        logBuffer.writeln("size:$size}");
        switch (format.toLowerCase()) {
          case "gb":
            final value = (size / (1024 * 1024 * 1024)).roundToDouble();
            return max(value, 2.0); // 确保不小于2 GB
          case "bytes":
            return size.toDouble();
          default:
            final value = (size / (1024 * 1024 * 1024)).roundToDouble();
            return max(value, 2.0);
        }
      } catch (e) {
        logBuffer.writeln("Error: $e");
        return 2.0;
      } finally {
        _log(logBuffer.toString());
        logBuffer.clear();
      }
    } else {
      throw Exception('Unsupported platform');
    }
  }

  /// 转成字节数：
  static double _parseSizeString(String sizeString) {
    String numberString = sizeString.replaceAll(RegExp('[A-Za-z ]'), '');
    double number = double.parse(numberString);
    double bytes;
    if (sizeString.contains('T')) {
      bytes = number * 1024 * 1024 * 1024 * 1024;
    } else if (sizeString.contains('G')) {
      bytes = number * 1024 * 1024 * 1024;
    } else if (sizeString.contains('M')) {
      bytes = number * 1024 * 1024;
    } else if (sizeString.contains('K')) {
      bytes = number * 1024;
    } else {
      bytes = number;
    }
    return bytes;
  }

  /// 安全提取盘符（支持 Windows 和 Linux/macOS 路径）
  static String _extractDriveLetter(String path) {
    if (path.isEmpty) return '';
    // 处理 Windows 盘符（如 "C:\"）
    if (Platform.isWindows) {
      final match = RegExp(r'^([A-Za-z]:)').firstMatch(path);
      return match?.group(1) ?? '';
    }
    // 处理 Linux/macOS 路径（返回首个目录或空）
    return path.split('/').where((part) => part.isNotEmpty).firstOrNull ?? '';
  }

  static void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[DiskPlugins] : $message');
    } else {
      _logger.warning('[DiskPlugins Error] : $message');
    }
  }
}
