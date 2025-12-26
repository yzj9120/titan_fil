import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../models/bug_picture.dart';
import '../../../models/feedback.dart';

class BugState {
  Rx<int> selectIndex = 0.obs;
  RxList<FeedbackItem> historyList = <FeedbackItem>[].obs;
  Rx<bool> hasHistory = false.obs;
  ValueNotifier<List<BugPicture>> picListNotifier = ValueNotifier([]);
  TextEditingController textEditingController = TextEditingController();
  TextEditingController telegramController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  FocusNode focusNode = FocusNode();
  Rx<String> email = "".obs;
  Rx<String> nodeId = "".obs;
  String code = "";
  String logs = "";
  String edge = "";
  int feedbackType = 1;
  var feedbackTypeListCn = ['意见', '咨询', '其他'];
  var feedbackTypeListEn = ['Opinion', 'Consult', 'Other'];
  int feedbackStatus = 0;
  RxInt hoverIndex = 0.obs;
}
