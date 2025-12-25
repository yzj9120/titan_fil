import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../styles/app_colors.dart';
import 'device_status_section.dart';
import 'home_controller.dart';
import 'income_chart.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logic = Get.put(HomeController());
    return VisibilityDetector(
      key: Key('my-home-page'),
      onVisibilityChanged: (VisibilityInfo info) {
        logic.onVisibilityChanged(info);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeviceStatusSection(),
            Expanded(child: IncomeChart()),
          ],
        ),
      ),
    );
  }
}
