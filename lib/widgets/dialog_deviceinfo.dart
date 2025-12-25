import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/styles/app_colors.dart';
import 'package:titan_fil/styles/app_text_styles.dart';

import '../constants/constants.dart';
import '../models/node_info.dart';
import '../models/user_data.dart';
import '../network/api_service.dart';
import '../services/global_service.dart';
import '../utils/app_helper.dart';
import '../utils/preferences_helper.dart';
import 'loading_indicator.dart';

class DialogDeviceInfo {
  static Completer<void>? _bottomSheetCompleter;

  static String getStatusText(int state) {
    switch (state) {
      case 0:
        return "publicNetwork".tr;
      case 1:
        return "NAT1";
      case 2:
        return "NAT2";
      case 3:
        return "NAT3";
      case 4:
        return "NAT4";
      default:
        return "none";
    }
  }

  static List<Map<String, String>> buildDeviceItems(
      Map<String, String> deviceData) {
    return [
      {'title': 'PCDN ID'.tr, 'value': deviceData['PCDNID'] ?? ''},
      // {'title': 'dg_deviceInfo_wallet'.tr, 'value': deviceData['wallet'] ?? ''},
      {'title': 'dg_deviceInfo_region'.tr, 'value': deviceData['area'] ?? ''},
      {'title': 'dg_deviceInfo_ipv4'.tr, 'value': deviceData['ipv4'] ?? ''},
      {
        'title': 'dg_deviceInfo_version'.tr,
        'value': deviceData['version'] ?? ''
      },
      {'title': 'dg_deviceInfo_ipv6'.tr, 'value': deviceData['ipv6'] ?? ''},
      {'title': 'dg_deviceInfo_nat'.tr, 'value': deviceData['nat'] ?? ''},
    ];
  }

  static int _safeParseNat(String? value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value.trim()) ?? 0;
  }

  static String _getWalletAddress(String? a, String? b) {
    return (a?.isNotEmpty ?? false)
        ? a!
        : (b?.isNotEmpty ?? false)
            ? b!
            : '';
  }

  static Future<void> showDeviceStatusBottomSheet(BuildContext ctx) async {

    if (_bottomSheetCompleter != null) return;
    _bottomSheetCompleter = Completer<void>();
    String agentId="";
    // 创建一个 Completer 用于等待 agentId 获取成功或超时
    final agentIdCompleter = Completer<String>();
    // 1. 定义轮询参数
    const int maxRetries = 10; // 最大重试次数 (例如 10 次)
    const Duration interval = Duration(seconds: 3); // 执行间隔 (例如 3 秒)
    int retryCount = 0;
    try {
      final loading = LoadingIndicator();
      loading.show(ctx, message: "loading".tr);
      // 2. 启动定时器
      final timer = Timer.periodic(interval, (timer) {
        retryCount++;
        debugPrint("queryAgentId attempt: $retryCount");
        // 尝试获取 agentId
        final currentId = Get.find<GlobalService>().agentId;
        // A. 成功获取
        if (currentId.isNotEmpty) {
          timer.cancel();
          if (!agentIdCompleter.isCompleted) {
            agentIdCompleter.complete(currentId);
          }
        }
        // B. 达到最大次数仍未获取
        else if (retryCount >= maxRetries) {
          timer.cancel();
          if (!agentIdCompleter.isCompleted) {
            // 这里可以选择返回空字符串或者抛出异常，视业务逻辑而定
            agentIdCompleter.complete("");
            debugPrint("queryAgentId timeout");
          }
        }
      });
      // 3. 关键点：等待轮询结束
      // 代码会暂停在这里，直到 agentIdCompleter.complete 被调用
      agentId = await agentIdCompleter.future;
      // --- 核心修改结束 ---
      debugPrint("DialogDeviceInfo agentId: $agentId");

      NodeInfo? nodeInfo;
      UserData? userData;
      if (agentId.isNotEmpty) {
        nodeInfo = await ApiService.fetchNodeInfo(agentId);
      }
      debugPrint("DialogDeviceInfo nodeInfo: ${nodeInfo.toString()}");
      String key = await PreferencesHelper.getString(Constants.bindKey) ?? "";
      if (key.isNotEmpty) {
        //mQFWviNLBmJ2 //sM7BFQRmg1HI
        userData = await ApiService.getUserInfo(key);
      }
      debugPrint("DialogDeviceInfo getUserInfo: ${userData.toString()}");

      final items = buildDeviceItems({
        'PCDNID': agentId,
        // 'wallet': _getWalletAddress(userData?.address, nodeInfo?.address),
        'area': "${nodeInfo?.location ?? ''}",
        'version': "${nodeInfo?.appVer ?? ''}",
        'ipv4': "${nodeInfo?.ipv4.isNotEmpty == true ? nodeInfo!.ipv4 : ''}",
        'ipv6': "${nodeInfo?.ipv6.isNotEmpty == true ? nodeInfo!.ipv6 : ''}",
        'nat': [
          nodeInfo?.natTcp != null && nodeInfo?.natTcp != ""
              ? '${getStatusText(_safeParseNat(nodeInfo?.natTcp))} TCP'
              : '',
          nodeInfo?.natUdp != null && nodeInfo?.natTcp != ""
              ? '${getStatusText(_safeParseNat(nodeInfo?.natUdp))} UDP'
              : '',
        ].where((s) => s.isNotEmpty).join('  '),
      });
      loading.hide();
      await showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 850,
                height: 400,
                decoration: const BoxDecoration(
                  color: Color(0xFF181818),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22.0, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleBar(context),
                      const SizedBox(height: 20),
                      Expanded(child: _buildDeviceGrid(items)),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'vpn_des_tip'.tr,
                          style: AppTextStyles.textStyleTip10,
                        ),
                      ),
                      const SizedBox(height: 35),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ).then((_) {
        _completeCompleter();
        // FileLogger.log("close");
      });
    } catch (e) {
      // FileLogger.log("error:$e");
    } finally {
      // FileLogger.log("close2");
      // 确保无论如何都会重置状态
      _completeCompleter();
    }
  }

// Helper method to safely complete the completer
  static void _completeCompleter() {
    if (_bottomSheetCompleter != null && !_bottomSheetCompleter!.isCompleted) {
      _bottomSheetCompleter!.complete();
    }
    _bottomSheetCompleter = null;
    // FileLogger.log("close3");
  }

  static Widget _buildTitleBar(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Text(
              'index_deviceInfo'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                // FileLogger.log("close2");
                _completeCompleter();
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.clear, color: Colors.white30, size: 20),
            ),
          )
        ],
      ),
    );
  }

  static Widget _buildDeviceGrid(List<Map<String, String>> items) {
    // 每个 item 一个 hover 状态
    final List<bool> hoverStates = List.generate(items.length, (_) => false);

    return StatefulBuilder(
      builder: (context, setOuterState) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 5,
          ),
          itemBuilder: (context, index) {
            return MouseRegion(
              onEnter: (_) => setOuterState(() {
                for (int i = 0; i < hoverStates.length; i++) {
                  hoverStates[i] = i == index;
                }
              }),
              onExit: (_) => setOuterState(() {
                hoverStates[index] = false;
              }),
              child: InkWell(
                hoverColor: Colors.transparent, // 防止 InkWell 自己搞 hover 效果
                mouseCursor: index <= 2
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic, // ← 这里强制设成箭头
                onTap: () {
                  if (index <= 2) {
                    AppHelper.onCopy(context, items[index]["title"]!,
                        items[index]["value"]!);
                  }
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: 45,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: hoverStates[index]
                        ? AppColors.themeColor
                        : Color(0xFF212121),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, 3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          items[index]["title"]!,
                          style: hoverStates[index]
                              ? AppTextStyles.textStyleTip10
                                  .copyWith(color: AppColors.back1)
                              : AppTextStyles.textStyleTip10,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(items[index]["value"]!,
                                style: hoverStates[index]
                                    ? AppTextStyles.textStyle12black
                                    : AppTextStyles.textStyle12white),
                            Spacer(),
                            if (index <= 2)
                              '\u{1F4CB}'.toEmojiText(fontSize: 12)
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
