import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/gen/assets.gen.dart';

import '../styles/app_colors.dart';

/// 消息弹窗配置模型
class MessageDialogConfig {
  final String titleKey;
  final String? messageKey;
  final String buttonTextKey;
  final String? cancelButtonTextKey;
  final VoidCallback? onAction;
  final VoidCallback? onCancel;
  final VoidCallback? onClose;
  final DialogIconType iconType;
  final Widget? customIcon;
  final Color? backgroundColor;
  final Duration? autoCloseDuration;
  final Curve? entranceCurve;
  final bool showCloseButton;
  final String? closeButtonTextKey;
  final double? width;
  final double? padding;
  final double? buttonWidth;
  final Widget? buttonWidget;
  final List<Widget>? childWidget;
  final ButtonStyle? cancelButtonStyle;

  final Widget? image;
  final TextStyle? messageTextStyle;
  final TextStyle? cancelButtonTextStyle;

  const MessageDialogConfig({
    required this.titleKey,
    this.messageKey,
    this.buttonTextKey = 'ok',
    this.cancelButtonTextKey,
    this.closeButtonTextKey,
    this.buttonWidth,
    this.onAction,
    this.onCancel,
    this.onClose,
    this.messageTextStyle,
    this.iconType = DialogIconType.none,
    this.customIcon,
    this.showCloseButton = false,
    this.backgroundColor,
    this.autoCloseDuration,
    this.entranceCurve = Curves.easeOutBack,
    this.width = 320,
    this.padding = 24,
    this.image,
    this.buttonWidget,
    this.cancelButtonStyle,
    this.cancelButtonTextStyle,
    this.childWidget,
  });

  String get title => titleKey.tr;

  String? get message => messageKey?.tr;

  String get buttonText => buttonTextKey.tr;

  String? get cancelButtonText => cancelButtonTextKey?.tr;
}

/// 图标类型枚举
enum DialogIconType { error, success, warning, info, none, image }

/// 消息弹窗核心实现
class MessageDialog {
  static Completer<void>? _currentDialog;
  static BuildContext? _currentContext;

  /// 显示弹窗（主入口）
  static Future<void> show({
    required BuildContext context,
    required MessageDialogConfig config,
    bool barrierDismissible = false,
  }) async {
    if (_currentDialog != null) {
      debugPrint('[MessageDialog] Dialog already shown, ignoring request');
      return;
    }

    _currentDialog = Completer<void>();

    debugPrint('[MessageDialog] Showing: ${config.title}');

    await showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_context) {
        _currentContext = _context;
        return _MessageDialogCore(config: config);
      },
    ).then((_) {
      _completeDialog();
    });

    if (config.autoCloseDuration != null) {
      Timer(config.autoCloseDuration!, () => dismiss());
    }
  }

  /// 快速显示成功弹窗
  static Future<void> success(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    VoidCallback? onConfirm,
    String buttonTextKey = 'ok',
  }) {
    return show(
      context: context,
      config: MessageDialogConfig(
        titleKey: titleKey,
        messageKey: messageKey,
        iconType: DialogIconType.success,
        buttonTextKey: buttonTextKey,
        onAction: onConfirm,
      ),
    );
  }

  /// 快速显示错误弹窗
  static Future<void> error(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    VoidCallback? onRetry,
    String buttonTextKey = 'retry',
  }) {
    return show(
      context: context,
      config: MessageDialogConfig(
        titleKey: titleKey,
        messageKey: messageKey,
        iconType: DialogIconType.error,
        buttonTextKey: buttonTextKey,
        onAction: onRetry,
      ),
    );
  }

  /// 快速显示警告弹窗
  static Future<void> warning(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    String? buttonTextKey,
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      config: MessageDialogConfig(
        titleKey: titleKey,
        messageKey: messageKey,
        iconType: DialogIconType.warning,
        buttonTextKey: buttonTextKey ?? 'confirm'.tr,
        onAction: onConfirm,
      ),
    );
  }

  /// 手动关闭弹窗
  static void dismiss() {
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.of(_currentContext!).pop();
      _completeDialog();
    }
  }

  static void _completeDialog() {
    _currentDialog?.complete();
    _currentDialog = null;
    _currentContext = null;
  }
}

/// 弹窗核心UI
class _MessageDialogCore extends StatefulWidget {
  final MessageDialogConfig config;

  const _MessageDialogCore({required this.config});

  @override
  _MessageDialogCoreState createState() => _MessageDialogCoreState();
}

class _MessageDialogCoreState extends State<_MessageDialogCore>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.config.entranceCurve!),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: _buildDialogContent(context),
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    final effectiveWidth = _calculateEffectiveWidth(context);
    return Dialog(
      backgroundColor: widget.config.backgroundColor ?? _defaultBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        width: effectiveWidth,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.config.showCloseButton) _buildCloseButtonRow(),
              if (widget.config.iconType != DialogIconType.none)
                _buildDefaultIcon(),
              SizedBox(height: widget.config.padding!),
              Text(
                widget.config.title,
                style: _titleTextStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: widget.config.padding!),
              if (widget.config.message != null) ...{
                Text(
                  widget.config.message ?? "",
                  style: widget.config.messageTextStyle ?? _messageTextStyle,
                  textAlign: TextAlign.center,
                )
              },
              SizedBox(height: widget.config.padding!),
              if ((widget.config.childWidget?.length ?? 0) > 0) ...[
                ...widget.config.childWidget!.map((widget) => widget),
                SizedBox(height: widget.config.padding!),
              ],
              _buildActionButtons(),
              widget.config.buttonWidget ?? SizedBox()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (widget.config.cancelButtonText != null) {
      return Column(
        children: [
          _buildConfirmButton(),
          const SizedBox(height: 16),
          _buildCancelButton(),
        ],
      );
    }
    return _buildConfirmButton();
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      height: 45,
      width: widget.config.buttonWidth ?? double.infinity,
      child: ElevatedButton(
        style: _actionButtonStyle,
        onPressed: () {
          widget.config.onAction?.call();
          MessageDialog.dismiss();
        },
        child: Text(
          widget.config.buttonText,
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 45,
      width: widget.config.buttonWidth ?? double.infinity,
      child: OutlinedButton(
        style: widget.config.cancelButtonStyle ?? _cancelButtonStyle,
        onPressed: () {
          MessageDialog.dismiss();
          widget.config.onCancel?.call();
        },
        child: Text(
          widget.config.cancelButtonText!,
          style: widget.config.cancelButtonTextStyle ??
              TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCloseButtonRow() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Center(
            child: Text(
              "${widget.config.closeButtonTextKey ?? ""}",
              style: _titleTextStyle,
            ),
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: InkWell(
            onTap: () {
              MessageDialog.dismiss();
              widget.config.onClose?.call();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.clear,
                color: Colors.white30,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultIcon() {
    return switch (widget.config.iconType) {
      DialogIconType.error => const _ErrorIcon(),
      DialogIconType.success => const _SuccessIcon(),
      DialogIconType.warning => const _WarningIcon(),
      DialogIconType.info => const _InfoIcon(),
      DialogIconType.none => const SizedBox.shrink(),
      DialogIconType.image => ImageIcon(widget.config.image!),
    };
  }

  double _calculateEffectiveWidth(BuildContext context) {
    return min(
      widget.config.width ?? 295,
      MediaQuery.of(context).size.width * 0.9,
    );
  }

  // 样式常量
  static const Color _defaultBackgroundColor = Color(0xFF181818);
  static const TextStyle _titleTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  static const TextStyle _messageTextStyle = TextStyle(
    fontSize: 13,
    color: Colors.white70,
    height: 1.5,
  );
  static final ButtonStyle _actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.themeColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
  );
  static final ButtonStyle _cancelButtonStyle = OutlinedButton.styleFrom(
    side: const BorderSide(color: AppColors.tcCff, width: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
  );
}

class ImageIcon extends StatelessWidget {
  final Widget image;

  ImageIcon(this.image);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: image,
    );
  }
}

// 图标组件
class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    // return Assets.images.icMsgSuccess.image(width: 72);
    return Container(
      // margin: const EdgeInsets.only(top: 50, bottom: 20),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(100),
      //   color: Colors.black.withOpacity(0.6),
      // ),
      child: Assets.images.icLogo2.image(width: 100),
    );
    return _DialogIcon(
      color: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon();

  @override
  Widget build(BuildContext context) {
    //return Assets.images.icMsgSuccess.image(width: 72);
    return Container(
      //margin: const EdgeInsets.only(top: 50, bottom: 20),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(100),
      //   color: Colors.black.withOpacity(0.6),
      // ),
      child: Assets.images.icLogo2.image(width: 100),
    );
    return _DialogIcon(
      color: Colors.red,
      icon: Icons.error_outline,
    );
  }
}

class _WarningIcon extends StatelessWidget {
  const _WarningIcon();

  @override
  Widget build(BuildContext context) {
    //return Assets.images.icMsgFail.image(width: 72);
    return Container(
      //margin: const EdgeInsets.only(top: 50, bottom: 20),
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(100),
      //   color: Colors.black.withOpacity(0.6),
      // ),
      child: Assets.images.icLogo2.image(width: 100),
    );
    return _DialogIcon(
      color: Colors.amber,
      icon: Icons.warning_amber_outlined,
    );
  }
}

class _InfoIcon extends StatelessWidget {
  const _InfoIcon();

  @override
  Widget build(BuildContext context) {
    return Assets.images.icLogo2.image(width: 72);
    return _DialogIcon(
      color: Colors.blue,
      icon: Icons.info_outline,
    );
  }
}

class _DialogIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _DialogIcon({
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 48,
        color: color,
      ),
    );
  }
}
