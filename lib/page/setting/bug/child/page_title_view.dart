import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../styles/app_colors.dart';
import '../../../../styles/app_text_styles.dart';
import '../bug_controller.dart';
import '../bug_state.dart';

class PageTitleView extends StatelessWidget {
  final BugController logic;

  const PageTitleView({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            _buildStorageSettingsCard(context, logic),
            const SizedBox(width: 10),
            _buildCpuSettingsCard(context, logic),
            const SizedBox(width: 10),
            _buildDataMigrationCard(context, logic),
          ],
        ));
  }
}

// Constants for layout and styling
class _BugConstants {
  static const double cardHeight = 140;
  static const double buttonWidth = 238;
  static const double buttonHeight = 45;
  static const double borderRadiusLarge = 28;
  static const EdgeInsets cardPadding = EdgeInsets.all(29);
}

extension _SetPcdnPageCards on PageTitleView {
  Widget _buildStorageSettingsCard(BuildContext ctx, BugController log) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 1,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _BugConstants.cardHeight,
          padding: _BugConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 1
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStorageLimitRow(log.state),
              const SizedBox(height: 10),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic.state.hoverIndex.value == 1
                      ? AppColors.themeColor
                      : Colors.transparent,
                  logic.state.hoverIndex.value == 1
                      ? AppColors.c1818
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 1
                      ? AppTextStyles.textStyle10black
                          .copyWith(fontWeight: FontWeight.bold)
                      : AppTextStyles.textStyle10black.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.themeColor), () {
                log.onHelpView(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCpuSettingsCard(BuildContext ctx, BugController log) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 2,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _BugConstants.cardHeight,
          padding: _BugConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 2
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStorageMigrationLimitRow(log.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic.state.hoverIndex.value == 2
                      ? AppColors.themeColor
                      : Colors.transparent,
                  logic.state.hoverIndex.value == 2
                      ? AppColors.c1818
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 2
                      ? AppTextStyles.textStyle10black
                          .copyWith(fontWeight: FontWeight.bold)
                      : AppTextStyles.textStyle10black.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.themeColor), () {
                log.onFeedbackView(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataMigrationCard(BuildContext ctx, BugController log) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => logic.state.hoverIndex.value = 3,
        onExit: (_) => logic.state.hoverIndex.value = 0,
        child: Container(
          height: _BugConstants.cardHeight,
          padding: _BugConstants.cardPadding,
          decoration: _cardDecoration(logic.state.hoverIndex.value == 3
              ? AppColors.themeColor
              : AppColors.c1818),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCpuLimitRow(log.state),
              const Spacer(),
              _buildSaveButton(
                  ctx,
                  logic.state.hoverIndex.value == 3
                      ? AppColors.themeColor
                      : Colors.transparent,
                  logic.state.hoverIndex.value == 3
                      ? AppColors.c1818
                      : AppColors.themeColor,
                  logic.state.hoverIndex.value == 3
                      ? AppTextStyles.textStyle10black
                          .copyWith(fontWeight: FontWeight.bold)
                      : AppTextStyles.textStyle10black.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.themeColor), () {
                log.onReportView(ctx);
              }),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(_BugConstants.borderRadiusLarge),
    );
  }
}

// Row components
extension _SetPcdnPageRows on PageTitleView {
  Widget _buildStorageLimitRow(BugState state) {
    return _buildLimitRow(
      "bug_help_title".tr,
      logic.state.hoverIndex.value == 1
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12white,
    );
  }

  Widget _buildStorageMigrationLimitRow(BugState state) {
    return _buildLimitRow(
      "bug_btn_feedback".tr,
      state.hoverIndex.value == 2
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12white,
    );
  }

  Widget _buildCpuLimitRow(BugState state) {
    return _buildLimitRow(
      "bug_btn_suggestions".tr,
      state.hoverIndex.value == 3
          ? AppTextStyles.textStyle12black
          : AppTextStyles.textStyle12white,
    );
  }

  Widget _buildLimitRow(String title, TextStyle titleStyle) {
    return Row(
      children: [
        Text(title, style: titleStyle),
        const Spacer(),
      ],
    );
  }
}

// Button components
extension _SetPcdnPageButtons on PageTitleView {
  Widget _buildSaveButton(BuildContext ctx, Color backgroundColor,
      Color borderColor, TextStyle textStyle, Function()? onPressed) {
    return InkWell(
      onTap: () {
        onPressed?.call();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: _BugConstants.buttonHeight,
          width: _BugConstants.buttonWidth,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor ?? Colors.transparent, // 可以传参数进来，默认透明
              width: 1.0,
            ),
            borderRadius:
                BorderRadius.circular(_BugConstants.borderRadiusLarge),
          ),
          child: Text("bug_btn_goto".tr, style: textStyle),
        ),
      ),
    );
  }
}
