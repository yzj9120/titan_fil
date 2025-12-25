import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/setting/pcdn_broadband/set_pcdn_broadband_controller.dart';
import 'package:titan_fil/page/setting/pcdn_broadband/set_pcdn_broadband_state.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/app_colors.dart';
import '../../../styles/app_text_styles.dart';
import '../../../widgets/LoadingWidget.dart';

class SetPcdnBroadbandPage extends StatelessWidget {
  const SetPcdnBroadbandPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetPcdnBroadbandController());
    return VisibilityDetector(
        key: Key('my-PcdnBroadband'),
        onVisibilityChanged: (VisibilityInfo info) {},
        child: _buildMainContainer(context, controller));
  }
}

// Main layout components
extension _SetPcdnPageLayout on SetPcdnBroadbandPage {
  Widget _buildMainContainer(
      BuildContext context, SetPcdnBroadbandController log) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(22),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildContentSection(context, log),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.c1818,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Assets.images.icTag.image(width: 31),
          const SizedBox(width: 5),
          Text(
            "流量设置".tr,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(28),
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

  Widget _buildContentSection(
      BuildContext ctx, SetPcdnBroadbandController log) {
    return Obx(() => Row(
          children: [_buildCpuSettingsCard(ctx, log), Spacer()],
        ));
  }

  Widget _buildInputField(
    SetPcdnBroadbandState state,
    TextEditingController controller,
    FocusNode focusNode,
    Color borderColor,
    TextStyle textStyle, {
    TextStyle? suffixStyle,
    Color? decorationColors,
  }) {
    return Container(
      width: 239,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: decorationColors ?? AppColors.back1,
        borderRadius: BorderRadius.circular(73),
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
              contentPadding: EdgeInsets.symmetric(vertical: 5),
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
                'Mbps',
                style: suffixStyle ?? textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext ctx, SetPcdnBroadbandController log,
      int tag, Color backgroundColor, TextStyle textStyle) {
    return InkWell(
      onTap: () {
        log.onSubmit(ctx);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: 29,
          width: 73,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text("save".tr, style: textStyle),
        ),
      ),
    );
  }

  Widget _buildCpuSettingsCard(
      BuildContext ctx, SetPcdnBroadbandController logic) {
    return MouseRegion(
      onEnter: (_) => logic.state.hoverIndex.value = 2,
      onExit: (_) => logic.state.hoverIndex.value = 0,
      child: Container(
        height: 265,
        width: 320,
        padding: EdgeInsets.all(29),
        decoration: _cardDecoration(logic.state.hoverIndex.value == 2
            ? AppColors.themeColor
            : AppColors.c1818),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("设置流量".tr,
                style: logic.state.hoverIndex.value == 2
                    ? AppTextStyles.textStyle15black
                    : AppTextStyles.textStyle15),
            const SizedBox(height: 44),
            _buildLimitRow(
              "当前配置 ".tr,
              "${logic.state.bandwidth.value} Mbps",
              logic.state.loadStatus.value,
              logic.state.hoverIndex.value == 2
                  ? AppTextStyles.textStyle12black
                  : AppTextStyles.textStyle12,
              logic.state.hoverIndex.value == 2
                  ? AppTextStyles.textStyleTip10back
                  : AppTextStyles.textStyleTip10,
            ),
            const SizedBox(height: 10),
            _buildInputField(
              logic.state,
              logic.state.editingController,
              logic.state.editFocusNode,
              logic.state.hoverIndex.value == 2
                  ? Colors.black
                  : Colors.white.withOpacity(0.5),
              logic.state.hoverIndex.value == 2
                  ? AppTextStyles.textStyle12black
                  : AppTextStyles.textStyle12,
              suffixStyle: logic.state.hoverIndex.value == 2
                  ? AppTextStyles.textStyle12black
                  : AppTextStyles.textStyle12,
              decorationColors: logic.state.hoverIndex.value == 2
                  ? AppColors.themeColor
                  : AppColors.back1,
            ),
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
    );
  }
}
