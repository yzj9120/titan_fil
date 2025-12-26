import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../constants/constants.dart';
import '../network/api_endpoints.dart';
import '../styles/app_colors.dart';
import 'FileDownloader.dart';
import 'FileLogger.dart';
import 'file_helper.dart';

class DownLoadHot {
  /// 检查更新
  /// [serverVersionUrl] 服务端版本信息API地址
  /// [minRequiredVersion] 最低必需版本（强制更新）
  /// [isEn] 是否显示更新对话框
  static Future<bool> checkForUpdate({
    required BuildContext context,
    String? minRequiredVersion,
    bool isEn = true,
  }) async {
    FileLogger.log("DownLoadHot:");
    try {
      // 从服务器获取最新版本信息
      var serverVersionUrl =
          "${ApiEndpoints.webServerURLV4}${ApiEndpoints.updates}?platform=windows";
      // debugPrint('serverVersionUrl: $serverVersionUrl');
      final Dio dio = Dio();
      final response = await dio.get(serverVersionUrl);
      final serverData = response.data as Map<String, dynamic>;
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      // final serverData = json as Map<String, dynamic>;
      await FileLogger.log("serverData:$serverData");
      final code = serverData['code'] as int;
      final data = serverData['data'];
      if (code == 0 && data != null) {
        final latestVersion = data['version'] as String;
        final downloadUrl = data['hotUrl'] as String;
        final hotFileName = data['fileName'] as String;
        final filePath = data['filePath'] as String;
        final isForceUpdate = data['isForceUpdate'] as bool;
        final isUpdate = data['isUpdate'] as bool;
        var users = data['users'];
        final deviceId = await PreferencesHelper.getString(Constants.deviceId);
        await FileLogger.log("deviceId:$deviceId");

        if (!isUpdate) {
          //判断是否时特定用户
          bool isValid = false;
          for (var user in users) {
            if (user['deviceId'].toString() == deviceId) {
              isValid = true;
              break; // 找到匹配的用户后就可以退出循环
            }
          }
          if (!isValid) {
            return false;
          }
        }
        await FileLogger.log("hot........");
        // 比较版本
        if (_compareVersions(currentVersion, latestVersion) <= 0) {
          final libsPath = await FileHelper.getCurrentPath();
          final md5Hash = await PreferencesHelper.getString("md5Hash");
          var savePath = "";
          if (filePath.isNotEmpty) {
            savePath = path.join(filePath, hotFileName);
          } else {
            savePath = path.join(libsPath, hotFileName);
          }
          String md5 = await calculateFileMD5(savePath);

          await FileLogger.log("${md5Hash == md5}");
          if (md5Hash == md5) {
            return false;
          }
          await FileLogger.log("hot.......start.");
          final result = await FileDownloader.download(
            fileUrl: downloadUrl,
            savePath: savePath,
            onProgress: (received, total) {
              if (total != 0) {
                final percent = (received / total * 100).toStringAsFixed(1);
                debugPrint('📥 onProgress: $percent%');
              }
            },
          );
          await FileLogger.log("hot....result:$result");
          if (result) {
            String md5Hash = await calculateFileMD5(savePath);
            await PreferencesHelper.setString("md5Hash", "$md5Hash");
            _showUpdateDialog(
                context: context,
                isForceUpdate: isForceUpdate,
                agentFileName: hotFileName,
                isEn: true);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      await FileLogger.log('error: $e');
      return false;
    }
  }

  /// 版本号比较 (格式: 1.2.3)
  /// 返回: -1(需要更新), 0(相同), 1(当前版本更高)
  static int _compareVersions(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    for (int i = 0;
        i < math.max(currentParts.length, latestParts.length);
        i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      if (currentPart < latestPart) return -1;
      if (currentPart > latestPart) return 1;
    }
    return 0;
  }

  /// 显示更新对话框
  static Future<void> _showUpdateDialog({
    required BuildContext context,
    required bool isForceUpdate,
    required String agentFileName,
    required bool isEn,
  }) async {
    final libsPath = await FileHelper.getCurrentPath();
    String updater =
        path.join(libsPath, path.join("titanUpdater", "titan_fil.exe"));
    String main = path.join(libsPath, "titan_fil.exe");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.only(top: 22, bottom: 22),
          content: SizedBox(
            width: 500,
            height: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                Assets.images.icLogo2.image(width: 100, height: 100),
                const SizedBox(height: 22),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  alignment: Alignment.center,
                  child: Text(
                    "hot_tip".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  child: Text(
                    "hot_tip2".tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
                Spacer(),
                SizedBox(
                  height: 45,
                  width: 300,
                  child: OutlinedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.themeColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    onPressed: () async {
                      Timer(const Duration(seconds: 1), () {
                        exit(0);
                      });
                      final result = await Process.run(
                        updater,
                        [
                          "main=$main",
                          "isEn=$isEn",
                          "libsPath=$libsPath",
                          "extractToPath=$libsPath",
                          "agentFileName=$agentFileName",
                        ],
                        runInShell: true,
                      );
                      // 打印标准输出
                      // if (result.stdout.isNotEmpty) {
                      //   _log("run updater  stdout: ${result.stdout}");
                      // }
                      // 打印错误输出
                      if (result.stderr.isNotEmpty) {
                        await FileLogger.log(
                            "run updater stderr: ${result.stderr}");
                      }
                    },
                    child: Text(
                      "hot_tip3".tr,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!isForceUpdate) ...{
                  SizedBox(
                    height: 45,
                    width: 300,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.tcCff, width: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "hot_tip4".tr,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  )
                }
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<String> calculateFileMD5(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      List<int> fileBytes = await file.readAsBytes();
      var digest = md5.convert(fileBytes);
      return digest.toString();
    } else {
      return "";
    }
  }
}
