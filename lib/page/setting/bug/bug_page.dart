import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/app_colors.dart';
import 'bug_controller.dart';
import 'child/page_feedback_bug.dart';
import 'child/page_feedback_list.dart';
import 'child/page_feedback_suggest.dart';
import 'child/page_title_view.dart';

class BugPage extends StatelessWidget {
  const BugPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BugController()); // 确保全局单例
    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(22),
        child: _buildContent(controller),
      );
    });
  }

  Widget _buildContent(BugController controller) {
    return Column(
      children: [
        _buildMainHeader(),
        const SizedBox(height: 22),
        PageTitleView(logic: controller),
      ],
    );
  }

  Widget _buildMainHeader() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.c1818,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          // Container(
          //   width: 4,
          //   height: 13,
          //   decoration: BoxDecoration(
          //     color: AppColors.btn,
          //     borderRadius: BorderRadius.circular(10),
          //   ),
          // ),
          Assets.images.icTag.image(width: 31),

          const SizedBox(width: 5),
          Text(
            "bug_title".tr,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
