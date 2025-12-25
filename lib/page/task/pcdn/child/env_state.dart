import 'package:get/get.dart';

import '../../../../models/Steps.dart';

class EnvState {
  bool isCheckAgent = false;
  bool hasCloseDialog = false;
  RxList<Steps> basicSteps = <Steps>[].obs;
  Rx<int> stepIndex = 0.obs;
  Rx<int> timerCount = 3.obs;
  Rx<bool> hasClose = false.obs;
}
