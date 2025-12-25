import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/utils/app_helper.dart';
import 'package:titan_fil/widgets/text_widget.dart';

import '../controllers/app_controller.dart';
import '../utils/FileDownloader.dart';
import '../utils/FileLogger.dart';
import 'message_dialog.dart';

class UpdateAppWidget extends StatefulWidget {
  final double? height;
  final int tag;
  final VoidCallback? onCallback;

  const UpdateAppWidget({
    super.key,
    this.height = 720,
    this.tag = 0,
    this.onCallback,
  });

  @override
  State<UpdateAppWidget> createState() => _UpdateAppWidgetState();
}

class _UpdateAppWidgetState extends State<UpdateAppWidget> {
  int _isDownloading = 0; // -1 下载失败，0 默认 1：下载中；2 下载成功
  double _progress = 0.0;
  String _progressStr = "";
  CancelToken _downloadCancelToken = CancelToken();
  int downloadMethod = 1; //1 aws
  Timer? _downloadTimer;
  final logic = Get.find<AppController>();
  @override
  void dispose() {
    _downloadTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    if (widget.tag == 2) {
      FileLogger.log('UpdateApp：initiate');
      _onUpdate(logic);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Stack(
          children: [
            Container(
              width: 500,
              height: 450,
              decoration: widget.tag == 0 || widget.tag == 2
                  ? BoxDecoration(
                      color: AppColors.minaColor,
                      borderRadius: BorderRadius.circular(15),
                    )
                  : null,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Assets.images.icLogo2.image(width: 100),
                  const SizedBox(height: 20),
                  Obx(() => Text(
                        "V${logic.localVersion.value}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 22),
                      )),
                  const SizedBox(height: 5),
                  Text(
                    'update_app_current_Version'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => _isDownloading == 1
                      ? _buildProgressBar()
                      : _isDownloading == -1
                          ? _buildActionFaiLButton(logic)
                          : _isDownloading == 2
                              ? _buildActionOkButton(logic)
                              : _buildActionButton(logic)),
                  const SizedBox(height: 20),
                  if (logic.bUpdate.value) _buildWebLink(logic),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            if (widget.tag == 0 || widget.tag == 2)
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _onClose(context, logic),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.close, color: Colors.white30, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 下载成功
  Widget _buildActionOkButton(AppController logic) {
    return Column(
      children: [
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 70),
            child: Text(
              "hot_tip6".tr,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 15),
        _buildBtn(
          name: "hot_tip7".tr,
          enabled: logic.bUpdate.value,
          onPressed: logic.bUpdate.value ? () => installApp(logic) : null,
        ),
      ],
    );
  }

  /// 下载失败
  Widget _buildActionFaiLButton(AppController logic) {
    return Column(
      children: [
        Center(
          child: Text(
            "error_exception".tr,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        SizedBox(height: 15),
        _buildBtn(
          name: "update_app_check_latestVersion2".tr,
          enabled: logic.bUpdate.value,
          onPressed: logic.bUpdate.value ? () => _onUpdate(logic) : null,
        ),
      ],
    );
  }

  /// 下载按钮或已是最新提示
  Widget _buildActionButton(AppController logic) {
    final btnText = logic.bUpdate.value
        ? "${'update_app_check_latestVersion'.tr} V${logic.remoteVersion}"
        : 'update_app_already_latest_Version'.tr;

    return _buildBtn(
      name: btnText,
      enabled: logic.bUpdate.value,
      onPressed: logic.bUpdate.value
          ? () => widget.tag == 0 ? _onUpdate(logic) : widget.onCallback?.call()
          : null,
    );
  }

  /// 构建统一按钮
  Widget _buildBtn({
    required String name,
    required bool enabled,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 38,
      width: 250,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              color: enabled ? AppColors.themeColor : const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(40),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: TextStyle(
                color: enabled ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 进度条
  Widget _buildProgressBar() {
    return Column(
      children: [
        Center(
          child: Text(
            "${'downloadInstallationPackage'.tr}: ${_progressStr}",
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: 15,
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              backgroundColor: Colors.black.withOpacity(0.6),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.themeColor),
              value: _progress,
            ),
          ),
        ),
      ],
    );
  }

  /// 备用下载链接
  Widget _buildWebLink(AppController logic) {
    return GestureDetector(
      onTap: () {
        final webUrl = logic.updateData?.url;
        if (webUrl != null && webUrl.isNotEmpty) {
          AppHelper.openUrl(context, webUrl);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            TextWidget(
              'update_app_down_error'.tr,
              color: AppColors.themeColor,
              fontSize: 12,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: const Offset(0, 2),
                child: Container(
                  height: 1,
                  color: AppColors.themeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 检查本地是否已存在下载文件
  Future<bool> _checkExistingFile(AppController logic) async {
    try {
      final filePath = await _getDownloadFilePath(logic);
      await FileLogger.log('UpdateApp：filePath: $filePath');
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await FileLogger.log('UpdateApp：delete: $filePath');
        return true;
      } else {
        await FileLogger.log('UpdateApp：file not file: $filePath');
      }
    } catch (e) {
      await FileLogger.log('UpdateApp：file error: $e');
    }
    return false;
  }

  /// 获取完整文件保存路径
  Future<String> _getDownloadFilePath(AppController logic) async {
    final dir = await getApplicationDocumentsDirectory();
    final version = logic.remoteVersion.value;
    final extension = Platform.isMacOS ? "_titan.dmg" : "_titan.exe";
    return '${dir.path}/downloadFile/$version$extension';
  }

  void _onClose(BuildContext context, AppController logic) {
    if (_isDownloading == 1) {
      MessageDialog.show(
        context: context,
        config: MessageDialogConfig(
          titleKey: "gentleReminder".tr,
          messageKey: "hot_tip5".tr,
          iconType: DialogIconType.info,
          buttonTextKey: "confirm".tr,
          onAction: () async {
            setState(() {
              _isDownloading = 0;
              _progress = 0;
            });
            final filePath = await _getDownloadFilePath(logic);
            await cancelDownload(filePath);
            Navigator.of(context).pop();
          },
          cancelButtonTextKey: "cancel".tr,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  /// 取消下载并清理
  Future<void> cancelDownload(String savePath) async {
    try {
      if (!_downloadCancelToken.isCancelled) {
        _downloadCancelToken.cancel();
      }
      final file = File(savePath);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('cancelDownload error: $e');
    }
  }

  Future<void> installApp(AppController logic) async {
    try {
      final filePath = await _getDownloadFilePath(logic);
      // 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        _onUpdate(logic);
      } else {
        Future.delayed(const Duration(seconds: 2)).then((_) {
          exit(0);
        });
        await Process.run('cmd', ['/c', 'start', '', filePath],
            runInShell: true);
      }
    } catch (e) {
      debugPrint('安装异常: ${e.toString()}');
      _onUpdate(logic);
    }
  }

  /// 更新流程入口
  Future<void> _onUpdate(AppController logic) async {
    await _checkExistingFile(logic);
    setState(() {
      _isDownloading = 1;
      _progress = 0;
    });

    bool result = false;
    await FileLogger.log('UpdateApp：_onUpdate: start');
    // 第一次尝试方式1
    await FileLogger.log('UpdateApp：aws: start');
    result = await _startFileDownload(logic);
    await FileLogger.log('UpdateApp：aws: result=$result');
    if (!result) {
      await FileLogger.log('UpdateApp：storage: result:$result');
    }
    await FileLogger.log('UpdateApp: result: $result');
    if (!result) {
      setState(() {
        _isDownloading = -1;
        _progress = 0;
      });
      final webUrl = logic.updateData?.url ?? "";
      _showDownloadFailedDialog(webUrl);
    }
  }

  /// 更新进度状态
  void updateProgress({
    required num? doneSize,
    required num? totalSize,
  }) {
    final double safeDoneSize = (doneSize ?? 0).toDouble();
    final double safeTotalSize =
        (totalSize == null || totalSize <= 0) ? 1 : totalSize.toDouble();
    final double progress = (safeDoneSize / safeTotalSize).clamp(0.0, 1.0);
    setState(() {
      _progress = progress;
      _progressStr = '${(progress * 100).toStringAsFixed(1)}%';
    });
  }

  /// 下载方式1：Dio + CancelToken
  Future<bool> _startFileDownload(AppController logic) async {
    final savePath = await _getDownloadFilePath(logic);
    final url = logic.updateData?.downUrl ?? '';
    final result = await FileDownloader.download(
      fileUrl: url,
      savePath: savePath,
      cancelToken: _downloadCancelToken,
      onProgress: (received, total) {
        updateProgress(
          doneSize: received,
          totalSize: total,
        );
      },
    );
    if (result) {
      setState(() {
        _isDownloading = 2;
      });
      //OpenFile.open(savePath);
      return true;
    } else {
      await cancelDownload(savePath);
      setState(() {
        _isDownloading = -1;
        _progress = 0;
      });
      return false;
    }
  }

  void _showDownloadFailedDialog(String webUrl) {
    MessageDialog.warning(
      context,
      titleKey: "msg_dialog_error".tr,
      messageKey: "download_error".tr,
      buttonTextKey: "confirm".tr,
      onConfirm: () {
        AppHelper.openUrl(context, webUrl); // 打开浏览器下载
      },
    );
  }
}
