import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/utils/app_helper.dart';

import '../controllers/notice_controller.dart';
import '../models/notice_bean.dart';

class DialogNotice {
  static BuildContext? _dialogContext;

  static void close() {
    if (_dialogContext != null && _dialogContext!.mounted) {
      Navigator.of(_dialogContext!).pop();
    }
  }

  static String _parseTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd').format(dateTime);
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
      return '';
    }
  }

  static void show(BuildContext context) {
    final noticeController = Get.find<NoticeController>();
    final notices = noticeController.notices;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _dialogContext = context;
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.only(top: 22, bottom: 22),
          content: SizedBox(
            width: 423,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        _buildHeader(context),
                        const Spacer(),
                      ],
                    ),
                    Positioned(
                      right: 15,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white30,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildNoticeList(notices),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'dialog_notice_list'.tr,
          style: AppTextStyles.textStyle15,
        ),
        Positioned(
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white30, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  static Widget _buildNoticeList(List<NoticeItemBean> notices) {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: notices.isEmpty
            ? Center(
                child: Text(
                  'not_data'.tr,
                  style: AppTextStyles.textStyle10,
                ),
              )
            : ListView.separated(
                itemCount: notices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildNoticeItem(context, notices[index]),
              ),
      ),
    );
  }

  static Widget _buildNoticeItem(BuildContext ctx, NoticeItemBean notice) {
    final date = _parseTime("${notice.invalidTo}" ?? '');
    final createdTime = _parseTime("${notice.createdAt}" ?? '');

    return GestureDetector(
      onTap: () {
        if (notice.redirectUrl.isNotEmpty) {
          AppHelper.openUrl(ctx, notice.redirectUrl);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        margin: EdgeInsets.zero,
        color: const Color(0xFF000000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notice.name ?? '',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: _isExpired(date) ? Colors.white : AppColors.cff0084,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                createdTime,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0x4DFFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isExpired(String targetTimeStr) {
    if (targetTimeStr.isEmpty) return true;

    try {
      final now = DateTime.now();
      final targetTime = DateTime.parse(targetTimeStr);
      return now.isAfter(targetTime);
    } catch (e) {
      debugPrint('Error comparing dates: $e');
      return true;
    }
  }
}
