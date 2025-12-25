import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/config/app_config.dart';
import 'package:titan_fil/page/index/side_menu.dart';

import '../../styles/app_colors.dart';
import '../bind/bind_page.dart';
import '../home/home_page.dart';
import '../setting/setting_page.dart';
import '../task/task_page.dart';
import 'index_controller.dart';

class IndexPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logic = Get.put(IndexController());
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
                        return HomePage();
                      case 1:
                        return TaskPage();
                      case 2:
                        return BindPage();
                      case 3:
                        return SettingPage();
                      default:
                        return Center(
                          child: Text(
                            "${AppConfig.isDebug ? "debug" : "release"}",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        );
                    }
                  })(),
                ),
              )),
        ],
      ),
    );
  }
}
