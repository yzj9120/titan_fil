import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyHelper {
  static Future<void> copyToClipboard(BuildContext context, String text,
      {String? successMessage}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Align(
            alignment: Alignment.center,
            child: Container(
              width: 200,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00F190),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                successMessage ?? '复制成功',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
