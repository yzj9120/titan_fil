import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/widgets/LoadingWidget.dart';

import '../../../../models/bug_picture.dart';
import '../bug_controller.dart';

class PageFeedbackSuggestPage extends StatelessWidget {
  final logic = Get.find<BugController>();
  var textFieldBorder = const OutlineInputBorder(
    borderSide: BorderSide(
      color: Colors.transparent,
      width: 0,
    ),
  );

  var testStyle = const TextStyle(fontSize: 12, color: Color(0xFFFFFFFF));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.c1818,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text("${"bug_nodeId".tr}:",
                        style: testStyle.copyWith(color: Colors.white38)),
                    SizedBox(width: 5),
                    Text("${logic.state.nodeId.value}", style: testStyle)
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("${"bug_email".tr}:",
                        style: testStyle.copyWith(color: Colors.white38)),
                    SizedBox(width: 5),
                    Text("${logic.state.email.value}", style: testStyle)
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'bug_telegram'.tr,
              style: testStyle.copyWith(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 50,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.c1818,
              borderRadius: BorderRadius.circular(22),
            ),
            child: MouseRegion(
              child: Center(
                child: TextField(
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  inputFormatters: [
                    // 允许除汉字以外的所有字符
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[^\u4e00-\u9fa5]'),
                    ),
                  ],
                  controller: logic.state.telegramController,
                  decoration: InputDecoration(
                    enabledBorder: textFieldBorder,
                    disabledBorder: textFieldBorder,
                    focusedBorder: textFieldBorder,
                    contentPadding: const EdgeInsets.only(
                        top: 0, bottom: 0, left: 20, right: 20),
                    hintText: "bug_telegramDsc".tr,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) async {
                    await Future.delayed(const Duration(seconds: 2));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'bug_questionDsc'.tr,
              style: testStyle.copyWith(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            alignment: Alignment.center,
            height: 100,
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.c1818,
              borderRadius: BorderRadius.circular(22),
            ),
            child: MouseRegion(
              child: TextField(
                maxLines: null,
                // 设置为 null 启用多行输入
                minLines: 3,
                // 设置最小行数
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                controller: logic.state.contentController,
                decoration: InputDecoration(
                  enabledBorder: textFieldBorder,
                  disabledBorder: textFieldBorder,
                  focusedBorder: textFieldBorder,
                  contentPadding: const EdgeInsets.only(
                      top: 10, bottom: 10, left: 20, right: 20),
                  hintText: "bug_questionDsc".tr,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) async {
                  await Future.delayed(const Duration(seconds: 2));
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<List<BugPicture>>(
            valueListenable: logic.state.picListNotifier,
            builder: (context, list, child) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  BugPicture bean = list[index];
                  return InkWell(
                    onTap: () {
                      logic.pickImage(index, context);
                    },
                    child: Stack(children: [
                      Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 5),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: Alignment.center,
                        child: bean.type == -1
                            ? const Icon(
                                Icons.add,
                                color: AppColors.themeColor,
                              )
                            : CachedNetworkImage(
                                imageUrl: bean.url,
                                placeholder: (context, url) => const Center(
                                  child: LoadingWidget(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Visibility(
                        visible: bean.url.isNotEmpty,
                        child: Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            child: const Icon(
                              Icons.highlight_remove,
                              color: Colors.white10,
                              size: 15,
                            ),
                            onTap: () {
                              logic.onRemovePicker(index);
                            },
                          ),
                        ),
                      ),
                      Visibility(
                        visible: bean.progress < 1.0,
                        child: Positioned.fill(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.transparent,
                                value: bean.progress,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.themeColor),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 100),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: () {
                _openDialog(context, logic);
              },
              child: Container(
                width: 238,
                height: 45,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.themeColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'submit'.tr,
                  style: testStyle.copyWith(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDialog(BuildContext context, BugController logic) {
    if (!logic.onCheck(context)) {
      return;
    }
    _showModalBottomSheet(context, logic);
  }

  void _showModalBottomSheet(BuildContext _context, BugController logic) {
    showDialog(
      // backgroundColor: Color(0x181818FF),
      context: _context,
      builder: (BuildContext context) {
        int selectIndex = 0;
        return StatefulBuilder(
          builder: (context, setState) {
            return Material(
                color: Colors.transparent.withOpacity(0.5),
                child: Center(
                  child: Container(
                    height:
                        logic.globalService.localeController.isChineseLocale()
                            ? 300
                            : 320,
                    width: 400,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF181818),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 10,
                            ),
                            Container(
                              width: 300,
                              margin: const EdgeInsets.only(top: 5),
                              child: Text(
                                'bug_feedbackDes'.tr,
                                style: const TextStyle(
                                    fontSize: 12.0, color: Colors.white38),
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: const Icon(
                                Icons.clear,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(10.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: logic.globalService.localeController
                                        .isChineseLocale() ==
                                    1
                                ? logic.state.feedbackTypeListCn.length
                                : logic.state.feedbackTypeListEn.length,
                            //
                            // 项目总数
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectIndex = index;
                                  });
                                },
                                child: Container(
                                  // width: width,
                                  height: 120,
                                  margin: const EdgeInsets.all(10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selectIndex == index
                                        ? AppColors.themeColor
                                        : const Color(0xFF2D2D2D),
                                    // Hex color value
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20)),
                                  ),
                                  child: Text(
                                    logic.globalService.localeController
                                            .isChineseLocale()
                                        ? logic.state.feedbackTypeListCn[index]
                                        : logic.state.feedbackTypeListEn[index],
                                    style: TextStyle(
                                        color: selectIndex == index
                                            ? Colors.black
                                            : AppColors.themeColor),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (selectIndex == 2) {
                              logic.state.feedbackType = 4;
                            } else {
                              logic.state.feedbackType = selectIndex + 1;
                            }
                            Navigator.of(context).pop();
                            logic.onSubmit(_context);
                          },
                          child: Container(
                            width: 320,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.themeColor, // Background color
                              borderRadius: BorderRadius.all(
                                  Radius.circular(85)), // Border radius
                            ),
                            child: Text(
                              "confirm".tr,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ));
          },
        );
      },
    );
  }
}
