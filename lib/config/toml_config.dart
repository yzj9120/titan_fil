import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:toml/toml.dart';

import '../services/log_service.dart';
import '../utils/file_helper.dart';

class TomlConfig {
  static late Map<String, dynamic> _tomlConfig;
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);
  static final logBuffer = StringBuffer();
  /// 加载配置文件
  static Future<void> load() async {
    try {
      _tomlConfig = await _loadTomlConfig('assets/configs/config.toml');
    } catch (e) {
      throw Exception("Error loading TOML file: $e");
    }
  }

  /// 解析 TOML 文件
  static Future<Map<String, dynamic>> _loadTomlConfig(String path) async {
    final tomlString = await rootBundle.loadString(path);
    final tomlMap = TomlDocument.parse(tomlString).toMap();
    return tomlMap;
  }

  /// 获取指定的URL
  static String getUrl(String key) {
    try {
      final url = _getValueByKey(key);
      if (url is String) {
        return url;
      } else {
        throw Exception("Value for '$key' is not a valid string URL.");
      }
    } catch (e) {
      throw Exception("Error fetching URL for '$key': $e");
    }
  }

  /// 获取所有的 URL 字段（以 URL 结尾的键）
  static Map<String, String> getAllUrls() {
    final urls = <String, String>{};
    _extractUrls(_tomlConfig, '', urls);
    return urls;
  }

  /// 递归提取所有 URL 字段
  static void _extractUrls(
      Map<String, dynamic> map, String prefix, Map<String, String> result) {
    map.forEach((key, value) {
      final currentKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _extractUrls(value, currentKey, result);
      } else if (key.endsWith('URL') && value is String) {
        result[currentKey] = value;
      }
    });
  }

  /// 获取指定键的值
  static dynamic _getValueByKey(String key) {
    final keys = key.split('.');
    dynamic value = _tomlConfig;
    for (final k in keys) {
      value = value[k];
      if (value == null) {
        throw Exception("Key '$key' not found.");
      }
    }
    return value;
  }

  static Future<void> updateConfigToml() async {
    logBuffer.clear();

    try {
      final appL2 = await FileHelper.getAppSupportDirTitanL2();
      final filePath = path.join(appL2, ".titanedge", "config.toml");
      final file = File(filePath);

      logBuffer.writeln("Config file path: $filePath");

      if (!await file.exists()) {
        throw Exception("Config file does not exist: $filePath");
      }

      String content = await file.readAsString();

      // Get new LocatorURL
      String url = getUrl('Network.LocatorURL');
      logBuffer.writeln("Target LocatorURL: $url");

      // Update
      content = await updateLocatorUrl(content, url);

      // Write back to file
      await file.writeAsString(content);
      logBuffer.writeln("Config update completed.");
    } catch (e, stack) {
      logBuffer.writeln("Error updating config: $e");
      logBuffer.writeln("Stack trace: $stack");
    } finally {
      _logger.info("[TomlConfig] ${logBuffer.toString()}");
    }
  }

  /// Update only LocatorURL
  static Future<String> updateLocatorUrl(
      String content, String newLocatorUrl) async {
    try {
      final regex = RegExp(r'^  LocatorURL\s*=\s*"(.*)"$', multiLine: true);
      final match = regex.firstMatch(content);

      if (match != null) {
        final currentValue = match.group(1); // old value
        if (currentValue == newLocatorUrl) {
          logBuffer.writeln("LocatorURL unchanged, no update required.");
          return content;
        } else {
          logBuffer.writeln("LocatorURL changed: $currentValue → $newLocatorUrl");
          return content.replaceFirst(
            regex,
            '  LocatorURL = "$newLocatorUrl"',
          );
        }
      } else {
        logBuffer.writeln("LocatorURL not found, appending new value.");
        return content + '\n  LocatorURL = "$newLocatorUrl"';
      }
    } catch (e, stack) {
      logBuffer.writeln("Error updating LocatorURL: $e");
      logBuffer.writeln("Stack trace: $stack");
      return content;
    }
  }
}
