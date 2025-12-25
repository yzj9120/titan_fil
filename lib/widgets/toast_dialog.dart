import 'dart:async';

import 'package:flutter/material.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:toastification/toastification.dart';

import '../styles/app_colors.dart';

class ToastConfig {
  final String? title;
  final String? message;
  final Widget? titleWidget;
  final Widget? messageWidget;
  final Widget? icon;
  final ToastificationType type;
  final Alignment alignment;
  final Duration autoCloseDuration;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final Color? primaryColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final List<BoxShadow> boxShadow;
  final bool showIcon;
  final bool showProgressBar;
  final CloseButtonShowType closeButtonShowType;
  final bool closeOnClick;
  final bool pauseOnHover;
  final bool dragToClose;
  final bool applyBlurEffect;
  final Duration animationDuration;
  final bool dismissExisting;
  final TextDirection direction;
  final double? width; // 新增宽度设置

  const ToastConfig({
    this.title,
    this.message,
    this.titleWidget,
    this.messageWidget,
    this.type = ToastificationType.warning,
    this.alignment = Alignment.topRight,
    this.autoCloseDuration = const Duration(seconds: 2),
    this.titleStyle,
    this.icon,
    this.messageStyle,
    this.primaryColor = AppColors.cToast,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = 12,
    this.boxShadow = const [
      BoxShadow(
        color: Color(0x07000000),
        blurRadius: 16,
        offset: Offset(0, 16),
        spreadRadius: 0,
      )
    ],
    this.showIcon = true,
    this.showProgressBar = false,
    this.closeButtonShowType = CloseButtonShowType.none,
    this.closeOnClick = false,
    this.pauseOnHover = true,
    this.dragToClose = true,
    this.applyBlurEffect = true,
    this.animationDuration = const Duration(milliseconds: 100),
    this.dismissExisting = true,
    this.direction = TextDirection.ltr,
    this.width, // 新增宽度设置
  });

  Color get effectiveForegroundColor {
    return foregroundColor ?? _getDefaultForegroundColor(type);
  }

  static Color _getDefaultForegroundColor(ToastificationType type) {
    switch (type) {
      case ToastificationType.warning:
        return AppColors.themeColor;
      case ToastificationType.info:
        return Colors.blue;
      case ToastificationType.success:
        return Colors.green;
      case ToastificationType.error:
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}

class ToastHelper {
  static Completer<void>? _toastCompleter;

  static void show(
    BuildContext context, {
    String? title,
    String? message,
    required ToastConfig config,
    Map<String, dynamic>? content,
  }) {
    if (_toastCompleter != null && config.dismissExisting) {
      dismiss();
    }

    _toastCompleter = Completer<void>();

    final effectiveContent = content ?? {};
    final effectiveTitle = title ?? effectiveContent['error']?.toString();
    final effectiveMessage = message ?? effectiveContent['msg']?.toString();

    toastification.show(
      context: context,
      type: config.type,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: config.autoCloseDuration,
      title: config.titleWidget ??
          Text(
            effectiveTitle ?? '',
            style: config.titleStyle ??
                const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
          ),
      description: config.messageWidget ??
          RichText(
            text: TextSpan(
              text: effectiveMessage ?? '',
              style: config.messageStyle ??
                  const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      alignment: config.alignment,
      direction: config.direction,
      animationDuration: config.animationDuration,
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      showIcon: config.showIcon,
      // icon: config.type == ToastificationType.success
      //     ? Platform.isWindows
      //         ? '\u{2705}'.toEmojiText()
      //         : Assets.images.iconCheckStatusOk2.image(width: 20)
      //     : Platform.isWindows
      //         ? '\u{26A0}'.toEmojiText()
      //         : Assets.images.icToastWorr.image(width: 20),
      icon: config.type == ToastificationType.success
          ? '\u{2705}'.toEmojiText()
          : '\u{26A0}'.toEmojiText(),
      primaryColor: config.primaryColor,
      foregroundColor: config.effectiveForegroundColor,
      padding: config.padding,
      margin: config.margin,
      borderRadius: BorderRadius.circular(config.borderRadius),
      boxShadow: config.boxShadow,
      showProgressBar: config.showProgressBar,
      closeButtonShowType: config.closeButtonShowType,
      closeOnClick: config.closeOnClick,
      pauseOnHover: config.pauseOnHover,
      dragToClose: config.dragToClose,
      applyBlurEffect: config.applyBlurEffect,
      callbacks: ToastificationCallbacks(
        onTap: (_) => _logEvent('Toast tapped'),
        onCloseButtonTap: (_) => _logEvent('Toast close button tapped'),
        onAutoCompleteCompleted: (_) => dismiss(),
        onDismissed: (_) => dismiss(),
      ),
    );
  }

  static void showFromMap(
    BuildContext context,
    Map<String, dynamic> content, {
    ToastConfig config = const ToastConfig(),
  }) {
    show(
      context,
      content: content,
      config: config,
    );
  }

  static void _logEvent(String message) {
    //debugPrint(message);
  }

  static void dismiss() {
    _toastCompleter?.complete();
    _toastCompleter = null;
    toastification.dismissAll();
  }

  // Quick show methods for common toast types
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    ToastConfig config = const ToastConfig(type: ToastificationType.success),
  }) {
    show(context, title: title ?? 'Success', message: message, config: config);
  }

  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    ToastConfig config = const ToastConfig(type: ToastificationType.error),
  }) {
    show(context, title: title ?? 'Error', message: message, config: config);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    ToastConfig config = const ToastConfig(type: ToastificationType.warning),
  }) {
    show(context, title: title ?? 'Warning', message: message, config: config);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    ToastConfig config = const ToastConfig(type: ToastificationType.info),
  }) {
    show(context, title: title ?? 'Info', message: message, config: config);
  }
}
