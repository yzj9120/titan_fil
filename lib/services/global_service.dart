import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan_fil/config/app_config.dart';
import 'package:titan_fil/services/pcdn_service.dart';
import 'package:titan_fil/services/scheduler_service.dart';

import '../constants/constants.dart';
import '../controllers/app_controller.dart';
import '../controllers/locale_controller.dart';
import '../controllers/notice_controller.dart';
import '../plugins/agent_plugin.dart';
import '../utils/FileLogger.dart';
import '../utils/preferences_helper.dart';
import 'log_service.dart';

class GlobalService extends GetxService {
  static final _logger4 = LoggerFactory.createLogger(LoggerName.t3);

  final _scheduler = SchedulerService();
  final localeController = Get.find<LocaleController>();

  // 存储节点运行状态（是否正在运行）
  var isShowIndexPage = false.obs;


  // PCDN代理运行状态
  var isAgentRunning = false.obs;

  // PCDN代理在线状态
  var isAgentOnline = false.obs;

  // PCDN监控状态：
  // 1: 默认自动检测中(验证区域)
  // 2: 检测失败（区域）
  // 3: 检测成功（区域）
  // 4: 运行环境检测
  // 5: 运行环境检测失败
  // 6: 运行环境检测成功
  // 7: 启动中
  Rx<int> pcdnMonitoringStatus = 1.obs;

  // storage 状态
  // 1:没有运行
  // 2:启动中
  // 3:启动结束
  Rx<int> storageStatus = 1.obs;

  var ipError = "".obs; // IP错误信息

  // 用于30秒检查的计数器
  int _processCheckCounter = 0;
  int _proxyCheckCounter = 0;

  /// agentid
  var agentId = "";
  var t4bindCount = 0;

  bool isReadAgentId = false;
  bool isOnceCheckVpn = false;

  String localIp = "";
  String proxyIp = "";

  //当三测开启了，但四测没有开启，则出现提示弹窗。
  var shouldShowPcdnTip = false.obs;

  Future<GetxService> init() async {
    return this;
  }

  @override
  void onInit() {
    onInitValue();
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  Future<void> onInitValue() async {}

  Future<void> start({
    Duration fastCheckInterval = const Duration(seconds: 5),
    Duration slowCheckInterval = const Duration(seconds: 30),
  }) async {
    _startFastCheck(fastCheckInterval, slowCheckInterval);
  }

  /// 重启监控
  Future<void> restart() async {
    _scheduler.cancelTask("periodicTask");
    _scheduler.cancelTask("agentTask");
    await start();
  }

  /// 启动快速检查模式
  void _startFastCheck(Duration fastInterval, Duration slowInterval) {
    _scheduler.schedulePeriodicTask(
      'periodicTask',
      fastInterval, // 执行间隔（5秒）
      () async {
        _executeTasksT3(); // 执行T3任务（每5秒）
        await _executeTasksT4(
            fastInterval, slowInterval); // 执行T4任务（部分每5秒，部分每30秒）
      },
    );
  }

  /// 执行T3任务（每5秒执行）
  Future<void> _executeTasksT3() async {
    try {
      // 自动清理日志
      //await LogService().autoCleanLogs();
      try {
        if (Get.isRegistered<NoticeController>()) {
          if (isShowIndexPage.value) {
            Get.find<NoticeController>().getNotice();
          }
        } else {
          _log('NoticeController not registered');
          Get.put(NoticeController(globalService: this)).getNotice(); // 自动注册并获取
        }
      } catch (e) {
        _log('Failed to get notice: $e');
      }
      try {
        if (Get.isRegistered<AppController>()) {
          Get.find<AppController>().onCheckVer(true);
        } else {
          _log('AppController not registered');
          Get.put(AppController()).onCheckVer(true); // 自动注册并检查
        }
      } catch (e) {
        _log('Failed to check version: $e');
      }
      _checkIfShouldShow();
    } catch (e) {
      _log("_execute tasksT3 error: $e");
      debugPrint("_execute tasksT3 error: $e");
    }
  }

  /// 执行T4任务
  /// [fastInterval] 快速间隔（5秒）
  /// [slowInterval] 慢速间隔（30秒）
  Future<void> _executeTasksT4(
      Duration fastInterval, Duration slowInterval) async {
    try {
      // 每次增加计数器（按快速间隔增加）

      _processCheckCounter += fastInterval.inSeconds;
      _proxyCheckCounter += fastInterval.inSeconds; // 新增代理检测计数器
      // 以下任务每5秒执行一次 --------
      if (!isReadAgentId) {
        await _checkAndUpdateAgentId();
      }
      if (agentId.isNotEmpty) {
        /// 需要判断agent收益
        PCDNService.getInstance().pullInfo(agentId.trim());
      }
      bool donRemind =
          await PreferencesHelper.getBool(Constants.checkVpm) ?? false;
      // 以下任务每30秒执行一次 --------
      if (_processCheckCounter >= slowInterval.inSeconds) {
        _processCheckCounter = 0; // 重置计数器
        /// 检查agent进程是否运行
        final isAgent =
            await AgentPlugin().isProcessRun(AppConfig.agentProcess);

        /// 检查controller进程是否运行
        final isController =
            await AgentPlugin().isProcessRun(AppConfig.controllerProcess);

        final agentStatus = isAgent && isController;
        debugPrint(
            "▶️ agent=$isAgent;controller=${isController};;isAgentRunning=${isAgentRunning.value}");
        if (agentStatus) {
          bool hasT4Bind =
              await PreferencesHelper.getBool(Constants.hasT4Bind) ?? false;
          String bindKey =
              await PreferencesHelper.getString(Constants.bindKey) ?? "";
          //  debugPrint("Ⓜ️ hasT4Bind=$hasT4Bind;bindKey=${bindKey}");

          ///是否符合区域条件
          if (!hasT4Bind && bindKey.isNotEmpty && t4bindCount <= 3) {
            final result = await AgentPlugin().bindKey(bindKey);
            if (!result.state) {
              t4bindCount++;
            }
            _log("T4Bind status: $result", ist3: false);
          }

          FileLogger.log('checkProxy： $pcdnMonitoringStatus;$donRemind',
              tag: 'vpn');

          /// 运行中+ 有1次运行+ 没有勾选
          /// 每 10 分钟检查一次代理（600秒）
          if (_proxyCheckCounter >= 600) {
            _proxyCheckCounter = 0; // 重置代理检测计时器
            /// 运行中 + 未勾选 "不提醒"
            if (pcdnMonitoringStatus == 6 && !donRemind) {
              Future.delayed(Duration(seconds: 3)).then((_) async {
                final pcdService = PCDNService.getInstance();
                await pcdService.checkProxy();
              });
            }
          }
        }
        // 更新运行状态
        if (isAgentRunning.value != agentStatus) {
          isAgentRunning.value = agentStatus;
        }
      }
    } catch (e) {
      _log("_execute tasksT4 error: $e", ist3: false);
    }
  }

  Future<void> _checkAndUpdateAgentId() async {
    try {
      final id = (await AgentPlugin().readAgentId()).trim();
      if (id.isNotEmpty) {
        isReadAgentId = true; // 标记已读取
      }
      agentId = id;
    } catch (e, stack) {
      _log("Error reading agentId: $e\n$stack", ist3: false);
    }
  }


  /// 检查今天是否需要显示
  Future<void> _checkIfShouldShow() async {
    bool isPCDNRun = isAgentRunning.value;
    if (!isPCDNRun) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastClosedDate = prefs.getString('tooltip_closed_date') ?? '';
      bool v = (lastClosedDate != today);
      shouldShowPcdnTip.value = v;
    }

    if(isPCDNRun){ shouldShowPcdnTip.value = false;}
    // shouldShowPcdnTip.value =true;
  }

  /// 点击关闭时调用
  Future<void> markTooltipClosedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('tooltip_closed_date', today);
    shouldShowPcdnTip.value = false;
  }

  void _log(dynamic message, {bool ist3 = true}) {
    _logger4.info("[Global SERVICE]:$message");
  }
}
