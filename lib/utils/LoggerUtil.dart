import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

import '../services/log_service.dart';

/// 日志工具类
class LoggerUtil {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  static const String _appName = 'Titan';
  static const String _version = '1.0.0';

  // 日志级别
  static const int VERBOSE = 0;
  static const int DEBUG = 1;
  static const int INFO = 2;
  static const int WARNING = 3;
  static const int ERROR = 4;
  static const int FATAL = 5;

  static int _logLevel = DEBUG;
  static bool _enableColors = true;
  static bool _showTimestamp = true;
  static bool _showLogLevel = true;
  static bool _showTag = true;

  // ANSI 颜色代码
  static const String _reset = '\x1B[0m';
  static const String _black = '\x1B[30m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _brightBlack = '\x1B[90m';
  static const String _brightRed = '\x1B[91m';
  static const String _brightGreen = '\x1B[92m';
  static const String _brightYellow = '\x1B[93m';
  static const String _brightBlue = '\x1B[94m';
  static const String _brightMagenta = '\x1B[95m';
  static const String _brightCyan = '\x1B[96m';
  static const String _brightWhite = '\x1B[97m';

  // 背景色
  static const String _bgRed = '\x1B[41m';
  static const String _bgGreen = '\x1B[42m';
  static const String _bgYellow = '\x1B[43m';
  static const String _bgBlue = '\x1B[44m';

  /// 初始化日志配置
  static void init({
    int logLevel = DEBUG,
    bool enableColors = true,
    bool showTimestamp = true,
    bool showLogLevel = true,
    bool showTag = true,
    String? logFilePath,
  }) {
    _logLevel = logLevel;
    _enableColors = enableColors && !kReleaseMode;
    _showTimestamp = showTimestamp;
    _showLogLevel = showLogLevel;
    _showTag = showTag;

    _header();
  }

  /// 显示应用头部信息
  static void _header() {
    final border = '${_color(_cyan, true)}${'═' * 60}';
    final title = '${_color(_brightCyan, true)}   🚀 $_appName v$_version   ';

    dev.log('');
    dev.log(border);
    dev.log(title);
    dev.log(
        '${_color(_cyan, true)}   Log Level: ${_levelToString(_logLevel)}${_showTimestamp ? ' | Timestamp: Enabled' : ''}');
    dev.log(border);
    dev.log('');
  }

  /// 详细日志
  static void v(dynamic message,
      {String tag = 'VERBOSE', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= VERBOSE) {
      _log(message,
          tag: tag, level: VERBOSE, error: error, stackTrace: stackTrace);
    }
  }

  /// 调试日志
  static void d(dynamic message,
      {String tag = 'DEBUG', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= DEBUG) {
      _log(message,
          tag: tag, level: DEBUG, error: error, stackTrace: stackTrace);
    }
  }

  /// 信息日志
  static void i(dynamic message,
      {String tag = 'INFO', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= INFO) {
      _log(message,
          tag: tag, level: INFO, error: error, stackTrace: stackTrace);
    }
  }

  /// 警告日志
  static void w(dynamic message,
      {String tag = 'WARNING', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= WARNING) {
      _log(message,
          tag: tag, level: WARNING, error: error, stackTrace: stackTrace);
    }
  }

  /// 错误日志
  static void e(dynamic message,
      {String tag = 'ERROR', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= ERROR) {
      _log(message,
          tag: tag, level: ERROR, error: error, stackTrace: stackTrace);
    }
  }

  /// 严重错误日志
  static void f(dynamic message,
      {String tag = 'FATAL', Object? error, StackTrace? stackTrace}) {
    if (_logLevel <= FATAL) {
      _log(message,
          tag: tag, level: FATAL, error: error, stackTrace: stackTrace);
    }
  }

  /// JSON 美化输出
  static void json(dynamic jsonObject, {String tag = 'JSON'}) {
    if (_logLevel <= DEBUG) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        final jsonString =
            jsonObject is String ? jsonObject : encoder.convert(jsonObject);
        _log(jsonString, tag: tag, level: DEBUG);
      } catch (e) {
        _log('Invalid JSON: $jsonObject', tag: tag, level: ERROR, error: e);
      }
    }
  }

  /// 路径格式化输出（专门为你优化）
  static void paths(Map<String, String> paths, {String title = 'PATHS'}) {
    if (_logLevel <= INFO) {
      final output = _formatPaths(paths, title);
      _log(output, tag: title, level: INFO);
    }
  }

  /// 网络请求日志
  static void network({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    int? statusCode,
    dynamic response,
    int duration = 0,
  }) {
    if (_logLevel <= DEBUG) {
      final output = '''
${_color(_cyan, true)}┌── NETWORK REQUEST ──${_reset}
${_color(_blue)}${method.padRight(7)}${_reset} $url
${_color(_brightBlack)}╰${'─' * 30}${_reset}
${_headersToString(headers)}
${_bodyToString(body)}
${_color(_cyan, true)}┌── RESPONSE ──${_reset} ${_statusColor(statusCode)}
Status: ${_statusCodeToString(statusCode)}
Duration: ${duration}ms
${_bodyToString(response)}
${_color(_brightBlack)}╰${'─' * 40}${_reset}''';

      _log(output, tag: 'NETWORK', level: DEBUG);
    }
  }

  /// 性能日志
  static void performance(String operation, int milliseconds,
      {String tag = 'PERF'}) {
    if (_logLevel <= INFO) {
      final color = milliseconds < 100
          ? _green
          : milliseconds < 500
              ? _yellow
              : _red;
      final emoji = milliseconds < 100
          ? '⚡'
          : milliseconds < 500
              ? '🐇'
              : '🐢';

      _log(
          '$emoji $operation took ${_color(color)}$milliseconds${_color(null)}ms',
          tag: tag,
          level: INFO);
    }
  }

  /// 表格输出
  static void table(List<Map<String, dynamic>> data, {String title = 'TABLE'}) {
    if (_logLevel <= DEBUG) {
      final output = _formatTable(data, title);
      _log(output, tag: title, level: DEBUG);
    }
  }

  /// 分割线
  static void divider(
      {String char = '─', int length = 60, String color = _brightBlack}) {
    if (_logLevel <= DEBUG) {
      _log(_color(color, true) + char * length + _reset,
          tag: 'DIVIDER', level: DEBUG);
    }
  }

  /// 成功消息
  static void success(String message, {String tag = 'SUCCESS'}) {
    _log('✅ $message', tag: tag, level: INFO);
  }

  /// 失败消息
  static void failure(String message, {String tag = 'FAILURE'}) {
    _log('❌ $message', tag: tag, level: ERROR);
  }

  /// 开始标记
  static void start(String operation, {String tag = 'START'}) {
    _log('🚀 START: $operation', tag: tag, level: INFO);
  }

  /// 结束标记
  static void end(String operation, {String tag = 'END'}) {
    _log('🏁 END: $operation', tag: tag, level: INFO);
  }

  /// 核心日志方法
  static void _log(
    dynamic message, {
    required String tag,
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();

    // 添加时间戳
    if (_showTimestamp) {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}.'
          '${now.millisecond.toString().padLeft(3, '0')}';
      buffer.write('${_color(_brightBlack)}[$time]${_reset} ');
    }

    // 添加日志级别
    if (_showLogLevel) {
      final levelStr = _levelToString(level);
      final levelColor = _levelColor(level);
      buffer.write('${_color(levelColor)}${levelStr.padRight(7)}${_reset} ');
    }

    // 添加标签
    if (_showTag) {
      buffer.write('${_color(_brightBlue)}[$tag]${_reset} ');
    }

    // 添加消息
    buffer.write(_color(_messageColor(level)) + message.toString() + _reset);

    // 输出到控制台
    dev.log(buffer.toString());

    // 输出错误信息
    if (error != null) {
      dev.log('${_color(_red)}ERROR: $error${_reset}');
    }

    // 输出堆栈跟踪
    if (stackTrace != null && level >= ERROR) {
      dev.log('${_color(_red)}STACK TRACE:\n$stackTrace${_reset}');
    }

    // 写入文件
    _writeToFile(buffer.toString(), error: error, stackTrace: stackTrace);
  }

  /// 格式化路径（专门为你的用例优化）
  static String _formatPaths(Map<String, String> paths, String title) {
    final buffer = StringBuffer();
    final maxKeyLength =
        paths.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b);
    final totalWidth = maxKeyLength + 50;

    buffer.writeln('');
    buffer.writeln('${_color(_cyan, true)}┏${'━' * (totalWidth - 2)}┓');
    buffer.write('┃ ');
    buffer.write(
        _color(_brightCyan) + title.padRight((totalWidth + title.length) ~/ 2));
    buffer.writeln('${_color(_cyan)} ┃');
    buffer.writeln('┡${'━' * (totalWidth - 2)}┩');

    // 分组处理
    final groups = <String, Map<String, String>>{};
    for (final entry in paths.entries) {
      final key = entry.key;
      if (key.contains('TitanL2')) {
        groups.putIfAbsent('Titan L2', () => {})[key] = entry.value;
      } else if (key.contains('TitanL4')) {
        groups.putIfAbsent('Titan L4', () => {})[key] = entry.value;
      } else if (key.contains('AppSupport')) {
        groups.putIfAbsent('Application Support', () => {})[key] = entry.value;
      } else if (key.contains('Install')) {
        groups.putIfAbsent('Installation', () => {})[key] = entry.value;
      } else {
        groups.putIfAbsent('System', () => {})[key] = entry.value;
      }
    }

    var isFirstGroup = true;
    groups.forEach((groupName, groupPaths) {
      if (!isFirstGroup) {
        buffer.writeln('│${' '.padRight(totalWidth - 2)}│');
      }
      isFirstGroup = false;

      buffer.writeln(
          '│ ${_color(_brightGreen)}📁 $groupName${' '.padRight(totalWidth - groupName.length - 5)}${_color(_cyan)}│');

      groupPaths.forEach((key, value) {
        final displayKey = key
            .replaceAll('_', ' ')
            .replaceAll('AppSupport', '📦')
            .replaceAll('Install', '⚙️ ')
            .replaceAll('TitanL2', 'L2')
            .replaceAll('TitanL4', 'L4')
            .replaceAll('workingDir', 'Working Dir')
            .replaceAll('parentPath', 'Parent Path')
            .replaceAll('currentPath', 'Current Path')
            .replaceAll('logs', 'Logs');

        final line =
            '│    ${_color(_brightYellow)}• ${displayKey.padRight(maxKeyLength)}:${_reset} ${_shortenPath(value)}';
        buffer.write(line);
        buffer.writeln(
            ' '.padRight(totalWidth - line.length + _color(_cyan).length + 4) +
                '${_color(_cyan)}│');
      });
    });

    buffer.writeln('└${'─' * (totalWidth - 2)}┘');
    buffer.writeln('');

    return buffer.toString();
  }

  /// 缩短路径显示
  static String _shortenPath(String path) {
    const home = '/Users/dq';
    const appSupport = 'Library/Application Support/com.titan_fil.titanNetwork';

    if (path.startsWith('$home/$appSupport')) {
      return '~/$appSupport${path.substring(home.length + appSupport.length + 1)}';
    } else if (path.startsWith(home)) {
      return '~${path.substring(home.length)}';
    }
    return path;
  }

  /// 格式化表格
  static String _formatTable(List<Map<String, dynamic>> data, String title) {
    if (data.isEmpty) return 'Empty table';

    final keys = data.first.keys.toList();
    final colWidths = Map<String, int>.fromIterable(keys,
        key: (key) => key.toString(),
        value: (key) => key.toString().length + 2);

    // 计算每列最大宽度
    for (final row in data) {
      for (final key in keys) {
        final value = row[key]?.toString() ?? '';
        final width = value.length + 2;
        if (width > colWidths[key]!) {
          colWidths[key] = width;
        }
      }
    }

    final buffer = StringBuffer();
    final totalWidth =
        colWidths.values.fold(0, (sum, width) => sum + width) + keys.length + 1;

    // 表头
    buffer.writeln('\n${_color(_cyan)}┌${'─' * (totalWidth - 2)}┐');
    buffer.write('│ ');
    buffer.write(_color(_brightCyan) +
        title.padRight((totalWidth + title.length - 4) ~/ 2));
    buffer.writeln('${_color(_cyan)} │');
    buffer.write('├');
    for (final key in keys) {
      buffer.write('─' * colWidths[key]!);
      buffer.write(key == keys.last ? '┤' : '┬');
    }
    buffer.writeln();

    // 列标题
    buffer.write('│');
    for (final key in keys) {
      buffer.write(
          ' ${_color(_brightYellow)}${key.toString().padRight(colWidths[key]! - 1)}${_color(_cyan)}│');
    }
    buffer.writeln();

    buffer.write('├');
    for (final key in keys) {
      buffer.write('─' * colWidths[key]!);
      buffer.write(key == keys.last ? '┤' : '┼');
    }
    buffer.writeln();

    // 数据行
    for (var i = 0; i < data.length; i++) {
      buffer.write('│');
      for (final key in keys) {
        final value = data[i][key]?.toString() ?? '';
        buffer.write(' ${value.padRight(colWidths[key]! - 1)}│');
      }
      buffer.writeln();

      if (i < data.length - 1) {
        buffer.write('├');
        for (final key in keys) {
          buffer.write('─' * colWidths[key]!);
          buffer.write(key == keys.last ? '┤' : '┼');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('└${'─' * (totalWidth - 2)}┘');

    return buffer.toString();
  }

  /// 工具方法
  static String _color(String? color, [bool fullLine = false]) {
    if (!_enableColors || color == null) return '';
    return fullLine ? '$color$color' : color;
  }

  static String _levelColor(int level) {
    switch (level) {
      case VERBOSE:
        return _brightBlack;
      case DEBUG:
        return _cyan;
      case INFO:
        return _green;
      case WARNING:
        return _yellow;
      case ERROR:
        return _red;
      case FATAL:
        return _bgRed + _white;
      default:
        return _white;
    }
  }

  static String _messageColor(int level) {
    switch (level) {
      case VERBOSE:
        return _brightBlack;
      case DEBUG:
        return _white;
      case INFO:
        return _brightWhite;
      case WARNING:
        return _brightYellow;
      case ERROR:
        return _brightRed;
      case FATAL:
        return _brightWhite;
      default:
        return _white;
    }
  }

  static String _levelToString(int level) {
    switch (level) {
      case VERBOSE:
        return 'VERBOSE';
      case DEBUG:
        return 'DEBUG';
      case INFO:
        return 'INFO';
      case WARNING:
        return 'WARNING';
      case ERROR:
        return 'ERROR';
      case FATAL:
        return 'FATAL';
      default:
        return 'UNKNOWN';
    }
  }

  static String _statusCodeToString(int? statusCode) {
    if (statusCode == null) return 'No Response';
    final color = statusCode >= 200 && statusCode < 300
        ? _green
        : statusCode >= 400 && statusCode < 500
            ? _yellow
            : _red;
    return '${_color(color)}$statusCode${_color(null)}';
  }

  static String _statusColor(int? statusCode) {
    if (statusCode == null) return '';
    return statusCode >= 200 && statusCode < 300
        ? _green
        : statusCode >= 400 && statusCode < 500
            ? _yellow
            : _red;
  }

  static String _headersToString(Map<String, dynamic>? headers) {
    if (headers == null || headers.isEmpty) return '';
    return 'Headers: ${jsonEncode(headers)}';
  }

  static String _bodyToString(dynamic body) {
    if (body == null) return '';
    try {
      if (body is String) return 'Body: $body';
      return 'Body: ${jsonEncode(body)}';
    } catch (e) {
      return 'Body: [Non-serializable: ${body.runtimeType}]';
    }
  }

  /// 写入文件（示例实现）
  static void _writeToFile(String message,
      {Object? error, StackTrace? stackTrace}) {
    _logger.info("$message");
  }
}
