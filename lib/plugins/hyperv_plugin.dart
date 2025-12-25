import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as path;

import '../models/Steps.dart';
import '../models/steps_warp.dart';
import '../services/log_service.dart';
import '../utils/file_helper.dart';
import '../widgets/loading_indicator.dart';
import 'base_plugin.dart';
import 'bat_sh_runner.dart';
import 'native_app.dart';

/**
 * Hyper-V 交互插件
 *
 */
class HyperVPlugin extends BasePlugin {
  static final HyperVPlugin _instance = HyperVPlugin._internal();
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  factory HyperVPlugin() {
    return _instance;
  }

  HyperVPlugin._internal();

  /// 检查 Hyper-V 是否已启用
  Future<Map<String, dynamic>> isHyperVEnabled() async {
    if (!Platform.isWindows) {
      return {"status": false, "type": false, "msg": "Not a Windows system"};
    }
    // 1. 先尝试主检查（BatShRunner）
    try {
      await BatShRunner().isHyperVEnabled();
      await Future.delayed(Duration(seconds: 2));
      final logspath = await FileHelper.getLogsPath();
      final filePath = path.join(logspath, "hyperv_status.json");
      final fileContent = await File(filePath).readAsString();
      final jsonData = jsonDecode(fileContent) as Map<String, dynamic>;

      // 如果主检查返回 false，也触发回退
      if (jsonData['hyperv_status'] == false) {
        throw Exception("Primary check returned false");
      }
      return {
        "status": jsonData['hyperv_status'],
        "type": jsonData['hyperv_status'],
        "msg": "${jsonData['hypervisorlaunchtype']}",
      };
    } catch (e) {
      // 2. 主检查失败或返回 false，回退到备用检查（使用 Get-WindowsOptionalFeature）
      try {
        final result = await Process.run(
          'powershell',
          [
            'Get-WindowsOptionalFeature',
            '-Online',
            '-FeatureName',
            'Microsoft-Hyper-V-All'
          ],
        ).timeout(const Duration(seconds: 10)); // 增加超时控制

        final output = result.stdout.toString();

        // 解析 PowerShell 输出
        final isEnabled = output.contains("State : Enabled");
        final isDisabled = output.contains("State : Disabled");
        if (isEnabled) {
          return {
            "status": true,
            "type": true, // 注意：这里type可能与主检查不同，需根据实际情况调整
            "msg": "Fallback to PowerShell check: Hyper-V is enabled",
          };
        } else if (isDisabled) {
          return {
            "status": false,
            "type": false,
            "msg": "Fallback to PowerShell check: Hyper-V is disabled",
          };
        } else {
          throw Exception("Failed to parse PowerShell output: $output");
        }
      } on TimeoutException {
        return {
          "status": false,
          "type": false,
          "msg": "PowerShell command timed out",
        };
      } catch (fallbackError) {
        return {
          "status": false,
          "type": false,
          "msg": "All checks failed: $e, $fallbackError",
        };
      } finally {}
    }
  }

  /// 开启 （运行状态）
  Future<void> setHypervisorLaunchType() async {
    if (!Platform.isWindows) {
      return null;
    }
    try {
      var result = await Process.run(
        powershell,
        [
          '-Command',
          'Start-Process bcdedit -ArgumentList "/set", "hypervisorlaunchtype", "auto" -Verb RunAs'
        ],
        runInShell: true,
      );
      _log('setBcdedit result: ${result.exitCode};${result.stdout}');
    } catch (e) {
      _log('setBcdedit Error in isHyperVEnabled: $e', warning: true);
    }
  }

  /// Hyper-V 启用
  Future<void> enableHyperV() async {
    if (!Platform.isWindows) {
      return null;
    }
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      logBuffer.writeln("enableHV:start ");
      ProcessResult result = await Process.run(
        powershell,
        [
          'Start-Process',
          'powershell',
          '-ArgumentList',
          '"Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -All"',
          '-Verb',
          'RunAs',
          '-WindowStyle', 'Hidden' // 隐藏窗口
        ],
        runInShell: true,
      );
      logBuffer.writeln(
          'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');
    } catch (e) {
      logBuffer.writeln("enableHV:start error $e");
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  /// Hyper-V 启用
  Future<StepsWarp> checkHyperVService(
      BuildContext ctx, int index, List<Steps> list) async {
    //检查 Hyper-V 是否已启用
    basicSteps = list;
    var map = await isHyperVEnabled();
    var status = map["status"];
    var statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
    var description = map["msg"];
    var buttonText = "pcd_starting";
    Completer<StepsWarp> completer = Completer<StepsWarp>();

    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false, des: description, txt: buttonText);
      await Future.delayed(const Duration(seconds: 2));
      checkHyperVService(ctx, index, getBasicSteps());
    }

    var retryCount = 0;

    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);

      ///Hyper-V 启用
      await enableHyperV();
      var map = await isHyperVEnabled();
      status = map["status"];
      await Future.delayed(const Duration(seconds: 2));
      loading.hide();
      description = 'pcd_hvError';
      retryCount++;
      await updateStep(index, status, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_starting" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);

      completer.complete(StepsWarp(
          stepCurrent: status ? index + 1 : index,
          list: getBasicSteps(),
          status: status));
    }

    await Future.delayed(const Duration(seconds: 1));
    await updateStep(index, status, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);
    if (!map["status"]) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    }
    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  ///Hyper-V 开启 （运行状态）
  Future<StepsWarp> checkHyperVStatus(
      BuildContext ctx, int index, List<Steps> list) async {
    basicSteps = list;

    var map = await isHyperVEnabled();
    var status = map["type"];
    var statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
    var description = map["msg"];
    var buttonText = "pcd_starting";
    Completer<StepsWarp> completer = Completer<StepsWarp>();

    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false, des: description, txt: buttonText);
      await Future.delayed(const Duration(seconds: 2));
      checkHyperVStatus(ctx, index, getBasicSteps());
    }

    var retryCount = 0;

    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);

      ///Hyper-V 开启 （运行状态）
      await setHypervisorLaunchType();
      var map = await isHyperVEnabled();
      status = map["type"];
      statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
      description = map["msg"];
      await Future.delayed(const Duration(seconds: 2));
      loading.hide();
      description = 'pcd_hvError2';
      retryCount++;
      await updateStep(index, status, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_starting" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);

      completer.complete(StepsWarp(
          stepCurrent: status ? index + 1 : index,
          list: getBasicSteps(),
          status: status));
    }

    await updateStep(index, status, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);

    if (!map["type"]) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    }

    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[HyperV Plugin] : $message');
    } else {
      _logger.warning('[HyperV Plugin Error] : $message');
    }
  }
}
