/**
 * 主界面控制器
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/page/setting/pcdn/set_pcdn_state.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../constants/constants.dart';
import '../../../models/ip_info.dart';
import '../../../network/api_service.dart';
import '../../../plugins/agent_Isolate.dart';
import '../../../plugins/bat_sh_runner.dart';
import '../../../plugins/multipass_plugin.dart';
import '../../../services/global_service.dart';
import '../../../services/log_service.dart';
import '../../../utils/preferences_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/toast_dialog.dart';

class SetPcdnController extends GetxController {
  final SetPcdnState state = SetPcdnState();
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);
  final GlobalService globalService = Get.find<GlobalService>();

  ///初始化
  @override
  void onInit() {
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

  void onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0;
    if (isVisible) {
      if (!state.loadStatus.value) {
        runScript();
      }
    }
  }

  String removeUnit(String sizeWithUnit) {
    // 匹配数字（包括小数点和整数）
    final regex = RegExp(r'^(\d+\.?\d*)');
    final match = regex.firstMatch(sizeWithUnit);
    return match?.group(1) ?? sizeWithUnit; // 如果匹配失败，返回原字符串
  }

  void setDefaultValue() {
    state.cpuEditingController.text = "4";
    state.memoryEditingController.text = "4";
    state.diskEditingController.text = "64";
  }

  Future<void> runScript() async {
    state.loadStatus.value = true;
    final logBuffer = StringBuffer();
    logBuffer.clear();
    logBuffer.writeln("runScript:");
    try {
      try {
        final value =
            await PreferencesHelper.getString(Constants.bandwidth) ?? "";
        state.bandwidthEditingController.text = value;

        final ipData = await ApiService.getLocation();
        final cnIpData = ipData?['cn'];
        final enIpData = ipData?['en'];
        if (cnIpData != null && enIpData != null) {
          bool hasChinaIpCn =
              isChinaIp(cnIpData) && isMainlandChinaIp(cnIpData);
          bool hasChinaIpEn =
              isChinaIp(enIpData) && isMainlandChinaIp(enIpData);
          if (hasChinaIpEn || hasChinaIpCn) {
            state.minDiskSize = 64;
          } else {
            state.minDiskSize = 100;
          }
        }
      } catch (e) {
        logBuffer.writeln("getLocation error:$e");
      }

      try {
        String? driveLetter = null;

        ///获取虚拟机的安装位置
        String? resultPath =
            await MultiPassPlugin().getMultipassPathFromProcess();
        // 如果路径不为空且是标准 Windows 路径（如 "C:\xxx"），提取盘符
        if (resultPath != null &&
            resultPath.length >= 2 &&
            resultPath[1] == ':') {
          driveLetter =
              resultPath[0].toUpperCase(); // 取第一个字母并转大写（如 "D:\" -> "D"）
        }
        // 调用批处理脚本
        final info = await BatShRunner().getSystemInfo(drivePath: driveLetter);

        logBuffer.writeln("info: $info");
        if (info != null) {
          state.info.value = info;
          state.info.value['disk']?['available'] =
              parseDiskSize(info['disk']?['available']);
          state.info.value['memory']?['total_gb'] =
              parseDiskSize(info['memory']?['total_gb']);
          state.info.value['cpu']?['cores'] =
              parseDiskSize(info['cpu']?['cores']);
        }
      } catch (e) {
        logBuffer.writeln("getSystemInfo error:$e");
      }

      try {
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
          state.vbName = list[0];
        } else if (vmNames.length > 0) {
          state.vbName = vmNames[0];
        }
        if (state.vbName.isEmpty) {
          setDefaultValue();
          return;
        }
        logBuffer.writeln("getVmNames:vbName:${state.vbName}");
      } catch (e) {
        logBuffer.writeln("getVmNames error:$e");
      }

      try {
        final plugin = MultiPassPlugin();
        final result = await plugin.runCommand(
            'multipass', ['get', "local.${state.vbName.trim()}.cpus"]);
        logBuffer.writeln("get local.vm.cpus :$result");

        final result2 = await plugin.runCommand(
            'multipass', ['get', "local.${state.vbName.trim()}.memory"]);
        logBuffer.writeln("get local.vm.memory :$result2");

        final result3 = await plugin.runCommand(
            'multipass', ['get', "local.${state.vbName.trim()}.disk"]);
        logBuffer.writeln("get local.vm.disk :$result3");

        if (result['status']) {
          state.cpuEditingController.text = "${parseDiskSize(result['msg'])}";
        } else {
          setDefaultValue();
        }
        if (result2['status']) {
          state.memoryEditingController.text =
              "${parseDiskSize(result2['msg'])}";
        } else {
          setDefaultValue();
        }

        if (result3['status']) {
          state.diskEditingController.text = "${parseDiskSize(result3['msg'])}";
          state.minDiskSize = state.diskEditingController.text.toRoundToInt();
        } else {
          setDefaultValue();
        }
      } catch (e) {
        setDefaultValue();
      }
    } catch (e) {
      logBuffer.writeln("catch :$e");
    } finally {
      state.loadStatus.value = false;
      _log(logBuffer.toString());
      logBuffer.clear();
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

  Future<void> onSave(BuildContext context, int tag) async {
    if (state.loadStatus.value) {
      _onErrorMsg(context, "task_pcdn_tip".tr);
      return;
    }

    // 检查对应输入框是否为空
    if ((tag == 1 && state.cpuEditingController.text.isEmpty) ||
        (tag == 2 && state.diskEditingController.text.isEmpty) ||
        (tag == 3 && state.memoryEditingController.text.isEmpty) ||
        (tag == 4 && state.bandwidthEditingController.text.isEmpty)) {
      _onErrorMsg(context, "task_pcdn_tip3".tr);
      return;
    }

    if (tag == 1) {
      String input = state.cpuEditingController.text.trim();
      double cpuValue = double.tryParse(input) ?? 0;
      if (cpuValue < state.minCpuSize) {
        final tip = "${"task_pcdn_tip4".tr}";
        _onErrorMsg(context, tip);
        return;
      }
      int cpuSize = state.info.value['cpu']?['cores'] ?? 0;

      if (cpuValue >= cpuSize) {
        final tip =
            "${"task_pcdn_tip7".tr} ${cpuSize} ${"task_pcdn_cpu_unit".tr}";
        _onErrorMsg(context, tip);
        return;
      }
    }

    if (tag == 2) {
      String input = state.diskEditingController.text.trim();
      double cpuValue = double.tryParse(input) ?? 0;

      if (cpuValue < state.minDiskSize) {
        final tip =
            "${"task_pcdn_tip6".tr}".replaceAll("@", "${state.minDiskSize}");
        _onErrorMsg(context, tip);
        return;
      }

      int cpuSize = parseDiskSize(state.info.value['disk']?['available']);
      if (cpuValue >= cpuSize) {
        _onErrorMsg(context, "${"task_pcdn_tip7".tr} ${cpuSize}G");
        return;
      }

      bool hasNext = await _startAction(context);
      if (!hasNext) return;
    }
    if (tag == 3) {
      String input = state.memoryEditingController.text.trim();
      double cpuValue = double.tryParse(input) ?? 0;
      if (cpuValue < state.minMemorySize) {
        _onErrorMsg(context, "${"task_pcdn_tip5".tr}");
        return;
      }
      int cpuSize = parseDiskSize(state.info.value['memory']?['total_gb']);
      if (cpuValue >= cpuSize) {
        _onErrorMsg(context, "${"task_pcdn_tip7".tr} ${cpuSize}G");
        return;
      }
    }

    if (tag == 4) {
      String input = state.bandwidthEditingController.text.trim();
      double bandwidthValue = double.tryParse(input) ?? 0;
      if (bandwidthValue < 10) {
        _onErrorMsg(context, "${"task_pcdn_tip10".tr}");
        return;
      }
    }

    if (globalService.isAgentRunning.value) {
      _onErrorMsg(context, "task_pcdn_tip8".tr);
      return;
    }

    final loading = LoadingIndicator();
    loading.show(context, message: "restarting".tr);

    final logBuffer = StringBuffer();
    logBuffer.writeln("onSave: tag = $tag");

    if (tag == 4) {
      String input = state.bandwidthEditingController.text.trim();
      final result = await BatShRunner()
          .runLimitScript('${input}', '${input}', vbName: state.vbName..trim());
      if (result.success) {
        _onToastMsg(context, "task_pcdn_bandwidth".tr);
        await PreferencesHelper.setString(Constants.bandwidth, input);
      } else {
        _onErrorMsg(context, result.toString());
      }
      print("runLimitScript:$result");
      _log(logBuffer.toString());
      loading.hide();
      return;
    }
    final plugin = MultiPassPlugin();
    final result = await plugin.runCommand(
        'multipass', ['list', '--format', 'json'],
        timeout: Duration(seconds: 120));

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(result['msg']) as Map<String, dynamic>;
    } catch (e) {
      loading.hide();
      _log(logBuffer.toString(), warning: true);
      _onErrorMsg(context, "task_pcdn_tip2".tr + " (${e.toString()})");
      return;
    }

    logBuffer.writeln("multipass list: $result");
    debugPrint("multipass list: $result");

    if (result['status'] != true || data['list'].length == 0) {
      loading.hide();
      _log(logBuffer.toString(), warning: true);
      _onErrorMsg(context, "task_pcdn_tip2".tr);
      return;
    }

    // 执行设置操作
    if (tag == 1) {
      await _setVmConfig(
        context,
        key: 'cpus',
        value: state.cpuEditingController.text,
        messageKey: "settings_pcdn_cpu_name",
        logBuffer: logBuffer,
      );
    } else if (tag == 2) {
      await _setVmConfig(
        context,
        key: 'disk',
        value: "${state.diskEditingController.text}G",
        messageKey: "settings_pcdn_memory_disk",
        logBuffer: logBuffer,
      );
    } else if (tag == 3) {
      await _setVmConfig(
        context,
        key: 'memory',
        value: "${state.memoryEditingController.text}G",
        messageKey: "settings_pcdn_memory_name",
        logBuffer: logBuffer,
      );
    }

    _log(logBuffer.toString());
    loading.hide();
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[SetPcdn] : $message');
    } else {
      _logger.warning('[SetPcdn Error] : $message');
    }
  }

  Future<void> _setVmConfig(
    BuildContext context, {
    required String key,
    required String value,
    required String messageKey,
    required StringBuffer logBuffer,
  }) async {
    final plugin = MultiPassPlugin();
    final keyValue = "local.${(state.vbName).trim()}.$key=$value";
    final res = await AgentIsolate.forceStopVm(state.vbName.trim());
    logBuffer.writeln("stop ${(state.vbName)}: $res");
    final result = await plugin.runCommand('multipass', ['set', keyValue]);
    logBuffer.writeln("set $keyValue : $result");
    if (result['status'] == true) {
      _onToastMsg(context, messageKey.tr);
    } else {
      _onErrorMsg(context, result.toString());
    }
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

  /// 检查 IP 是否属于中国
  bool isChinaIp(IpInfo ipData) {
    final countryCode = ipData.countryCode.toString().toUpperCase();
    return countryCode == 'CN';
  }

  bool isMainlandChinaIp(IpInfo ipData) {
    if (!isChinaIp(ipData)) return false;

    final province = ipData.province.toString().toLowerCase() ?? '';
    // 检查是否属于港澳台（中英文关键字）
    final nonMainlandKeywords = [
      '香港',
      'hong kong',
      'hk',
      'Hong Kong'
          '澳门',
      'macau',
      'macao',
      'mo',
      'Macao'
          '台湾',
      'taiwan',
      'tw',
      'Taiwan'
    ];
    for (final keyword in nonMainlandKeywords) {
      if (province.contains(keyword)) {
        return false;
      }
    }
    return true;
  }

  int parseDiskSize(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      return value.ceil(); // 直接向上取整
    } else if (value is String) {
      try {
        // 移除所有非数字字符（如 "GB"、"MB"）
        String numericString = value.replaceAll(RegExp(r'[^0-9.]'), '');
        double parsedValue = double.tryParse(numericString) ?? 0.0;
        return parsedValue.floor(); // 解析后向下取整
      } catch (e) {
        return 0;
      }
    } else {
      return 0;
    }
  }
}
