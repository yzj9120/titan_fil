import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/extension/extension.dart';

import '../config/app_config.dart';
import '../models/node_bandwidths.dart';
import '../models/node_data.dart';
import '../models/node_income.dart';
import '../models/node_info.dart';
import '../network/api_service.dart';
import '../services/global_service.dart';
import '../styles/app_colors.dart';
import '../utils/app_helper.dart';
import '../widgets/message_dialog.dart';
import '../widgets/toast_dialog.dart';

class AgentController extends GetxController {
  final GlobalService globalService;

  AgentController({
    required this.globalService,
  });

  final Rx<NodeData?> nodeData = Rx<NodeData?>(null);
  final Rx<NodeInfo?> nodeInfo = Rx<NodeInfo?>(null);
  final RxList<NodeIncomeDetail> nodeIncomeList = <NodeIncomeDetail>[].obs;
  final RxList<double> last7IncomeU = <double>[].obs;
  final RxDouble last7IncomeUSum = 0.0.obs;

  DateTime? _startTime;
  DateTime? _lastExecutedTime;

  @override
  void onInit() {
    super.onInit();
    // 初始化逻辑...
    // _initTestData();
  }

  void _initTestData() {
    final now = DateTime.now();
    for (int i = 13; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final timestamp = date.millisecondsSinceEpoch ~/ 1000;

      // 简单的线性增长数据
      final incomeU = 40.0 + i * 5;

      nodeIncomeList.add(NodeIncomeDetail(
        income: incomeU * 0.9,
        incomeU: incomeU,
        createdAt: timestamp,
        nodes: 20,
        averageIncome: incomeU / 20,
      ));
    }
  }

  Future<void> refreshData(String agentId) async {
    if (agentId.isEmpty) return;
    try {
      final results = await Future.wait([
        ApiService.fetchNodeInfo(agentId),
        ApiService.fetchNodeInfo2(agentId),
        ApiService.fetchNodeIncomes(agentId, 14),
      ]);

      final nodeInfoRes = results[0] as NodeInfo?;
      final nodeDataRes = results[1] as NodeData?;
      final nodeRes = results[2] as NodeIncomeData?;

      if (nodeInfoRes != null) nodeInfo.value = nodeInfoRes;
      if (nodeDataRes != null) nodeData.value = nodeDataRes;
      if (nodeDataRes != null) {
        _setAgentStatus(nodeDataRes.node.state);
        _setAgentStatusToast(nodeDataRes.node.serviceState);
      } else {
        _setAgentStatus(nodeInfo.value!.status);
      }
      if (nodeRes?.list != null && nodeRes!.list.isNotEmpty) {
        nodeIncomeList.value = nodeRes.list;

        // 更新最近7天的 income_u
        final last7 = nodeRes.list.length >= 7
            ? nodeRes.list.sublist(nodeRes.list.length - 7)
            : nodeRes.list;
        last7IncomeU.value = last7.map((e) => e.incomeU.toDouble()).toList();
        print('最近7天 income_u: ${last7IncomeU.value}');

        final sum = last7.fold<double>(
            0.0, (previousValue, element) => previousValue + element.incomeU);
        last7IncomeUSum.value = sum;
        print('最近7天 income_u 总和: $sum');
      }

      if (globalService.isAgentOnline.value &&
          globalService.isAgentRunning.value) {
        getNodeBandwidths();
      }
    } catch (e) {
      debugPrint('Refresh data error: $e');
    }
  }

  double calculateLast7DaysIncomeSum() {
    if (nodeIncomeList.isEmpty) return 0.0;
    return nodeIncomeList.reversed
        .take(7)
        .fold(0.0, (sum, item) => sum + (item.incomeU ?? 0.0));
  }

  double last7DaysIncomeSum() {
    if (nodeIncomeList.isEmpty) return 0.0;
    return nodeIncomeList.reversed
        .take(7)
        .fold(0.0, (sum, item) => sum + (item.income ?? 0.0));
  }

  double getMaxIncome() {
    if (nodeIncomeList.isEmpty) return _calculateDynamicMax();
    final max = nodeIncomeList
        .map((item) => item.incomeU ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return max > 0 ? max * 1.1 : _calculateDynamicMax() * 1.1;
  }

  double _calculateDynamicMax() {
    final avg = calculateLast7DaysIncomeSum() / 7;
    if (avg == 0 || avg == 0.0) {
      return 15;
    }
    return avg * 3;
  }

  /// 设置agent 服务的状态：

  void _setAgentStatus(int status) {
    if (status == globalService.isAgentOnline.value) return;
    if (status == 0) {
      //故障
      globalService.isAgentOnline.value = false;
    } else if (status == 1) {
      //在线
      globalService.isAgentOnline.value = true;
    } else if (status == 2) {
      // 离线
      globalService.isAgentOnline.value = false;
    }
  }

  Future<void> _onOpenNodeRevenue(BuildContext context) async {
    var url = "";
    if (globalService.agentId.isNotEmpty) {
      url = await ApiService.fetchNodeDetails(globalService.agentId);
    }
    if (url.isEmpty) {
      ToastHelper.showWarning(
        context,
        title: 'msg_dialog_error'.tr, // 错误标题
        message: "msg_dialog_node_empty".tr,
        config: const ToastConfig(
          primaryColor: Color(0xFF9D9D9C),
          autoCloseDuration: Duration(seconds: 5),
        ),
      );
    }
    AppHelper.openUrl(context, url);
  }

  void _onViewOpenRegions(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl = isChineseLocale ? AppConfig.t4WebUrlZH : AppConfig.t4WebUrlEN;
    AppHelper.openUrl(context, webUrl);
  }

  /**
      弹窗频率控制逻辑：
      首次调用时正常弹出
      之后每隔 5分钟的倍数 弹出一次（5、10、15...分钟）
      到了60分钟后，重新从0开始计时，循环上述逻辑
   */
  void _setAgentStatusToast(int serviceState) {
    if (globalService.isAgentRunning.value &&
        (serviceState == 5 || serviceState == 7 || serviceState == 12)) {
      final now = DateTime.now();
      if (_startTime == null) {
        _startTime = now;
        _showDialog();
        return;
      }
      final diff = now.difference(_startTime!).inMinutes;
      if (diff >= 60) {
        _startTime = now;
        _showDialog();
      } else if (diff % 5 == 0 && diff != 0) {
        _showDialog();
      }
    }
  }

  void _showDialog() {
    final context = Get.overlayContext;
    if (context != null && context.mounted) {
      MessageDialog.show(
        context: context,
        config: MessageDialogConfig(
          width: 430,
          titleKey: "run_vpn_tip7".tr,
          messageKey: "run_vpn_tip8".tr.replaceAll("@@", "run_vpn_tip9".tr),
          iconType: DialogIconType.image,
          image: '\u{26A0}'.toEmojiText(fontSize: 51),
          showCloseButton: true,
          buttonTextKey: "run_vpn_btn3".tr,
          cancelButtonTextKey: "run_vpn_btn4".tr,
          cancelButtonStyle: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.themeColor, width: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          cancelButtonTextStyle:
              TextStyle(color: AppColors.themeColor, fontSize: 13),
          onAction: () {
            _onOpenNodeRevenue(context);
          },
          onCancel: () {
            _onViewOpenRegions(context);
          },
        ),
      );
    }
  }

  Future<void> getNodeBandwidths() async {
    const intervalSeconds = 300;
    final now = DateTime.now();

    if (_lastExecutedTime != null &&
        now.difference(_lastExecutedTime!).inSeconds < intervalSeconds) {
      debugPrint("跳过执行，距离上次不足5分钟");
      return;
    }
    _lastExecutedTime = now;
    final agentId = globalService.agentId;
    debugPrint("agentId=$agentId");

    if (agentId.isEmpty) {
      debugPrint("agentId为空，跳过执行");
      return;
    }
    final todayStr = "${now.year.toString().padLeft(4, '0')}"
        "-${now.month.toString().padLeft(2, '0')}"
        "-${now.day.toString().padLeft(2, '0')}";
    try {
      final obj = await ApiService.nodeBandwidths(agentId, todayStr);
      if (obj == null) {
        debugPrint("API返回空响应");
        return;
      }
      final bandwidthList = obj.list ?? [];
      final current = findCurrentBandwidthRecord(bandwidthList);
      if (current != null) {
        final time =
            DateTime.fromMillisecondsSinceEpoch(current.createdAt * 1000);
        if (current.bandwidthUpload < 10) {
          final context = Get.overlayContext;
          if (context != null) {
            ToastHelper.show(
              context,
              title: 'gentleReminder'.tr, // 错误标题
              message: "run_pcdn_net_tip".tr,
              config: const ToastConfig(
                primaryColor: Color(0xFF9D9D9C),
                autoCloseDuration: Duration(seconds: 5),
              ),
            );
          }

          debugPrint(
              "当前时间 $time 位于记录区间内，且上传带宽小于 10：${current.bandwidthUpload}");
        } else {
          debugPrint(
              "当前时间 $time 位于记录区间内，上传带宽为 ${current.bandwidthUpload}，不小于 10");
        }
      } else {
        debugPrint("当前时间不在记录范围内");
      }
    } catch (e) {
      debugPrint("请求或处理异常：$e");
    }
  }

  BandwidthRecord? findCurrentBandwidthRecord(List<BandwidthRecord> list) {
    if (list.isEmpty) return null;
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int start = list[0].createdAt;
    if (now < start) return null;
    int interval = 300;
    int index = (now - start) ~/ interval;
    if (index >= list.length - 1) {
      return list.last;
    }
    return list[index];
  }
}
