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
      return LineChart(
        sampleData1,
        duration: const Duration(milliseconds: 250),
      );
    });
  }

  /// 计算第一组数据的Y轴最大值
  double _calculatePrimaryMaxY() {
    if (minerLogic.weeksIncomeList.isEmpty) return 4;

    final maxDataY = minerLogic.weeksIncomeList
        .map((income) => income.y)
        .reduce((a, b) => a > b ? a : b);

    return maxDataY * 1.1;
  }

  /// 第二组数据的固定Y轴最大值
  static const double _secondaryMaxY = 15.0;

  /// 主图表配置
  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData(),
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        minX: 0,
        maxX: 14,
        minY: 0,
        maxY: _calculatePrimaryMaxY(),
      );

  /// 触摸交互配置
  LineTouchData lineTouchData() {
    return LineTouchData(
      enabled: true,
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> touchedIndexes) {
        return touchedIndexes.map((index) {
          final color = barData == lineChartBarData1_1
              ? AppColors.themeColor
              : AppColors.tcDB1;
          return TouchedSpotIndicatorData(
            FlLine(color: color, strokeWidth: 1),
            FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  color: color,
                  radius: 4,
                );
              },
            ),
          );
        }).toList();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            final isPrimary = spot.barIndex == 0;
            final value = isPrimary
                ? spot.y
                : (spot.y / _calculatePrimaryMaxY()) * _secondaryMaxY;
            return LineTooltipItem(
              '${spot.x.toInt()}: ${value.toStringAsFixed(2)}',
              TextStyle(
                color: isPrimary ? AppColors.themeColor : AppColors.tcDB1,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  /// 坐标轴标题配置
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

  /// 左侧Y轴标题（主数据）
  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: (value, meta) {
          const style = TextStyle(
            color: AppColors.cff9bb,
            fontSize: 10,
          );
          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(_formatYAxisLabel(value), style: style),
          );
        },
        showTitles: true,
        interval: _calculatePrimaryMaxY() / 4,
        reservedSize: 40,
      );

  /// 右侧Y轴标题（固定0-4范围，显示4等份）
  SideTitles rightTitles() => SideTitles(
        getTitlesWidget: (value, meta) {
          // 将主坐标系的Y值转换为次坐标系的Y值（0-4范围）
          final secondaryValue =
              (value / _calculatePrimaryMaxY()) * _secondaryMaxY;

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
        interval:
            _secondaryMaxY / (_calculatePrimaryMaxY() / (_secondaryMaxY / 4)),
        reservedSize: 40,
      );

  /// 网格线配置（确保右侧网格线对齐刻度）
  FlGridData get gridData => FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval:
            _calculatePrimaryMaxY() / (_secondaryMaxY / 0.5), // 使网格对齐右侧刻度
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          // 检查是否是右侧Y轴的刻度位置
          final secondaryValue =
              (value / _calculatePrimaryMaxY()) * _secondaryMaxY;
          if (secondaryValue % 1 == 0) {
            return FlLine(
              color: AppColors.tcDB1.withOpacity(0.3), // 参考数据网格用不同颜色
              strokeWidth: 1,
            );
          }
          return FlLine(
            color: Colors.grey.withOpacity(0.1), // 主网格线更淡
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.1),
          strokeWidth: 1,
        ),
      );

  /// X轴标题
  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: (value, meta) {
          const style = TextStyle(
            color: AppColors.tcCff,
            fontSize: 10,
          );
          final index = value.toInt();
          if (index < 0 || index >= minerLogic.weeksIncomeList.length) {
            return Container();
          }
          final dateText = minerLogic.weeksIncomeList[index].x;
          return SideTitleWidget(
            space: 10,
            axisSide: meta.axisSide,
            child: Text(dateText, style: style),
          );
        },
      );

  /// 顶部标题（图例）
  SideTitles topTitles() => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value == meta.min) {
            return Transform.translate(
              offset: Offset(-5, 0),
              child: Text(
                '矿工收益',
                style: TextStyle(fontSize: 10, color: AppColors.themeColor),
              ),
            );
          } else if (value == meta.max) {
            return Transform.translate(
              offset: Offset(-5, 0),
              child: Text(
                '参考数据 (0-4)',
                style: TextStyle(fontSize: 10, color: AppColors.tcDB1),
              ),
            );
          }
          return Container();
        },
        reservedSize: 30,
      );

  /// 格式化Y轴标签（主数据）
  String _formatYAxisLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return value.toInt().toString();
    }
  }

  /// 边框配置
  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.transparent, width: 0),
          left: BorderSide(color: Colors.grey.withOpacity(0.5)),
          right: BorderSide(color: Colors.grey.withOpacity(0.5)),
          top: BorderSide(color: Colors.transparent),
        ),
      );

  /// 折线数据
  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1, // 主数据集
        lineChartBarData2_2, // 参考数据集
      ];

  /// 主数据集（矿工数据）
  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: false,
        color: AppColors.themeColor,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3,
            color: AppColors.themeColor,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              AppColors.themeColor.withOpacity(0.3),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        spots: minerLogic.weeksIncomeList.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.y);
        }).toList(),
      );

  /// 参考数据集（固定0-4范围）
  LineChartBarData get lineChartBarData2_2 => LineChartBarData(
        isCurved: false,
        color: AppColors.tcDB1,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3,
            color: AppColors.tcDB1,
          ),
        ),
        // 标记使用右侧Y轴
        showingIndicators: [0],
        // 将参考数据的Y值映射到主坐标系
        spots: const [
          FlSpot(1, 1),
          FlSpot(3, 2.8),
          FlSpot(7, 1.2),
          FlSpot(10, 2.8),
          FlSpot(12, 2.6),
          FlSpot(13, 3.9),
        ].map((spot) {
          // 将0-4范围的Y值映射到主坐标系
          final mappedY = (spot.y / _secondaryMaxY) * _calculatePrimaryMaxY();
          return FlSpot(spot.x, mappedY);
        }).toList(),
      );
}
