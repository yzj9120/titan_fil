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
    switch (controller.state.selectIndex.value) {
      case 0:
        return Column(
          children: [
            _buildMainHeader(),
            const SizedBox(height: 22),
            PageTitleView(logic: controller),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildSubHeader("bug_btn_feedback".tr, controller),
            const SizedBox(height: 22),
            VisibilityDetector(
                key: Key('my-bug_btn_feedback'),
                onVisibilityChanged: (VisibilityInfo info) {
                  controller.onVisibilityChanged(info, 0);
                },
                child: PageFeedbackBug()),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildSubHeader("bug_btn_suggestions".tr, controller),
            const SizedBox(height: 22),
            VisibilityDetector(
                key: Key('my-bug_btn_suggestions'),
                onVisibilityChanged: (VisibilityInfo info) {
                  controller.onVisibilityChanged(info, 1);
                },
                child: PageFeedbackSuggestPage()),
          ],
        );

      case 3:
        return Column(
          children: [
            _buildSubHeader("bug_btn_history".tr, controller),
            const SizedBox(height: 22),
            Expanded(
                child: VisibilityDetector(
                    key: Key('my-bug_btn_history'),
                    onVisibilityChanged: (VisibilityInfo info) {
                      controller.onVisibilityChanged(info, 2);
                    },
                    child: FeedbackListPage(
                      feedbackType: controller.state.feedbackStatus,
                      historyList: controller.state.historyList.toList(),
                    ))),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubHeader(String title, BugController controller) {
    final showHistoryButton = controller.state.selectIndex.value == 1 ||
        controller.state.selectIndex.value == 2;

    return Container(
      height: 55,
      decoration: BoxDecoration(
          color: AppColors.c1818, borderRadius: BorderRadius.circular(28)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 15),
          _buildBackButton(controller),
          const SizedBox(width: 10),
          _buildTitle(title, controller),
          const Spacer(),
          if (showHistoryButton) _buildHistoryButton(controller),
        ],
      ),
    );
  }

  Widget _buildBackButton(BugController controller) {
    return GestureDetector(
      onTap: () => controller.state.selectIndex.value = 0,
      child: '\u{2B05}'.toEmojiText(fontSize: 12),
      // child: Assets.images.icBack.image(width: 31),
      // child: Transform.rotate(
      //   angle: 180 * 3.1415926535897932 / 180,
      //   child: Icon(
      //     Icons.east,
      //     color: AppColors.themeColor,
      //     size: 20,
      //   ),
      // ),
    );
  }

  Widget _buildTitle(String title, BugController controller) {
    return GestureDetector(
      onTap: () => controller.onBack(),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHistoryButton(BugController controller) {
    return GestureDetector(
      onTap: () {
        controller.onHistoryListView();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.themeColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(73),
        ),
        child: Center(
          child: Text(
            'bug_btn_history'.tr,
            style: const TextStyle(
                color: AppColors.themeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
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
