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

class StepOk extends StatelessWidget {
  StepOk({super.key});

  final BindController logic = Get.find<BindController>();
  final LocaleController localeController = Get.find<LocaleController>();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key'.tr,
            style: AppTextStyles.textStyle12white,
          ),
          const SizedBox(height: 10),
          Text(
            '${logic.state.key}',
            style: AppTextStyles.textCff,
          ),
          const SizedBox(height: 18),
          Text(
            'PCDN ID'.tr,
            style: AppTextStyles.textStyle12white,
          ),
          const SizedBox(height: 10),
          Text(
            '${logic.globalService.agentId}',
            style: AppTextStyles.textCff,
          ),
          const SizedBox(height: 18),
          Text(
            'fil_wallet_address'.tr,
            style: AppTextStyles.textStyle12white,
          ),
          const SizedBox(height: 10),
          Text(
            '${logic.state.email.value}',
            style: AppTextStyles.textCff,
          ),
          const SizedBox(height: 18),
        ],
      );
}
