import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/constants.dart';
import '../main.dart';
import '../models/app_update_data.dart';
import '../network/api_service.dart';
import '../utils/FileDownloader.dart';
import '../utils/file_helper.dart';
import '../utils/preferences_helper.dart';
import '../widgets/update_app_hot_widget.dart';
import '../widgets/update_app_widget.dart';

/// 应用更新与版本管理控制器
class AppController extends GetxController {
  /// 远程版本号
  RxString remoteVersion = '1.0.0'.obs;

  /// 本地版本号
  RxString localVersion = '1.0.0'.obs;

  /// 是否需要安装包更新
  RxBool bUpdate = false.obs;

  /// 是否存在热更新（文件替换式更新）
  bool _hasHotUpdate = false;

  /// 是否正在下载
  bool _isDownloading = false;

  /// 是否允许弹出更新对话框（防止重复弹窗）
  bool _canShowDialog = true;

  /// 上次检查时间
  DateTime? _lastCheckTime;

  /// 版本更新数据
  AppUpdateData? updateData;


  /// 模拟接口返回数据，后期可替换真实接口
  final Map<String, dynamic> _mockJson = {
    "code": 0,
    "msg": "请求成功",
    "data": {
      "cid": "bafybeic6sx6kvnndanrzlddltcpw7nerjfkahfxzj536die4nmojwlnmqi",
      "description": "测试更新",
      "version": "1.0.6",
      "size": 102400,
      "min_version": "0.0.13",
      "url": "https://www.titannet.io/download",
      // "downUrl": "https://pcdn.titannet.io/test4/hmr/data.zip",
      "download_url":
          "https://pcdn.titannet.io/test4/latest/titan_fil_win_v1.0.0.exe",
      "file_name": "data.zip",
      "file_path": "",
      "is_force_update": true,
      "devices": [
        "47368D95-4C34-5A71-810E-CE56B88C4065",
        "7E6FC9B0-21B6-4960-9303-31BE37C62C3B"
      ]
    }
  };

  @override
  void onInit() {
    super.onInit();
    _loadLocalVersion();
  }

  /// 加载本地应用版本信息
  Future<void> _loadLocalVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    localVersion.value = packageInfo.version;
    // final dataJson = await PreferencesHelper.getMap("mockJson");
    // if(dataJson==null){
    //   await PreferencesHelper.setMap("mockJson", _mockJson);
    // }
  }

  /// 仅检查版本更新，不涉及弹窗
  /// 返回 true 表示检查完成
  Future<bool> checkVersion() async {
     final res = await ApiService.checkVersion();
    // 解析模拟数据（可替换为实际接口）
    // final dataJson = _mockJson['data'] as Map<String, dynamic>;
    // final dataJson = await PreferencesHelper.getMap("mockJson");
    // debugPrint("checkRes:dataJson=$dataJson");
    // final res = AppUpdateData.fromJson(dataJson!['data']);

    if (res == null) {
      return false;
    }
    updateData = res;

    remoteVersion.value = res.version;
     // 比较版本
    final compareResult =
        _compareVersions(localVersion.value, remoteVersion.value);

    debugPrint(
        '本地版本: ${localVersion.value}, 远程版本: ${remoteVersion.value}, 比较结果: $compareResult');

    if (compareResult == -1) {
      // 需要安装包整体更新
      bUpdate.value = true;
      _hasHotUpdate = false;
    } else if (compareResult == 0) {
      // 版本相同+下载地址不为空：存在热更新
      bUpdate.value = false;
      if (res.downUrl.isNotEmpty) {
        _hasHotUpdate = true;
      } else {
        _hasHotUpdate = false;
      }
    } else {
      // 无需更新
      bUpdate.value = false;
      _hasHotUpdate = false;
    }

    return true;
  }

  /// 主动触发版本检测，符合条件时弹出更新对话框

  String _lastPopupDateKey = 'last_update_popup_date';

  Future<void> onCheckVer(bool check) async {
    if (check) {
      final now = DateTime.now();
      // 两分钟内重复调用不再检查
      if (_lastCheckTime != null &&
          now.difference(_lastCheckTime!).inMinutes < 2) {
        return;
      }
      _lastCheckTime = now;
    }
    await checkVersion();
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastPopupDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool alreadyShownToday = false;

    if (dateString != null) {
      final lastDate = DateTime.tryParse(dateString);
      if (lastDate != null &&
          lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        alreadyShownToday = true;
      }
    }

    if (!_canShowDialog ||
        _isDownloading ||
        navigatorKey.currentContext == null) {
      return;
    }

    if (alreadyShownToday) {
      return;
    }

    if (bUpdate.value) {
      _showUpdateDialog();
      prefs.setString(_lastPopupDateKey, today.toIso8601String());
    }

    if (_hasHotUpdate) {
      checkHotForUpdate();
    }
  }

  /// 版本号比较
  /// 返回 -1：远程版本高，需要更新
  /// 返回 0：版本相同（通常用于热更新场景）
  /// 返回 1：本地版本高，无需更新
  // int _compareVersions(String current, String latest) {
  //   final currentParts = current.split('.').map(int.parse).toList();
  //   final latestParts = latest.split('.').map(int.parse).toList();
  //   final maxLength = math.max(currentParts.length, latestParts.length);
  //
  //   for (int i = 0; i < maxLength; i++) {
  //     final c = i < currentParts.length ? currentParts[i] : 0;
  //     final l = i < latestParts.length ? latestParts[i] : 0;
  //     if (c < l) return -1;
  //     if (c > l) return 1;
  //   }
  //   return 0;
  // }

  int _compareVersions(String current, String latest) {
    final currentParts = _parseVersionParts(current);
    final latestParts = _parseVersionParts(latest);
    final maxLength = math.max(currentParts.length, latestParts.length);

    for (int i = 0; i < maxLength; i++) {
      final c = i < currentParts.length ? currentParts[i] : 0;
      final l = i < latestParts.length ? latestParts[i] : 0;
      if (c < l) return -1;
      if (c > l) return 1;
    }
    return 0;
  }

  List<int> _parseVersionParts(String version) {
    // 移除所有非数字字符（除了点号），然后分割并解析
    String cleanVersion = version.replaceAll(RegExp(r'[^0-9.]'), '');
    return cleanVersion.split('.').map((part) {
      return int.tryParse(part) ?? 0;
    }).toList();
  }
  /// 弹出更新对话框，避免重复弹出
  Future<void> _showUpdateDialog() async {
    _canShowDialog = false;
    await showDialog(
      context: navigatorKey.currentState!.context,
      barrierDismissible: false,
      builder: (_) => UpdateAppWidget(
        height: 550,
        tag: 0,
      ),
    );
    _canShowDialog = true;
    _lastCheckTime = DateTime.now(); // 真正打扰了用户后，记录时间
  }

  Future<String> calculateFileMD5(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      List<int> fileBytes = await file.readAsBytes();
      var digest = md5.convert(fileBytes);
      return digest.toString();
    } else {
      return "";
    }
  }

  /// 部分更新
  Future<void> checkHotForUpdate() async {
    try {
      if (updateData == null) return;
      final downloadUrl = updateData!.downUrl;
      final hotFileName = updateData!.fileName;
      final filePath = updateData!.filePath;
      final isForceUpdate = updateData!.isForceUpdate;
      final users = updateData!.devices;

      final deviceId = await PreferencesHelper.getString(Constants.deviceId);
      debugPrint("hot: deviceId: $deviceId");

      // 如果不是所有人更新，校验是否是目标用户
      if (users.length > 0) {
        final matchedUser = users.any((user) => user.trim() == deviceId);
        if (!matchedUser) return;
      }

      // 保存路径
      final libsPath = await FileHelper.getCurrentPath();
      final savePath = filePath.isNotEmpty
          ? path.join(filePath, hotFileName)
          : path.join(libsPath, hotFileName);

      debugPrint("hot: savePath: $savePath");

      // 获取上一次下载的 MD5
      final localMd5 = await PreferencesHelper.getString("md5Hash");

      // 检查本地文件是否存在，存在就校验 MD5
      final file = File(savePath);
      if (await file.exists()) {
        final existingMd5 = await calculateFileMD5(savePath);
        if (existingMd5 == localMd5) {
          debugPrint("hot: file already up to date");
          return;
        }
      }

      // 下载文件
      final result = await FileDownloader.download(
        fileUrl: downloadUrl,
        savePath: savePath,
        onProgress: (received, total) {
          if (total > 0) {
            final percent = (received / total * 100).toStringAsFixed(1);
            debugPrint('hot: Download Progress: $percent%');
          }
        },
      );

      if (!result) {
        debugPrint("hot: download failed");
        return;
      }

      // 下载完成后校验 MD5
      final downloadedMd5 = await calculateFileMD5(savePath);
      debugPrint("hot: downloadedMd5: $downloadedMd5");

      // 如果一致，说明重复更新，跳过
      if (downloadedMd5 == localMd5) {
        debugPrint("hot: file already updated");
        return;
      }

      // 保存新的 MD5
      await PreferencesHelper.setString("md5Hash", downloadedMd5);

      // 8. 弹出更新对话框（强制或非强制）
      _canShowDialog = false;
      await showDialog(
        context: navigatorKey.currentState!.context,
        barrierDismissible: false,
        builder: (_) => UpdateAppHotWidget(
          agentFileName: hotFileName,
          isForceUpdate: isForceUpdate,
        ),
      );
      _canShowDialog = true;
      _lastCheckTime = DateTime.now();
    } catch (e, stack) {
      debugPrint('hot: error: $e');
      debugPrint('hot: stackTrace: $stack');
    }
  }
}
