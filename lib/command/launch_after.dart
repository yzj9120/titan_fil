import 'dart:core';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../constants/constants.dart';
import '../controllers/agent_controller.dart';
import '../controllers/miner_controller.dart';
import '../page/setting/setting_controller.dart';
import '../page/task/pcdn/child/env_controller.dart';
import '../plugins/agent_plugin.dart';
import '../services/global_service.dart';
import '../services/log_service.dart';
import '../utils/download_agent.dart';
import '../utils/download_ps_tools.dart';
import '../utils/download_vm_name.dart';
import '../utils/file_helper.dart';
import '../utils/network_helper.dart';
import '../utils/preferences_helper.dart';
import 'dart:async';

class LaunchAfterCommand {
  static Function(double)? _progressCallback;
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);
  static final logBuffer = StringBuffer();

  static void setProgressCallback(Function(double) callback) {
    _progressCallback = callback;
  }

  static Future<void> setUp() async {
    logBuffer.clear();
    final stopwatch = Stopwatch()..start();

    // 1. 同步初始化 (内存操作，不易卡死，保持原样)
    try {
      Get.lazyPut(() => MinerController());
      Get.lazyPut(() => SettingController());
      Get.lazyPut(
          () => AgentController(globalService: Get.find<GlobalService>()));
      Get.lazyPut(() => EnvController());
    } catch (e) {
      _logCritical("Controller/Service init error: $e");
    }

    // 2. 并行执行独立任务 (加入超时保护！)
    // 这里的每一个任务现在都有了 10秒(默认) 的寿命，超时就跳过，绝不卡死
    await Future.wait([
      _safeRun(_initNetworkIP, "initNetworkIP"), // 之前是裸跑，现在包起来
      _safeRun(DownLoadVmName.download, "down VmName"),
      _safeRun(DownLoadPSTools.download, "down pstools"),
    ]);

    // 3. 核心业务：Agent 检查与下载
    // Agent 下载通常比较大，我们给它更长的超时时间 (例如 5分钟)
    // 或者 agent 下载内部自己有进度流，这里主要防止 fetchMd5Checksum 卡住
    await _safeRun(_checkAndDownloadAgent, "checkAndDownloadAgent",
        timeout: const Duration(minutes: 5) // 这是一个长任务，给多点时间
        );

    stopwatch.stop();
    logBuffer
        .writeln("Execution completed in ${stopwatch.elapsedMilliseconds}ms");

    if (logBuffer.isNotEmpty) {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  // --- 子任务方法 (逻辑保持不变) ---

  static Future<void> _initNetworkIP() async {
    // 移除内部 try-catch，统一交给 _safeRun 处理，或者保留用于记录特定日志
    await NetworkHelper.clearCachedIP();
    String freshIp = await NetworkHelper.getUserIP(forceRefresh: true);
    logBuffer.writeln("freshIp: $freshIp");
  }

  static Future<void> _checkAndDownloadAgent() async {
    final agentProcess = await FileHelper.getAgentProcessPath();
    debugPrint("agent工作地址：" + agentProcess);
    // 3. 检查【文件】是否存在
    File agentFile = File(agentProcess);
    bool isFileExists = await agentFile.exists();

    logBuffer.writeln("Agent file exists? $isFileExists ($agentProcess)");

    final remoteMd5 = await AgentPlugin.fetchMd5Checksum();
    logBuffer.writeln("fetchMd5Checksum: $remoteMd5");

    // 检查远程 MD5 是否获取失败
    bool isNetworkError = (remoteMd5.isEmpty || remoteMd5.contains("Dio"));

    if (isNetworkError) {
      logBuffer.writeln("⚠️ Fetch MD5 failed.");

      if (isFileExists) {
        // 情况 A：获取版本失败，但本地有文件。
        logBuffer
            .writeln("Safe to skip: Local file exists, using old version.");
        return;
      } else {
        // 情况 B：获取版本失败，且本地连文件都没有！
        logBuffer.writeln(
            "❌ Critical: No local file and network check failed.attempting force download...");
        // 代码继续往下走，去执行下载逻辑 ->
      }
    }

    final localMd5 = await PreferencesHelper.getString(Constants.md5);
    logBuffer.writeln("localMd5=$localMd5");

    //. 判断是否需要下载
    // 逻辑：
    // - 如果网络错了但没文件 (isNetworkError && !isFileExists) -> 下载
    // - 如果没文件 (!isFileExists) -> 下载
    // - 如果有更新 (remoteMd5 != localMd5) -> 下载
    // - 注意：如果 isNetworkError 为 true，remoteMd5 可能为空，所以要避免空指针对比
    bool needDownload = false;
    if (!isFileExists) {
      needDownload = true; // 没文件，必须下
    } else if (!isNetworkError && remoteMd5 != localMd5) {
      needDownload = true; // 有网且版本不同，更新
    }
    if (needDownload) {
      logBuffer.writeln("Starting download (Missing: ${!isFileExists})...");
      final result = await DownloadAgent.downloadAgent(
        onProgress: (progress) {
          _progressCallback?.call(progress);
        },
      );
      logBuffer.writeln("downloadAgent result: $result");
    } else {
      logBuffer.writeln("Agent check passed (Up to date or fallback).");
    }
  }

  // --- 核心修改：防卡死执行器 ---
  /// 通用安全执行包装器
  /// [task] 异步任务
  /// [taskName] 任务名
  /// [timeout] 超时时间，默认 10秒。如果 10秒没做完，强制跳过。
  static Future<void> _safeRun(
      FutureOr<dynamic> Function() task, String taskName,
      {Duration timeout = const Duration(seconds: 10)} // 新增参数
      ) async {
    try {
      // 使用 .timeout() 加上 Future.value() 确保兼容性
      await Future.value(task()).timeout(timeout, onTimeout: () {
        // 当超时发生时，抛出 TimeoutException
        throw TimeoutException(
            'Operation timed out after ${timeout.inSeconds}s');
      });
    } catch (e) {
      // 无论是超时还是代码报错，都会被捕获，程序不会崩溃，也不会卡死
      logBuffer.writeln("$taskName error/timeout: $e");
    }
  }

  static void _log(String message) {
    _logger.info("[AfterCommand] $message");
  }

  static void _logCritical(String message) {
    _logger.severe("[AfterCommand] $message");
    logBuffer.writeln("CRITICAL: $message");
  }
}
