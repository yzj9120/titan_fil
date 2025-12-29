import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/bind/bind_controller.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/widgets/rounded_container_button.dart';

class StepKey extends StatelessWidget {
  final bool isEdit;

  const StepKey({
    super.key,
    this.isEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<BindController>();
    final emailController = TextEditingController();

    if (!isEdit) {
      emailController.text = logic.state.email.value;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Text(
          'bind_key_button'.tr,
          style: AppTextStyles.textStyle12gray,
        ),
        const SizedBox(height: 20),
        Container(
          height: 41,
          decoration: BoxDecoration(
            color: AppColors.back1,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black12.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: emailController,
            style: AppTextStyles.textStyle12,
            readOnly: !isEdit,
            decoration: InputDecoration(
              hintText: 'input_key_placeholder'.tr,
              hintStyle: AppTextStyles.textStyle12,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            ),
          ),
        ),
        const SizedBox(height: 20),

        RichText(
          textAlign: TextAlign.left, // 可选，双重保证
          text: TextSpan(
            style: AppTextStyles.textStyle12,
            children: [
              WidgetSpan(
                child: Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.grey,
                  ),
                ),
                alignment: PlaceholderAlignment.middle,
              ),
              TextSpan(
                text: "no_key_hint".tr
              ),
              TextSpan(
                text: "click_here_prompt".tr,
                style: AppTextStyles.textUnderline.copyWith(
                  fontSize: 12,
                  color: AppColors.themeColor,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    logic.onOpenWebBingKey(context);
                  },
              ),
              TextSpan(
                text: "view_tutorial".tr,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        MouseRegion(
          child: InkWell(
            onTap: () {
              // 获取邮箱值并打印
              String email = emailController.text.trim();
              logic.onBindKey(context, email);
            },
            child: RoundedContainerButton(
              width: 306,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'bind_click_to_bind'.tr,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
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
