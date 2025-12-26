import 'package:get/get.dart';

import '../models/Steps.dart';
import '../page/task/pcdn/child/env_controller.dart';
import '../services/global_service.dart';

class BasePlugin {
  final globalService = Get.find<GlobalService>();

  List<Steps> basicSteps = <Steps>[];
  int stepIndex = 0;

  List<Steps> getBasicSteps() => basicSteps;

  int getStepIndex() => stepIndex;

  final String powershell =
      r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';
  final String cmd = r'C:\Windows\System32\cmd.exe';
  final String setx = r'C:\Windows\System32\setx.exe';

  void setDada(int tag) {
    basicSteps.clear();
    if (tag == 1) {
      basicSteps.addAll([
        Steps(title: "pcd_virtualBoxCheck"),
        Steps(title: "pcd_multiPassCheck"),
        Steps(title: "pcd_vmCheck"),
        Steps(title: "pcd_ubuntuUnlink"),
        Steps(title: "pcd_systemBootCommand"),
      ]);
    } else if (tag == 2) {
      basicSteps.addAll([
        Steps(title: "pcd_hyperVCheck"),
        Steps(title: "pcd_hyperVStatusCheck"),
        Steps(title: "pcd_multiPassCheck"),
        Steps(title: "pcd_vmCheck"),
        Steps(title: "pcd_ubuntuUnlink"),
        Steps(title: "pcd_systemBootCommand"),
      ]);
    } else {
      basicSteps.addAll([
        Steps(title: "pcd_multiPassCheck"),
        Steps(title: "pcd_ubuntuUnlink"),
        Steps(title: "pcd_systemBootCommand"),
      ]);
    }
  }

  void uploadData() {
    final logic = Get.find<EnvController>();
    basicSteps.forEach((step) {
      step.isActive = false; // 修改为激活状态
      step.status = false; // 假设状态成功
    });
    logic.state.basicSteps.refresh();
    logic.state.stepIndex.value = 0;
    logic.state.stepIndex.refresh();
  }

  // 用于更新步骤的状态
  Future<void> updateStep(int stepIndex, dynamic status, String subtitle,
      {bool isActive = true,
      String? des,
      String? txt,
      Function? onTap,
      Function? onRetry}) async {
    upDateBasicSteps(
      stepIndex,
      isActive,
      status,
      subtitle,
      des: des,
      txt: txt,
      onTap: onTap,
      onRetry: onRetry,
    );
  }

  void upDateBasicSteps(int index, bool isActive, bool status, String subtitle,
      {String? des, String? txt, Function? onTap, Function? onRetry}) {
    if (index >= 0 && index < basicSteps.length) {
      final logic = Get.find<EnvController>();
      basicSteps[index].isActive = isActive;
      basicSteps[index].status = status;
      basicSteps[index].subtitle = subtitle;
      basicSteps[index].des = des;
      basicSteps[index].txt = txt;
      basicSteps[index].onTap = onTap;
      basicSteps[index].onRetry = onRetry;
      logic.state.basicSteps.value = getBasicSteps();
      logic.state.stepIndex.value = status ? index + 1 : index;
      logic.state.basicSteps.refresh();
      logic.state.stepIndex.refresh();
    }
  }
}
