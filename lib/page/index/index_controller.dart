/**
 * 主界面控制器
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/utils/file_helper.dart';

import '../../constants/constants.dart';
import '../../models/check_info.dart';
import '../../network/api_service.dart';
import '../../plugins/agent_Isolate.dart';
import '../../plugins/agent_plugin.dart';
import '../../plugins/bat_sh_runner.dart';
import '../../plugins/macos_pligin.dart';
import '../../plugins/native_app.dart';
import '../../services/global_service.dart';
import '../../services/log_service.dart';
import '../../utils/download_agent.dart';
import '../../utils/preferences_helper.dart';
import '../../widgets/message_dialog.dart';
import 'index_state.dart';

class IndexController extends GetxController {
  final IndexPageState state = IndexPageState();
  final globalService = Get.find<GlobalService>();
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  ///初始化
  @override
  void onInit() {
    globalService.start();
    _onCheck();
    _init();
    super.onInit();
  }

  ///页面渲染完成
  @override
  void onReady() {
    super.onReady();
  }

  Future<void> _init() async {
    final logBuffer = StringBuffer(); // 用于拼接所有日志
    logBuffer.clear();
    // try {
    //   if (!AppConfig.isDebug) {
    //     await _checkAdminPermissions();
    //   }
    // } catch (e) {
    //   logBuffer.writeln("_init.checkAdminPermissions: $e");
    // }
    try {
      final info = await BatShRunner().getCheckProxyIp();
      debugPrint('getCheckProxyIp: $info');
      logBuffer.writeln('checkip:$info');
      if (info != null) {
        final local = info["local_ip"] ?? "";
        final proxy = info["proxy_ip"] ?? "";
        if (local != "" && local != "unknown") {
          final value =
              await PreferencesHelper.getString(Constants.locationIp) ?? "";
          if (value.isEmpty) {
            await PreferencesHelper.setString(Constants.locationIp, local);
          }
        }
        if (proxy != "" && proxy != "unknown") {
          await PreferencesHelper.setString(Constants.proxyIp, proxy);
        }
      }
    } catch (e) {
      logBuffer.writeln("_init.checkProxyIp: $e");
    }
    try {
      _checkAgent();
    } catch (e) {
      logBuffer.writeln("_init.checkAgent: $e");
    }
    try {
      _checkInstallMultiPassPkg();
    } catch (e) {
      logBuffer.writeln("_init.checkinstallMultipassPkg: $e");
    }
    try {
      LogService.cleanupOldLogs();
    } catch (e) {
      logBuffer.writeln("_init.cleanupOldLogs: $e");
    }

    try {
      AgentIsolate.killProcesses();
    } catch (e) {
      logBuffer.writeln("killProcesses;  error : $e");
    }
    try {
      FileHelper.clearStorage();
    } catch (e) {
      logBuffer.writeln("_init.clearStorage: $e");
    }

    try {
      final result = await AgentIsolate.killMainProcesses();
      logBuffer.writeln("killMainProcesses;  result : $result");
    } catch (e) {
      logBuffer.writeln("killMainProcesses;  error : $e");
    }
    // try {
    //   final urls = [
    //     ApiEndpoints.webServerURLV4,
    //     ApiEndpoints.agentServerV4,
    //     ApiEndpoints.nodeInfoURLV4,
    //     ApiEndpoints.webServerURLV3,
    //     ApiEndpoints.storageURL,
    //     ApiEndpoints.nodeInfoURLV3,
    //   ];
    //   await NativeApp.batchVerifyCertificates(urls);
    // } catch (e) {
    //   logBuffer.writeln("_init.checkAdminPermissions: $e");
    // }
    _log(logBuffer.toString());
    logBuffer.clear();
  }

  ///释放资源
  @override
  void onClose() {
    super.onClose();
  }

  void onChangeIndex(int index) {
    state.selectedIndex.value = index;
  }

  // 检查管理员权限
  Future<void> _checkAdminPermissions() async {
    final desktopPlugins = NativeApp();
    bool isAdmin = await desktopPlugins.isAdministrator();
    if (!isAdmin) {
      if (Get.context != null) {
        MessageDialog.show(
          context: Get.context!,
          config: MessageDialogConfig(
              width: 500,
              buttonWidth: 300,
              titleKey: "",
              padding: 10,
              image: !globalService.localeController.isChineseLocale()
                  ? Assets.images.checkAdminCn.image(width: 300, height: 280)
                  : Assets.images.checkAdminEn.image(width: 300, height: 280),
              messageKey: "${"run_admin_tip".tr}",
              iconType: DialogIconType.image,
              buttonTextKey: 'exit'.tr,
              messageTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              onAction: () async {
                exit(0);
              }),
        );
      }
    }
  }

  Future<void> _checkAgent() async {
    final status = await AgentPlugin.checkAgent();
    if (!status) {
      await DownloadAgent.downloadAgent(onProgress: (progress) {});
    }
  }

  Future<void> _checkInstallMultiPassPkg() async {
    if (Platform.isMacOS) {
      bool status = await MacOsPlugin.checkAndInstallMultipass();
      debugPrint('status: $status');
      if (!status) {
        try {
          if (Get.context != null) {
            await MessageDialog.warning(
              Get.context!,
              titleKey: 'msg_dialog_startup_prompt'.tr,
              messageKey: 'install_mulptpass_tip'.tr,
              buttonTextKey: "install_mulptpass_title".tr,
              onConfirm: () async {
                await MacOsPlugin.installMultipassPkg();
              },
            );
          }
        } catch (e) {
          debugPrint('checkAndInstallMultipass: $e');
        }
      }
    }
  }

  Future<void> _onCheck() async {
    try {
      CheckInfo? retryRes = await ApiService.checkActivity(maxRetries: 5);
      debugPrint('retryRes: $retryRes');
      if (retryRes != null) {
        globalService.pcdnMonitoringStatus.value = (retryRes.open) ? 3 : 2;
      }
    } catch (e) {
      globalService.pcdnMonitoringStatus.value = 2;
    }
  }

  void _log(dynamic message, {bool w = true}) {
    if (w) {
      _logger.info("【Index】$message");
    } else {
      _logger.warning("【Index】$message");
    }
  }
}
