import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles/app_colors.dart';

/// 加载指示器

import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 假设你使用了 GetX


class LoadingIndicator {
  late OverlayEntry _overlayEntry;
  bool _isVisible = false;

  // 1. 定义一个 ValueNotifier 来管理消息状态
  final ValueNotifier<String> _messageNotifier = ValueNotifier('');

  /// 显示加载提示框
  void show(
      BuildContext context, {
        bool? showText = true,
        String? message = 'loading',
        Color? backgroundColor = Colors.grey,
        Color? valueColor = AppColors.themeColor,
      }) {
    if (_isVisible) {
      // 如果已经显示，直接更新文字并返回
      updateMessage(message ?? 'loading');
      return;
    }

    // 初始化文字
    _messageNotifier.value = (message == "loading") ? "loading".tr : (message ?? "");

    _overlayEntry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withOpacity(0.5),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black54, // 半透明背景
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xff181818),
                    borderRadius: BorderRadius.circular(85),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          backgroundColor: backgroundColor,
                          valueColor: AlwaysStoppedAnimation<Color>(valueColor!),
                        ),
                      ),
                      if (showText == true) ...[
                        const SizedBox(width: 10),
                        // 2. 使用 ValueListenableBuilder 包裹 Text
                        ValueListenableBuilder<String>(
                          valueListenable: _messageNotifier,
                          builder: (context, value, child) {
                            return Text(
                              value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry);
    _isVisible = true;
  }

  void showWithGet({
    bool? showText = true,
    String? message = 'loading',
    Color? backgroundColor = Colors.grey,
    Color? valueColor = AppColors.themeColor,
  }) {
    final context = Get.overlayContext;
    if (context == null) return;
    show(context,
        showText: showText,
        message: message,
        backgroundColor: backgroundColor,
        valueColor: valueColor);
  }

  /// 3. 新增：动态更新 Message 的方法
  void updateMessage(String message) {
    if (!_isVisible) return;

    // 处理多语言逻辑（与 show 方法保持一致）
    String finalMessage = message;
    if (finalMessage == "loading") {
      finalMessage = "loading".tr;
    }

    // 更新 notifier 的值，ValueListenableBuilder 会自动刷新 Text
    _messageNotifier.value = finalMessage;
  }

  /// 隐藏加载提示框
  void hide() {
    if (_isVisible) {
      _overlayEntry.remove();
      // 这里不需要重新赋值 OverlayEntry 为 SizedBox，只需要标记不可见即可
      // 如果为了防止内存泄漏，可以考虑 dispose notifier，但如果是单例模式则不需要
      _isVisible = false;
    }
  }
}