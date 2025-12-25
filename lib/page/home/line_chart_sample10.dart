import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../styles/app_colors.dart';
import '../../controllers/miner_controller.dart';
import 'home_controller.dart';

class MyLineChart extends StatelessWidget {
  final logic = Get.find<HomeController>();
  final minerLogic = Get.find<MinerController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // print('Date: ${minerLogic.weeksIncomeList.toJson()}');
      return LineChart(
        sampleData1,
        duration: const Duration(milliseconds: 250), // 动画时间
      );
    });
  }

  /// 计算 Y 轴最大值（数据最大值的 1.1 倍，留出顶部间距）
  double _calculateMaxY() {
    if (minerLogic.weeksIncomeList.isEmpty) return 4; // 默认值
    final maxDataY = minerLogic.weeksIncomeList
        .map((income) => income.y)
        .reduce((a, b) => a > b ? a : b);
    return maxDataY * 1.1; // 增加 10% 的间距
  }

  /// 第二组数据的固定Y轴最大值
  static const double _secondaryMaxY = 15.0;

  /// 主图数据
  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData(),
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        minX: 0,
        maxX: 14,
        minY: 0,
        maxY: _calculateMaxY(),
      );

  /// 配置触摸数据，定制悬停时的样式
  LineTouchData lineTouchData() {
    return LineTouchData(
      enabled: true,
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> touchedIndexes) {
        return touchedIndexes.map((index) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: AppColors.cff0084,
              strokeWidth: 1,
            ),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  color: Colors.red,
                  radius: 4,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) => Colors.green,
      ),
    );
  }

  /// 主图坐标轴配置
  FlTitlesData get titlesData1 => FlTitlesData(
        topTitles: AxisTitles(sideTitles: topTitles()),
        bottomTitles: AxisTitles(sideTitles: bottomTitles),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
          axisNameWidget: Text(
            '主数据',
            style: TextStyle(fontSize: 10, color: AppColors.themeColor),
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: rightTitles(),
          axisNameWidget: Text(
            '参考数据',
            style: TextStyle(fontSize: 10, color: AppColors.tcDB1),
          ),
        ),
      );

  /// 折线数据（默认主图只显示一条线）
  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
      ];

  /// 格式化 Y 轴标签（动态单位：k/m/无）
  String _formatYAxisLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m'; // 百万单位
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k'; // 千单位
    } else {
      return value.toInt().toString(); // 普通数字
    }
  }

  /// y轴刻度样式
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.cff9bb,
      fontSize: 10,
    );

    final maxY = _calculateMaxY(); // 获取动态计算的 Y 轴最大值
    final interval = maxY / 4; // 将 Y 轴分为 4 段

    // 检查当前 value 是否为 4 等分点（0%, 25%, 50%, 75%, 100%）
    bool isMajorTick(double value) {
      final tolerance = 0.001 * maxY; // 允许浮点数误差
      return (value % interval < tolerance) || (value == maxY);
    }

    if (value == 0 || isMajorTick(value)) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          _formatYAxisLabel(value), // 格式化标签文本
          style: style,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(); // 其他情况不显示标签
  }

  /// x轴配置
  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true, //true，表示显示标题，若设置为 false，则不显示标题
        interval: 1, //每隔 1 个单位显示一个标题，如 1m、2m、3m 等
        reservedSize: 40, //预留 40 像素宽度给左侧标题，以确保标题有足够的空间显示
      );

  /// 右侧Y轴标题（固定0-4范围，显示4等份）
  SideTitles rightTitles() => SideTitles(
        getTitlesWidget: (value, meta) {
          // 将主坐标系的Y值转换为次坐标系的Y值（0-4范围）
          final secondaryValue = (value / _calculateMaxY()) * _secondaryMaxY;

          const style = TextStyle(
            color: AppColors.cff0084,
            fontSize: 10,
          );

          // 只显示整数值（0, 1, 2, 3, 4）
          if (secondaryValue % 1 == 0 &&
              secondaryValue >= 0 &&
              secondaryValue <= _secondaryMaxY) {
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(secondaryValue.toInt().toString(), style: style),
            );
          }
          return Container();
        },
        showTitles: true,
        // 计算间隔确保正好分成4等份
        interval: _secondaryMaxY / (_calculateMaxY() / (_secondaryMaxY / 4)),
        reservedSize: 40,
      );

  /// x轴刻度样式
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.tcCff,
      fontSize: 10,
    );

    // 检查 value 是否在有效范围内
    final index = value.toInt();
    if (index < 0 || index >= minerLogic.weeksIncomeList.length) {
      return Container();
    }

    // 直接使用 IncomeData.x 的字符串（如 "04-10"）
    final dateText = minerLogic.weeksIncomeList[index].x;

    return SideTitleWidget(
      space: 10,
      axisSide: meta.axisSide,
      child: Text(dateText, style: style),
    );
  }

  SideTitles topTitles() => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          // 只在最大x坐标显示单位
          if (value == meta.min) {
            return Transform.translate(
              offset: Offset(-5, 0),
              child: Text(
                'TNT3 单位',
                style: TextStyle(fontSize: 10, color: AppColors.cff9bb),
              ),
            );
          } else if (value == meta.max) {
            return Transform.translate(
              offset: Offset(-5, 0),
              child: Text(
                'FIL 单位', // 在顶部显示单位
                style: TextStyle(fontSize: 10, color: AppColors.cff0084),
              ),
            );
          } else {
            return Container(); // 对于其他值返回空容器，不显示单位
          }
        },
        reservedSize: 30, // 给顶部标题预留空间
      );

  /// x轴配置
  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  /// 显示背景网格线
  FlGridData get gridData => const FlGridData(
        drawHorizontalLine: true, // 显示垂直网格线
        drawVerticalLine: true, // 不显示水平网格线
      );

  /// 边框线（只显示底部粗线，可改为 transparent 去掉）
  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.transparent, width: 0),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );

  // === 折线配置（每条折线一组）===
  /// 主图折线
  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: false,
        color: AppColors.themeColor,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true, // 显示数据点
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4, // 设置原点半径（默认是4）
            color: AppColors.themeColor, // 原点颜色
            // strokeWidth: 2, // 边框宽度
            // strokeColor: Colors.white, // 边框颜色
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.5),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        spots: minerLogic.weeksIncomeList.asMap().entries.map((entry) {
          final index = entry.key;
          final income = entry.value;
          return FlSpot(index.toDouble(), income.y);
        }).toList(),
      );
}

class LineChartSample1 extends StatefulWidget {
  const LineChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: MyLineChart(),
      margin: EdgeInsets.only(top: 20, bottom: 10),
    );
  }
}
