import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles/app_colors.dart';
import '../utils/TimeUtils.dart';

/// 倒计时组件（保持原有逻辑不变）
///
/// [times] 初始时间列表（格式化的时、分、秒）
/// [onCountdownComplete] 倒计时结束回调
/// [duration] 目标时间戳（秒级）
class CountdownTimer extends StatefulWidget {
  final List<String> times;
  final VoidCallback onCountdownComplete;
  final int duration;
  final Color color;
  final bool check;

  const CountdownTimer({
    Key? key,
    required this.times,
    required this.onCountdownComplete,
    required this.duration,
    required this.color,
    required this.check,
  }) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late List<String> timeDifferenceList;
  Timer? _timer;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    timeDifferenceList = widget.times;
    _endTime = DateTime.fromMillisecondsSinceEpoch(widget.duration * 1000);
    _startTimer();
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当duration变化时重新初始化
    if (oldWidget.duration != widget.duration) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(widget.duration * 1000);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 确保定时器被取消
    super.dispose();
  }

  /// 启动定时器（保持原有逻辑）
  void _startTimer() {
    _timer?.cancel(); // 取消已有定时器
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return; // 防止在组件卸载后调用setState
      setState(() {
        timeDifferenceList = TimeUtils.getTimeDifferenceString(_endTime);
        // 检查是否倒计时结束（假设TimeUtils返回全0时表示结束）
        if (timeDifferenceList.every((item) => item == "00")) {
          timer.cancel();
          widget.onCountdownComplete();
        }
      });
    });
  }

  /// 构建单个时间单元（时/分/秒）
  Widget _buildTimeUnit(int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 时间数字容器
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 50,
          child: Column(
            children: [
              // 数字显示
              Container(
                width: 45,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.themeColor, AppColors.themeColor],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: !widget.check ? Colors.transparent : widget.color),
                ),
                child: Text(
                  timeDifferenceList[index],
                  style: TextStyle(
                      fontSize: 16,
                      color: !widget.check ? Colors.black : widget.color),
                ),
              ),
              // 单位标签
              Text(
                _getTimeUnitLabel(index),
                style: TextStyle(
                    fontSize: 12,
                    color: !widget.check ? Colors.white : widget.color),
              ),
            ],
          ),
        ),
        // 分隔符（最后一个不显示）
        if (index < timeDifferenceList.length - 1) ...[
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Text(
              ":",
              style: TextStyle(fontSize: 18, color: widget.color),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ],
    );
  }

  /// 获取时间单位标签
  String _getTimeUnitLabel(int index) {
    switch (index) {
      case 0:
        return "settings_storage_hours".tr;
      case 1:
        return "settings_storage_minutes".tr;
      case 2:
        return "settings_storage_seconds".tr;
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          timeDifferenceList.length,
          (index) => _buildTimeUnit(index),
        ),
      ),
    );
  }
}
