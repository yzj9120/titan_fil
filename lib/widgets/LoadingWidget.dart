import 'package:flutter/material.dart';

import '../styles/app_colors.dart';
import 'gradientCircularProgress.dart';

class LoadingWidget extends StatefulWidget {
  final double radius; // Make radius configurable
  final double strokeWidth; // Optionally make strokeWidth configurable too

  const LoadingWidget({
    super.key,
    this.radius = 25.0, // Default value
    this.strokeWidth = 5.0,
  });

  @override
  LoadingWidgetState createState() => LoadingWidgetState();
}

class LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState(); // 先调用 super.initState()
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationController.addListener(() => setState(() {}));
    _animationController.repeat(); // 启动循环动画
  }

  @override
  void dispose() {
    _animationController.stop(); // 停止动画（可选）
    _animationController.dispose(); // 必须先销毁 AnimationController
    super.dispose(); // 最后调用父类的 dispose
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
      child: GradientCircularProgressIndicator(
        radius: widget.radius,
        gradientColors: [
          Colors.white.withOpacity(0.1),
          AppColors.themeColor,
        ],
        strokeWidth: widget.strokeWidth,
      ),
    );
  }
}
