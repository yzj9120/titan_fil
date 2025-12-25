import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SetPcdnState {
  var runningStatus = false.obs;
  TextEditingController memoryEditingController = TextEditingController();
  TextEditingController cpuEditingController = TextEditingController();
  TextEditingController diskEditingController = TextEditingController();
  TextEditingController bandwidthEditingController = TextEditingController();
  FocusNode memoryFocusNode = FocusNode();
  FocusNode cpuFocusNode = FocusNode();
  FocusNode diskFocusNode = FocusNode();
  FocusNode bandwidthFocusNode = FocusNode();
  RxInt hoverIndex = 0.obs;
  String vbName = "";
  Rx<bool> loadStatus = false.obs;
  Rx<Map<String, dynamic>> info = Rx<Map<String, dynamic>>({});
  int minCpuSize = 4;
  int minMemorySize = 4;
  int minDiskSize = 50;
}
