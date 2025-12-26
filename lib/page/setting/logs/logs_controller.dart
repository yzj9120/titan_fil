/**
 * 主界面控制器
 */

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../network/api_service.dart';
import '../../../services/global_service.dart';
import '../../../services/log_service.dart';
import '../../../styles/app_colors.dart';
import '../../../utils/file_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/toast_dialog.dart';
import 'logs_state.dart';

class LogsController extends GetxController {
  final LogsState state = LogsState();
  final globalService = Get.find<GlobalService>();

  ///初始化
  @override
  void onInit() {
    super.onInit();
  }

  ///页面渲染完成
  @override
  void onReady() {
    super.onReady();
  }

  ///释放资源
  @override
  void onClose() {
    super.onClose();
  }

  void onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0;
    if (isVisible) {
      initLogFolder();
    }
  }

  Future<void> onReadLogFolder(DateTime today) async {
    state.isLoading.value = true;
    final tags = state.dateList[state.selectedIndex.value];
    final logsPath = await FileHelper.getLogsPath();
    final todayLogs = await LogService.getTodayLogFiles(today, logsPath);
    final logNames = await LogService.getLogsNameByTags(todayLogs, tags);

    if (logNames.length <= 0) {
      state.logs.value = [];
      state.isLoading.value = false;
      return;
    }
    final name = logNames.first.path;
    var logFolder = null;
    if (tags == "agent") {
      logFolder = await LogService.getLogFileContent3(name);
    } else {
      logFolder = await LogService.getLogFileContent2(name);
    }
    state.logs.value = logFolder.toList();
    state.isLoading.value = false;
  }

  Future<void> initLogFolder() async {
    final logTypes = LoggerType.values
        .where((type) => type != LoggerType.edge && type != LoggerType.storage)
        .map((type) => type.name)
        .toList();
    state.dateList.value = logTypes;
    if (state.dateList.value.length > 0) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day); // 去除时间部分
      onReadLogFolder(today);
    } else {
      state.isLoading.value = false;
    }
  }

  void onChangeSelect(int index, String name) {
    state.selectedIndex.value = index;
    state.selectedName.value = name;

    DateTime dateTime = DateTime.parse(state.selectedTime.value);
    onReadLogFolder(dateTime);
  }

  Future<void> onOpenLogDirectory() async {
    final logDir = await LogService.getLogDir();
    OpenFile.open(logDir, linuxUseGio: true);
  }

  Future<void> onSelectTime(BuildContext context) async {
    final white12 = TextStyle(
        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600);
    final disabled12 = TextStyle(
        color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600);
    final selected12 = TextStyle(
        color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600);
    final now = DateTime.now();
    // final firstDate = DateTime(2025, 3, 1);
    // final lastDate = DateTime(2025, 4, 1);
    // final firstDate = DateTime(now.year, now.month - 1, now.day);
    // final lastDate = now;

    final DateTime lastDate = DateTime.now(); // 当前日期
    final DateTime firstDate = lastDate.subtract(Duration(days: 6)); // 7天前（含今天）

    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogBackgroundColor: AppColors.c1818,
      // 背景颜色
      dialogSize: const Size(350, 400),
      borderRadius: BorderRadius.circular(15),
      value: state.selectedDates.value,
      config: CalendarDatePicker2WithActionButtonsConfig(
        // firstDayOfWeek: 1,
        calendarType: CalendarDatePicker2Type.single,
        // centerAlignModePicker: true,
        disableModePicker: true,
        // 禁用模式切换，隐藏年和月的选择
        disableMonthPicker: true,
        // 允许月份选择（如果参数存在）
        customModePickerIcon: SizedBox(),
        firstDate: firstDate,
        lastDate: lastDate,
        currentDate: lastDate,

        calendarViewMode: CalendarDatePicker2Mode.day,
        // 日期控制样式
        // hideLastMonthIcon: true,
        // hideNextMonthIcon: true,
        lastMonthIcon: Icon(
          Icons.chevron_left, // 图标类型
          color: Colors.white30, // 颜色
          size: 20, // 大小
        ),
        nextMonthIcon: Icon(
          Icons.chevron_right, // 图标类型
          color: Colors.white30, // 颜色
          size: 20, // 大小
        ),
        selectableYearPredicate: (int year) {
          return year >= firstDate.year && year <= lastDate.year;
        },
        // 月份样式
        selectableMonthPredicate: (int year, int month) =>
            month >= now.month - 1,
        selectableDayPredicate: (DateTime date) {
          // 只允许选择最近7天（含今天）
          return date.isAfter(firstDate.subtract(Duration(days: 1))) &&
              date.isBefore(lastDate.add(Duration(days: 1)));
        },
        controlsTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),

        // 星期标签样式
        weekdayLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),

        // 日期样式
        todayTextStyle: white12,
        dayTextStyle: white12,
        disabledDayTextStyle: disabled12,
        selectedDayTextStyle: selected12,
        selectedDayHighlightColor: AppColors.themeColor,

        monthTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        selectedMonthTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        disabledMonthTextStyle: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),

        // 年份样式
        yearTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        selectedYearTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        disabledYearTextStyle: const TextStyle(color: Colors.white38),

        // 确定 / 取消按钮
        cancelButtonTextStyle: TextStyle(
          color: AppColors.tcCff,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        okButtonTextStyle: TextStyle(
          color: AppColors.themeColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (results != null && results.isNotEmpty && results.first != null) {
      final selectedDate = results.first!;
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      //print(formattedDate); // 输出：2025-05-20
      state.selectedTime.value = formattedDate;
      DateTime dateTime = DateTime.parse(state.selectedTime.value);
      onReadLogFolder(dateTime);
    } else {
      debugPrint('未选择日期');
      state.selectedTime.value = state.currentTime;
    }
  }

  Future<void> onSendLogs(BuildContext context) async {
    DateTime now = DateTime.parse(state.selectedTime.value);
    // DateTime now = DateTime.now();
    // final today = DateTime(now.year, now.month, now.day);
    final logsPath = await FileHelper.getLogsPath();
    final todayLogs = await LogService.getTodayLogFiles(now, logsPath);
    debugPrint('发送日志文件: ${todayLogs}');
    if (todayLogs.length <= 0) {
      ToastHelper.showWarning(
        context,
        title: 'msg_dialog_error'.tr,
        message: "settings_logs_send_not".tr,
        config: const ToastConfig(
          autoCloseDuration: Duration(seconds: 3),
        ),
      );
      return;
    }
    final loading = LoadingIndicator();
    loading.show(context, message: "settings_logs_send_load".tr);
    final zipName = 'logs-${state.selectedTime.value}';
    final zipFile = await FileHelper.compressLogs(todayLogs, zipName);
    print('压缩: ${zipFile.path}');
    // debugPrint('发送日志文件: ${todayLogs}');
    final res = await ApiService.uploadLogFile(zipFile);
    debugPrint('res: ${res}');
    loading.hide();
    if (res.code == 200) {
      ToastHelper.showSuccess(context,
          message: "bug_feedbackSuccessfulNotice".tr, title: "submittingOk".tr);
    } else {
      ToastHelper.showWarning(
        context,
        title: 'msg_dialog_error'.tr,
        message: "${res.toString()}",
        config: const ToastConfig(
          autoCloseDuration: Duration(seconds: 5),
        ),
      );
    }

    // return;
    // final results = await Future.wait(todayLogs
    //     .take(4)
    //     .toList()
    //     .map((file) => ApiService.uploadLogFile(file)));
    // loading.hide();
    // final failedUploads = results.where((r) => r.code != 200);
    // if (failedUploads.isEmpty) {
    //   ToastHelper.showSuccess(context,
    //       message: "bug_feedbackSuccessfulNotice".tr, title: "submittingOk".tr);
    // } else {
    //   ToastHelper.showWarning(
    //     context,
    //     title: 'msg_dialog_error'.tr,
    //     message: "${failedUploads.toString()}",
    //     config: const ToastConfig(
    //       autoCloseDuration: Duration(seconds: 3),
    //     ),
    //   );
    // }
  }
}
