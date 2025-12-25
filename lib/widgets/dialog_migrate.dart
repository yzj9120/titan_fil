import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/plugins/native_app.dart';
import 'package:titan_fil/styles/app_text_styles.dart';
import 'package:titan_fil/utils/file_helper.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../constants/constants.dart';
import '../plugins/disk_plugins.dart';
import '../services/global_service.dart';
import '../styles/app_colors.dart';
import 'message_dialog.dart';

class MigrateDialog {
  static void show(
      BuildContext context, String path, String newPath, double totalSize,
      {Function? onFileCopyCall, Function? onStart, Function? onReMigrate}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProgressDialogWidget(
            path: path,
            newPath: newPath,
            totalSize: totalSize,
            onCall: onFileCopyCall,
            onStart: onStart,
            onReMigrate: onReMigrate,
          );
        });
  }
}

class ProgressDialogWidget extends StatefulWidget {
  final String path;
  final String newPath;
  final double totalSize;
  final Function? onCall;
  final Function? onStart;
  final Function? onReMigrate;

  const ProgressDialogWidget(
      {super.key,
      this.onCall,
      this.onStart,
      this.onReMigrate,
      required this.totalSize,
      required this.path,
      required this.newPath});

  @override
  _ProgressDialogWidget createState() => _ProgressDialogWidget();
}

class _ProgressDialogWidget extends State<ProgressDialogWidget> {
  Timer? _timer;
  double totalSize = 0;
  double progress = 0.0;
  double copySize = 0.0;
  String copyStep = "";
  String copyTime = "";

  dynamic itemCount = 0;
  dynamic copyItemCount = 0;
  int changeStorageStatus =
      0; //1 正在迁移，2: 迁移完成，3: 迁移异常  4:手动取消迁移;5 重新迁移完成, 运行中取消
  int elapsedTime = 0; // 经过的时间，单位秒
  double lastCopySize = 0;

  @override
  void initState() {
    super.initState();
    getFindFileCountAndSize();
  }

  // 获取原路径的数量+大小
  Future<void> getFindFileCountAndSize() async {
    try {
      totalSize = widget.totalSize;
      itemCount = await FileHelper.findFile("${widget.path}/");
      if (totalSize <= 0) {
        totalSize = await DiskPlugins.getFolderSize(widget.path);
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('getFindFile: $e');
    }
  }

  void startMonitoring() {
    if (copySize != lastCopySize) {
      elapsedTime++;
      lastCopySize = copySize;
    }
    double copySpeed = copySize / elapsedTime; // 每秒拷贝的速度，单位GB/s
    double remainingSize =
        totalSize * 1024 * 1024 * 1024 - copySize; // 剩余大小，单位GB
    double copyTimeSeconds = (remainingSize / copySpeed) * 1.5; // 预计剩余时间，单位秒
    if (copyTime.isEmpty) {
      copyTime = copyTimeSeconds.toTimeFormat();
    }
    double copySpeedKm = copySpeed / (1024 * 1024); // 千兆每秒
    String copySpeedFormatted = '${copySpeedKm.toStringAsFixed(2)} M/s';
    copyStep = copySpeedFormatted;
  }

  Future<void> startCopy() async {
    debugPrint("path=${widget.path}");
    final directory = Directory(widget.path);
    widget.onStart?.call();
    if (!await directory.exists()) {
      // 文件夹不存在时：直接迁移成功 写入配置
      _timer?.cancel();
      progress = 1;
      changeStorageStatus = 2;
      widget.onCall!(changeStorageStatus);
      setState(() {});
      return;
    }
    await PreferencesHelper.setString(Constants.copyFileStatus, "");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (changeStorageStatus == 2) {
        _timer?.cancel();
        _timer = null;
      } else {
        await getCopyItemCount();
        await getCopyFileSize();
        startMonitoring();
      }
    });
  }

  Future<void> getCopyItemCount() async {
    try {
      copyItemCount = await FileHelper.findFile(widget.newPath);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('copyItemCount: $e');
    }
  }

  Future<void> getCopyFileSize() async {
    try {
      //取文件大小 字节
      copySize =
          await DiskPlugins.getFolderSize(widget.newPath, format: 'bytes');
      changeStorageStatus = 1;
      if (copySize >= (totalSize * 1024 * 1024 * 1024) ||
          itemCount == copyItemCount) {
        _timer?.cancel();
        changeStorageStatus = 2;
      } else {
        progress = copySize / (totalSize * 1024 * 1024 * 1024);
      }
      String hasKill =
          await   PreferencesHelper.getString(Constants.copyFileStatus) ?? "";
      if (hasKill == "kill") {
        _timer?.cancel();
        changeStorageStatus = 3;
        widget.onCall!(changeStorageStatus);
      } else if (hasKill == "ok") {
        _timer?.cancel();
        progress = 1;
        changeStorageStatus = 2;
        widget.onCall!(changeStorageStatus);
      } else if (hasKill == "cancel") {
        _timer?.cancel();
        changeStorageStatus = 6;
        widget.onCall!(changeStorageStatus);
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('copyItemCount: $e');
    }
  }

  //取消修改
  Future<void> onKill(BuildContext context) async {
    Future<void> _onAction() async {
      _timer?.cancel();
      Navigator.of(context).pop();
      String hasKill =
          await PreferencesHelper.getString(Constants.copyFileStatus) ?? "";
      if (hasKill == "ok") {
        widget.onCall!(2);
        return;
      }
      var res = await NativeApp.stopCopy();
      if (res == "ok") {
        await PreferencesHelper.setString(
            Constants.copyFileStatus, "cancel");
      }
    }

    if (changeStorageStatus == 1) {
      MessageDialog.show(
        context: context,
        config: MessageDialogConfig(
          titleKey: "settings_storage_killTitle".tr,
          messageKey: "settings_storage_killContent".tr,
          iconType: DialogIconType.error,
          buttonTextKey: "confirm".tr,
          onAction: () => _onAction(),
          cancelButtonTextKey: "cancel".tr,
        ),
      );
    } else {
      changeStorageStatus = 4;
      Navigator.of(context).pop();
      widget.onCall!(changeStorageStatus);
    }
  }

  int elapsedTime2 = 0; // 经过的时间，单位秒
  double lastCopySize2 = 0;

  //重新迁移
  Future<void> onReMigrate() async {
    var ollProgress = progress;
    await PreferencesHelper.setString(Constants.copyFileStatus, "");
    setState(() {
      // copySize = 0;
      // progress = 0;
      // itemCount = copyItemCount = 0;
      changeStorageStatus = 1;
    });
    widget.onReMigrate?.call();
    //单位字节
    var ptahTotalSize = totalSize;
    // await NativeTool.getFolderSize(widget.path, format: 'bytes');
    // 已经复制过的大小
    var newPathTotalSize = await DiskPlugins.getFolderSize(widget.newPath);
    itemCount = await FileHelper.findFile(widget.path);
    // 从新迁移时更新数据库中历史数据残留文件的大小：
    // var list = HiveUtils.historyGetList();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        // 现在复制的总大小
        var moveSize = await DiskPlugins.getFolderSize(widget.newPath);
        copySize =
            double.parse((moveSize - (newPathTotalSize)).toStringAsFixed(3));
        copyItemCount = await FileHelper.findFile(widget.newPath);
        progress = ollProgress + copySize / (ptahTotalSize ?? 1);
        if (progress < 0) {
          progress = 0;
        }
        if (copySize != lastCopySize2) {
          elapsedTime2++;
          lastCopySize2 = copySize;
        }
        if (copySize < 0) {
          copySize = 0;
        }
        double copySpeed =
            elapsedTime2 != 0 ? copySize / elapsedTime2 : 1; // 每秒拷贝的速度，单位GB/s
        double remainingSize = ptahTotalSize - copySize; // 剩余大小，单位GB
        double copyTimeSeconds = (remainingSize / copySpeed) < 0
            ? 0
            : (remainingSize / copySpeed); // 预计剩余时间，单位秒

        if (copyTime.isEmpty && copyTime == "0") {
          copyTime = copyTimeSeconds.toTimeFormat();
        }
        double copySpeedKm = copySpeed < 0 ? 0 : copySpeed * 1024; // 千兆每秒
        String copySpeedFormatted = '${copySpeedKm.toStringAsFixed(2)} M/s';
        copyStep = copySpeedFormatted;
        // if (list.isNotEmpty) {
        //   var bean = list[0];
        //   HiveUtils.historyUpdate("${bean.hId}",
        //       time: bean.time,
        //       size: "${remainingSize.toStringAsFixed(2)}GB",
        //       oldPath: bean.oldPath,
        //       newPath: bean.newPath,
        //       status: bean.status);
        // }
        if (progress > 1) {
          progress = 1;
        }
        String hasKill =
            await PreferencesHelper.getString(Constants.copyFileStatus) ?? "";
        if (hasKill == "ok") {
          await Future.delayed(const Duration(seconds: 1));
          progress = 1;
          _timer?.cancel();
          changeStorageStatus = 2;
          widget.onCall!(changeStorageStatus);
        } else if (hasKill == "kill") {
          _timer?.cancel();
          changeStorageStatus = 3;
          widget.onCall!(changeStorageStatus);
        } else if (hasKill == "cancel") {
          _timer?.cancel();
          changeStorageStatus = 6;
          widget.onCall!(changeStorageStatus);
        }
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        debugPrint('copyItemCount: $e');
      }
    });
  }

  //关闭程序
  Future<void> onCloseApp() async {
    Navigator.pop(context);
    widget.onCall!(100);
    // NativeTool.restartApplication();
  }

  @override
  void dispose() {
    try {
      _timer?.cancel();
    } catch (e) {}

    super.dispose();
  }

  Widget _containerGroup(int tag, Widget child, {Function? onSubmit}) {
    return GestureDetector(
      onTap: () {
        onSubmit?.call();
      },
      child: Container(
        width: 480,
        height: 84,
        margin: tag == 0
            ? const EdgeInsets.all(15)
            : const EdgeInsets.only(left: 15, right: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF353535),
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }

  final GlobalService globalService = Get.find<GlobalService>();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          height: globalService.localeController.locale() == 0 ? 600 : 540,
          width: 580 / 1.5,
          decoration: const BoxDecoration(
            color: Color(0xFF2E2E2E),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 26),
                SizedBox(
                  width: 120 / 1.5,
                  height: 120 / 1.5,
                  child: Assets.images.icLogo2.image(),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 12, left: 40, right: 40),
                  child: Text(
                    Platform.isMacOS
                        ? "settings_storage_migration_restart".tr
                        : 'settings_storage_migration_restart'.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textStyle15,
                  ),
                ),
                const SizedBox(height: 30),
                _containerGroup(
                  0,
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'settings_storage_migration_pathBefore'.tr,
                              style: AppTextStyles.textStyle12white,
                            ),
                            const Spacer(),
                            Text(
                              "${totalSize} GB",
                              style: AppTextStyles.textStyle12white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                            child: Text(
                          widget.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(125),
                            fontSize: 11,
                          ),
                        )),
                      ],
                    ),
                  ),
                  onSubmit: () {},
                ),
                _containerGroup(
                  1,
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'settings_storage_migration_pathAfter'.tr,
                              style: AppTextStyles.textStyle12white,
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                            child: Text(
                          widget.newPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withAlpha(125),
                            fontSize: 11,
                          ),
                        ))
                      ],
                    ),
                  ),
                ),
                if (changeStorageStatus == 0) ...[
                  const SizedBox(height: 62 / 1.5),
                  SizedBox(
                    width: 480 / 1.5,
                    height: 62 / 1.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () {
                        startCopy();
                      },
                      child: Text('settings_storage_migration_pathData'.tr),
                    ),
                  )
                ] else if (changeStorageStatus == 1) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20, right: 5),
                        child: Text(
                          "${'settings_storage_migrating_load'.tr}：${(progress * 100).toInt()}% ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (itemCount - copyItemCount > 0) ...{
                        Container(
                          margin: EdgeInsets.only(top: 20),
                          child: Text(
                            'settings_storage_migration_copy_fileDes4'
                                .tr
                                .replaceAll(
                                    "#", "${(itemCount - copyItemCount)}"),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        )
                      },
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text(
                      "$copyStep ${'settings_storage_migration_completion_time'.tr}：$copyTime ",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Container(
                    height: 10,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    width: 360,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: LinearProgressIndicator(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                               AppColors.themeColor),
                            value: progress)),
                  )
                ] else if (changeStorageStatus == 2) ...{
                  Container(
                    margin: EdgeInsets.only(top: 48),
                    child: Text(
                      totalSize < 5
                          ? 'settings_storage_migration_success2'.tr
                          : 'settings_storage_migration_success'.tr,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Container(
                    height: 10,
                    margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
                    width: 360,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                        child: LinearProgressIndicator(
                            backgroundColor: Colors.black.withOpacity(0.6),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.themeColor),
                            value: 1)),
                  )
                } else if (changeStorageStatus == 3) ...{
                  Container(
                    margin: const EdgeInsets.only(top: 25, bottom: 10),
                    child: Text(
                      'settings_storage_fail_migration'.tr,
                      style: TextStyle(
                        color: Colors.red.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 480 / 1.5,
                    height: 62 / 1.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () {
                        onReMigrate();
                      },
                      child: Text('settings_storage_re_migration'.tr),
                    ),
                  )
                },
                if (changeStorageStatus != 2) ...{
                  GestureDetector(
                    onTap: () {
                      onKill(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Text("settings_storage_cancel_migration".tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                            decorationColor: Colors.white38,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2.0,
                          )),
                    ),
                  )
                } else if (changeStorageStatus == 2) ...{
                  GestureDetector(
                    onTap: () {
                      onCloseApp();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Text("settings_storage_complete_migration".tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            decorationColor: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2.0,
                          )),
                    ),
                  )
                },
                // GestureDetector(
                //   onTap: () {
                //     _text();
                //   },
                //   child: const Text("kill",
                //       style: TextStyle(
                //         fontSize: 16,
                //         color: Colors.white,
                //         decorationColor: Colors.white,
                //         decoration: TextDecoration.underline,
                //         decorationThickness: 2.0,
                //       )).withMargin(const EdgeInsets.only(top: 20)),
                // )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
