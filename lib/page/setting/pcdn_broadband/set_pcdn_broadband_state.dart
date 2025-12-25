import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SetPcdnBroadbandState {
  RxInt hoverIndex = 0.obs;
  TextEditingController editingController = TextEditingController();
  FocusNode editFocusNode = FocusNode();
  String vbName = "";
  String psexecPath = "";
  Rx<bool> loadStatus = false.obs;
  Rx<String> bandwidth = "".obs;
}
