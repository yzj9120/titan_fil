import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/page/task/pcdn/pcdn_page.dart';
import 'package:titan_fil/styles/app_text_styles.dart';

import '../../styles/app_colors.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 0, vertical: 32),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                PcdnPage(),
              ],
            ),
            Spacer(),
            Row(
              children: [
                Spacer(),
                Text(
                  'task_requirements_note'.tr,
                  style: AppTextStyles.textStyle12,
                ),
                SizedBox(width: 18),
              ],
            )
          ],
        ),
      ),
    );
  }
}
