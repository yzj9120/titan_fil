/**
 * 主界面控制器
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/task/pcdn/pcdn_state.dart';
import 'package:titan_fil/utils/app_helper.dart';

import '../../../config/app_config.dart';
import '../../../constants/constants.dart';
import '../../../models/check_info.dart';
import '../../../network/api_service.dart';
import '../../../plugins/agent_Isolate.dart';
import '../../../plugins/multipass_plugin.dart';
import '../../../services/global_service.dart';
import '../../../services/pcdn_service.dart';
import '../../../utils/preferences_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/toast_dialog.dart';
import '../../index/index_controller.dart';
import '../../setting/setting_controller.dart';
import 'child/env_controller.dart';
import 'child/environment_monitoring_widget.dart';

class PCDNController extends GetxController {
  final PCDNPageState state = PCDNPageState();
  final globalService = Get.find<GlobalService>();

  ///初始化
  @override
  void onInit() {
    onCheck();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> onOpenNodeRevenue(BuildContext context) async {
    var url = "";
    if (globalService.agentId.isNotEmpty) {
      url = await ApiService.fetchNodeDetails(globalService.agentId);
    }
    if (url.isEmpty) {
      ToastHelper.showWarning(
        context,
        title: 'msg_dialog_error'.tr, // 错误标题
        message: "msg_dialog_node_empty".tr,
        config: const ToastConfig(
          primaryColor: Color(0xFF9D9D9C),
          autoCloseDuration: Duration(seconds: 5),
        ),
      );
    } else {
      AppHelper.openUrl(context, url);
    }
  }

  ///存储设置
  void onSaveSetting() {
    final indexController = Get.find<IndexController>();
    indexController.onChangeIndex(3);
    final logic = Get.find<SettingController>();
    logic.onChangeIndex(0);
  }

  Future<void> onCheck() async {
    CheckInfo? checkRes = await ApiService.checkActivity();
    debugPrint("checkActivity:$checkRes");
    if (checkRes != null) {
      await Future.delayed(Duration(seconds: 3));
      globalService.pcdnMonitoringStatus.value = checkRes.open ? 3 : 2;
    } else {
      globalService.pcdnMonitoringStatus.value = 2;
    }
  }

  ///检测是否地区是否执
  void onChangeStatus() {}

  ///填写等待名单
  void onWaitingList(BuildContext context) {
    AppHelper.openUrl(context, AppConfig.t4WebWaitingAddress);
  }

  /// 自动检测中
  void onAutoDetectButton(BuildContext context) {
    ToastHelper.showWarning(
      context,
      title: 'gentleReminder'.tr, // 错误标题
      message: "tryAgainLater".tr + "," + "task_check_t4_auto2".tr,
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 5), // 5秒后自动关闭
      ),
    );
  }

  void onToastButton(BuildContext context, String str) {
    ToastHelper.showWarning(
      context,
      title: 'gentleReminder'.tr, // 错误标题
      message: str,
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 3), // 5秒后自动关闭
      ),
    );
  }

  void onViewOpenRegions(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl = isChineseLocale ? AppConfig.t4WebUrlZH : AppConfig.t4WebUrlEN;
    AppHelper.openUrl(context, webUrl);
  }

  late Completer<void> _dialogCompleter;

  ///立即运行
  Future<void> onRunImmediately(BuildContext pContext) async {
    final loading = LoadingIndicator();
    bool donRemind =
        await PreferencesHelper.getBool(Constants.checkVpm) ?? false;
    if (!donRemind) {
      final pcdService = PCDNService.getInstance();
      loading.show(pContext, message: "loading".tr);
      bool status = await pcdService.checkProxy(
          isNext: true,
          onShow: () {
            loading.hide();
          });
      ////if (!status) return;
    }

    final EnvController logic = Get.find<EnvController>();

    final dirstatus = await logic.ensureWorkDir(pContext);
    if (!dirstatus) {
      return;
    }

    late Route _pcdnRoute;
    logic.onStartOperatingEnvironment(
      pContext,
      onTimerComplete: (context) {
        if (_pcdnRoute.isActive) {
          Navigator.of(context, rootNavigator: true).removeRoute(_pcdnRoute);
        }
      },
    );
    _dialogCompleter = Completer<void>();
    _pcdnRoute = DialogRoute(
      context: pContext,
      settings: const RouteSettings(name: "pcdn_check"),
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 450,
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(28),
              ),
              child: EnvironmentMonitoringWidget(),
            ),
          ),
        );
      },
    );
    Navigator.of(pContext, rootNavigator: true).push(_pcdnRoute).then((_) {
      if (!_dialogCompleter.isCompleted) {
        _dialogCompleter.complete();
      }
    });
    return _dialogCompleter.future;

    // 在需要弹出 Dialog 的地方调用：
    // state.runStatus.value = 4;
    // await Future.delayed(Duration(seconds: 2));
    // state.runStatus.value = 5;
  }

  ///重新检测是否地区
  Future<void> onRetestCheck() async {
    globalService.pcdnMonitoringStatus.value = 1;
    onCheck();
  }

  /// 停止
  Future<void> onStop(BuildContext context) async {
    // globalService.pcdnMonitoringStatus.value = 1;
    // final pcdnService = PCDNService.getInstance();
    // await pcdnService.stopEarningProcess(context);
    // globalService.isAgentRunning.value = false;
    // globalService.isAgentOnline.value = false;
    final pcdnService = PCDNService.getInstance();
    await pcdnService.onStop(context);
    onCheck();
  }

  ///

  Future<void> onAgainStart(BuildContext context) async {
    final loading = LoadingIndicator();
    loading.show(context, message: "pcd_restarting".tr);
    await AgentIsolate.killProcesses();
    var list = await MultiPassPlugin().getVmNames();
    await Future.wait(list.map((e) async {
      await AgentIsolate.forceStopVm(e);
    }));
    await MultiPassPlugin().killProcesses();

    Future.delayed(Duration(seconds: 10)).then((_) {
      loading.hide();
    });
    final pcdnService = PCDNService.getInstance();
    await pcdnService.startAutoEarningProcess(context);
  }

  // 外部调用关闭：
  void closeDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void onViewOpen(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl = isChineseLocale ? AppConfig.t4urlCn : AppConfig.t4urlEn;
    AppHelper.openUrl(context, webUrl);
  }
}
