/**
 * 主界面控制器
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/app_config.dart';
import '../../constants/constants.dart';
import '../../models/check_info.dart';
import '../../network/api_service.dart';
import '../../services/global_service.dart';
import '../../services/log_service.dart';
import '../../services/pcdn_service.dart';
import '../../utils/app_helper.dart';
import '../../utils/preferences_helper.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/message_dialog.dart';
import '../../widgets/toast_dialog.dart';
import '../index/index_controller.dart';
import '../task/pcdn/child/env_controller.dart';
import '../task/pcdn/child/environment_monitoring_widget.dart';
import 'home_state.dart';

class HomeController extends GetxController {
  final HomePageState state = HomePageState();
  final globalService = Get.find<GlobalService>();

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
    globalService.isShowIndexPage.value = isVisible;
  }

  void onChangeIndex() {
    final indexController = Get.find<IndexController>();
    indexController.onChangeIndex(1);
  }

  /// 开始赚钱按钮操作：
  Future<void> onEarningProgressButton(BuildContext context) async {
    final loading = LoadingIndicator();
    loading.show(context, message: "msg_dialog_waitStart".tr);
    final p = PCDNService.getInstance();
    bool isOpen = globalService.pcdnMonitoringStatus.value == 3;
    final driveStatus = await p.startAutoEarningProcess(context,
        isOpen: isOpen, loading: loading);
    loading.hide();
    if (!driveStatus["status"]) {
      _showWarningDialog(context, 'pcd_task_fail'.tr, driveStatus["error"]);
    }
  }

  ///pcdn 按钮操作
  Future<void> onHandlerPCDN(BuildContext context, bool start) async {
    final pcdService = PCDNService.getInstance();
    if (start) {
      if (globalService.pcdnMonitoringStatus == 7) {
        _onErrorMsg(context, "task_pcdn_load".tr);
        return;
      }
      final loading = LoadingIndicator();
      bool donRemind =
          await PreferencesHelper.getBool(Constants.checkVpm) ?? false;
      if (!donRemind) {
        loading.show(context, message: "loading".tr);
        bool status = await pcdService.checkProxy(
            isNext: true,
            onShow: () {
              loading.hide();
            });
        // if (!status) return;
      }

      loading.show(context, message: "task_check_t4_tip11".tr);
      CheckInfo? checkRes = await ApiService.checkActivity();

      if (checkRes == null) {
        loading.hide();
        _onErrorMsg(context, "task_check_t4_tip12".tr);
        globalService.pcdnMonitoringStatus.value = 2;
        return;
      }
      if (!checkRes.open) {
        loading.hide();
        _onErrorMsg(context, "task_check_t4_tip1".tr);
        globalService.pcdnMonitoringStatus.value = 2;
        return;
      }
      globalService.pcdnMonitoringStatus.value = checkRes.open ? 3 : 2;
      await Future.delayed(Duration.zero); // 确保 UI 更新完成
      final EnvController logic = Get.find<EnvController>();
      late Route _pcdnRoute;
      loading.hide();
      final disastrous = await logic.ensureWorkDir(context);
      if (!disastrous) {
        return;
      }
      logic.onStartOperatingEnvironment(
        context,
        onTimerComplete: (context) {
          if (_pcdnRoute.isActive) {
            Navigator.of(context, rootNavigator: true).removeRoute(_pcdnRoute);
          }
        },
      );
      _pcdnRoute = DialogRoute(
        context: context,
        settings: const RouteSettings(name: "pcdn_check"),
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: Material(
              color: Colors.transparent,
              elevation: 1000, // 设置很高的elevation
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
      Navigator.of(context, rootNavigator: true).push(_pcdnRoute);
    } else {
      // globalService.pcdnMonitoringStatus.value = 3;
      // await pcdService.stopEarningProcess(context);
      // globalService.isAgentRunning.value = false;
      // globalService.isAgentOnline.value = false;
      final pcdnService = PCDNService.getInstance();
      await pcdnService.onStop(context);
    }
  }

  /// 停止赚钱：
  Future<void> onStopProgressButton(BuildContext context) async {
    final pcdnService = PCDNService.getInstance();
    await pcdnService.onStop(context);
  }

  /// 打开节点收益
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
    }
    AppHelper.openUrl(context, url);
  }

  /// t3-t4 切换
  void onChangeStorageOrPcdn() {}

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

  void openNodeRewards(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl = isChineseLocale
        ? AppConfig.t4WebUrlNodeRewardsZH
        : AppConfig.t4WebUrlNodeRewardsEN;
    AppHelper.openUrl(context, webUrl);
  }

  /// 用户点击关闭时调用
  Future<void> closeToday() async {
    globalService.markTooltipClosedToday();
  }

  /// 显示警告对话框
  void _showWarningDialog(BuildContext context, String title, String message) {
    MessageDialog.warning(
      context,
      titleKey: title,
      messageKey: message,
      buttonTextKey: "close".tr,
    );
  }
}
