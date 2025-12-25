/**
 * 主界面控制器
 */

import 'package:get/get.dart';
import 'package:titan_fil/page/setting/setting_state.dart';

class SettingController extends GetxController {
  final SettingPageState state = SettingPageState();

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

  void onChangeIndex(int index) {
    state.selectedIndex.value = index;
  }
}
