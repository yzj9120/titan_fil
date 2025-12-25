/**
 * 主界面控制器
 */

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:titan_fil/constants/constants.dart';
import 'package:titan_fil/utils/preferences_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../config/app_config.dart';
import '../../../controllers/miner_controller.dart';
import '../../../models/bug_picture.dart';
import '../../../network/api_service.dart';
import '../../../services/global_service.dart';
import '../../../services/log_service.dart';
import '../../../utils/app_helper.dart';
import '../../../widgets/loading_indicator.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/toast_dialog.dart';
import 'bug_state.dart';

class BugController extends GetxController {
  final BugState state = BugState();
  final GlobalService globalService = Get.find<GlobalService>();
  final minerController = Get.find<MinerController>();

  ///初始化
  @override
  void onInit() {
    init();
    super.onInit();
  }

  ///页面渲染完成
  @override
  void onReady() {
    getBugsList();
    super.onReady();
  }

  ///释放资源
  @override
  void onClose() {
    super.onClose();
  }

  void onVisibilityChanged(VisibilityInfo info, int tag) {
    final isVisible = info.visibleFraction > 0;
    print('组件可见性: ${isVisible ? "可见" : "不可见"}');
    if (isVisible) {
      getBugsList();
    } else {}
  }

  Future<void> init() async {
    state.picListNotifier.value.clear();
    state.picListNotifier.value.add(BugPicture(url: "", type: -1, progress: 0));
    var account =
        await PreferencesHelper.getString(Constants.userAddress) ?? "";
    if (account.isEmpty) {
      account = minerController.account.value;
    }
    state.email.value = account;

    if (state.email.value.isEmpty) {
      String key =
          await PreferencesHelper.getString(Constants.bindKey) ?? "";
      if (key.isNotEmpty) {
        final response = await ApiService.getUserInfo(key);
        if (response != null) {
          state.email.value = response.account.toString();
        }
      }
    }
    state.code = await PreferencesHelper.getString(Constants.userCode) ?? "";
    state.nodeId.value = globalService.agentId;
  }

  Future<void> onReadLogFolder() async {
    try {
      List<String> logFolder =
          await LogService.getAllLogFileNames(fileName: LoggerName.t3.value);
      // 把 edge 日志提取出来
      String? edgeLog;
      logFolder.removeWhere((name) {
        if (name == 'edge.log') {
          edgeLog = name;
          return true;
        }
        return false;
      });

      final name = logFolder[0];
      var data = await LogService.getLogFileContent2(name,
          fileName: LoggerName.t3.value);
      state.edge = data.take(100).toList().toString();
    } catch (e) {
      state.edge = "";
    }
  }

  Future<void> initLogFolder() async {
    try {
      List<String> logFolder =
          await LogService.getAllLogFileNames(fileName: LoggerName.t3.value);
      List<String> nonAgentLogs = logFolder
          .where((fileName) => fileName.startsWith("agent-"))
          .take(1)
          .toList();
      final name = nonAgentLogs[0];
      var logCon = await LogService.getLogFileContent3(name);
      state.logs = logCon.take(100).toList().toString();
    } catch (e) {
      state.logs = "";
    }
  }

  void onHelpView(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl = isChineseLocale ? AppConfig.helpCn2 : AppConfig.helpEn2;
    AppHelper.openUrl(context, webUrl);
  }

  void onFeedbackView(BuildContext context) {
    state.selectIndex.value = 1;
    state.feedbackStatus = 1;
  }

  void onReportView(BuildContext context) {
    state.selectIndex.value = 2;
    state.feedbackStatus = 2;
  }

  void onHistoryListView() {
    state.selectIndex.value = 3;
    getBugsList();
  }

  void onBack() {
    state.selectIndex.value = 0;
    state.selectIndex.refresh();
  }

  bool hasUploadIma = true;

  Future<void> pickImage(int position, BuildContext context) async {
    if (!hasUploadIma) {
      return;
    }
    hasUploadIma = false;
    // 使用 FilePicker 选择图片
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      var image = File(result.files.single.path.toString());
      // 获取选择的图片路径
      try {
        var res = await ApiService.uploadImage(image, onProgress: (p) {
          state.picListNotifier.value[position].progress = p;
          if (p >= 1) {
            hasUploadIma = true;
          }
        });
        if (res == null) return;
        int code = res["code"];
        if (code == 0) {
          state.picListNotifier.value[position].url = res["data"]["url"];
          state.picListNotifier.value[position].type = 0;
          state.picListNotifier.value = List.from(state.picListNotifier.value);
          //..add(Picture(url: "", type: -1, progress: 0));
          bool exists =
              state.picListNotifier.value.any((picture) => picture.type == -1);
          // 如果不存在，则添加
          if (!exists) {
            state.picListNotifier.value
                .add(BugPicture(url: "", type: -1, progress: 0));
          }
        } else {
          _onErrorMsg(context, "${res["msg"]}");
        }
      } catch (e) {
        _onErrorMsg(context, "$e");
      }
    } else {
      hasUploadIma = true;
    }
  }

  void onRemovePicker(int index) {
    if (index >= 0 && index < state.picListNotifier.value.length) {
      state.picListNotifier.value = List.from(state.picListNotifier.value)
        ..removeAt(index);
    }
  }

  bool onCheck(BuildContext context) {
    if (state.code.isEmpty) {
      _onErrorMsg(context, "error_please_bind_identity_code".tr);
      return false;
    }
    if (state.telegramController.text.trim().isEmpty) {
      _onErrorMsg(context, "error_please_enter_telegram".tr);
      return false;
    }
    if (state.contentController.text.trim().isEmpty) {
      _onErrorMsg(context, "bug_questionDsc".tr);
      return false;
    }
    if (state.picListNotifier.value.length < 2) {
      _onErrorMsg(context, "bug_pleasePicture".tr);
      return false;
    }
    return true;
  }

  Future<void> onSubmit(BuildContext context) async {
    if (!onCheck(context)) {
      return;
    }
    List pics = filterAndConvertToStrings(state.picListNotifier.value);
    if (pics.isEmpty) {
      _onErrorMsg(context, "bug_pleasePicture".tr);
      return;
    }
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var image = jsonEncode(pics);

    final loading = LoadingIndicator();
    loading.show(context, message: "submitting".tr);

    await onReadLogFolder();
    await initLogFolder();

    final data = {
      'code': state.code,
      'telegram_id': state.telegramController.text.trim(),
      "description": state.contentController.text.trim(),
      "feedback_type": state.feedbackType,
      "platform": Platform.isMacOS == true ? 1 : 2,

      ///platform 1macos 2windows 3android 4ios
      "version": packageInfo.version,
      "log": "测试",
      "benefit_log": state.edge,
      "pics": image.toString(),
    };

    final String lang =
        globalService.localeController.locale() == 1 ? "cn" : "en";
    var res = await ApiService.report(data, lang);

    loading.hide();

    if (res.code == 200) {
      MessageDialog.success(context,
          titleKey: 'bug_feedbackSuccessful'.tr,
          messageKey: 'bug_feedbackSuccessfulNotice'.tr,
          buttonTextKey: "close".tr);
      state.telegramController.text = "";
      state.contentController.text = "";
      state.picListNotifier.value = [
        BugPicture(url: "", type: -1, progress: 0)
      ];
      getBugsList();
    } else {
      state.telegramController.text = "";
      state.contentController.text = "";
      state.picListNotifier.value = [
        BugPicture(url: "", type: -1, progress: 0)
      ];
      _onErrorMsg(context, res.msg);
    }
  }

  List<String> filterAndConvertToStrings(List<BugPicture> list) {
    List<BugPicture> filteredList =
        list.where((picture) => picture.type == 0).toList();
    List<String> stringList =
        filteredList.map((picture) => picture.url).toList();
    return stringList;
  }

  void _onErrorMsg(BuildContext context, String msg) {
    ToastHelper.showWarning(
      context,
      title: 'msg_dialog_error'.tr, // 错误标题
      message: msg,
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 5),
      ),
    );
  }

  Future<void> getBugsList() async {
    var code = await PreferencesHelper.getString(Constants.userCode) ?? "";
    var res = await ApiService.bugsList(code);
    state.historyList.value = res?.list ?? [];
  }
}
