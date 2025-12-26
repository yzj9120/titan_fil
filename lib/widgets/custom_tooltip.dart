import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:titan_fil/styles/app_colors.dart';

class CustomTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final double sizeWidth;
  final Color color;
  final Color backgroundColor;
  final AxisDirection preferredDirection;
  final double offset;
  final double fontSize;

  /// 是否进入页面后自动显示
  final bool autoShow;
  final bool showClose;
  final TooltipTriggerMode triggerMode;

  /// 自动关闭的时间（秒）
  final Duration autoHideDuration;

  /// ✨关闭事件回调
  final VoidCallback? onClose;

  const CustomTooltip({
    Key? key,
    required this.message,
    required this.child,
    this.fontSize = 11,
    this.sizeWidth = 300,
    this.backgroundColor = AppColors.tooltipColor,
    this.color = Colors.white,
    this.preferredDirection = AxisDirection.up,
    this.offset = 3,
    this.autoShow = false,
    this.showClose = false,
    this.autoHideDuration = const Duration(seconds: 3),
    this.triggerMode = TooltipTriggerMode.tap,
    this.onClose,
  }) : super(key: key);

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  late final JustTheController _tooltipController;
  bool hasShow = false;

  @override
  void initState() {
    super.initState();
    _tooltipController = JustTheController();
    // 自动显示并自动关闭
  }

  @override
  void dispose() {
    _tooltipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.autoShow) {
        Future.delayed(widget.autoHideDuration, () {
          if (mounted) _tooltipController.showTooltip(immediately: true);
        });
      } else {
        if (mounted) _tooltipController.hideTooltip(immediately: true);
      }
    });

    return JustTheTooltip(
      key: ValueKey('tooltip_${Localizations.localeOf(context).languageCode}'),
      controller: _tooltipController,
      preferredDirection: widget.preferredDirection,
      backgroundColor: widget.backgroundColor,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      offset: widget.offset,
      tailLength: 10,
      elevation: 10,
      triggerMode: widget.triggerMode,
      barrierDismissible: false,
      isModal: widget.showClose,
      onShow: () {
        hasShow = true;
      },
      onDismiss: () {
        hasShow = false;
      },
      content: Container(
        width: widget.sizeWidth == 0 ? null : widget.sizeWidth,
        padding: const EdgeInsets.all(10),
        child: Stack(
          // alignment: Alignment.centerLeft,
          children: [
            // 内容文本
            Padding(
              padding: EdgeInsets.only(right: widget.showClose ? 24 : 0.0),
              child: Text(
                widget.message,
                textAlign: TextAlign.left,
                style:
                    TextStyle(fontSize: widget.fontSize, color: widget.color),
              ),
            ),
            // 右上角关闭按钮
            if (widget.showClose) ...{
              Positioned(
                right: 0,
                top: 1,
                child: GestureDetector(
                  onTap: () {
                    widget.onClose?.call();
                    _tooltipController.hideTooltip();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ),
            }
          ],
        ),
      ),
      child: widget.child,
    );
  }
}
