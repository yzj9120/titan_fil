import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/task/pcdn/pcdn_controller.dart';
import 'package:titan_fil/styles/app_text_styles.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/app_colors.dart';
import '../../../widgets/underlined_text.dart';

class PcdnPage extends GetView<PCDNController> {
  const PcdnPage({super.key});

  // Constants
  static const double _padding = 29.0;
  static const double _buttonHeight = 55.0;
  static const double _buttonWidth = 217.0;
  static const double _radiusLarge = 29.0;
  static const double _radiusMedium = 22.0;
  static const double _radiusSmall = 41.0;
  static const double _featureRadius = 73.0;
  static const double pageWidth = 580 * 2;
  static const double pageHeight = 492;

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => PCDNController());
    return Obx(() {
      final isAgentRunning = controller.globalService.isAgentRunning.value;
      final isAgentOnline = controller.globalService.isAgentOnline.value;
      final contentColor = isAgentRunning ? Colors.black : Colors.white;
      int runStatus = controller.globalService.pcdnMonitoringStatus.value;

      if (isAgentRunning && isAgentOnline) {
        runStatus = 6;
      } else if (isAgentRunning && !isAgentOnline) {
        runStatus = 8;
      }
      final backgroundColor = runStatus == 6
          ? AppColors.btn
          : runStatus == 7
              ? AppColors.tc435
              : runStatus == 8
                  ? AppColors.warning
                  : AppColors.c1818;

      return Column(
        children: [
          Container(
            height: pageHeight,
            width: pageWidth,
            padding: const EdgeInsets.all(_padding),
            decoration: BoxDecoration(
              color: AppColors.c1818,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 31),
                _buildHeader(context, controller, isAgentRunning, contentColor,
                    backgroundColor, runStatus),
                const SizedBox(height: 38),
                _buildTopIconRow(isAgentRunning),
                const SizedBox(height: 39),
                _buildIntroTexts(isAgentRunning),
                Spacer(),
                _buildStatusContent2(context, runStatus),
                const SizedBox(height: 58),
              ],
            ),
          ),
          SizedBox(height: 21),
          if (runStatus == 2) ...{
            _buildInfoTextRow(context),
          } else ...{
            SizedBox()
          }
        ],
      );
    });
  }

  Widget _buildStatusContent2(BuildContext context, int runStatus) {
    return Row(
      children: [
        Container(
          width: 83,
          height: 45,
          decoration: BoxDecoration(
              color: AppColors.btn, borderRadius: BorderRadius.circular(73)),
          child: Center(
            child: Text(
              "FIL",
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(width: 12),
        if (runStatus == 1) ...{
          ////环境自动监测中
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () {
                  controller.onToastButton(context, "task_check_t4_tip9".tr);
                  controller.onRetestCheck();
                },
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 2) ...{
          ////环境监测失败
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () =>
                    controller.onToastButton(context, "task_check_t4_tip6".tr),
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
          Spacer(),
          // _buildRetestButton(context),
        } else if (runStatus == 3) ...{
          ////环境监测成功
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () => controller.onRunImmediately(context),
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 4) ...{
          /////运行环境监测中
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () =>
                    controller.onToastButton(context, "task_check_t4_tip7".tr),
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 5) ...{
          ////运行环境监测失败
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () => controller.onRunImmediately(context),
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 6) ...{
          /////运行环境监测成功
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () => controller.onStop(context),
                child: Assets.images.icTaskSw3.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 7) ...{
          ////首页安装启动中
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () =>
                    controller.onToastButton(context, "task_check_t4_tip10".tr),
                child: Assets.images.icTaskSw1.image(width: 101, height: 45)),
          ),
        } else if (runStatus == 8) ...{
          /////启动了但是离线
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
                onTap: () => controller.onStop(context),
                child: Assets.images.icTaskSw3.image(width: 101, height: 45)),
          ),
        } else ...{
          ////
        },
      ],
    );
  }

  Widget _buildHeader(BuildContext context, PCDNController controller,
      bool isRunning, Color contentColor, Color bgColor, int runStatus) {
    return Row(
      children: [
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.white,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: InkWell(
                    onTap: () => controller.onSaveSetting(),
                    child: Text('\u{2699}', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.white,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: InkWell(
                    onTap: () => controller.onViewOpen(context),
                    child: Text('\u{2139}', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 48,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.white,
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: InkWell(
                    onTap: () => controller.onOpenNodeRevenue(context),
                    child: Text('\u{1F4B0}', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            )
          ],
        ),
        const Spacer(),
        if (runStatus == 1) ...{
          _buildAreaLoad()
        } else if (runStatus == 2) ...{
          _buildClosedAreaFail()
        } else if (runStatus >= 3) ...{
          _buildSuccessMessage()
        } else ...{
          SizedBox()
        }
      ],
    );
  }

  Widget _buildTopIconRow(bool isRunning) {
    return isRunning
        ? Assets.images.icTaskPcdnOn.image(height: 100)
        : Assets.images.icTaskPcdnOff.image(height: 100);
  }

  Widget _buildIntroTexts(bool isRunning) {
    return Column(
      children: [
        Text(
          "pcd_des".tr,
          style: AppTextStyles.textStyle12white,
          textAlign: TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildClosedAreaFail() {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Text(
            "task_check_t4_tip1".tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.textStyle10white,
          ),
          InkWell(
            onTap: () => controller.onRetestCheck(),
            child: UnderlinedText(
              text: "task_retest".tr,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAreaLoad() {
    return Container(
      alignment: Alignment.centerRight,
      child: Text(
        "task_check_t4_15".tr,
        textAlign: TextAlign.center,
        style: AppTextStyles.textStyle10white
            .copyWith(color: AppColors.themeColor),
      ),
    );
  }

  Widget _buildInfoTextRow(BuildContext context) {
    return Container(
      width: 570,
      child: Wrap(
        alignment: WrapAlignment.end, // 改为 start 让内容从左到右排列
        crossAxisAlignment: WrapCrossAlignment.center, // 垂直居中
        runSpacing: 4,
        children: [
          // 第一部分文本
          Text(
            "task_check_t4_tip2".tr,
            style: AppTextStyles.textStyle10,
          ),
          // 可点击文本1
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () => controller.onWaitingList(context),
              child: UnderlinedText(
                text: "task_check_t4_tip2_2".tr,
                underlineColor: AppColors.titleColor,
                textStyle: TextStyle(
                  color: AppColors.titleColor,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          // 第二部分文本
          Text(
            "task_check_t4_tip2_3".tr,
            style: AppTextStyles.textStyle10,
          ),
          // 可点击文本2
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () => controller.onViewOpenRegions(context),
              child: UnderlinedText(
                text: "task_check_t4_tip3".tr,
                underlineColor: AppColors.titleColor,
                textStyle: TextStyle(
                  color: AppColors.titleColor,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Assets.images.icTaskCheckOk.image(width: 20),
        const SizedBox(width: 5),
        Text(
          'task_check_t4_tip4'.tr,
          style: TextStyle(fontSize: 12, color: AppColors.white),
        ),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle textStyle;

  const _FeatureButton({
    required this.text,
    required this.color,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 131,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PcdnPage._featureRadius),
      ),
      alignment: Alignment.center,
      child: Text(text, style: textStyle),
    );
  }
}

class _AppButton extends StatelessWidget {
  final String text;
  final Color color;
  final Color? borderColor;
  final TextStyle? textStyle;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _AppButton({
    required this.text,
    required this.color,
    this.borderColor,
    this.textStyle,
    this.width = double.infinity,
    this.height = PcdnPage._buttonHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: borderColor == null ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(PcdnPage._radiusSmall),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: textStyle ??
                AppTextStyles.textStyle15black.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _ClickableButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? backgroundColor;
  final BoxBorder? border;

  const _ClickableButton({
    required this.onTap,
    required this.child,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PcdnPage._radiusSmall),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: PcdnPage._buttonWidth,
          height: PcdnPage._buttonHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(PcdnPage._radiusSmall),
            border: border,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}
