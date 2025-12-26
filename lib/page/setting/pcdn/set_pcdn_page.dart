import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/setting/pcdn/set_pcdn_controller.dart';
import 'package:titan_fil/page/setting/pcdn/set_pcdn_state.dart';
import 'package:titan_fil/widgets/LoadingWidget.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/app_colors.dart';
import '../../../styles/app_text_styles.dart';

class SetPcdnPage extends StatelessWidget {
  const SetPcdnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetPcdnController());
    return VisibilityDetector(
        key: Key('my-SetPcdnPage'),
        onVisibilityChanged: (VisibilityInfo info) {
          controller.onVisibilityChanged(info);
        },
        child: _buildMainContainer(context, controller));
  }
}

// Constants for layout and styling
class _PcdnPageConstants {
  static const double cardHeight = 265;
  static const double inputFieldWidth = 239;
  static const double inputFieldHeight = 45;
  static const double buttonWidth = 73;
  static const double buttonHeight = 29;
  static const double borderRadiusLarge = 28;
  static const double borderRadiusSmall = 73;
  static const EdgeInsets cardPadding = EdgeInsets.all(29);
  static const EdgeInsets inputFieldPadding = EdgeInsets.symmetric(vertical: 5);
  static const EdgeInsets inputSuffixPadding = EdgeInsets.only(right: 10);
}

// Main layout components
extension _SetPcdnPageLayout on SetPcdnPage {
  Widget _buildMainContainer(BuildContext context, SetPcdnController log) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(22),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildContentSection(context, log),
          if (Platform.isWindows) ...[
            const SizedBox(height: 10),
            _buildContentSection2(context, log)
          ],
          Spacer(),
          Row(
            children: [
              Spacer(),
              Text(
                'settings_pcdn_notice'.tr,
                style: AppTextStyles.textStyle12,
              ),
              SizedBox(width: 18),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.c1818,
        borderRadius:
            BorderRadius.circular(_PcdnPageConstants.borderRadiusLarge),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Assets.images.icTag.image(width: 31),
          const SizedBox(width: 5),
          Text(
            "settings_pcdn_title".tr,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext ctx, SetPcdnController log) {
    return Obx(() => Row(
          children: [
            _buildCpuSettingsCard(ctx, log),
            const SizedBox(width: 10),
            _buildDataMigrationCard(ctx, log),
            const SizedBox(width: 10),
            _buildStorageSettingsCard(ctx, log),
          ],
        ));
  }

  Widget _buildContentSection2(BuildContext ctx, SetPcdnController log) {
    return Obx(() => Row(
          children: [
            _buildDataBandwidthCard(ctx, log),
            const SizedBox(width: 10),
            Spacer(),
            const SizedBox(width: 10),
            Spacer(),
          ],
        ));
  }
}

// Card components
extension _SetPcdnPageCards on SetPcdnPage {
  Widget _buildStorageSettingsCard(BuildContext ctx, SetPcdnController logic) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 1,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _PcdnPageConstants.cardHeight,
          padding: _PcdnPageConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 1
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("settings_pcdn_memory_disk".tr,
                  style: logic.state.hoverIndex.value == 1
                      ? AppTextStyles.textStyle15black
                      : AppTextStyles.textStyle15),
              const SizedBox(height: 44),
              _buildStorageLimitRow(logic.state),
              const SizedBox(height: 10),
              _buildStorageInputField(logic.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic,
                  2,
                  logic.state.hoverIndex.value == 1
                      ? AppColors.back1
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 1
                      ? AppTextStyles.textStyle10white
                      : AppTextStyles.textStyle10black),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCpuSettingsCard(BuildContext ctx, SetPcdnController logic) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 2,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _PcdnPageConstants.cardHeight,
          padding: _PcdnPageConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 2
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("settings_pcdn_cpu_name".tr,
                  style: logic.state.hoverIndex.value == 2
                      ? AppTextStyles.textStyle15black
                      : AppTextStyles.textStyle15),
              const SizedBox(height: 44),
              _buildCpuLimitRow(logic.state),
              const SizedBox(height: 10),
              _buildCpuInputField(logic.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic,
                  1,
                  logic.state.hoverIndex.value == 2
                      ? AppColors.back1
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 2
                      ? AppTextStyles.textStyle10white
                      : AppTextStyles.textStyle10black),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataMigrationCard(BuildContext ctx, SetPcdnController logic) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 3,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _PcdnPageConstants.cardHeight,
          padding: _PcdnPageConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 3
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("settings_pcdn_memory_name".tr,
                  style: logic.state.hoverIndex.value == 3
                      ? AppTextStyles.textStyle15black
                      : AppTextStyles.textStyle15),
              const SizedBox(height: 44),
              _buildStorageMigrationLimitRow(logic.state),
              const SizedBox(height: 10),
              _buildMigrationInputField(logic.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic,
                  3,
                  logic.state.hoverIndex.value == 3
                      ? AppColors.back1
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 3
                      ? AppTextStyles.textStyle10white
                      : AppTextStyles.textStyle10black),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataBandwidthCard(BuildContext ctx, SetPcdnController logic) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 4,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _PcdnPageConstants.cardHeight,
          padding: _PcdnPageConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 4
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("task_pcdn_bandwidth".tr,
                      style: logic.state.hoverIndex.value == 4
                          ? AppTextStyles.textStyle15black
                          : AppTextStyles.textStyle15),
                  Text("(Beta)".tr,
                      style: logic.state.hoverIndex.value == 4
                          ? AppTextStyles.textStyle15black
                          : AppTextStyles.textStyle15),
                  SizedBox(width: 5),
                  if (logic.state.loadStatus.value) ...{
                    LoadingWidget(
                      radius: 8,
                      strokeWidth: 2,
                    )
                  },
                ],
              ),
              const SizedBox(height: 44),
              Text(
                "task_pcdn_bandwidth_des".tr,
                style: logic.state.hoverIndex.value == 4
                    ? AppTextStyles.textStyle12black
                    : AppTextStyles.textStyle12,
              ),
              const SizedBox(height: 10),
              _buildBandwidthInputField(logic.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic,
                  4,
                  logic.state.hoverIndex.value == 4
                      ? AppColors.back1
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 4
                      ? AppTextStyles.textStyle10white
                      : AppTextStyles.textStyle10black),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(_PcdnPageConstants.borderRadiusLarge),
    );
  }
}

// Input field components
extension _SetPcdnPageInputFields on SetPcdnPage {
  Widget _buildStorageInputField(SetPcdnState state) {
    return _buildInputField(
      state,
      state.diskEditingController,
      state.diskFocusNode,
      state.hoverIndex.value == 1
          ? Colors.black
          : Colors.white.withOpacity(0.5),
      state.hoverIndex.value == 1
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      suffixStyle: state.hoverIndex.value == 1
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      decorationColors:
          state.hoverIndex.value == 1 ? AppColors.themeColor : AppColors.back1,
    );
  }

  Widget _buildCpuInputField(SetPcdnState state) {
    return _buildInputField(
      state,
      state.cpuEditingController,
      state.cpuFocusNode,
      state.hoverIndex.value == 2
          ? Colors.black
          : Colors.white.withOpacity(0.5),
      state.hoverIndex.value == 2
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      suffixStyle: state.hoverIndex.value == 2
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      decorationColors:
          state.hoverIndex.value == 2 ? AppColors.themeColor : AppColors.back1,
    );
  }

  Widget _buildMigrationInputField(SetPcdnState state) {
    return _buildInputField(
      state,
      state.memoryEditingController,
      state.memoryFocusNode,
      state.hoverIndex.value == 3
          ? Colors.black
          : Colors.white.withOpacity(0.5),
      state.hoverIndex.value == 3
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      suffixStyle: state.hoverIndex.value == 3
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      decorationColors:
          state.hoverIndex.value == 3 ? AppColors.themeColor : AppColors.back1,
    );
  }

  Widget _buildBandwidthInputField(SetPcdnState state) {
    return _buildInputField(
      state,
      state.bandwidthEditingController,
      state.bandwidthFocusNode,
      state.hoverIndex.value == 4
          ? Colors.black
          : Colors.white.withOpacity(0.5),
      state.hoverIndex.value == 4
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      suffixStyle: state.hoverIndex.value == 4
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      decorationColors:
          state.hoverIndex.value == 4 ? AppColors.themeColor : AppColors.back1,
    );
  }

  Widget _buildInputField(
    SetPcdnState state,
    TextEditingController controller,
    FocusNode focusNode,
    Color borderColor,
    TextStyle textStyle, {
    TextStyle? suffixStyle,
    Color? decorationColors,
  }) {
    return Container(
      width: _PcdnPageConstants.inputFieldWidth,
      height: _PcdnPageConstants.inputFieldHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: decorationColors ?? AppColors.back1,
        borderRadius:
            BorderRadius.circular(_PcdnPageConstants.borderRadiusSmall),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Stack(
        alignment: Alignment.center, // 让 TextField 居中
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            cursorColor: Colors.green,
            // 例如设置为红色
            textAlign: TextAlign.center,
            textAlignVertical: TextAlignVertical.center,
            style: textStyle,
            maxLength: 12,
            // 设置最大长度为 10
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              isCollapsed: true,
              hintText: "",
              contentPadding: _PcdnPageConstants.inputFieldPadding,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          Positioned(
            right: 10, // 靠右固定
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                controller == state.cpuEditingController
                    ? "task_pcdn_cpu_unit".tr
                    : controller == state.bandwidthEditingController
                        ? "Mbps"
                        : 'GB',
                style: suffixStyle ?? textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Row components
extension _SetPcdnPageRows on SetPcdnPage {
  Widget _buildStorageLimitRow(SetPcdnState state) {
    return _buildLimitRow(
      "settings_pcdn_set_con".tr,
      "${(state.info.value['disk']?['available'] ?? '').toString()} GB",
      state.loadStatus.value,
      state.hoverIndex.value == 1
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      state.hoverIndex.value == 1
          ? AppTextStyles.textStyleTip10back
          : AppTextStyles.textStyleTip10,
    );
  }

  Widget _buildStorageMigrationLimitRow(SetPcdnState state) {
    return _buildLimitRow(
      "settings_pcdn_set_con".tr,
      "${(state.info.value['memory']?['total_gb'] ?? '').toString()} GB",
      state.loadStatus.value,
      state.hoverIndex.value == 3
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      state.hoverIndex.value == 3
          ? AppTextStyles.textStyleTip10back
          : AppTextStyles.textStyleTip10,
    );
  }

  Widget _buildCpuLimitRow(SetPcdnState state) {
    return _buildLimitRow(
      "settings_pcdn_set_con".tr,
      "${(state.info.value['cpu']?['cores'] ?? '').toString()} ${"task_pcdn_cpu_unit".tr}",
      state.loadStatus.value,
      state.hoverIndex.value == 2
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12,
      state.hoverIndex.value == 2
          ? AppTextStyles.textStyleTip10back
          : AppTextStyles.textStyleTip10,
    );
  }

  Widget _buildLimitRow(
    String title,
    String value,
    bool isLoad,
    TextStyle titleStyle,
    TextStyle valueStyle,
  ) {
    return Row(
      children: [
        Text(title, style: titleStyle),
        !isLoad
            ? Text("${value}", style: valueStyle)
            : LoadingWidget(
                radius: 8,
                strokeWidth: 2,
              ),
        const Spacer(),
      ],
    );
  }
}

// Button components
extension _SetPcdnPageButtons on SetPcdnPage {
  Widget _buildSaveButton(BuildContext ctx, SetPcdnController log, int tag,
      Color backgroundColor, TextStyle textStyle) {
    return InkWell(
      onTap: () {
        log.onSave(ctx, tag);
        //onChangeRunning
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: _PcdnPageConstants.buttonHeight,
          width: _PcdnPageConstants.buttonWidth,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(_PcdnPageConstants.borderRadiusLarge),
          ),
          child: Text("save".tr, style: textStyle),
        ),
      ),
    );
  }
}
