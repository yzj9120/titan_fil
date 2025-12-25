/**
 * 处理文件存储
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../styles/app_colors.dart';
import '../widgets/toast_dialog.dart';

class AppHelper {
  static void onCopy(BuildContext context, String message, String title) {
    if (title.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: title)).then((_) {
        ToastHelper.showSuccess(
          context,
          message: 'copied_clipboard'.tr,
          title: "$message",
        );
      });
    }
  }

  static void openUrl(BuildContext context, String webUrl) async {
    final Uri uri = Uri.parse(webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      //showSnackBar(context, "Could not launch url");
    }
  }

  /// 显示异常提示SnackBar
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Align(
          alignment: Alignment.center,
          child: Container(
            width: 200,
            alignment: Alignment.center,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.tipColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
