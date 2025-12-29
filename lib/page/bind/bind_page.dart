import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/controllers/locale_controller.dart';
import 'package:titan_fil/page/bind/widgets/step1.dart';
import 'package:titan_fil/page/bind/widgets/step2.dart';
import 'package:titan_fil/page/bind/widgets/step3.dart';
import 'package:titan_fil/page/bind/widgets/step4.dart';
import 'package:titan_fil/page/bind/widgets/stepkey.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../gen/assets.gen.dart';
import '../../widgets/LoadingWidget.dart';
import 'bind_controller.dart';

class BindPage extends StatelessWidget {
  get localeController => Get.find<LocaleController>();

  @override
  Widget build(BuildContext context) {
    final logic = Get.put(BindController());

    Widget _buildTitleWidget(int bindStatus) {
      String title = "";
      if(bindStatus==0){
        title = "bind_title3".tr;
      }else{
        title = "bind_title".tr;
      }


      return Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    Widget _buildDesWidget(int bindStatus) {
      String title = "";
      if(bindStatus==0){
        title = "bind_subtitle2".tr;
      }else{
        title = "bind_subtitle".tr;
      }
      if (bindStatus == 0) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Assets.images.icTaskCheckOk.image(width: 15),
                SizedBox(width: 3),
                Text(
                  title,
                  style: AppTextStyles.textStyle10white,
                )
              ],
            ),
            Text(
              "bind_subtitle2_1".tr,
              style: AppTextStyles.textStyle10,
            ),
          ],
        );
      }
      return Text(
        title,
        style: AppTextStyles.textStyle10,
      );
    }

    // 辅助方法：判断是否可编辑
    bool _shouldEdit(int bindStatus) {
      return bindStatus !=0; // 邮箱不为空不可编辑
    }

    Widget _buildStepWidget(int bindStatus) {
      // 定义步骤映射表
      final stepWidgets = {
        1: Step1(isEdit: _shouldEdit(bindStatus)),
        2: Step2(isEdit: _shouldEdit(bindStatus)),
        3: Step3(),
        4: Step4(),
      };

      // 根据状态返回对应组件
      if (bindStatus == 0) return stepWidgets[4]!;

      if (bindStatus >= 1 && bindStatus <= 3) {
        return stepWidgets[logic.state.step.value] ??
            LoadingWidget(radius: 10, strokeWidth: 2);
      }

      return const SizedBox();
    }

    return VisibilityDetector(
        key: Key('my-bind-key'),
        onVisibilityChanged: (VisibilityInfo info) {
          logic.onVisibilityChanged(info);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Container(
              child: Center(
                child: Container(
                  width: 365,
                  // height: 350,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 29, vertical: 27),
                  decoration: BoxDecoration(
                    color: AppColors.tipColor,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Obx(() => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text("${logic.state.bindStatus.value}",style: TextStyle(color: Colors.red),),
                          Row(
                            children: [
                              if (!logic.state.load.value) ...{
                                Text(
                                  "bind_title".tr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              } else ...{
                                _buildTitleWidget(logic.state.bindStatus.value),
                                SizedBox(width: 5),
                              },
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (!logic.state.load.value) ...{
                            Container(
                              margin: EdgeInsets.only(
                                  left: 135, top: 50, bottom: 100),
                              child: LoadingWidget(
                                radius: 20,
                                strokeWidth: 2,
                              ),
                            )
                          } else ...{
                            StepKey()
                            // Step4()
                            // _buildDesWidget(logic.state.bindStatus.value),
                            // const SizedBox(height: 42),
                            // _buildStepWidget(logic.state.bindStatus.value),
                          }
                        ],
                      )),
                ),
              ),
            ),
          ),
        ));
  }
}
