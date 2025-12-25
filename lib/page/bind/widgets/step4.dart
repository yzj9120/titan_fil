import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/utils/app_helper.dart';

import '../../../gen/assets.gen.dart';
import '../bind_controller.dart';

class Step4 extends StatelessWidget {
  const Step4({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<BindController>();

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Assets.images.icEmailIcon.image(width: 15),
              SizedBox(width: 3),
              Text(
                'bind_email'.tr,
                style: AppTextStyles.textStyle12gray,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${logic.state.userData.value.account}',
            style: AppTextStyles.textStyle15,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Assets.images.icWalletIcon.image(width: 15),
              SizedBox(width: 3),
              Text(
                'bindUSDCWallet'.tr,
                style: AppTextStyles.textStyle12gray,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Obx(() {
            if (logic.state.userData.value.addressEth.isEmpty) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () {
                    _showBottomSheet2(context, onCall: () {
                      logic.onViewOpenUSDC(context);
                    });
                  },
                  child: Container(
                    width: 102,
                    height: 41,
                    decoration: BoxDecoration(
                      color: AppColors.themeColor,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('bind_click_why'.tr,
                            style: AppTextStyles.textStyle12black
                                .copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(width: 3),
                        Assets.images.icBindWWh.image(width: 15)
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${logic.state.userData.value.addressEth}'.abbreviate(),
                      style: AppTextStyles.textStyle15),
                  InkWell(
                    onTap: () {
                      AppHelper.onCopy(
                        context,
                        'bindUSDCWallet'.tr,
                        '${logic.state.userData.value.addressEth}',
                      );
                    },
                    child: Text('\u{1F4CB}', style: TextStyle(fontSize: 14)),
                  ),
                ],
              );
            }
          }),
          const SizedBox(height: 18),
          Row(
            children: [
              Assets.images.icWalletIcon.image(width: 15),
              SizedBox(width: 3),
              Text(
                logic.state.userData.value.address.isEmpty
                    ? 'bind_wallet'.tr
                    : "bind_wallet2".tr,
                style: AppTextStyles.textStyle12gray,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            if (logic.state.userData.value.address.isEmpty) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () {
                    _showBottomSheet(context, onCall: () {
                      logic.onViewOpen(context);
                    });
                  },
                  child: Container(
                    width: 102,
                    height: 41,
                    decoration: BoxDecoration(
                      color: AppColors.themeColor,
                      borderRadius: BorderRadius.all(Radius.circular(22)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('bind_click_why'.tr,
                            style: AppTextStyles.textStyle12black
                                .copyWith(fontWeight: FontWeight.bold)),
                        SizedBox(width: 3),
                        Assets.images.icBindWWh.image(width: 15)
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${logic.state.userData.value.address}'.abbreviate(),
                      style: AppTextStyles.textStyle15),
                  InkWell(
                    onTap: () {
                      AppHelper.onCopy(
                        context,
                        'bind_wallet'.tr,
                        '${logic.state.userData.value.address}',
                      );
                    },
                    child: Text('\u{1F4CB}', style: TextStyle(fontSize: 14)),
                  ),
                ],
              );
            }
          })
        ],
      );
    });
  }

  void _showBottomSheet(BuildContext ctx, {required Function onCall}) {
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
                width: 400,
                height: 250,
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 24, 24, 24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                "bind_click_wallet_view".tr,
                                style: AppTextStyles.textStyle15,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Colors.white30,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 36),
                    Text("bind_wallet_help_content".tr,
                        style: AppTextStyles.textStyle12),
                    SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.textStyle12, // 默认样式
                        children: [
                          TextSpan(
                            text: "bind_wallet_tip".tr,
                          ),
                          TextSpan(
                            text: " ".tr,
                          ),
                          TextSpan(
                            text: "bind_click_to_view".tr,
                            style: AppTextStyles.textUnderline.copyWith(
                              fontSize: 12,
                              color: AppColors.themeColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).pop();
                                onCall.call();
                              },
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        );
      },
    ).then((_) {});
  }

  void _showBottomSheet2(BuildContext ctx, {required Function onCall}) {
    showDialog(
      context: ctx,
      builder: (BuildContext context) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
                width: 400,
                height: 250,
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 24, 24, 24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Text(
                                "bindUSDCWallet_note".tr,
                                style: AppTextStyles.textStyle15,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Colors.white30,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 36),
                    Text("bindUSDCWallet_note2".tr,
                        style: AppTextStyles.textStyle12),
                    SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.textStyle12, // 默认样式
                        children: [
                          TextSpan(
                            text: "bindUSDCWallet_note3".tr,
                          ),
                          TextSpan(
                            text: " ".tr,
                          ),
                          TextSpan(
                            text: "bindUSDCWallet_note4".tr,
                            style: AppTextStyles.textUnderline.copyWith(
                              fontSize: 12,
                              color: AppColors.themeColor,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.of(context).pop();
                                onCall.call();
                              },
                          ),
                        ],
                      ),
                    )
                  ],
                )),
          ),
        );
      },
    ).then((_) {});
  }
}
