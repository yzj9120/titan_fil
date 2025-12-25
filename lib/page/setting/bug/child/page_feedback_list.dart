import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';

import '../../../../gen/assets.gen.dart';
import '../../../../models/feedback.dart';
import '../../../../styles/app_colors.dart';

class FeedbackListPage extends StatelessWidget {
  final List<FeedbackItem> historyList;
  final int feedbackType;
  final String uniqueTag; // 添加唯一标识

   FeedbackListPage({
    super.key,
    required this.historyList,
    required this.feedbackType
  }) : uniqueTag = 'feedback_${DateTime.now().millisecondsSinceEpoch}'; // 生成唯一tag

  @override
  Widget build(BuildContext context) {
    // 使用Get.put并指定唯一tag
    final controller = Get.put(
      FeedbackListController(historyList, feedbackType),
      tag: uniqueTag,
    );

    return Obx(() {
      print("当前页面tag: $uniqueTag, 数据量: ${controller.filteredList.length}");
      if (controller.filteredList.isEmpty) {
        return Center(
          child: Text(
            'not_data'.tr,
            style: AppTextStyles.feedbackTextWhite70,
          ),
        );
      }
      return ListView.builder(
        itemCount: controller.filteredList.length,
        itemBuilder: (context, index) {
          return FeedbackListItem(
            item: controller.filteredList[index],
            onToggle: () => controller.toggleItem(index),
          );
        },
      );
    });
  }
}

class FeedbackListController extends GetxController {
  final RxList<FeedbackItem> historyList;
  final int feedbackType;
  final RxList<FeedbackItem> filteredList = <FeedbackItem>[].obs;

  FeedbackListController(List<FeedbackItem> list, this.feedbackType)
      : historyList = list.obs {
    _filterList();
  }

  void _filterList() {
    filteredList.assignAll(
        historyList.where((element) =>
        feedbackType == 2 ? element.feedbackType != 3 : element.feedbackType == 3
        )
    );
    print("过滤后的数据量: ${filteredList.length}");
  }

  void toggleItem(int index) {
    final item = filteredList[index];
    item.checked = !(item.checked ?? false);
    item.angle = (item.angle ?? 0) == 0 ? 180 : 0;
    filteredList.refresh();
  }
}

class FeedbackListItem extends StatelessWidget {
  final FeedbackItem item;
  final VoidCallback onToggle;

  const FeedbackListItem(
      {super.key, required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.itemMarginBottom),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (item.checked == true) _buildDetails(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.itemPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(item.description, style: AppTextStyles.feedbackText),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(
              item.state == 1 ? "bug_pending".tr : "bug_password".tr,
              style: item.state == 1
                  ? AppTextStyles.feedbackText
                      .copyWith(color: AppColors.themeColor)
                  : AppTextStyles.feedbackText,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggle,
              child: Transform.rotate(
                angle: (item.angle ?? 0) * 3.1415927 / 180,
                child: const Icon(
                  Icons.arrow_drop_down,
                  size: 25,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        // if (item.state == 2) _buildRewardInfo(),
        _buildUserInfo(),
        _buildImageGrid(),
      ],
    );
  }

  Widget _buildRewardInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.itemPadding),
      child: Row(
        children: [
          Assets.images.iconJiangli.image(width: AppDimens.iconSize),
          const SizedBox(width: 8),
          Text(
            '${'bug_reward'.tr}：${item.rewardType.isEmpty ? 'TNT2' : item.rewardType}  +${item.reward}',
            style: AppTextStyles.rewardText,
          ),
          const Spacer(),
          Text(
            '${'bug_updateTime'.tr}：${item.updatedAt.toString().toDate()}',
            style: AppTextStyles.feedbackText,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.itemPadding),
      child: Column(
        children: [
          _buildInfoRow("bug_nodeId".tr, item.nodeId),
          const SizedBox(height: 20),
          _buildInfoRow("bug_email".tr, item.email, isLabel: true),
          const SizedBox(height: 20),
          _buildInfoRow("bug_telegram".tr, item.telegramId, isLabel: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLabel = false}) {
    return Row(
      children: [
        Text("$label:",
            style:
                isLabel ? AppTextStyles.labelText : AppTextStyles.feedbackText),
        const SizedBox(width: 8),
        Text(value, style: AppTextStyles.feedbackText),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Container(
      margin: const EdgeInsets.all(AppDimens.itemPadding),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: AppDimens.gridSpacing,
          mainAxisSpacing: AppDimens.gridSpacing,
          childAspectRatio: AppDimens.childAspectRatio,
        ),
        itemCount: item.pics.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: item.pics[index],
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 30),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image),
            fit: BoxFit.cover,
            memCacheWidth: 200,
            maxWidthDiskCache: 200,
          );
        },
      ),
    );
  }
}

class AppTextStyles {
  static const TextStyle feedbackText =
      TextStyle(fontSize: 12, color: Colors.white38);
  static const TextStyle feedbackTextWhite70 =
      TextStyle(fontSize: 12, color: Colors.white70);
  static const TextStyle rewardText =
      TextStyle(fontSize: 12, color: Color(0xFF52FF38));
  static const TextStyle labelText =
      TextStyle(fontSize: 12, color: Colors.white24);
}

class AppDimens {
  static const double itemMarginBottom = 15;
  static const double itemPadding = 15;
  static const double iconSize = 30;
  static const double dropdownIconSize = 15;
  static const double gridSpacing = 10.0;
  static const double childAspectRatio = 0.85;
}
