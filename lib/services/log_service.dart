import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entry.dart';
import '../utils/file_helper.dart';

/// 日志来源名称
enum LoggerName { t4, t3 }

enum LoggerType {
  agent, // 客户端代理日志
  server, // 服务端日志
  edge, // 边缘计算日志
  storage // 存储服务日志
}

extension LoggerNameExtension on LoggerName {
  String get value {
    switch (this) {
      case LoggerName.t4:
        return 't4';
      case LoggerName.t3:
        return 't3';
    }
  }
}

extension LoggerTypeListExtension on LoggerType {
  static List<String> get allDisplayNames {
    return LoggerType.values.map((type) => type.displayName).toList();
  }

  static List<String> get allRawNames {
    return LoggerType.values.map((type) => type.name).toList();
  }

  String get displayName {
    switch (this) {
      case LoggerType.agent:
        return 'agent';
      case LoggerType.server:
        return 'server';
      case LoggerType.edge:
        return 'edge';
      case LoggerType.storage:
        return 'storage';
    }
  }
}

class LoggerFactory {
  static final Map<String, Logger> _loggers = {};

  /// 创建或获取指定名称的单例 Logger 实例
  static Logger createLogger(LoggerName log) {
    return _loggers.putIfAbsent(log.name, () => Logger(log.name));
  }
}

/// 日志管理服务类
class LogService {
  /// 创建一个指定名称的 Logger 实例

  /// 判断今天是否已经执行过日志清理操作
  static Future<bool> hasCleanedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCleanDate = prefs.getString('lastCleanDate');
    final currentDate =
        DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    return lastCleanDate == currentDate;
  }

  /// 更新最近清理日期为今天
  static Future<void> _updateCleanDate() async {
    final prefs = await SharedPreferences.getInstance();
    final currentDate = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('lastCleanDate', currentDate);
  }

  /// 初始化日志监听器，将日志写入文件并打印到控制台
  Future<void> init() async {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) async {
      await log(LogEntry(
        level: record.level.name,
        msg: record.message,
        logger: record.loggerName,
      ));
      stdout.writeln('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  /// 将日志记录写入文件
  Future<void> log(LogEntry entry) async {
    // 1. 获取日志文件路径（根据不同的 logger 类型决定路径）
    final name = entry.logger == LoggerName.t3.value
        ? LoggerType.storage.displayName
        : LoggerType.server.displayName;
    final filePath = await getLogTypeNameFilePath(name);

    // debugPrint("filePath==$filePath");
    // 2. 创建一个 File 对象，表示目标日志文件
    final file = File(filePath);
    // 3. 确保日志文件的父目录存在（如果不存在则递归创建）
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
    }
    // await file.parent.create(recursive: true);
    // 4. 将日志条目转换为 JSON 字符串，并添加换行符
    final logJson = '${jsonEncode(entry.toJson())}\n';
    try {
      // 5. 以追加模式（FileMode.append）将日志写入文件
      await file.writeAsString(logJson, mode: FileMode.append);
    } catch (e) {
      // 6. 如果写入失败，将错误信息打印到标准错误输出
      stderr.writeln("写入日志失败: $e");
    }
  }

  /// 读取日志目录下的所有日志条目，并按时间倒序返回
  static Future<List<LogEntry>> readLogEntries() async {
    final logDir = await getLogDir();
    final directory = Directory(logDir);
    if (!await directory.exists()) return [];

    final logEntries = <LogEntry>[];
    await for (var entity in directory.list()) {
      if (entity is File) {
        final fileContent = await entity.readAsString();
        final entries = fileContent
            .trim()
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => LogEntry.fromJson(jsonDecode(line)))
            .toList();
        logEntries.addAll(entries);
      }
    }
    logEntries.sort((a, b) => b.ts.compareTo(a.ts));
    return logEntries;
  }

  /// 获取所有日志文件名（按日期倒序）
  static Future<List<String>> getAllLogFileNames({String? fileName}) async {
    final logDir = await getLogDir(fileName: fileName);
    final directory = Directory(logDir);
    if (!await directory.exists()) return [];

    final logFileNames = <String>[];
    await for (var entity in directory.list()) {
      if (entity is File && path.extension(entity.path) == '.log') {
        logFileNames.add(path.basename(entity.path));
      }
    }

    logFileNames.sort((a, b) =>
        _extractDateFromFileName(b).compareTo(_extractDateFromFileName(a)));
    return logFileNames;
  }

  /// 从日志文件名中提取日期
  static DateTime _extractDateFromFileName(String fileName) {
    final match = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(fileName);
    return match != null
        ? DateTime.parse(match.group(1)!)
        : DateTime(1970, 1, 1);
  }

  static Future<List<LogEntry>> getLogFileContent2(String name,
      {String? fileName}) async {
    final receivePort = ReceivePort();
    final logDir = await getLogDir(fileName: fileName);
    final params = {
      'name': name,
      'fileName': fileName,
      'logDir': logDir,
      'sendPort': receivePort.sendPort,
    };
    await Isolate.spawn(_isolateGetLogFileContent, params);
    return await receivePort.first as List<LogEntry>;
  }

  static Future<List<LogEntry>> getLogFileContent3(String name) async {
    final receivePort = ReceivePort();
    String libsPath = await FileHelper.getLogsPath();
    String workingDir = LoggerName.t4.value;
    String savePath = path.join(libsPath, workingDir);
    final params = {
      'name': name,
      'logDir': savePath,
      'sendPort': receivePort.sendPort,
    };
    await Isolate.spawn(_isolateGetLogFileContent3, params);
    return await receivePort.first as List<LogEntry>;
  }

  static Future<void> _isolateGetLogFileContent3(
      Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final name = params['name'] as String;
    final logDir = params['logDir'] as String;
    final logFilePath = path.join(logDir, name);
    final logFile = File(logFilePath);
    final entries = <LogEntry>[];
    int count = 1;
    print("onReadLogFolder logFile: $logFilePath");
    if (!await logFile.exists()) {
      sendPort.send(<LogEntry>[]);
      return;
    }
    try {
      await for (final chunk
          in logFile.openRead().transform(ByteToLineTransformer())) {
        entries.add(LogEntry(
          level: "agent_chunk",
          msg: chunk,
          logger: 'info',
          ts: "${count++}",
        ));
        await Future.delayed(const Duration(milliseconds: 10));
      }
      // 发送完成信号
      sendPort.send(entries);
    } catch (e) {
      print('Error processing log file: $e');
      sendPort.send(<LogEntry>[]);
    }
  }

  Future<void> processInChunks(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final name = params['name'] as String;
    final logDir = params['logDir'] as String;
    final logFilePath = path.join(logDir, name);
    final output = StringBuffer();
    final entries = <LogEntry>[];

    const chunkSize = 1024 * 1024; // 每次处理1MB
    final file = File(logFilePath);
    final fileSize = await file.length();
    var position = 0;
    var chunkCount = 0;
    print('开始分块处理 ${fileSize ~/ 1024} KB 的日志文件...');
    while (position < fileSize) {
      chunkCount++;
      final end = (position + chunkSize).clamp(0, fileSize);
      final chunk = await file
          .openRead(position, end)
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      print('处理块 #$chunkCount (位置: $position-$end): ${chunk.length}行');
      // 处理当前块的数据
      for (final line in chunk) {
        // 你的处理逻辑
        entries.add(LogEntry(
          level: 'Info',
          ts: "",
          msg: line.toString(),
          logger: '',
        ));
      }
      position = end;
    }

    print('完成所有 ${chunkCount} 块的处理');
  }

  static String _safeDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return utf8
            .decode(bytes, allowMalformed: true)
            .replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
      }
    }
  }

  static List<LogEntry> _parseMixedLog(String content) {
    final entries = <LogEntry>[];
    final lines = content.split('\n');

    final structuredPattern = RegExp(
      r'^time="([^"]+)"\s+level=(\w+)\s+(?:\w+=\S+\s+)*msg="([^"]*)"',
      caseSensitive: false,
    );

    final jsonPattern = RegExp(r'^\s*\{.*\}\s*$'); // 简单JSON检测

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      // 跳过ASCII艺术等非日志行
      if (trimmedLine.startsWith('╭') ||
          trimmedLine.startsWith('┃') ||
          trimmedLine.startsWith('╰')) {
        continue;
      }
      try {
        // 尝试解析为结构化日志
        final structuredMatch = structuredPattern.firstMatch(trimmedLine);
        if (structuredMatch != null) {
          entries.add(LogEntry(
              level: structuredMatch.group(2)!,
              msg: structuredMatch.group(3)!,
              logger: 'info',
              ts: ""));
          continue;
        }
        // 尝试解析为JSON格式
        if (jsonPattern.hasMatch(trimmedLine)) {
          final logJson = jsonDecode(trimmedLine) as Map<String, dynamic>;
          entries.add(LogEntry.fromJson(logJson));
          continue;
        }
        // 作为非结构化日志处理
        entries.add(LogEntry(
            level: 'UNSTRUCTURED', msg: trimmedLine, logger: 'info', ts: ""));
      } catch (e) {
        // 解析失败的行作为错误日志
        entries.add(LogEntry(
          level: 'ERROR',
          ts: "",
          msg:
              'Parse failed: ${line.length > 50 ? '${line.substring(0, 50)}...' : line}',
          logger: '',
        ));
      }
    }
    return entries;
  }

  static Future<void> _isolateGetLogFileContent(
      Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final name = params['name'] as String;
    final logDir = params['logDir'] as String;

    final logFilePath = path.join(logDir, name);
    final logFile = File(logFilePath);

    if (await logFile.exists()) {
      try {
        final bytes = await logFile.readAsBytes();
        String fileContent;

        try {
          fileContent = utf8.decode(bytes);
        } catch (_) {
          fileContent = latin1.decode(bytes);
        }
        final logEntries = <LogEntry>[];

        for (var entry in fileContent.trim().split('\n')) {
          if (entry.isNotEmpty) {
            try {
              final logJson = jsonDecode(entry);
              final logEntry = LogEntry.fromJson(logJson);
              logEntries.add(logEntry);
            } catch (_) {}
          }
        }

        // Sort by timestamp descending
        logEntries.sort((a, b) => b.ts.compareTo(a.ts));

        sendPort.send(logEntries);
      } catch (e) {
        sendPort.send(<LogEntry>[]); // fallback empty list
      }
    } else {
      sendPort.send(<LogEntry>[]);
    }
  }

  /// 读取指定日志文件内容，并解析为 LogEntry 列表
  static Future<List<LogEntry>> getLogFileContent(String name,
      {String? fileName}) async {
    final logDir = await getLogDir(fileName: fileName);
    final logFilePath = path.join(logDir, name);
    final logFile = File(logFilePath);

    if (await logFile.exists()) {
      try {
        // 先以二进制方式读取文件内容
        final bytes = await logFile.readAsBytes();
        String fileContent;

        // 尝试 UTF-8 解码
        try {
          fileContent = utf8.decode(bytes);
        } catch (e) {
          print('UTF-8 解码失败，尝试使用 ISO-8859-1: $e');
          fileContent = latin1.decode(bytes); // 适用于 Windows 可能的 ANSI 编码
        }

        final logEntries = <LogEntry>[];

        // 解析文件内容，按行分隔并转成 LogEntry 对象
        for (var entry in fileContent.trim().split('\n')) {
          if (entry.isNotEmpty) {
            try {
              final logJson = jsonDecode(entry);
              final logEntry = LogEntry.fromJson(logJson);
              logEntries.add(logEntry);
            } catch (e) {
              debugPrint('Failed to parse log entry: $e');
            }
          }
        }

        // 按日期排序，最新的排在前面
        logEntries.sort((a, b) => b.ts.compareTo(a.ts));
        return logEntries;
      } catch (e) {
        debugPrint('读取日志文件失败: $e');
        throw Exception('无法读取日志文件: $e');
      }
    } else {
      throw Exception('Log file does not exist');
    }
  }

  static Future<String> getLogTypeNameFilePath(String name) async {
    // /Users/dq/Library/Application Support/com.titan_fil.titanNetwork/logs
    ///final lig = LoggerName.t3.value==name?"":
    final dir = await getLogDir();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return path.join("$dir", '$name-$date.log');
  }

  /// 获取当前日期对应的日志文件路径（按 logger 名称区分）
  static Future<String> getLogFilePath(String name) async {
    // /Users/dq/Library/Application Support/com.titan_fil.titanNetwork/logs
    final dir = await getLogDir();
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return path.join("$dir/$name", '$date.log');
  }

  /// 获取日志目录路径（支持指定子目录）
  static Future<String> getLogDir({String? fileName}) async {
    final baseDir = await FileHelper.getLogsPath();
    if (baseDir.isEmpty) throw Exception("无法初始化日志目录");
    final logsPath = fileName != null ? path.join(baseDir, fileName) : baseDir;
    // debugPrint("日志路径: $logsPath");
    return logsPath;
  }

  static Future<void> autoCleanLogs() async {
    if (await hasCleanedToday()) {
      debugPrint("今天已经清理过日志，无需重复清理");
      return;
    }
    try {
      await Future.wait([
        _cleanOldLogs("t3"),
        _cleanOldLogs("t4"),
      ]);
      await _updateCleanDate();
    } catch (e) {
      debugPrint('日志清理失败: $e');
    }
  }

  /// 清理 5 天前的旧日志，仅每天执行一次
  static Future<void> _cleanOldLogs(String fileName) async {
    if (await hasCleanedToday()) {
      // print("今天已经清理过日志，无需重复清理");
      return;
    }
    final logDir = await getLogDir(fileName: fileName);
    final directory = Directory(logDir);
    if (!await directory.exists()) return;
    final thresholdDate = DateTime.now().subtract(const Duration(days: 5));
    await for (var entity in directory.list()) {
      if (entity is File) {
        final fileName = path.basename(entity.path);

        // Skip edge.log files
        if (fileName == 'edge.log') continue;

        final match = RegExp(r'(\d{4}-\d{2}-\d{2})\.log').firstMatch(fileName);
        if (match != null &&
            DateTime.parse(match.group(1)!).isBefore(thresholdDate)) {
          await entity.delete();
        }
      }
    }
  }

  /// 获取指定日志文件（File 对象）
  static Future<File> getLogFile(String fileName) async {
    final logDir = await getLogDir();
    final filePath = path.join(logDir, fileName);
    final file = File(filePath);
    if (!await file.exists()) throw Exception('日志文件不存在');
    return file;
  }

  /// 获取 titan-agent 所在目录路径
  static Future<String> getAgentLogDir() async {
    if (kDebugMode) {
      final baseDir = await FileHelper.getInstallationDirTitanL4();
      return path.join(baseDir, 'titan-agent');
    }
    return path.join(Directory.current.path, 'titan-agent');
  }

  ///获取edge日志目录
  static Future<String> getEdgeLogDir() async {
    final logDir = await LogService.getLogDir();
    final logFilePath = path.join(logDir, LoggerName.t3.value);
    final edge = path.join(logFilePath, "edge.log");
    return edge;
  }

  ///获取t4日志目录
  static Future<String> getStorageLogDir() async {
    final logDir = await LogService.getLogDir();
    final logFilePath = path.join(logDir, LoggerName.t3.value);
    return logFilePath;
  }

  ///获取t4日志目录
  static Future<String> getPcdnLogDir() async {
    final logDir = await LogService.getLogDir();
    final logFilePath = path.join(logDir, LoggerName.t4.value);
    return logFilePath;
  }

  /// 获取今天的日志文件列表
  static Future<List<File>> getTodayLogFiles(
      DateTime today, String logsDirPath) async {
    //final now = DateTime.now();
    //final today = DateTime(now.year, now.month, now.day); // 去除时间部分
    // 将字符串路径转换为Directory对象
    final logsDir = Directory(logsDirPath);
    // 检查目录是否存在
    if (!await logsDir.exists()) {
      return [];
    }
    final allFiles = await logsDir
        .list()
        .where((file) {
          if (file is! File) return false;

          // 提取文件名中的日期部分（支持两种格式）
          final fileName = path.basenameWithoutExtension(file.path);
          final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(fileName);
          if (dateMatch == null) return false;

          final fileDate = DateTime.tryParse(dateMatch.group(1)!);
          return fileDate != null &&
              fileDate.year == today.year &&
              fileDate.month == today.month &&
              fileDate.day == today.day;
        })
        .cast<File>()
        .toList();
    return allFiles;
  }

  static List<File> getLogsNameByTags(List<File> todayLogs, String tags) {
    final regExp = RegExp('$tags-\\d{4}-\\d{2}-\\d{2}(T\\d{2}-\\d{2})?\\.log',
        caseSensitive: false);
    return todayLogs.where((file) {
      return regExp.hasMatch(file.path.split('/').last);
    }).toList();
  }

  /// 零时日志保存
  static Future<void> deleteOldLogsInParallel(List<String> filePaths) async {
    List<Future> futures = [];

    for (final filePath in filePaths) {
      futures.add(_startIsolateForLogDeletion(filePath));
    }
    // Wait for all isolates to complete their tasks
    await Future.wait(futures);
  }

  static Future<void> _startIsolateForLogDeletion(String filePath) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_deleteOldLogsInIsolate, receivePort.sendPort);

    final sendPort = await receivePort.first as SendPort;
    final responsePort = ReceivePort();
    sendPort.send([filePath, responsePort.sendPort]);

    await responsePort.first; // Wait for the isolate to finish the task
  }

  static Future<void> _deleteOldLogsInIsolate(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    await for (final message in receivePort) {
      final data = message as List;
      final filePath = data[0] as String;
      final responsePort = data[1] as SendPort;

      final file = File(filePath);
      final exists = await file.exists();
      if (!exists) {
        responsePort.send(null);
        return;
      }
      try {
        final lines = await file.readAsLines();
        // Get today's date (ignoring the time part)
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        final twoDaysAgoStart = todayStart.subtract(const Duration(days: 4));
        // 创建一个临时文件用于写入保留的数据
        final tempFile = File('${file.path}.tmp');
        debugPrint("临时文件=${tempFile}");
        final sink = tempFile.openWrite();
        // 读取文件并直接过滤写入临时文件
        for (final line in lines) {
          if (line.isNotEmpty) {
            final jsonEntry = jsonDecode(line);
            final entryDate = DateTime.parse(jsonEntry['ts'] as String);
            // 如果该条目在过去两天内，则写入临时文件
            if (entryDate.isAfter(twoDaysAgoStart)) {
              sink.writeln(line);
            }
          }
        }
        await sink.close(); // 关闭写入流
        await file.delete(); // 删除原始文件
        await tempFile.rename(file.path); // 重命名临时文件为原始文件
      } catch (e) {
        print('Error while deleting old logs: $e');
      }
      responsePort.send(null); // Signal completion
    }
  }

  /// 主清理函数
  static Future<void> cleanupOldLogs({int daysToKeep = 7}) async {
    if (await hasCleanedToday()) {
      debugPrint("今天已经清理过日志，无需重复清理");
      return;
    }
    final logsDirPath = await FileHelper.getLogsPath();
    /// 定义日志类型前缀
    // List<String> logTypes = ['agent-', 'server-', 'edge-', 'storage-'];
    final logTypes = LoggerType.values.map((type) => type.name).toList();
    final logsDir = Directory(logsDirPath);
    if (!await logsDir.exists()) {
      print('日志目录不存在: $logsDirPath');
      return;
    }
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: daysToKeep));
    // 获取所有日志文件并按类型分组
    final Map<String, List<File>> logFilesByType = {};
    await for (final entity in logsDir.list()) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        for (final type in logTypes) {
          if (fileName.startsWith(type)) {
            logFilesByType.putIfAbsent(type, () => []).add(entity);
            break;
          }
        }
      }
    }

    // 处理每种日志类型
    for (final type in logFilesByType.keys) {
      await _deleteOldFilesForType(
        files: logFilesByType[type]!,
        cutoffDate: cutoffDate,
        type: type,
      );
    }

    await _updateCleanDate();
  }

  /// 删除指定类型的旧文件
  static Future<void> _deleteOldFilesForType({
    required List<File> files,
    required DateTime cutoffDate,
    required String type,
  }) async {
    /// 从文件名提取日期（格式: prefix_yyyy-MM-dd.log）
    DateTime _extractDateFromFileName(String filePath) {
      final fileName = path.basenameWithoutExtension(filePath);
      debugPrint('fileName: $fileName');
      // 处理两种可能的格式：
      // 1. "agent-2025-05-26T08-00" → 提取 "2025-05-26"
      // 2. "server_-2025-05-26" → 提取 "2025-05-26"
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})').firstMatch(fileName);
      if (dateMatch == null) {
        throw FormatException('Unable to extract date from file name: $fileName');
      }
      return DateTime.parse(dateMatch.group(1)!);
    }

    // 提取日期并排序（最新日期在前）
    files.sort((a, b) {
      final dateA = _extractDateFromFileName(a.path);
      final dateB = _extractDateFromFileName(b.path);
      return dateB.compareTo(dateA);
    });

    int keptCount = 0;
    for (final file in files) {
      final fileDate = _extractDateFromFileName(file.path);
      if (fileDate.isAfter(cutoffDate) || keptCount < 7) {
        keptCount++;
        debugPrint('保留 [$type] 日志: ${path.basename(file.path)}');
      } else {
        try {
          await file.delete();
          debugPrint('删除旧 [$type] 日志: ${path.basename(file.path)}');
        } catch (e) {
          debugPrint('删除失败 (${file.path}): $e');
        }
      }
    }
  }
}

// class ByteToLineTransformer extends StreamTransformerBase<List<int>, String> {
//   @override
//   Stream<String> bind(Stream<List<int>> stream) async* {
//     final decoder = utf8.decoder;
//     final buffer = StringBuffer();
//     var pending = '';
//
//     await for (final chunk in stream) {
//       try {
//         final str = pending + decoder.convert(chunk);
//         final lines = str.split('\n');
//
//         // 所有完整行
//         for (var i = 0; i < lines.length - 1; i++) {
//           yield lines[i];
//         }
//
//         // 保存不完整的行以待下次
//         pending = lines.last;
//       } catch (e) {
//         // 如果UTF-8解码失败，尝试Latin1
//         final str = pending + latin1.decode(chunk);
//         final lines = str.split('\n');
//
//         for (var i = 0; i < lines.length - 1; i++) {
//           yield lines[i];
//         }
//
//         pending = lines.last;
//       }
//     }
//
//     // 处理剩余内容
//     if (pending.isNotEmpty) {
//       yield pending;
//     }
//   }
// }

class ByteToLineTransformer extends StreamTransformerBase<List<int>, String> {
  @override
  Stream<String> bind(Stream<List<int>> stream) async* {
    const chunkSize = 1024 * 1024; // 1MB分块大小
    final decoder = utf8.decoder;
    var buffer = StringBuffer();
    var pending = '';

    await for (final dataChunk in stream) {
      try {
        final strChunk = pending + decoder.convert(dataChunk);
        final lines = strChunk.split('\n');

        // 完整行处理
        for (var i = 0; i < lines.length - 1; i++) {
          buffer.writeln(lines[i]);

          // 当缓冲区达到chunkSize时发送
          if (buffer.length > chunkSize) {
            yield buffer.toString();
            buffer.clear();
          }
        }

        pending = lines.last; // 保存不完整行
      } catch (e) {
        // UTF-8失败时尝试Latin1
        final strChunk = pending + latin1.decode(dataChunk);
        final lines = strChunk.split('\n');

        for (var i = 0; i < lines.length - 1; i++) {
          buffer.writeln(lines[i]);
          if (buffer.length > chunkSize) {
            yield buffer.toString();
            buffer.clear();
          }
        }

        pending = lines.last;
      }
    }

    // 处理剩余内容
    if (pending.isNotEmpty) {
      buffer.writeln(pending);
    }
    if (buffer.isNotEmpty) {
      yield buffer.toString();
    }
  }
}
