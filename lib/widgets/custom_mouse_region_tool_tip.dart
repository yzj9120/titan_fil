import 'package:flutter/material.dart';

import 'custom_tooltip.dart';

class CustomMouseRegionToolTip extends StatelessWidget {
  final String message;
  final VoidCallback onPressed;
  final Widget child;
  final AxisDirection preferredDirection;
  final bool showTooltip;

  const CustomMouseRegionToolTip({
    super.key,
    this.message = "",
    required this.onPressed,
    required this.child,
    this.preferredDirection = AxisDirection.right,
    this.showTooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: showTooltip
          ? CustomTooltip(
              message: "$message",
              preferredDirection: preferredDirection,
              sizeWidth: 0,
              child: InkWell(
                onTap: () => onPressed(),
                child: child,
              ),
            )
          : InkWell(
              onTap: () => onPressed(),
              child: child,
            ),
    );
  }
}
