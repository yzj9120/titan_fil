import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/gen/assets.gen.dart';

import '../../../../models/Steps.dart';
import '../../../../styles/app_colors.dart';
import '../../../../styles/app_text_styles.dart';
import '../../../../styles/app_theme.dart';
import 'env_controller.dart';

/// 运行环境监测主组件
class EnvironmentMonitoringWidget extends StatelessWidget {
  // 获取环境控制器实例
  final EnvController logic = Get.find<EnvController>();
  final String uniqueTag; // 添加唯一标识

  EnvironmentMonitoringWidget({
    super.key,
  }) : uniqueTag = 'env_${DateTime.now().millisecondsSinceEpoch}'; // 生成唯一tag

  @override
  Widget build(BuildContext context) {
    // 开始运行环境检测
    return Obx(() {
      if (logic.state.basicSteps.length == 0) {
        return SizedBox();
      }
      return Container(
        margin: const EdgeInsets.all(29),
        // 根据步骤数量动态计算容器高度
        height: _calculateContainerHeight(logic.state.basicSteps.length),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context), // 顶部标题栏
            const SizedBox(height: 19),
            _buildStepsList(), // 步骤列表
            Visibility(
              child: Center(
                  child: Text(
                "${logic.state.timerCount.value}${"pcd_task_close_dialog".tr}",
                style: AppTextStyles.textStyle12,
              )),
              visible: logic.state.hasClose.value,
            )
          ],
        ),
      );
    });
  }

  /// 计算容器高度
  double _calculateContainerHeight(int stepCount) {
    if (stepCount == 3) {
      return 360;
    }
    return stepCount == 5 ? 510 : 600; // 5个步骤时510，其他情况600
  }

  /// 构建顶部标题栏
  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 左侧标题文本
          Positioned(
            left: 0,
            child: Text(
              "pcd_task_progress".tr, // 翻译文本
              style: AppTextStyles.textStyle15,
            ),
          ),
          // 右侧关闭按钮
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                logic.onCloseDoalog(context);
              },
              child: const Icon(Icons.clear, color: Colors.white30, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建步骤列表
  Widget _buildStepsList() {
    if (logic.state.basicSteps.isEmpty) return const SizedBox();
    // 使用ListView构建步骤列表
    return ListView.builder(
      itemCount: logic.state.basicSteps.length,
      physics: const NeverScrollableScrollPhysics(), // 禁用滚动
      shrinkWrap: true, // 自适应高度
      itemBuilder: (context, index) => StepItem(index: index), // 每个步骤项
    );
  }
}

/// 单个步骤项组件
class StepItem extends StatelessWidget {
  final int index; // 步骤索引
  final EnvController logic = Get.find<EnvController>(); // 获取控制器

  StepItem({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = logic.state.basicSteps[index]; // 获取当前步骤数据
    final stepHeight = _calculateStepHeight(steps); // 计算步骤高度

    return Container(
      height: stepHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(steps), // 左侧步骤指示器
          const SizedBox(width: 10),
          StepDetails(index: index, steps: steps), // 右侧步骤详情
        ],
      ),
    );
  }

  /// 构建步骤指示器（图标+竖线）
  Widget _buildStepIndicator(Steps steps) {
    return Column(
      children: [
        _getStepIcon(steps), // 步骤图标
        const SizedBox(height: 10),
        // 如果不是最后一个步骤，显示连接竖线
        if (index < logic.state.basicSteps.length - 1)
          Expanded(
            child: VerticalDivider(
              color: _getStepColor(steps), // 根据状态获取颜色
              thickness: 1,
              width: 0.5,
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// 获取步骤图标（根据状态显示不同图标）
  Widget _getStepIcon(Steps steps) {
    final isCurrentStep = index == logic.state.stepIndex.value;

    // 未激活状态显示加载图标
    if (!steps.isActive) {
      return '\u{23F3}'.toEmojiText(fontSize: 20);
      return Platform.isWindows
          ? '\u{23F3}'.toEmojiText(fontSize: 20)
          : Assets.images.iconCheckStatusLoad2.image(width: 22);
    }

    // 根据成功/失败状态返回对应图标
    return steps.status
        ? '\u{2705}'.toEmojiText(fontSize: 20)
        : '\u{26A0}'.toEmojiText(fontSize: 20);
    return steps.status
        ? Platform.isWindows
            ? '\u{2705}'.toEmojiText(fontSize: 20)
            : Assets.images.iconCheckStatusOk2.image(width: 22)
        : Platform.isWindows
            ? '\u{26A0}'.toEmojiText(fontSize: 20)
            : Assets.images.iconCheckStatusError.image(width: 22);
  }

  /// 获取步骤颜色（用于图标和竖线）
  Color _getStepColor(Steps steps) {
    final isCurrentStep = index == logic.state.stepIndex.value;

    // 未激活状态使用默认颜色
    if (!steps.isActive) return AppColors.tcCff;

    // 成功状态使用主题色，失败状态使用警告色
    return steps.status ? AppColors.btn : AppColors.themeColor;
  }

  /// 计算步骤高度
  double _calculateStepHeight(Steps steps) {
    final isCurrentStep = index == logic.state.stepIndex.value;
    final isErrorState = !steps.status &&
        steps.isActive &&
        logic.globalService.pcdnMonitoringStatus.value == 5;

    // 当前步骤且是错误状态时高度为145，其他情况80
    return isCurrentStep && isErrorState ? 145 : 80;
  }
}

/// 步骤详情组件
class StepDetails extends StatelessWidget {
  final int index; // 步骤索引
  final Steps steps; // 步骤数据
  final EnvController logic = Get.find<EnvController>();

  StepDetails({Key? key, required this.index, required this.steps})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(), // 步骤标题和状态
        if (shouldShowErrorBox()) _buildErrorBox(context), // 错误信息框
        if (shouldShowProgressIndicator()) _buildProgressIndicator(), // 进度条
      ],
    );
  }

  /// 构建步骤标题和状态徽章
  Widget _buildStepHeader() {
    return SizedBox(
      width: 350,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 步骤标题
          Text("${steps.title}".tr, style: AppTextStyles.textStyle12white),
          // 如果步骤已激活，显示状态徽章
          if (steps.isActive) _buildStatusBadge(),
        ],
      ),
    );
  }

  /// 构建状态徽章
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: steps.status
            ? AppColors.themeColor3
            : Colors.transparent, // 根据状态设置颜色
        borderRadius: BorderRadius.circular(13), // 圆角边框
        border: Border.all(
          color: steps.status ? Colors.transparent : AppColors.white,
          width: 1,
        ),
      ),
      child: Text(
        "${steps.subtitle}".tr, // 状态文本
        style: AppTextStyles.textStyle11.copyWith(
            color: steps.status ? AppColors.themeColor : AppColors.white),
      ),
    );
  }

  /// 构建错误信息框
  Widget _buildErrorBox(BuildContext context) {
    return Expanded(
      child: Container(
        width: 350,
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
        decoration: _errorBoxDecoration(),
        // 错误框样式
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 错误描述文本
            Text(
              "${steps.des.toString().trim()}".tr,
              style: AppTextStyles.textStyle11,
              maxLines: 2, // 最多显示2行
              overflow: TextOverflow.ellipsis, // 超出部分显示省略号
            ),
            const SizedBox(height: 10),
            _buildHelpLink(), // 帮助链接
            const SizedBox(height: 10),
            _buildActionButtons(), // 操作按钮组
          ],
        ),
      ),
    );
  }

  /// 错误框装饰样式
  BoxDecoration _errorBoxDecoration() {
    return BoxDecoration(
      color: AppColors.cff21, // 背景色
      borderRadius: BorderRadius.circular(12), // 圆角
      boxShadow: [
        BoxShadow(
            // 底部阴影
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10)),
        BoxShadow(
            // 顶部浅阴影
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2)),
      ],
    );
  }

  /// 构建帮助链接
  Widget _buildHelpLink() {
    return GestureDetector(
      onTap: () => logic.openHelp(Get.context!), // 点击打开帮助
      child: Text(
        "pcd_task_viewHelp".tr,
        style: AppTextStyles.textUnderline.copyWith(
          fontSize: 11,
          color: AppColors.themeColor, // 链接颜色
        ),
      ),
    );
  }

  /// 构建操作按钮组
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // 主要操作按钮（如果有）
        if (steps.txt != null) _buildPrimaryButton(),
        // 两个按钮之间有间距
        if (steps.txt != null && steps.onRetry != null)
          const SizedBox(width: 5),
        // 重试按钮（如果有）
        if (steps.onRetry != null) _buildRetryButton(),
      ],
    );
  }

  /// 构建主要操作按钮
  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: () => steps.onTap?.call(), // 点击回调
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        decoration: AppTheme.minaCircular.copyWith(color: AppColors.themeColor),
        child: Text(
          "${steps.txt}".tr,
          style: AppTextStyles.textStyle11.copyWith(
            color: AppColors.back1,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// 构建重试按钮
  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () => steps.onRetry?.call(), // 点击重试回调
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45), // 圆形边框
          border: Border.all(color: AppColors.themeColor, width: 1), // 边框样式
        ),
        child: Text(
          "pcd_task_retestStep".tr,
          style: AppTextStyles.textStyle11.copyWith(
            color: AppColors.themeColor,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(height: 10),
        Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            // 进度条背景
            SizedBox(
              height: 3,
              width: 300,
              child: DecoratedBox(
                decoration:
                    AppTheme.minaCircular.copyWith(color: Colors.white30),
              ),
            ),
            // 滑动的小方块
            SlidingBox(),
          ],
        ),
      ],
    );
  }

  /// 是否需要显示错误框
  bool shouldShowErrorBox() {
    return index == logic.state.stepIndex.value && // 是当前步骤
        steps.isActive && // 已激活
        !steps.status && // 状态失败
        logic.globalService.pcdnMonitoringStatus.value == 5; // 特定环境状态
  }

  /// 是否需要显示进度指示器
  bool shouldShowProgressIndicator() {
    return index == logic.state.stepIndex.value && !steps.isActive;
  }
}

/// 滑动方块组件（用于进度指示）
class SlidingBox extends StatefulWidget {
  const SlidingBox({super.key});

  @override
  _SlidingBoxState createState() => _SlidingBoxState();
}

class _SlidingBoxState extends State<SlidingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // 动画控制器
  late final Animation<double> _animation; // 动画值

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // 动画时长2秒
      vsync: this, // 垂直同步
    )..addStatusListener(_handleAnimationStatus); // 添加状态监听
    _animation = _createAnimation(); // 创建动画
    _controller.forward(); // 启动动画
  }

  /// 创建动画
  Animation<double> _createAnimation() {
    return Tween<double>(begin: 0, end: 280).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // 缓入缓出曲线
      ),
    );
  }

  /// 处理动画状态变化
  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // 动画完成时
      _controller.reset(); // 重置动画
      _controller.forward(); // 重新开始
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        // 根据动画值平移方块
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Container(
            width: 20,
            height: 5,
            decoration:
                AppTheme.minaCircular.copyWith(color: AppColors.themeColor),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // 销毁控制器
    super.dispose();
  }
}
