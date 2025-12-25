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
      //print('Date: ${ minerLogic.weeksIncomeList.toJson()}');
      return LineChart(
        sampleData1,
        duration: const Duration(milliseconds: 250), // 动画时间
      );
    });
  }

  /// 主图数据
  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData(),
        // 触摸交互
        gridData: gridData,
        // 网格线
        titlesData: titlesData1,
        // 坐标轴标题
        borderData: borderData,
        // 边框线
        lineBarsData: lineBarsData1,
        // 折线数据
        minX: 0,
        // X 轴最小值
        maxX: 14,
        // X 轴最大值
        minY: 0,
        // Y 轴最小值
        maxY: 4, // Y 轴最大值
      );

  /// 交互配置：启用默认触摸行为，显示tooltip
  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.green,
        ),
      );

// 配置触摸数据，定制悬停时的样式
  LineTouchData lineTouchData() {
    return LineTouchData(
      enabled: true, // 启用触摸交互
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> touchedIndexes) {
        // 返回每个触摸点的指示器，可以设置不同的样式
        return touchedIndexes.map((index) {
          return TouchedSpotIndicatorData(
            FlLine(
              color: AppColors.cff0084, // Color of the vertical line
              strokeWidth: 1, // Stroke width of the vertical line
            ),
            FlDotData(
              show: true, // Whether to show the dot at the touched spot
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  color: Colors.red, // Color of the dot
                  radius: 4, // Size of the dot
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
        bottomTitles: AxisTitles(sideTitles: bottomTitles), // 底部
        leftTitles: AxisTitles(sideTitles: leftTitles()), // 左侧
        rightTitles: AxisTitles(sideTitles: rightTitles()), // 右侧
        topTitles: AxisTitles(sideTitles: topTitles()), //顶部
      );

  /// 折线数据（默认主图只显示一条线）
  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
        lineChartBarData2_2,
      ];

  /// y轴刻度样式
  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.cff9bb,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1m';
        break;
      case 2:
        text = '2m';
        break;
      case 3:
        text = '3m';
        break;
      case 4:
        text = '5m';
        break;
      case 5:
        text = '6m';
        break;
      default:
        return Container(); // 其他值不显示
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  /// y轴刻度样式
  Widget rightTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.cff0084,
      fontSize: 10,
    );
    String text;
    switch (value.toInt()) {
      case 1:
        text = '1m';
        break;
      case 2:
        text = '2m';
        break;
      case 3:
        text = '3m';
        break;
      case 4:
        text = '5m';
        break;
      case 5:
        text = '6m';
        break;
      default:
        return Container(); // 其他值不显示
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style, textAlign: TextAlign.center),
    );
  }

  /// x轴配置
  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true, //true，表示显示标题，若设置为 false，则不显示标题
        interval: 1, //每隔 1 个单位显示一个标题，如 1m、2m、3m 等
        reservedSize: 40, //预留 40 像素宽度给左侧标题，以确保标题有足够的空间显示
      );

  SideTitles topTitles() => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          // 只在最大x坐标显示单位
          if (value == meta.min) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'TNT3 单位', // 在顶部显示单位
                style: TextStyle(fontSize: 10, color: AppColors.cff9bb),
              ),
            );
          } else if (value == meta.max) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
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

  SideTitles rightTitles() => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 1,
        reservedSize: 40,
      );

  /// x轴刻度样式
  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    print('======value======$value');

    //minerLogic
    const style = TextStyle(
      color: AppColors.tcCff,
      fontSize: 10,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('03-23', style: style);
        break;
      case 7:
        text = const Text('03-24', style: style);
        break;
      case 12:
        text = const Text('03-25', style: style);
        break;
      default:
        text = const Text('03-26', style: style);
        break;
    }

    return SideTitleWidget(
      space: 10,
      axisSide: meta.axisSide,
      child: text,
    );
  }

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
        // 折线（false表示折线，不是弧线）
        color: AppColors.themeColor,
        barWidth: 1,
        // 线宽
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        // 显示拐点
        // belowBarData: BarAreaData(show: false), // 不显示底部阴影区域
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

        spots: const [
          FlSpot(1, 1),
          FlSpot(3, 1.5),
          FlSpot(5, 1.4),
          FlSpot(7, 3.4),
          FlSpot(10, 2),
          FlSpot(12, 2.2),
          FlSpot(13, 1.8),
        ],
      );

  /// 备用图折线 1
  LineChartBarData get lineChartBarData2_1 => LineChartBarData(
        isCurved: false,
        curveSmoothness: 0,
        color: AppColors.tc435,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        // belowBarData: BarAreaData(show: false),
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

        spots: const [
          FlSpot(1, 1),
          FlSpot(3, 4),
          FlSpot(5, 1.8),
          FlSpot(7, 5),
          FlSpot(10, 2),
          FlSpot(12, 2.2),
          FlSpot(13, 1.8),
        ],
      );

  /// 备用图折线 2
  LineChartBarData get lineChartBarData2_2 => LineChartBarData(
        isCurved: false,
        color: AppColors.tcDB1,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
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
        spots: const [
          FlSpot(1, 1),
          FlSpot(3, 2.8),
          FlSpot(7, 1.2),
          FlSpot(10, 2.8),
          FlSpot(12, 2.6),
          FlSpot(13, 3.9),
        ],
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
