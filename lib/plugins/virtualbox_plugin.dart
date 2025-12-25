import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:titan_fil/plugins/native_app.dart';

import '../models/Steps.dart';
import '../models/steps_warp.dart';
import '../services/log_service.dart';
import '../utils/file_helper.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/message_dialog.dart';
import 'base_plugin.dart';
import 'multipass_plugin.dart';

/**
 * VirtualBox 交互插件
 */
class VirtualBoxPlugin extends BasePlugin {
  static final VirtualBoxPlugin _instance = VirtualBoxPlugin._internal();
  static final logUtils = LoggerFactory.createLogger(LoggerName.t3);

  factory VirtualBoxPlugin() {
    return _instance;
  }

  VirtualBoxPlugin._internal();


  Future<bool> checkVirtualBoxVersion() async {
    Process? process;
    final logBuffer = StringBuffer();
    logBuffer.clear();

    try {
      logBuffer.writeln('VBoxManage Version:');
      process = await Process.start(
        'VBoxManage',
        ['--version'],
        runInShell: Platform.isWindows,
      );

      // 1. 等待退出代码 (这里包含超时逻辑)
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('check Version shell timeout ');
        },
      );

      // 2. 读取标准输出 (stdout) 和 标准错误 (stderr) 并转为字符串
      // 注意：需要在 process 结束后或者流关闭后才能完全获取
      final version = await process.stdout.transform(utf8.decoder).join();
      final error = await process.stderr.transform(utf8.decoder).join();

      // 3. 【关键修改】拿到具体数据后再打印
      // trim() 去除可能的换行符
      logBuffer.writeln(
          'exitCode:$exitCode; stdout:${version.trim()}; stderr:${error.trim()}');

      if (exitCode == 0) {
        return true;
      } else {
        return false;
      }
    } on TimeoutException {
      logBuffer.writeln('TimeoutException');
      return false;
    } on ProcessException catch (e) {
      logBuffer.writeln('ProcessException : ${e.message}');
      return false;
    } catch (e) {
      logBuffer.writeln('check Version catch: $e');
      return false;
    } finally {
      // 确保进程被清理（虽然上面 await process.exitCode 通常意味着进程已结束，但在异常情况下需要）
      // 只有在进程还在运行且未被 kill 时调用 kill
      // process?.kill(); // 视情况保留，通常 process.exitCode 返回后进程已死

      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }


  ///设置环境变量
  Future<bool> updateSystemPath() async {
    const String vboxPath = r"C:\Program Files\Oracle\VirtualBox";
    Process? process;
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      // 获取当前PATH环境变量
      final String? currentPath = Platform.environment['PATH'];
      // 检查路径是否已存在
      if (currentPath?.contains(vboxPath) ?? false) {
        logBuffer.writeln('path already exists in system PATH');
        await checkVirtualBoxVersion();
        return true;
      }

      // 构建新PATH值
      final String newPath =
          currentPath != null ? '$currentPath;$vboxPath' : vboxPath;
      logBuffer.writeln('setx PATH ;$newPath');

      // 使用Process.start以便更好的控制
      process = await Process.start(
        'setx',
        ['PATH', newPath, '/M'],
        runInShell: true,
      );
      logBuffer.writeln(
          'exitCode:${process.exitCode};stdout:${process.stdout}:stderr:${process.stderr}');

      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('setx command timed out');
        },
      );

      final errorOutput =
          (await process.stderr.transform(utf8.decoder).join()).trim();

      if (exitCode == 0) {
        return true;
      } else {
        return false;
      }
    } on TimeoutException {
      logBuffer.writeln('timed out');
      return false;
    } on ProcessException catch (e) {
      logBuffer.writeln('setx command catch: ${e.message}');
      return false;
    } catch (e) {
      logBuffer.writeln('Unknown error : $e');
      return false;
    } finally {
      process?.kill();
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  ///检测是否安装：
  Future<bool> isVirtualBoxInstalled() async {
    if (!Platform.isWindows) {
      return true;
    }

    Process? process;

    try {
      // 1. 优先检查注册表（快速检测）
      try {
        process = await Process.start(
          'reg',
          ['query', r'HKLM\SOFTWARE\Oracle\VirtualBox', '/v', 'InstallDir'],
        );

        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            process?.kill(ProcessSignal.sigkill);
            throw TimeoutException('Registry query timed out');
          },
        );

        if (exitCode == 0) {
          return true;
        }
      } catch (e) {
        debugPrint('Registry check failed: $e');
      }

      // 2. 注册表检查失败后尝试 VBoxManage
      try {
        process = await Process.start(
          'VBoxManage',
          ['--version'],
          runInShell: true,
        );

        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            process?.kill(ProcessSignal.sigkill);
            throw TimeoutException('VBoxManage check timed out');
          },
        );

        return exitCode == 0;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      process?.kill();
    }
  }

  /// 执行安装：
  Future<void> installVirtualBox({
    int timeoutSeconds = 600, // Default 10-minute timeout
  }) async {
    if (!Platform.isWindows) return;
    final logBuffer = StringBuffer();
    logBuffer.clear();

    if (await isVirtualBoxInstalled()) {
      logBuffer
          .writeln("VirtualBox is already installed. Skipping installation.");
      return;
    }

    final exeName = 'VirtualBox-7.1.6-167084-Win.exe';
    final libsPath = await FileHelper.getCurrentPath();
    final installerPath = '${libsPath}\\$exeName';

    if (!File(installerPath).existsSync()) {
      logBuffer.writeln(
        "Installer not found at: $installerPath",
      );
      return;
    }

    try {
      logBuffer.writeln("Installer : ");

      final process = await Process.start(
        powershell,
        [
          'Start-Process',
          '-FilePath',
          installerPath,
          '-Verb',
          'RunAs',
          '-Wait'
        ],
        runInShell: true,
      );
      logBuffer.writeln(
          'exitCode:${process.exitCode};stdout:${process.stdout}:stderr:${process.stderr}');

      // Timeout control
      await process.exitCode.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          process.kill();
          return -1; // Custom timeout code
        },
      );
    } on TimeoutException {
      logBuffer.writeln("Installation process timed out");
    } catch (e) {
      logBuffer.writeln("Installation error: ${e.toString()}");
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  ///VirtualBox 是否安装
  Future<StepsWarp> checkInstalled(
      BuildContext ctx, int index, List<Steps> list) async {
    basicSteps = list;

    var isInstalled = await isVirtualBoxInstalled();
    var statusText = isInstalled ? 'pcd_installed' : 'pcd_notInstalled';
    var description = "pcd_virtualBoxNotFind";
    var buttonText = "pcd_installNow";

    await updateSystemPath();
    Completer<StepsWarp> completer = Completer<StepsWarp>();
    // 使用 Completer 来处理返回值
    //去安装：
    var retryCount = 0;
    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);
      await installVirtualBox();
      await Future.delayed(const Duration(seconds: 2));
      var isInstalled = await isVirtualBoxInstalled();
      statusText = isInstalled ? 'pcd_installed' : 'pcd_notInstalled';
      loading.hide();
      description = 'pcd_virtualBoxNotFind2';
      retryCount++;
      await updateStep(index, isInstalled, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_reinstall" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);

      var isInstalled2 = await MultiPassPlugin().isMultiPassInstalled();
      if (isInstalled2) {
        if (isInstalled) {
          MessageDialog.show(
            context: ctx,
            config: MessageDialogConfig(
              titleKey: "gentleReminder".tr,
              messageKey: "pcd_task_restartComputer".tr,
              iconType: DialogIconType.error,
              buttonTextKey: "pcd_task_restart".tr,
              onAction: () => NativeApp.restartWindows(),
              cancelButtonTextKey: "cancel".tr,
            ),
          );
          return;
        }
      }
      // Only complete if not already completed
      if (!completer.isCompleted) {
        completer.complete(StepsWarp(
            stepCurrent: index + 1, list: getBasicSteps(), status: true));
      }
    }

    //重新检测：
    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false,
          des: description,
          txt: buttonText,
          onRetry: retry,
          onTap: method);
      await Future.delayed(const Duration(seconds: 2));
      checkInstalled(ctx, index, getBasicSteps());
    }

    await Future.delayed(const Duration(seconds: 1));
    await updateStep(index, isInstalled, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);
    if (!isInstalled) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    } // 这里是确保函数总是返回一个StepsWarp类型
    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      logUtils.info('[VirtualBox Plugin] : $message');
    } else {
      logUtils.warning('[VirtualBox Plugin Error] : $message');
    }
  }
}
