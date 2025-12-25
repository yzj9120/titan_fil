import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/controllers/locale_controller.dart';
import 'package:titan_fil/page/bind/bind_controller.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/utils/app_helper.dart';
import 'package:titan_fil/widgets/rounded_container_button.dart';

import '../../../gen/assets.gen.dart';

class Step3 extends StatelessWidget {
  Step3({super.key});
  final BindController logic = Get.find<BindController>();
  final LocaleController localeController = Get.find<LocaleController>();

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      // barrierColor: Colors.black.withOpacity(0.2),
      builder: (BuildContext context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 右侧内容区域的蒙层
            Positioned(
              left: 175, // 左侧边栏的宽度
              top: 0,
              right: 0,
              bottom: 0,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            // 弹框内容
            Positioned(
              left: 175, // 左侧边栏的宽度
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 292,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(29),
                  decoration: BoxDecoration(
                    color: AppColors.back2,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Obx(() => Text(
                                  'bind_wallet_help'.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: localeController.isChineseLocale()
                                        ? 16
                                        : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'bind_wallet_help_content'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    height: 1.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'bind_wallet_tip'.tr,
                                    ),
                                    TextSpan(
                                      text: 'bind_click_to_view'.tr,
                                      style: const TextStyle(
                                        color: AppColors.btn,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          AppHelper.openUrl(context,
                                              'https://test4.titannet.io');
                                        },
                                    ),
                                    const TextSpan(
                                      text: '。',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'bind_email'.tr,
            style: AppTextStyles.textStyle12white,
          ),
          const SizedBox(height: 10),
          Text(
            '${logic.state.email.value}',
            style: AppTextStyles.textStyle15,
          ),
          const SizedBox(height: 18),
          Text(
            'bind_wallet'.tr,
            style: AppTextStyles.textStyle12white,
          ),
          const SizedBox(height: 10),
          MouseRegion(
            child: InkWell(
                onTap: () => logic.onAddStep(),
                child: RoundedContainerButton(
                  width: 102,
                  height: 41,
                  borderRadius: 22,
                  onTap: () => logic.onAddStep(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'bind_click_to_bind'.tr,
                          style: AppTextStyles.textStyle10black,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _showHelpDialog(context),
                        child: Assets.images.tabHomeOn.image(width: 13),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                )),
          )
        ],
      );
}
