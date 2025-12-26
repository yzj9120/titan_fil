import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/config/app_config.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/widgets/LoadingWidget.dart';

import '../../../styles/app_colors.dart';
import '../../widgets/custom_tooltip.dart';
import '../../widgets/dialog_deviceinfo.dart';
import 'home_controller.dart';
import 'node_animation_widget.dart';

/// Central dashboard component showing device status, notifications,
/// earning progress, and service information
class DeviceStatusSection extends StatelessWidget {
  const DeviceStatusSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HomeController>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 22),
      width: 395,
      child: Column(
        children: [
          _buildMainStatusPanel(context, logic),
          SizedBox(height: 22),
          _buildRunningTasksSection(context, logic),
          SizedBox(height: 20),
          _buildServicesStatusSection(context, logic),
        ],
      ),
    );
  }

  // ====================== Main Status Panel ====================== //

  /// Builds the main container with device status, notifications, and earning progress
  Widget _buildMainStatusPanel(BuildContext context, HomeController logic) {
    return Container(
      width: 395,
      padding: const EdgeInsets.only(left: 29, right: 29, top: 29, bottom: 10),
      decoration: _roundedBoxDecoration(AppColors.c1818),
      child: Column(
        children: [
          _buildStatusAndNotificationRow(context, logic),
          const SizedBox(height: 15),
          NodeAnimationWidget(),
          _buildEarningProgressButton(context, logic),
          const SizedBox(height: 22),
          _buildDeviceInfoLink(context),
        ],
      ),
    );
  }

  /// Creates a row containing device status and notification indicators
  Widget _buildStatusAndNotificationRow(
      BuildContext ctx, HomeController logic) {
    return Row(
      children: [
        _buildDeviceStatusIndicator(logic),
        const Spacer(),
        // _buildNotificationIndicator(ctx, logic),
      ],
    );
  }

  /// Shows the current device status (online/offline/reconnecting)
  Widget _buildDeviceStatusIndicator(HomeController logic) {
    return Obx(() {
      final stats = logic.globalService;
      bool agentStatus =
          stats.isAgentRunning.value && stats.isAgentOnline.value;
      return Container(
        width: 335,
        height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: AppConfig.isDebug ? Colors.red : Colors.transparent,
          border: Border.all(
            color:
                AppConfig.isDebug ? Colors.red : _getStatusColor(agentStatus),
            width: 1.0, // 设置边框宽度
          ),
        ),
        child: Text(
          _getStatusText(agentStatus),
          style: TextStyle(
              color: _getStatusTextColor(agentStatus),
              fontSize: 13,
              fontWeight: FontWeight.bold),
        ),
      );
    });
  }



  /// Large button showing earning progress/status
  Widget _buildEarningProgressButton(
      BuildContext context, HomeController logic) {
    return Obx(() {
      final stats = logic.globalService;
      bool agentStatus = stats.isAgentRunning.value;

      final bool isActive = agentStatus;
      final bool isChinese = stats.localeController.isChineseLocale();

      Widget btn = isChinese
          ? (isActive
              ? Assets.images.icHomeStatusBtnOnCh.image()
              : Assets.images.icHomeStatusBtnOffCh.image())
          : (isActive
              ? Assets.images.icHomeStatusBtnOnEn.image()
              : Assets.images.icHomeStatusBtnOffEn.image());

      return isActive
          ? Container(
              width: 335,
              height: 53,
              child: btn,
            )
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () {
                  if (!agentStatus) {
                    logic.onEarningProgressButton(context);
                  } else {
                    // 没有关闭逻辑
                    // logic.onStopProgressButton(context);
                  }
                },
                child: Container(
                  width: 335,
                  height: 53,
                  child: btn,
                ),
              ),
            );
    });
  }

  /// Link to device information section
  Widget _buildDeviceInfoLink(BuildContext context) {
    return InkWell(
      onTap: () {
        DialogDeviceInfo.showDeviceStatusBottomSheet(context);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "index_deviceInfo".tr,
            style: const TextStyle(color: AppColors.tcCff, fontSize: 12),
          ),
          SizedBox(width: 7),
          Text('\u{2139}', style: TextStyle(fontSize: 14)),
          // Assets.images.icArrowInfo.image(width: 22)
        ],
      ),
    );
  }

  // ====================== Running Tasks Section ====================== //

  /// Builds the running tasks row with count indicator
  Widget _buildRunningTasksSection(BuildContext context, HomeController logic) {
    return Row(
      children: [
        _buildTasksLabelContainer(logic),
        Spacer(),
        _buildTasksCounterContainer(logic),
      ],
    );
  }

  /// Container showing "Running Tasks" label
  Widget _buildTasksLabelContainer(HomeController logic) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => logic.onChangeIndex(),
        borderRadius: BorderRadius.circular(28), // 可选：圆角效果
        child: Container(
          width: 285,
          height: 45,
          decoration: _roundedBoxDecoration(AppColors.c1818),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Assets.images.icTag.image(width: 31),
              // Container(
              //   width: 4,
              //   height: 13,
              //   decoration: _roundedBoxDecoration(AppColors.btn, radius: 10),
              // ),
              const SizedBox(width: 5),
              Text(
                "index_run_task_title".tr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Assets.images.icArrowInfo.image(width: 22),
              Text('\u{2139}', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }

  /// Container showing tasks count (0/2)
  Widget _buildTasksCounterContainer(HomeController logic) {
    String _getTaskCount(bool agentStatus) {
      if (agentStatus) {
        return "1";
      } else {
        return "0".tr;
      }
    }

    return Obx(() {
      final stats = logic.globalService;
      bool agentStatus = stats.isAgentRunning.value;
      //&& stats.isAgentOnline.value;

      /// 获取任务数量

      // 确定任务数量
      String taskCount = _getTaskCount(agentStatus);
      return Container(
        width: 98,
        height: 45,
        decoration: _roundedBoxDecoration(AppColors.c1818),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                taskCount,
                style: const TextStyle(
                    color: AppColors.themeColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                "/1".tr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ====================== Services Status Section ====================== //

  /// Builds the services status row (Storage and PCDN)
  Widget _buildServicesStatusSection(
      BuildContext context, HomeController logic) {
    return Row(
      children: [
        _buildPCDNServiceTile(context, logic),
      ],
    );
  }

  /// Tile showing PCDN service status
  Widget _buildPCDNServiceTile(BuildContext context, HomeController logic) {
    return Obx(() {
      final stats = logic.globalService;
      bool isRunning = stats.isAgentRunning.value;
      bool isOnline = stats.isAgentOnline.value;
      bool shouldShowPcdnTip = stats.shouldShowPcdnTip.value;
      FontWeight fontWeight = FontWeight.normal;
      Color color = AppColors.c1818;
      String status = "";
      Widget image;
      bool isStart = true;
      if (isRunning && isOnline) {
        /// 成功
        color = Colors.white;
        status = 'node_status_succeed'.tr;
        fontWeight = FontWeight.bold;
        image = Assets.images.icStatusSmaillOn.image(width: 40);
        isStart = false;
      } else if (isRunning && !isOnline) {
        /// 启动失败/未运行
        color = AppColors.danger;
        status = 'node_status_online'.tr;
        fontWeight = FontWeight.normal;
        image = Assets.images.icStatusSmaillOn.image(width: 40);
        isStart = false;
      } else {
        color = AppColors.cf9;
        // status = 'node_status_error'.tr;
        status = '';
        fontWeight = FontWeight.normal;
        image = Assets.images.icStatusSmaillOff.image(width: 40);
        isStart = true;
      }
      return Container(
        width: 395,
        height: 104,
        decoration: _roundedBoxDecoration(AppColors.c1818),
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(23),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getPCDNIcon(isRunning),
                  Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "FIL".tr,
                        style: TextStyle(
                          color: AppColors.cf9,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      CustomTooltip(
                        message: "shouldShowPcndTip".tr,
                        preferredDirection: AxisDirection.down,
                        sizeWidth: 0,
                        fontSize: 13,
                        autoShow: shouldShowPcdnTip,
                        showClose: true,
                        // triggerMode: TooltipTriggerMode.manual,
                        onClose: () {
                          logic.closeToday();
                        },
                        backgroundColor: AppColors.white,
                        color: AppColors.back1,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () {
                              logic.onHandlerPCDN(context, isStart);
                            },
                            child: image,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: logic.globalService.pcdnMonitoringStatus.value == 7
                  ? LoadingWidget(
                      radius: 5,
                      strokeWidth: 2,
                    )
                  : Text(
                      "$status", // "Running"
                      style: TextStyle(
                          color: color, fontWeight: fontWeight, fontSize: 10),
                    ),
            ),
          ],
        ),
      );
    });
  }

  // ====================== Helper Methods ====================== //

  /// Creates a rounded box decoration with given color and optional radius
  BoxDecoration _roundedBoxDecoration(Color color, {double radius = 28}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Returns color based on device status index
  Color _getStatusColor(bool agentStatus) {
    if (agentStatus) {
      return AppColors.themeColor;
    } else {
      return AppColors.white;
    }
  }

  Color _getStatusTextColor(bool agentStatus) {
    if (agentStatus) {
      return AppColors.themeColor;
    } else {
      return AppColors.white;
    }
  }

  /// Returns status text based on device status index
  String _getStatusText(bool agentStatus) {
    if (agentStatus) {
      return "index_device_status_running".tr;
    } else {
      return "index_device_status_not_started".tr;
    }
  }

  /// Returns notification text with count if > 0
  String _getNotificationText(int count) {
    final name = "index_notification_title".tr;
    return count == 0 ? name : "$name（$count）";
  }

  /// Returns notification color based on count
  Color _getNotificationColor(int count, int i) {
    if (count == 0) {
      if (i == 1) {
        return Colors.transparent;
      }
      return AppColors.white;
    } else {
      if (i == 1) {
        return AppColors.themeColor2;
      }
      return Colors.transparent;
    }
  }

  /// Returns PCDN icon based on running status
  Image _getPCDNIcon(bool isRunning) {
    return isRunning
        ? Assets.images.icPcdnOn.image(height: 28)
        : Assets.images.icPsdnOff.image(height: 28);
  }

  /// Returns Storage icon based on running status
  Image _getStorageIcon(bool isRunning, bool isOnline) {
    return isRunning
        ? Assets.images.icTssOn.image(height: 28)
        : Assets.images.icTssOff.image(height: 28);
  }
}
