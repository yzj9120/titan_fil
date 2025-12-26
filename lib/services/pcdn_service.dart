import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/constants/constants.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/services/scheduler_service.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../controllers/agent_controller.dart';
import '../models/check_info.dart';
import '../network/api_service.dart';
import '../page/task/pcdn/child/env_state.dart';
import '../plugins/agent_Isolate.dart';
import '../plugins/agent_plugin.dart';
import '../plugins/base_plugin.dart';
import '../plugins/bat_sh_runner.dart';
import '../plugins/hyperv_plugin.dart';
import '../plugins/multipass_plugin.dart';
import '../plugins/native_app.dart';
import '../plugins/virtualbox_plugin.dart';
import '../widgets/custom_tooltip.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/message_dialog.dart';
import '../widgets/text_widget.dart';
import 'global_service.dart';
import 'log_service.dart';

/// PCDN服务类 - 负责处理赚钱流程的启动、停止和重启等操作
class PCDNService {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  PCDNService._internal();

  // 静态变量存储单例实例
  static PCDNService? _instance;

  // 使用 getInstance 方法来返回单例实例
  static PCDNService getInstance() {
    if (_instance == null) {
      _instance = PCDNService._internal(); // 如果实例为空，则创建新实例
    }
    return _instance!; // 返回单例实例
  }

  final _globalService = Get.find<GlobalService>();

  /// 全局服务实例
  final AgentController _agentController = Get.find<AgentController>();

  void pullInfo(String newAgentId) async {
    _agentController.refreshData(newAgentId);
  }

  /// 监测是否支持运行区域
  Future<bool> onCheckOperatingArea() async {
    CheckInfo? checkRes = await ApiService.checkActivity();
    if (checkRes != null) {
      return checkRes.open;
    } else {
      return false;
    }
  }

  Future<bool> checkProxy({Function? onShow, bool isNext = false}) async {
    final completer = Completer<bool>();
    try {
      final info = await BatShRunner().getCheckProxyIp();
      _log('getCheckProxyIp vpn ；$info');
      onShow?.call();
      if (info != null) {
        bool proxy_process = info["proxy_working"] is bool
            ? info["proxy_working"]
            : (info["proxy_working"] == "true") &&
                info["proxy_ip"] != "unknown";
        if (proxy_process) {
          final context = Get.overlayContext;
          if (context != null && context.mounted) {
            bool _dontRemind = false; // 局部状态变量
            MessageDialog.show(
              context: context,
              config: MessageDialogConfig(
                width: 430,
                buttonWidth: 250,
                showCloseButton: true,
                iconType: DialogIconType.image,
                image: '\u{26A0}'.toEmojiText(fontSize: 51),
                titleKey: "run_vpn_tip2".tr,
                messageKey: "run_vpn_tip".tr,
                buttonTextKey: "run_vpn_btn1".tr,
                cancelButtonTextKey: "run_vpn_btn2".tr,
                childWidget: [
                  Stack(
                    children: [
                      CustomTooltip(
                        message: "run_vpn_tip5".tr,
                        preferredDirection: AxisDirection.up,
                        sizeWidth: 0,
                        fontSize: 13,
                        child: TextWidget(
                          "run_vpn_tip4".tr,
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Transform.translate(
                          offset: Offset(0, 2),
                          child: Container(
                            height: 1,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
                buttonWidget: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Container(
                      margin: EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _dontRemind,
                            onChanged: (bool? value) {
                              setState(() async {
                                _dontRemind = value ?? false;
                                await PreferencesHelper.setBool(
                                    Constants.checkVpm, _dontRemind);
                              });
                            },
                            side: BorderSide(
                              color: Colors.grey, // 边框颜色
                              width: 1.5,
                            ),
                            fillColor: WidgetStateProperty.resolveWith<Color>(
                                (states) {
                              if (states.contains(WidgetState.selected)) {
                                return AppColors.themeColor;
                              }
                              return AppColors.tooltipColor;
                            }),
                            // activeColor: AppColors.themeColor,
                            checkColor:
                                _dontRemind ? Colors.black54 : Colors.white,
                          ),
                          Text("run_vpn_tip6".tr,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white))
                        ],
                      ),
                    );
                  },
                ),
                onAction: () async {
                  if (!isNext) {
                    completer.complete(true); // 停止
                    await Future.delayed(Duration.zero);
                    if (context.mounted) {
                      onStop(context);
                    }
                  } else {
                    completer.complete(false);
                  }
                },
                onClose: () {
                  if (!isNext) {
                    completer.complete(true); // 继续
                  } else {
                    completer.complete(false);
                  }
                },
                onCancel: () {
                  if (!isNext) {
                    completer.complete(true);
                  } else {
                    completer.complete(true);
                  }
                },
              ),
            );
          } else {
            completer.complete(true); // 继续
            _log("Error: Unable to get valid overlay context");
          }
        } else {
          completer.complete(true); // 继续
        }
      } else {
        completer.complete(true); // 继续
      }
    } catch (e) {
      completer.complete(true); // 继续
      _log("_init.checkProxyIp: $e");
    } finally {
      return completer.future;
    }
  }

  /// 启动自动赚钱流程
  /// [context]: BuildContext上下文
  /// [isCheckArea]: 是否检查运营区域（默认false）
  /// [state]: 环境状态对象（可选）
  /// 返回值: Future<bool> 表示流程是否成功启动
  Future<Map<String, dynamic>> startAutoEarningProcess(BuildContext context,
      {bool isCheckArea = false,
      bool isOpen = false,
      EnvState? state,
      LoadingIndicator? loading}) async {
    final logBuffer = StringBuffer(); // 用于拼接所有日志
    logBuffer.clear(); // 清空所有内容
    // ========== 第一步：检查运营区域 ==========
    _globalService.pcdnMonitoringStatus.value = 7;
    if (!isOpen) {
      try {
        logBuffer.writeln("auto start :");
        final checkArea = await onCheckOperatingArea();
        logBuffer.writeln("auto start checkArea:$checkArea");
        if (!checkArea) {
          _globalService.pcdnMonitoringStatus.value = 2;
          _log("${logBuffer.toString()}");
          return {'status': false, 'error': "auto start checkArea:$checkArea"};
        }
      } catch (e) {
        _globalService.pcdnMonitoringStatus.value = 2;
        logBuffer.writeln("checkArea error:$e");
        _log("${logBuffer.toString()}");
        return {'status': false, 'error': "checkArea error:$e"};
      }
    }

    // ========== 第二步：清理现有Agent进程 ==========
    try {
      final result = await AgentIsolate.killProcesses();
      logBuffer.writeln("killProcesses:$result");
    } catch (e) {
      _globalService.pcdnMonitoringStatus.value = 3;
      logBuffer.writeln("killProcesses error:$e");
      _log("${logBuffer.toString()}");
      return {'status': false, 'error': "kill error:$e"};
    }

    // ========== 第三步：验证系统要求 ==========

    if (Platform.isWindows) {
      try {
        final isWindowsHome = await NativeApp.isWindowsHome();
        logBuffer.writeln("is home:$isWindowsHome");
        if (isWindowsHome) {
          final status = await VirtualBoxPlugin().isVirtualBoxInstalled();
          logBuffer.writeln("is VirtualBox Installed:$status");
          if (!status) {
            _globalService.pcdnMonitoringStatus.value = 3;
            _log("${logBuffer.toString()}");
            return {
              'status': false,
              'error': "is VirtualBox Installed:$status"
            };
          }
        } else {
          final hyperVStatus = await HyperVPlugin().isHyperVEnabled();
          logBuffer.writeln("is HyperV Enabled:$hyperVStatus");
          if (!hyperVStatus["status"]) {
            _globalService.pcdnMonitoringStatus.value = 3;
            _log("${logBuffer.toString()}");
            return {
              'status': false,
              'error': "is HyperV Enabled:$hyperVStatus"
            };
          }
        }
      } catch (e) {
        logBuffer.writeln("auto start catch:$e");
        _log("${logBuffer.toString()}");
        _globalService.pcdnMonitoringStatus.value = 3;
        return {'status': false, 'error': "auto start catch:$e"};
      }
    }
    // ========== 第四步：验证MultiPass配置 ==========
    try {
      final hasMp = await MultiPassPlugin().isMultiPassInstalled();
      logBuffer.writeln("is MultiPass Installed:$hasMp");
      if (!hasMp) {
        _globalService.pcdnMonitoringStatus.value = 3;
        _log("${logBuffer.toString()}");
        return {'status': false, 'error': "is MultiPass Installed:$hasMp"};
      }
    } catch (e) {
      logBuffer.writeln("is MultiPass Installed catch:$e");
      _globalService.pcdnMonitoringStatus.value = 3;
      _log("${logBuffer.toString()}");
      return {'status': false, 'error': "is MultiPass Installed catch:$e"};
    }

    if (Platform.isWindows) {
      try {
        final driveStatus = await MultiPassPlugin().getMultiPassLocalDrive();
        logBuffer.writeln("get MultiPass LocalDrive:$driveStatus");
        if (!driveStatus["status"]) {
          _globalService.pcdnMonitoringStatus.value = 3;
          _log("${logBuffer.toString()}");
          return {
            'status': false,
            'error': "get MultiPass LocalDrive:$driveStatus"
          };
        }
      } catch (e) {
        _globalService.pcdnMonitoringStatus.value = 3;
        logBuffer.writeln("get MultiPass LocalDrive catch:$e");
        _log("${logBuffer.toString()}");
        return {'status': false, 'error': "get MultiPass LocalDrive catch:$e"};
      }
    }
    final Completer<Map<String, dynamic>> completer = Completer();
    try {
      logBuffer.writeln("auto start .....");
      debugPrint("====e=====auto start .....");
      final scheduler = SchedulerService();
      var taskRunCount = 0;
      AgentIsolate.runAgent();

      scheduler.schedulePeriodicTask(
        'agentT4StatusTask',
        const Duration(seconds: 3),
        () async {
          taskRunCount++;
          var agentStatus = _globalService.isAgentRunning.value;
          if (agentStatus) {
            _globalService.pcdnMonitoringStatus.value = 6;
            loading?.hide();
            scheduler.cancelTask('agentT4StatusTask');
            logBuffer.writeln("auto start ok....");
            _log("${logBuffer.toString()}");
            // 2. 标记完成：成功
            if (!completer.isCompleted) {
              completer.complete({'status': true});
            }
          } else if (taskRunCount >= 60) {
            _globalService.pcdnMonitoringStatus.value = 3;
            scheduler.cancelTask('agentT4StatusTask');
            logBuffer.writeln("auto start fail....");
            _log("${logBuffer.toString()}");
            // 3. 标记完成：失败
            if (!completer.isCompleted) {
              completer
                  .complete({'status': false, 'error': "pcd_restartError".tr});
            }
          }
        },
      );
    } catch (e) {
      _globalService.pcdnMonitoringStatus.value = 3;
      logBuffer.writeln("auto start runAgent catch:$e");
      _log("${logBuffer.toString()}");
      return {'status': false, 'error': "auto start runAgent catch:$e"};
    }
    _log("${logBuffer.toString()}");
    // 4. 等待 Completer 完成
    // 函数会在这里“暂停”，直到上面的定时器调用了 complete
    return await completer.future;
  }

  void closeSchedulerAgentStatusTask() {
    try {
      AgentPlugin().closeSchedulerAgentStatusTask();
    } catch (e) {
      e.printError();
    }
  }

  /// 手动启动
  Future<Stream<bool>> startEarningProcess(
      BuildContext context, BasePlugin basicPlugin, EnvState state) async {
    // var load = LoadingIndicator();
    // load.show(context, message: "checking".tr);
    final logBuffer = StringBuffer(); // 用于拼接所有日志
    logBuffer.clear(); // 清空所有内容
    logBuffer.writeln("startEarningProcess:");
    final controller = StreamController<bool>();
    _globalService.pcdnMonitoringStatus.value = 7;

    /// 重新检测需要结束所以的agent进程：
    final res = await AgentIsolate.killProcesses();
    logBuffer.writeln("killProcesses:${res.toString()}");
    // load.hide();
    var _index = 0;
    basicPlugin.uploadData();
    state.stepIndex.value = 0;
    if (Platform.isWindows) {
      ///是否home
      final isWindowsHome = await NativeApp.isWindowsHome();
      logBuffer.writeln("isWindowsHome:${isWindowsHome}");
      if (isWindowsHome) {
        basicPlugin.setDada(1);
        state.basicSteps.value = basicPlugin.getBasicSteps();

        /// 检查vb是否安装
        var stepsWarp = await VirtualBoxPlugin()
            .checkInstalled(context, _index, state.basicSteps.value);
        logBuffer
            .writeln("VirtualBoxPlugin:${stepsWarp.list[_index].toString()}");
        if (!stepsWarp.status) {
          _log(logBuffer.toString());
          logBuffer.clear();
          controller.add(false);
          return controller.stream;
        }
        await Future.delayed(const Duration(seconds: 2));
        _index++;
      } else {
        basicPlugin.setDada(2);
        state.basicSteps.value = basicPlugin.getBasicSteps();

        ///检查HyperV状态
        var stepsWarp = await HyperVPlugin()
            .checkHyperVService(context, _index, state.basicSteps.value);
        logBuffer.writeln("HyperVPlugin:${stepsWarp.list[_index].toString()}");

        if (!stepsWarp.status) {
          _log(logBuffer.toString());
          logBuffer.clear();
          controller.add(false);
          return controller.stream;
        }
        await Future.delayed(const Duration(seconds: 2));
        _index++;

        var stepsWarp2 = await HyperVPlugin()
            .checkHyperVStatus(context, _index, state.basicSteps.value);
        logBuffer
            .writeln("HyperVPlugin2:${stepsWarp2.list[_index].toString()}");

        if (!stepsWarp2.status) {
          _log(logBuffer.toString());
          logBuffer.clear();
          controller.add(false);
          return controller.stream;
        }
        await Future.delayed(const Duration(seconds: 2));
        _index++;
      }
      var stepsWarp = await MultiPassPlugin()
          .checkMultiPassInstalled(context, _index, state.basicSteps.value);
      logBuffer.writeln(
          "checkMultiPassInstalled:${stepsWarp.list[_index].toString()}");

      if (!stepsWarp.status) {
        _log(logBuffer.toString());
        logBuffer.clear();

        controller.add(false);
        return controller.stream;
      }
      await Future.delayed(const Duration(seconds: 2));
      _index++;
      var stepsWarp2 = await MultiPassPlugin()
          .checkLocalDrive(context, _index, state.basicSteps.value);
      logBuffer.writeln("checkLocalDrive:${stepsWarp2.toString()}");

      if (!stepsWarp2.status) {
        _log(logBuffer.toString());
        logBuffer.clear();

        controller.add(false);
        return controller.stream;
      }
      await Future.delayed(const Duration(seconds: 2));
      _index++;

      var stepsWarp3 = await MultiPassPlugin()
          .checkVmRunning(context, _index, state.basicSteps.value);
      logBuffer.writeln("checkVmRunning:${stepsWarp3.toString()}");

      if (!stepsWarp3.status) {
        _log(logBuffer.toString());
        logBuffer.clear();
        controller.add(false);
        return controller.stream;
      }
      await Future.delayed(const Duration(seconds: 2));
      _index++;
    } else {
      basicPlugin.setDada(3);
      state.basicSteps.value = basicPlugin.getBasicSteps();
      var stepsWarp = await MultiPassPlugin()
          .checkMultiPassInstalled(context, _index, state.basicSteps.value);
      logBuffer.writeln("checkMultiPassInstalled:${stepsWarp.toString()}");

      if (!stepsWarp.status) {
        _log(logBuffer.toString());
        logBuffer.clear();

        controller.add(false);
        return controller.stream;
      }
      await Future.delayed(const Duration(seconds: 2));
      _index++;
      var stepsWarp3 = await MultiPassPlugin()
          .checkVmRunning(context, _index, state.basicSteps.value);

      logBuffer.writeln("checkVmRunning:${stepsWarp3.toString()}");

      if (!stepsWarp3.status) {
        _log(logBuffer.toString());
        logBuffer.clear();

        controller.add(false);
        return controller.stream;
      }
      await Future.delayed(const Duration(seconds: 2));
      _index++;
    }
    logBuffer.writeln("run agent....");

    AgentPlugin().monitorAgentStatus(
      context,
      _index,
      state.basicSteps.value,
      (bool status) {
        controller.add(status); // 每次回调都发送新状态
      },
    );
    // 当stream被取消时关闭controller
    controller.onCancel = () {
      // 这里可以添加清理逻辑
    };
    _log(logBuffer.toString());
    logBuffer.clear();
    return controller.stream;
  }

  Future<void> onStop(BuildContext context) async {
    _globalService.pcdnMonitoringStatus.value = 1;
    await stopEarningProcess(context);
    _globalService.isAgentRunning.value = false;
    _globalService.isAgentOnline.value = false;
  }

  /// 停止赚钱流程
  Future<void> stopEarningProcess(BuildContext context) async {
    var load = LoadingIndicator();
    load.show(context, message: "stopRunning".tr);
    try {
      // 杀死agent.exe
      await AgentIsolate.killProcesses();
      var list = await MultiPassPlugin().getVmNames();
      await Future.wait(list.map((e) async {
        await AgentIsolate.forceStopVm(e);
      }));
      await MultiPassPlugin().killProcesses();
    } catch (error) {
      debugPrint("停止赚钱流程时发生异常: $error");
    }
    load.hide();
  }

  Future<void> onRestartAfter(BuildContext context,
      {required Function onFunction}) async {}

  /// 显示警告对话框
  void _showWarningDialog(BuildContext context, String title, String message) {
    MessageDialog.warning(
      context,
      titleKey: title,
      messageKey: message,
      buttonTextKey: "close".tr,
    );
  }

  void _log(dynamic message, {bool w = true}) {
    if (w) {
      _logger.info("[PCDN SERVICE]:$message");
    } else {
      _logger.warning("[PCDN SERVICE]:$message");
    }
  }
}
