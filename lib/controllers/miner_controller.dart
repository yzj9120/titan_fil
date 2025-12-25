import 'dart:math';

import 'package:get/get.dart';

import '../models/miner_info.dart';
import '../services/log_service.dart';

class MinerController extends GetxController {
  double _todayIncome = 0.0;
  Rx<double> todayIncome = (0.0).obs; // 今日收益
  double _totalIncome = 0.0; // 总收益
  Rx<double> totalIncome = (0.0).obs; // 总收益
  double _yesterdayIncome = 0.0; // 昨日收益
  Rx<double> yesterdayIncome = (0.0).obs; // 昨日收益
  double _monthIncome = 0.0; // 本月收益
  Rx<double> monthIncome = (0.0).obs; // 本月收益
  double _weekIncome = 0.0;
  Rx<double> weekIncome = (0.0).obs; // 7天的数据
  String _tokenUnit = 'TNT3'; // 代币单位
  double _incomeIncr = 0; // 收益增量

  /// 今日预计收益
  Rx<String> account = "".obs; // 账户
  Rx<String> address = "".obs; // 地址
  Rx<String> bindingCode = "".obs; // 绑定码

  List<IncomeData> _weeksIncomes = [];
  RxList<IncomeData> weeksIncomeList = <IncomeData>[].obs; // 每周收益数据
  List<IncomeData> _monthsIncomes = []; // 每月收益数据
  var _initTime;
  final _loggers = LoggerFactory.createLogger(LoggerName.t3);

  @override
  void onInit() {
    _initTime = DateTime.now();
    initData();
    super.onInit();
  }

  /// 初始化数据 记录过去15天的数据
  void initData() {
    DateTime now = DateTime.now(); // 获取当前日期时间
    for (int i = 14; i > 0; i--) {
      // 从 14 开始，循环到 1
      DateTime dayAgo = now.subtract(Duration(days: i));
      String m = dayAgo.month.toString().padLeft(2, '0');
      String d = dayAgo.day.toString().padLeft(2, '0');
      var income = IncomeData(x: '$m-$d', y: 0);
      _weeksIncomes.add(income);
    }
  }

  bool _hasSameDay() {
    var tempTime = DateTime.now(); // 获取当前时间
    final difference = tempTime.difference(_initTime).inDays;
    if (difference > 0) {
      // 如果差值大于0，说明不是同一天
      _initTime = tempTime;
      return false;
    }
    return true;
  }

  void _log(message) {
    _loggers.info("[IncomeData]：$message");
  }

  /// 更新收益信息:刷新页面
  void updateIncome() {
    if (_incomeIncr <= 0) {
    } else {
      final isSameDay = _hasSameDay();
      if (!isSameDay) {
        _todayIncome = 0;
        _incomeIncr = 0;
      }
      _todayIncome += _incomeIncr;
    }
    //今日收益
    todayIncome.value = _todayIncome;
    if (_todayIncome > totalIncome.value) {
      totalIncome.value = _todayIncome;
    }
    if (_todayIncome > yesterdayIncome.value) {
      yesterdayIncome.value = _todayIncome;
    }
    if (_todayIncome > monthIncome.value) {
      monthIncome.value = _todayIncome;
    }
    if (_todayIncome > weekIncome.value) {
      weekIncome.value = _todayIncome;
    }
  }

  /// 清除今日收益
  void clearIncome() {
    _todayIncome = 0;
  }

  ///清除收益增量
  void clearIncomeIncr() {
    _incomeIncr = 0;
  }

  /// 从JSON数据更新对象
  int updateFromJSON(String nodeID, Map jMap) {
    final logBuffer = StringBuffer(); // 用于拼接所有日志
    logBuffer.clear(); // 清空所有内容

    logBuffer.writeln('jMap: $jMap');
    var rspBody = NodeInfoRsp.fromMap(jMap);
    if (rspBody.code != 0) {
      _log(logBuffer.toString());
      return 0;
    }
    var data = rspBody.data;
    logBuffer.writeln("data:${data.toString()}");
    _log(logBuffer.toString());
    logBuffer.clear(); // 清空所有内容
    if (data == null) {
      return 0;
    }

    var isIncomeNotify = false;
    var isIncomesNotify = false;

    var income = data.income;
    if (income != null) {
      _todayIncome = income.today;
      _totalIncome = income.total;
      isIncomeNotify = true;
    }

    var epochInfo = data.epochInfo;
    if (epochInfo != null) {
      if (_tokenUnit != epochInfo.token) {
        if (epochInfo.token.isNotEmpty) {
          _tokenUnit = epochInfo.token;
        }
        isIncomeNotify = true;
        isIncomesNotify = true;
      }
    }

    var nodeInfo = data.nodeInfo;
    if (nodeInfo != null) {
      _incomeIncr = nodeInfo.incr / 360;
    }

    var monthIncomeInfo = data.monthIncomes;

    if (monthIncomeInfo != null) {
      _weekIncome = 0;
      _monthIncome = 0;
      _monthsIncomes = monthIncomeInfo.incomeList;
      // 获取当前月收入数据的长度
      var le = _monthsIncomes.length;
      // 如果月收入数据不足 30 天，则补充数据
      if (le < 30) {
        List<IncomeData> temps = [];
        DateTime now = DateTime.now();
        for (int i = le; i < 30; i++) {
          DateTime dayAgo = now.subtract(Duration(days: 30 - i));

          String m = dayAgo.month.toString().padLeft(2, '0');
          String d = dayAgo.day.toString().padLeft(2, '0');

          // 检查是否已经存在相同日期的数据
          bool exists = _monthsIncomes.any((income) => income.x == '$m-$d');

          if (!exists) {
            var income = IncomeData(x: '$m-$d', y: 0);
            temps.add(income);
          }
        }
        temps.addAll(_monthsIncomes);
        _monthsIncomes = temps;
      }

      // 截取最后 14 天的数据作为 _weeksIncomes
      _weeksIncomes =
          _monthsIncomes.sublist(max(0, _monthsIncomes.length - 14));

      ///0904添加 ：最近7天的数据
      var _weekIncome2s =
          _monthsIncomes.sublist(max(0, _monthsIncomes.length - 7));

      // 计算周收入和月收入
      _monthIncome = 0;
      _weekIncome = 0;

      ///最近7天的数据
      for (final IncomeData info in _weekIncome2s) {
        _weekIncome += info.y;
      }
      // _log.info("最近7天的数据=======$_weekIncome");

      // for (final IncomeData info in _weeksIncomes) {
      //   _weekIncome += info.y;
      // }
      for (final IncomeData info in _monthsIncomes) {
        _monthIncome += info.y;
      }

      // 设置昨日收入
      _yesterdayIncome = _weeksIncomes[min(12, _weeksIncomes.length - 1)].y;
      //debugPrint("设置昨日收入=======$_yesterdayIncome");
      // 标记通知
      isIncomeNotify = true;
      isIncomesNotify = true;

      try {
        _weeksIncomes.sort((a, b) {
          // 假设 x 是 "MM.dd" 格式
          List<String> partsA = a.x.split('.');
          List<String> partsB = b.x.split('.');

          int currentYear = DateTime.now().year;
          DateTime dateA =
              DateTime(currentYear, int.parse(partsA[0]), int.parse(partsA[1]));
          DateTime dateB =
              DateTime(currentYear, int.parse(partsB[0]), int.parse(partsB[1]));
          return dateA.compareTo(dateB);
        });
      } catch (e) {}
    }

    if (isIncomeNotify) {
      /// 刷新收益
      todayIncome.value = _todayIncome;
      totalIncome.value = max(_totalIncome, _todayIncome);
      yesterdayIncome.value = max(_yesterdayIncome, _todayIncome);
      monthIncome.value = max(_monthIncome, _todayIncome);
      weekIncome.value = max(_weekIncome, _todayIncome);
    }

    if (isIncomesNotify) {
      /// 刷新折线收益图
      weeksIncomeList.value = _weeksIncomes;
      // debugPrint("刷新折线收益图=======$_weeksIncomes");
    }
    var aInfo = data.accountInfo;
    if (aInfo != null &&
        (aInfo.account != account.value ||
            aInfo.address != address.value ||
            aInfo.code != bindingCode.value)) {
      address.value = aInfo.address;
      account.value = aInfo.account;
      bindingCode.value = aInfo.code;

      /// 刷新绑定账号信息
      // notify("account");
    }

    return data.since;
  }
}
