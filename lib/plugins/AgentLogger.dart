import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

class AgentLogger {
  final ReceivePort _receivePort = ReceivePort();
  final StreamController<String> _logStream = StreamController.broadcast();

  AgentLogger() {
    _receivePort.listen((message) {
      if (message is String) {
        _logStream.add(message);
        debugPrint('AgentLog: $message');
      }
    });
  }

  /// 执行任务并监听日志
  Future<Map<String, dynamic>> executeTask({
    required String taskName,
    required Future<dynamic> Function(SendPort) taskFunction,
    Duration? timeout,
  }) async {
    final taskId = '${taskName}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<Map<String, dynamic>>();

    // 发送任务开始日志
    _receivePort.sendPort.send('[$taskId] 任务开始: $taskName');

    // 设置超时
    Timer? timeoutTimer;
    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        if (!completer.isCompleted) {
          _receivePort.sendPort.send('[$taskId] 任务超时');
          completer.completeError(TimeoutException('任务执行超时'));
        }
      });
    }

    try {
      final result = await taskFunction(_receivePort.sendPort);
      timeoutTimer?.cancel();

      _receivePort.sendPort.send('[$taskId] 任务完成: ${result['state']}');
      completer.complete(result);
    } catch (e, stackTrace) {
      timeoutTimer?.cancel();
      _receivePort.sendPort.send('[$taskId] 任务失败: $e\n$stackTrace');
      completer.completeError(e, stackTrace);
    }

    return completer.future;
  }

  /// 获取日志流
  Stream<String> get onLog => _logStream.stream;

  /// 获取SendPort用于直接发送日志
  SendPort get sendPort => _receivePort.sendPort;

  void dispose() {
    _receivePort.close();
    _logStream.close();
  }
}
//
// final logger = AgentLogger();
// final result = await logger.executeTask(
// taskName: 'check_vm_status',
// taskFunction: (sendPort) => AgentIsolate.isVmRunning(sendPort),
// timeout: Duration(seconds: 30),
// );
