import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/setting/pcdn/set_pcdn_page.dart';
import 'package:titan_fil/page/setting/setting_controller.dart';
import 'package:titan_fil/styles/app_colors.dart';

import './side_menu.dart';
import 'about/setting_about.dart';
import 'bug/bug_page.dart';
import 'logs/logs_page.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logic = Get.find<SettingController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => SideMenu(
                selectedIndex: logic.state.selectedIndex.value,
                onItemSelected: (index) {
                  logic.onChangeIndex(index);
                },
              )),
          Obx(() => Expanded(
                child: RepaintBoundary(
                  child: (() {
                    switch (logic.state.selectedIndex.value) {

                      case 0:
                        return SetPcdnPage();
                      case 1:
                        return LogsPage();
                      case 2:
                        return BugPage();
                      case 3:
                        return SettingAbout();
                      default:
                        return Container();

                    }
                  })(),
                ),
              )),
        ],
      ),
    );
  }
}
