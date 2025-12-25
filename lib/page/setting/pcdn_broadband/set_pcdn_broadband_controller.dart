/**
 * 主界面控制器
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:titan_fil/page/setting/pcdn_broadband/set_pcdn_broadband_state.dart';

import '../../../constants/constants.dart';
import '../../../plugins/multipass_plugin.dart';
import '../../../services/global_service.dart';
import '../../../services/log_service.dart';
import '../../../utils/file_helper.dart';
import '../../../utils/preferences_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/toast_dialog.dart';

class SetPcdnBroadbandController extends GetxController {
  final SetPcdnBroadbandState state = SetPcdnBroadbandState();
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);
  final GlobalService globalService = Get.find<GlobalService>();

  ///初始化
  @override
  void onInit() {
    runScript();
    super.onInit();
  }

  ///页面渲染完成
  @override
  void onReady() {
    super.onReady();
  }

  ///释放资源
  @override
  void onClose() {
    super.onClose();
  }

  Future<void> runScript() async {
    state.loadStatus.value = true;
    final logBuffer = StringBuffer();
    logBuffer.clear();
    logBuffer.writeln("runScript:");
    try {
      final value =
          await PreferencesHelper.getString(Constants.bandwidth) ?? "";
      state.bandwidth.value = value;

      /// todo : hh
      /* String libsPath = await FileHelper.getParentPath();
      String workingDir = AppConfig.workingDir;*/
      // String extractToPath = path.join(libsPath, path.join(workingDir, "PSTools"));
      String libsPath = await FileHelper.getWorkAgentPath();
      state.psexecPath = path.join(libsPath, "PSTools", "psexec.exe");

      ///获取虚拟机名称
      var list = await MultiPassPlugin().getVmNames();
      logBuffer.writeln("getVmNames:$list");
      final result0 = await MultiPassPlugin().runCommand(
          'multipass', ['list', '--format', 'json'],
          timeout: Duration(seconds: 120));
      logBuffer.writeln("result0:$result0");
      final data = jsonDecode(result0['msg']) as Map<String, dynamic>;
      final vmNames = (data['list'] as List)
          .map<String>((v) => v['name'] as String)
          .toList();
      if (list.length > 0) {
        state.vbName = list[0].trim();
      } else if (vmNames.length > 0) {
        state.vbName = vmNames[0].trim();
      }
      if (state.vbName.isEmpty) {
        return;
      }
      logBuffer.writeln("getVmNames:vbName:${state.vbName}");
    } catch (e) {
      logBuffer.writeln("catch :$e");
    } finally {
      state.loadStatus.value = false;
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<void> onSubmit(BuildContext context) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    debugPrint("vbName:${state.vbName}");
    logBuffer.writeln("onSubmit");
    final loading = LoadingIndicator();
    try {
      if (state.loadStatus.value) {
        _onErrorMsg(context, "虚拟机查询中，请稍后".tr);
        return;
      }
      String input = state.editingController.text.trim();
      double cpuValue = double.tryParse(input) ?? 0;
      if (cpuValue < 0) {
        _onErrorMsg(context, "数据不能小于0");
        return;
      }
      debugPrint("input:${input}");
      // bool hasNext = await _startAction(context);
      // if (!hasNext) return;
      if (globalService.isAgentRunning.value) {
        _onErrorMsg(context, "task_pcdn_tip8".tr);
        return;
      }

      loading.show(context, message: "restarting".tr);
      final res = await runCommand([
        'bandwidthctl',
        '${state.vbName.trim()}',
        'set',
        'Limit',
        '--limit',
        '${input}m',
      ]);

      if (res.success) {
        _onToastMsg(context, "上行流量修改成功");
        await PreferencesHelper.setString(Constants.bandwidth, input);
        state.bandwidth.value = input;

        return;
      }
      // 绑定带宽组到网卡1
      final result = await runCommand([
        'modifyvm',
        '${state.vbName.trim()}',
        '--nicbandwidthgroup1',
        'Limit',
      ]);
      if (!result.success) {
        logBuffer.writeln("绑定带宽组到网卡1:$result");
        return;
      }
      // 修改带宽限制为30m
      final result2 = await runCommand([
        'bandwidthctl',
        '${state.vbName.trim()}',
        'set',
        'Limit',
        '--limit',
        '${input}m',
      ]);
      if (!result2.success) {
        logBuffer.writeln("修改带宽限制为30m:$result2");
        return;
      }
      await PreferencesHelper.setString(Constants.bandwidth, input);
      state.bandwidth.value = input;
      // 解绑网卡带宽限制
      final result3 = await runCommand([
        'modifyvm',
        '${state.vbName.trim()}',
        '--nicbandwidthgroup1',
        'none',
      ]);
      if (!result3.success) {
        logBuffer.writeln("修改带宽限制为30m:$result3");
        return;
      }
    } catch (e) {
      logBuffer.writeln("catch :$e");
    } finally {
      state.loadStatus.value = false;
      loading.hide();
      _log(logBuffer.toString());
      logBuffer.clear();
    }

    // debugPrint("解绑网卡带宽限制:$result3");
    // // 删除带宽组
    // final result4 = await runCommand([
    //   'bandwidthctl',
    //   '${state.vbName.trim()}',
    //   'remove',
    //   'Limit',
    // ]);
    // debugPrint("删除带宽组:$result4");
    // // 列出带宽组状态
    // final result5 = await runCommand([
    //   'bandwidthctl',
    //   '${state.vbName.trim()}',
    //   'list',
    // ]);
    // debugPrint("列出带宽组状态:$result5");
  }

  int timeoutSeconds = 30;

  Future<CommandResult> runCommand(List<String> vboxmanageArgs) async {
    final args = [
      '-s',
      'vboxmanage',
      ...vboxmanageArgs,
    ];

    print('Running in C:\\Windows\\System32: psexec ${args.join(' ')}');
    print('psexecPath:  ${state.psexecPath}');

    try {
      final result = await Process.run(
        state.psexecPath,
        args,
        workingDirectory: r'C:\Windows\System32',
      ).timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          throw TimeoutException(
              '命令执行超时（${timeoutSeconds}s）: psexec ${args.join(' ')}');
        },
      );

      final success = result.exitCode == 0;
      return CommandResult(
        success: success,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        errorMessage: null,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: '',
        errorMessage: e.toString(),
      );
    } catch (e) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: '',
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> _startAction(BuildContext context) async {
    final completer = Completer<bool>();
    MessageDialog.show(
      context: context,
      config: MessageDialogConfig(
        titleKey: "gentleReminder".tr,
        messageKey: "task_pcdn_tip9".tr,
        iconType: DialogIconType.error,
        buttonTextKey: "confirm".tr,
        onAction: () => completer.complete(true),
        onCancel: () => completer.complete(false),
        cancelButtonTextKey: "cancel".tr,
      ),
    );
    return completer.future;
  }

  void _onErrorMsg(BuildContext context, String msg) {
    ToastHelper.showWarning(
      context,
      title: 'msg_dialog_error'.tr, // 错误标题
      message: msg,
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 5),
      ),
    );
  }

  void _onToastMsg(BuildContext context, String msg) {
    ToastHelper.showSuccess(
      context,
      message: 'msg_dialog_change_ok'.tr,
      title: "$msg",
    );
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[SetPcdn] : $message');
    } else {
      _logger.warning('[SetPcdn Error] : $message');
    }
  }
}

class CommandResult {
  final bool success;
  final int exitCode;
  final String stdout;
  final String stderr;
  final String? errorMessage; // 超时或异常信息

  CommandResult({
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'CommandResult{success: $success, exitCode: $exitCode, stdout: $stdout, stderr: $stderr, errorMessage: $errorMessage}';
  }
}
