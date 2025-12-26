/**
 * 主界面控制器
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:titan_fil/config/app_config.dart';
import 'package:titan_fil/utils/app_helper.dart';

import '../../../../plugins/agent_plugin.dart';
import '../../../../plugins/base_plugin.dart';
import '../../../../plugins/macos_pligin.dart';
import '../../../../plugins/native_app.dart';
import '../../../../services/global_service.dart';
import '../../../../services/pcdn_service.dart';
import '../../../../utils/download_agent.dart';
import '../../../../utils/file_helper.dart';
import '../../../../widgets/loading_indicator.dart';
import '../../../../widgets/message_dialog.dart';
import '../../../../widgets/toast_dialog.dart';
import 'env_state.dart';

/// 新增：定义回调函数类型
typedef OnTimerCompleteCallback = void Function(BuildContext context);

class EnvController extends GetxController {
  final EnvState state = EnvState();
  final globalService = Get.find<GlobalService>();
  final _basicPlugin = BasePlugin();
  Timer? periodicTimer;

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

  /// 打开帮助文档
  Future<void> openHelp(BuildContext context) async {
    try {
      final isChinese = globalService.localeController.isChineseLocale();
      final isHome = await NativeApp.isWindowsHome();
      final url = _getHelpUrl(isChinese: isChinese, isHome: isHome);
      AppHelper.openUrl(context, url);
    } catch (e) {
      _handleError(context, e);
    }
  }

  String _getHelpUrl({required bool isChinese, required bool isHome}) {
    if (isHome) {
      return isChinese ? AppConfig.t4HomeHelpUrlCn : AppConfig.t4HomeHelpUrlEn;
    } else {
      return isChinese
          ? AppConfig.t4MajorHelpUrlCn
          : AppConfig.t4MajorHelpUrlEn;
    }
  }

  void _handleError(BuildContext context, dynamic error) {
    debugPrint('Error opening help: $error');
    ToastHelper.showWarning(
      context,
      title: 'msg_dialog_error'.tr, // 错误标题
      message: "Failed to open help documentation",
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 5),
      ),
    );
  }

  void onCloseDoalog(BuildContext context) {
    if (globalService.pcdnMonitoringStatus.value == 1 ||
        globalService.pcdnMonitoringStatus.value == 3 ||
        globalService.pcdnMonitoringStatus.value == 4 ||
        globalService.pcdnMonitoringStatus.value == 7) {
      ToastHelper.showWarning(
        context,
        title: 'gentleReminder'.tr, // 错误标题
        message: "pcd_env_tip_error".tr,
        config: const ToastConfig(
          autoCloseDuration: Duration(seconds: 5), // 5秒后自动关闭
        ),
      );
    } else {
      if (Navigator.of(context).canPop()) {
        PCDNService.getInstance().closeSchedulerAgentStatusTask();
        state.hasCloseDialog = true;
        periodicTimer?.cancel();
        Navigator.of(context).pop();
      } else {
        print('当前已在根路由，无法返回');
      }
    }
  }

  /// 返回 true 表示目录存在或复制成功，false 表示失败
  Future<bool> ensureWorkDir(BuildContext context) async {
    try {
      if (!Platform.isWindows) {
        return true;
      }

      final String targetDirPath = await FileHelper.getAppSupportDir();
      final Directory targetDir = Directory(targetDirPath);

      final String agentPath = path.join(targetDirPath, AppConfig.agentProcess);
      final File agentFile = File(agentPath);
      // ------------------ 目录存在直接返回成功 ------------------
      if (await targetDir.exists() && await agentFile.exists()) {
        return true;
      }

      final result = await DownloadAgent.downloadAgent(
        onProgress: (progress) {},
      );
      if (result.success) {
        return true;
      }
      // ------------------ 需要复制 ------------------
      bool success = false;
      await MessageDialog.show(
        context: context,
        config: MessageDialogConfig(
          titleKey: "pcdn_error".tr,
          messageKey: null,
          iconType: DialogIconType.error,
          buttonTextKey: "pcdn_run_copy".tr,
          childWidget: [
            _buildItem("pcdn_run_copying_tip".tr),
            _buildItem("pcdn_run_copying_tip2".tr),
            _buildItem(
                "pcdn_run_copying_tip3".tr.replaceAll("&", targetDir.path)),
          ],
          onAction: () async {
            final downUrl = Platform.isMacOS
                ? await MacOsPlugin.isSupportAgents()
                    ? AppConfig.downAgentDarwin
                    : AppConfig.downAgentDarwinArm64
                : AppConfig.downAgentWindows;

            AppHelper.onCopy(context, 'pcdn_downpour'.tr, downUrl);
            final load = LoadingIndicator();
            load.showWithGet(message: "pcdn_run_copying".tr);
            final result = await DownloadAgent.downloadAgent(
              onProgress: (progress) {
                load.updateMessage("pcdn_run_copying".tr +
                    '${(progress * 100).toStringAsFixed(0)}%');
              },
            );
            load.hide();
            if (result.success) {
              success = true;
            } else {
              success = false;
              ToastHelper.showWarning(
                context,
                title: 'msg_dialog_error'.tr,
                message: "pcdn_run_copying_failed".tr,
                config: const ToastConfig(
                  primaryColor: Color(0xFF9D9D9C),
                  autoCloseDuration: Duration(seconds: 5),
                ),
              );
            }
          },
          cancelButtonTextKey: "cancel".tr,
          onCancel: () {
            success = false;
          },
        ),
      );
      return success;
    } catch (e, stackTrace) {
      debugPrint("ensureWorkDir error: $e\n$stackTrace");
      return false;
    }
  }

// 辅助构建方法，统一文字样式
  Widget _buildItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        // 使用 Row 可以支持左对齐，同时保持整体居中容器
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.left, // 列表通常左对齐更好看
            ),
          ),
        ],
      ),
    );
  }

  /// 监测环境
  Future<void> onStartOperatingEnvironment(
    BuildContext context, {
    OnTimerCompleteCallback? onTimerComplete,
  }) async {
    if (globalService.pcdnMonitoringStatus.value == 1) {
      return;
    }

    ///重治状态
    state.hasClose.value = false;
    state.hasCloseDialog = false;
    state.timerCount.value = 3;
    globalService.pcdnMonitoringStatus.value = 4;
    _basicPlugin.uploadData();
    final pcdnService = PCDNService.getInstance();
    pcdnService.closeSchedulerAgentStatusTask();
    var statusStream =
        await pcdnService.startEarningProcess(context, _basicPlugin, state);
    statusStream.listen((status) {
      if (status) {
        ///启动成功：
        ///刷新pcdn数据
        globalService.pcdnMonitoringStatus.value = 6;
        state.hasClose.value = true;
        startPeriodicTimer(
          context,
          onTimerComplete: state.hasCloseDialog ? null : onTimerComplete,
        );
      } else {
        globalService.pcdnMonitoringStatus.value = 5;
        state.hasClose.value = false;
        state.timerCount.value = 3;
      }
    });
  }

  Future<void> handleStartEarningProcess(
    BuildContext context, {
    OnTimerCompleteCallback? onTimerComplete,
  }) async {}

  void startPeriodicTimer(
    BuildContext context, {
    OnTimerCompleteCallback? onTimerComplete,
  }) {
    int count = 4;
    periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      count--;
      if (count <= 0) {
        timer.cancel(); // 倒计时结束
        if (onTimerComplete != null) {
          onTimerComplete(context); // 触发回调，由外部控制关闭
        }
      } else {
        state.timerCount.value = count;
      }
    });
  }
}
