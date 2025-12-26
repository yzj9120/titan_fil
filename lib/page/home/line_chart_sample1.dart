import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../styles/app_colors.dart';
import '../../controllers/agent_controller.dart';
import 'home_controller.dart';

class MyLineChart extends StatelessWidget {
  final logic = Get.find<HomeController>();
  final agentController = Get.find<AgentController>();

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
    if (agentController.nodeIncomeList.isEmpty) return 4;
    var maxIncome = agentController.nodeIncomeList
        .map((incomeData) => incomeData.incomeU.toDouble())
        .reduce((a, b) => a > b ? a : b);
    if (maxIncome < 4) {
      maxIncome = 4;
    }
    return maxIncome * 1.1; // 添加10%的余量
  }

  /// 第二组数据的固定Y轴最大值

  /// 主图表配置
  LineChartData get sampleData1 => LineChartData(
        lineTouchData: lineTouchData(),
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        minX: 0,
        maxX: 13,
        minY: 0,
        maxY: _calculatePrimaryMaxY(),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
                y: 0.0, color: Colors.white.withOpacity(1), strokeWidth: 0.2),
          ],
        ),
      );

  /// 触摸交互配置
  LineTouchData lineTouchData() {
    return LineTouchData(
      enabled: true,
      getTouchedSpotIndicator:
          (LineChartBarData barData, List<int> touchedIndexes) {
        return touchedIndexes.map((index) {
          final color = AppColors.tcDB1;
          return TouchedSpotIndicatorData(
            FlLine(color: color, strokeWidth: 0.5),
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
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            return LineTooltipItem(
              'FIL: ${spot.y.toStringAsFixed(4)}', // 直接显示y值
              TextStyle(
                color: AppColors.cff0084,
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
        // leftTitles: AxisTitles(sideTitles: leftTitles()),
        rightTitles: AxisTitles(sideTitles: rightTitles()),
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

  /// 右侧Y轴标题（显示最大值的4等分）
  double getInterval() {
    final primaryMaxY = _calculatePrimaryMaxY();
    // 确保返回合理的间隔值
    return (primaryMaxY / 4).clamp(1.0, double.infinity); // 最小间隔为1.0
  }

  SideTitles rightTitles() => SideTitles(
        getTitlesWidget: (value, meta) {
          final maxIncome = agentController.getMaxIncome();
          final primaryMaxY = _calculatePrimaryMaxY();
          // 添加调试信息
          //debugPrint("PrimaryMaxY: $primaryMaxY, MaxIncome: $maxIncome");
          // 安全保护
          if (primaryMaxY <= 0 || maxIncome <= 0) {
            return Container();
          }
          // 计算转换后的值
          final secondaryValue = (value / primaryMaxY) * maxIncome;
          const style = TextStyle(
            color: AppColors.cff0084,
            fontSize: 10,
          );

          // 生成5个目标点 (0%, 25%, 50%, 75%, 100%)
          final targetPoints = [
            0.0,
            maxIncome * 0.25,
            maxIncome * 0.5,
            maxIncome * 0.75,
            maxIncome
          ];
          // debugPrint("Actual Target Points: $targetPoints");
          // 找到最接近的目标点
          final closestPoint = targetPoints.reduce((a, b) =>
              (secondaryValue - a).abs() < (secondaryValue - b).abs() ? a : b);

          // 显示逻辑 - 调整容差
          final tolerance = maxIncome * 0.01; // 1%的容差
          if ((secondaryValue - closestPoint).abs() < tolerance) {
            // 改进的显示格式
            String displayText;
            if (closestPoint == 0) {
              displayText = "0";
            } else if (closestPoint < 0.1) {
              displayText = closestPoint.toStringAsFixed(3); // 小于0.1显示3位小数
            } else if (closestPoint < 1) {
              displayText = closestPoint.toStringAsFixed(2); // 小于1显示2位小数
            } else if (closestPoint % 1 == 0) {
              displayText = closestPoint.toInt().toString();
            } else {
              displayText = closestPoint.toStringAsFixed(1);
            }
            return SideTitleWidget(
              axisSide: meta.axisSide,
              child: Text(displayText, style: style),
            );
          }
          return Container();
        },
        showTitles: true,
        interval: getInterval(),
        reservedSize: 40,
      );

  /// 网格线配置（确保右侧网格线对齐刻度）
  FlGridData get gridData => const FlGridData(
        drawHorizontalLine: false, // 显示垂直网格线
        drawVerticalLine: false, // 不显示水平网格线
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

          // 如果有数据，用数据的时间戳
          if (index >= 0 && index < agentController.nodeIncomeList.length) {
            final incomeData = agentController.nodeIncomeList[index];
            final timestamp = incomeData.createdAt;

            // 直接转换时间戳为日期
            try {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
              final dateText =
                  '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              return SideTitleWidget(
                space: 10,
                axisSide: meta.axisSide,
                child: Text(dateText, style: style),
              );
            } catch (e) {
              // 转换失败，显示索引
              return SideTitleWidget(
                space: 10,
                axisSide: meta.axisSide,
                child: Text('${index + 1}', style: style),
              );
            }
          }

          // 没有数据时，显示默认的连续日期
          final now = DateTime.now();
          // 假设显示最近14天
          final date = now.subtract(Duration(days: 13 - index));
          final dateText =
              '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
            return SizedBox();
          } else if (value == meta.max) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'FIL ${"unit".tr}',
                style: TextStyle(fontSize: 10, color: AppColors.cff0084),
              ),
            );
          } else {
            return Container();
          }
        },
        reservedSize: 30, // 给顶部标题预留空间
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
        lineChartBarData2_2, // 参考数据集
      ];

  /// 参考数据集（固定0-4范围）
  LineChartBarData get lineChartBarData2_2 => LineChartBarData(
        isCurved: false,
        color: AppColors.cff0084,
        barWidth: 1,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3,
            color: AppColors.tcDB1,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [Color(0X1A00F190), Color(0X0000F190)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // 标记使用右侧Y轴
        showingIndicators: [0],
        // 将参考数据的Y值映射到主坐标系
        spots: agentController.nodeIncomeList.asMap().entries.map((entry) {
          final index = entry.key + 0;
          final income = entry.value.incomeU.toDouble(); // 确保转换为double
          final maxIncome = agentController.getMaxIncome().toDouble();
          final primaryMaxY = _calculatePrimaryMaxY();
          final mappedY =
              maxIncome > 0 ? (income / maxIncome) * primaryMaxY : 0.0;
          return FlSpot(index.toDouble(), mappedY);
        }).toList(),
      );
}
