import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:titan_fil/models/status_result.dart';
import 'package:win32/win32.dart';

import '../config/app_config.dart';
import '../constants/constants.dart';
import '../models/Steps.dart';
import '../models/system_command.dart';
import '../services/log_service.dart';
import '../services/scheduler_service.dart';
import '../utils/file_helper.dart';
import '../utils/preferences_helper.dart';
import 'agent_Isolate.dart';
import 'base_plugin.dart';
import 'macos_pligin.dart';
import 'multipass_plugin.dart';
import 'native_app.dart';

/**
 * Titan Agent 交互插件
 *
 */
class AgentPlugin extends BasePlugin {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  static final AgentPlugin _instance = AgentPlugin._internal();

  factory AgentPlugin() {
    return _instance;
  }

  AgentPlugin._internal();

  static Future<bool> checkAgent() async {
    /// todo :hhh
    // String libsPath = await FileHelper.getParentPath();
    // String workingDir = AppConfig.workingDir;
    // String agent = AppConfig.agentProcess;
    // String agentPath = path.join(libsPath, path.join(workingDir, agent));

    String agentPath = await FileHelper.getAgentProcessPath();
    final file = File(agentPath);
    if (await file.exists()) {
      return true;
    }
    return false;
  }

  static Future<String> fetchMd5Checksum() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ));
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    Future<String> getAgentMD5Url() async {
      if (!Platform.isMacOS) return AppConfig.downAgentWindowsMD5;
      final hasArm64 = await MacOsPlugin.isSupportAgents();
      return hasArm64
          ? AppConfig.downAgentDarwinMD5
          : AppConfig.downAgentDarwinArm64MD5;
    }

    try {
      final downUrl = await getAgentMD5Url();
      final response = await dio.get(downUrl);
      return response.data.toString().trim();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return "Dio timed error: ${e.type} - ${e.message}";
      } else {
        return "Dio error: $e";
      }
    } catch (e) {
      return "Dio Unexpected error: $e";
    }
  }

  /// 绑定key
  Future<StatusResult> bindKey(String key) async {
    try {
      await PreferencesHelper.setString(Constants.bindKey, key);
      StatusResult result = await AgentIsolate.bindKey();
      await PreferencesHelper.setBool(Constants.hasT4Bind, result.state);
      return result;
    } catch (e) {
      return StatusResult(
        state: false,
        name: 'ERROR',
        message: "bind t4Key error ${e}",
      );
    }
  }

  Future<String> readAgentId() async {
    try {
      // todo:hhh
      // String libsPath = await FileHelper.getParentPath();
      // String workingDir = path.join(libsPath, AppConfig.workingDir, '.titanagent', 'agent_id');

      String agentPath = await FileHelper.getWorkAgentPath();
      String workingDir = path.join(agentPath, '.titanagent', 'agent_id');
      final file = File(workingDir);
      // 先判断文件是否存在
      if (!await file.exists()) {
        return "";
      }
      // 读取文件内容
      String content = await file.readAsString();
      // 读取文件内容
      return content;
    } catch (e) {
      _log("read agent_id error :${e}", warning: true);
      return "";
    }
  }

  Future<SystemCommand?> readMutipassStatus() async {
    if (!Platform.isWindows) {
      return null;
    }
    final logBuffer = StringBuffer();

    try {
      logBuffer.clear();
      //todo :hhh
      // String libsPath = await FileHelper.getParentPath();
      // String workingDir = '${libsPath}\\${AppConfig.workingDir}\\apps\\qiniu-windows\\opt';

      String agentPath = await FileHelper.getWorkAgentPath();
      String workingDir = path.join(agentPath, 'apps', 'qiniu-windows', "opt");
      logBuffer.writeln("read workingDir :$workingDir");
      // 读取文件内容
      String content = await File(workingDir).readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;
      logBuffer.writeln("read jsonData :$jsonData");
      return SystemCommand.fromJson(jsonData);
    } catch (e) {
      logBuffer.writeln("read agent_id error :${e}");
      return null;
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<bool> isProcessRun(String processName) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    if (!Platform.isWindows) {
      try {
        final result = await Process.run('pgrep', ['-x', '$processName'])
            .timeout(Duration(seconds: 5));
        if (result.exitCode == 0 &&
            (result.stdout as String).trim().isNotEmpty) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        logBuffer.writeln("isProcessRun error :$e");
        _log(logBuffer.toString());
        return false;
      }
    }
    final processIds = calloc<DWORD>(1024); // 存储进程 ID
    final bytesReturned = calloc<DWORD>();
    // 获取所有进程 ID
    if (EnumProcesses(processIds, sizeOf<DWORD>() * 1024, bytesReturned) == 0) {
      calloc.free(processIds);
      calloc.free(bytesReturned);
      return false;
    }
    final count = bytesReturned.value ~/ sizeOf<DWORD>();
    for (var i = 0; i < count; i++) {
      final pid = processIds.elementAt(i).value;
      // 打开进程，获取进程句柄
      final hProcess = OpenProcess(
          PROCESS_ACCESS_RIGHTS.PROCESS_QUERY_INFORMATION |
              PROCESS_ACCESS_RIGHTS.PROCESS_VM_READ,
          0,
          pid);
      if (hProcess != 0) {
        final exeName = calloc<WCHAR>(MAX_PATH).cast<Utf16>();
        GetModuleBaseName(hProcess, 0, exeName, MAX_PATH);

        final exeFileName = exeName.toDartString();
        if (exeFileName.toLowerCase() == processName.toLowerCase()) {
          CloseHandle(hProcess);
          calloc.free(processIds);
          calloc.free(bytesReturned);
          calloc.free(exeName);
          return true;
        }
        CloseHandle(hProcess);
        calloc.free(exeName);
      }
    }

    calloc.free(processIds);
    calloc.free(bytesReturned);
    return false;
  }

  final scheduler = SchedulerService();

  /// 重新检查的时候，或者关闭检查弹窗。需要先关闭定时查询：不然会导致 检测时一直同时检查agent (出现同时检查最后一步)
  void closeSchedulerAgentStatusTask() {
    try {
      scheduler.cancelTask('agentStatusTask');
    } catch (e) {
      e.printError();
    }
  }

  void monitorAgentStatus(
    BuildContext ctx,
    int index,
    List<Steps> list,
    void Function(bool success) onResult,
  ) async {
    basicSteps = list;
    int taskRunCount = 0;
    bool hasRestart = false;
    AgentIsolate.runAgent();
    Future<void> retry() async {
      taskRunCount = 0;
      hasRestart = true;
      await updateStep(index, false, "", isActive: false);
      await AgentIsolate.killProcesses();
      await Future.delayed(const Duration(seconds: 2));
      await MultiPassPlugin().killProcesses();
      await Future.delayed(const Duration(seconds: 2));
      AgentIsolate.runAgent();
    }

    scheduler.schedulePeriodicTask(
      'agentStatusTask',
      const Duration(seconds: 3),
      () async {
        taskRunCount++;
        var agentStatus = globalService.isAgentRunning.value;
        var statusText =
            agentStatus ? 'pcd_task_success'.tr : 'pcd_task_fail'.tr;
        var description = "pcd_restartError";
        var buttonText = "pcd_task_restart".tr;

        if (agentStatus) {
          scheduler.cancelTask('agentStatusTask');
          await updateStep(index, true, statusText);
          globalService.pcdnMonitoringStatus.value = 3;
          onResult(true);
        } else if (taskRunCount >= 60) {
          globalService.pcdnMonitoringStatus.value = 5;
          if (hasRestart) {
            description = "pcd_restartError2";
            await updateStep(index, false, statusText,
                des: description, txt: null, onTap: null, onRetry: null);
          } else {
            await updateStep(index, false, statusText,
                des: description,
                txt: buttonText,
                onTap: () => NativeApp.restartWindows(),
                onRetry: retry);
          }
          onResult(false);
        }
      },
    );
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[Agent Plugin] : $message');
    } else {
      _logger.warning('[Agent Plugin Error] : $message');
    }
  }
}
