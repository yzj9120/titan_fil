import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/bind/bind_controller.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/widgets/rounded_container_button.dart';

class Step2 extends StatelessWidget {
  final bool isEdit;

  const Step2({
    super.key,
    this.isEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<BindController>();
    final state = logic.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bind_verify_email'.tr,
          style: AppTextStyles.textStyle12white,
        ),
        const SizedBox(height: 29),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              return Text(
                "${state.email.value}",
                style: AppTextStyles.textStyle12white,
              );
            }),
            const SizedBox(width: 8),
            Visibility(
              visible: isEdit,
              child: InkWell(
                onTap: () => logic.onClearStep(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    // color: AppColors.themeColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.themeColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'bind_change'.tr,
                    style: AppTextStyles.textStyle10blackbold
                        .copyWith(color: AppColors.themeColor),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Obx(() {
          final sendStatus = state.emailCodeStatus.value;
          return Container(
            alignment: Alignment.center,
            child: Text(
              sendStatus == 1
                  ? "bind_code_snd".tr
                  : sendStatus == 2
                      ? "bind_verify_code_sent".tr
                      : sendStatus == 3
                          ? logic.state.sndError.value ??
                              "bind_code_snd_error".tr
                          : ''.tr,
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          );
        }),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            6,
            (index) => Container(
              width: 42,
              height: 39,
              decoration: BoxDecoration(
                color: AppColors.back1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: state.verifyControllers[index],
                focusNode: state.verifyFocusNodes[index],
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                style: AppTextStyles.textStyle26,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                ),
                maxLength: 1,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isEmpty && index > 0) {
                    FocusScope.of(context)
                        .requestFocus(state.verifyFocusNodes[index - 1]);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => TextButton(
                  onPressed: state.canResend.value
                      ? () => logic.resendVerifyCode(context)
                      : null,
                  style: TextButton.styleFrom(
                    backgroundColor: state.canResend.value
                        ? AppColors.tcDB1
                        : AppColors.back2,
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    minimumSize: const Size(72, 30),
                    // fixedSize: const Size(72, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    state.canResend.value
                        ? 'bind_resend'.tr
                        : '${state.countDown.value} S',
                    style: TextStyle(
                      fontSize: 10,
                      color: state.canResend.value
                          ? AppColors.primaryColor
                          : AppColors.titleColor,
                    ),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 18),
        MouseRegion(
          child: InkWell(
            onTap: () => logic.submitVerifyCode(context),
            child: RoundedContainerButton(
              width: 306,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'bind_login_and_bind'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
