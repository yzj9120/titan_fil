import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

class RoundedContainerButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final double borderRadius;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final Gradient? gradient;

  const RoundedContainerButton({
    Key? key,
    required this.child,
    this.onTap,
    this.width = 175,
    this.height = 45,
    this.borderRadius = 73,
    this.backgroundColor = AppColors.themeColor,
    this.padding,
    this.border,
    this.shadow,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: gradient == null ? backgroundColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: shadow,
        ),
        child: Center(child: child),
      ),
    );
  }
}
