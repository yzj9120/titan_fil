import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/bind/bind_controller.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/widgets/rounded_container_button.dart';

class Step1 extends StatelessWidget {
  final bool isEdit;

  const Step1({
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
        Text(
          'bind_input_email'.tr,
          style: AppTextStyles.textStyle12white,
        ),
        const SizedBox(height: 8),
        Text(
          'bind_email_tip'.tr,
          style: AppTextStyles.textStyle10,
        ),
        const SizedBox(height: 16),
        Container(
          height: 41,
          decoration: BoxDecoration(
            color: AppColors.back1,
            borderRadius: BorderRadius.circular(55),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: emailController,
            style: AppTextStyles.textStyle12,
            readOnly: !isEdit,
            decoration: InputDecoration(
              hintText: 'bind_input_email'.tr,
              hintStyle: AppTextStyles.textStyle12,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            ),
          ),
        ),
        const SizedBox(height: 24),
        MouseRegion(
          child: InkWell(
            onTap: () {
              // 获取邮箱值并打印
              String email = emailController.text.trim();
              logic.onCreateEmail(context, email);
            },
            child: RoundedContainerButton(
              width: 306,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'bind_next'.tr,
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
