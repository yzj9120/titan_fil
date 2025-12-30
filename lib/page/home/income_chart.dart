import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../gen/assets.gen.dart';
import '../../../styles/app_colors.dart';
import '../../controllers/agent_controller.dart';
import '../../controllers/miner_controller.dart';
import '../../utils/LoggerUtil.dart';
import '../../widgets/custom_tooltip.dart';
import 'home_controller.dart';
import 'line_chart_sample1.dart';

class IncomeChart extends StatelessWidget {
  const IncomeChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HomeController>();
    return Container(
      margin: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildRunningTasksNote(context, logic),
          const SizedBox(height: 15),
          _buildRunningTasksSection(context, logic),
          const SizedBox(height: 10),
          _buildIncomeCardsRow(context, logic),
          const SizedBox(height: 15),
          _buildTrendTitle(context, logic),
          Spacer(),
          _buildTrendChart(context, logic),
        ],
      ),
    );
  }

  Widget _buildRunningTasksNote(BuildContext context, HomeController logic) {
    return Container(
      height: 100,
      decoration: _roundedBoxDecoration(AppColors.c1818),
      alignment: Alignment.center,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              borderRadius: BorderRadius.circular(28), // 圆角
              onTap: () => logic.openNodeRewards(context),
              child: Row(
                children: [
                  Text(
                    "index_income_node_title".tr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  Spacer(),
                  Text(
                    "more".tr,
                    style: const TextStyle(
                        color: AppColors.themeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.themeColor,
                    size: 12,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "index_income_node_1".tr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            "index_income_node_2".tr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            "index_income_node_3".tr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建"正在进行的任务"部分
  Widget _buildRunningTasksSection(BuildContext context, HomeController logic) {
    return Row(
      children: [
        Expanded(child: _buildTasksLabelContainer(context, logic)),
        SizedBox(
          width: 10,
        ),
        _buildTasksCounterContainer(logic, "PCDN", AppColors.themeColor,
            AppColors.back1, FontWeight.bold),
      ],
    );
  }

  /// 构建任务标签容器
  Widget _buildTasksLabelContainer(BuildContext context, HomeController logic) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => logic.onOpenNodeRevenue(context),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 55,
          decoration: _roundedBoxDecoration(AppColors.c1818),
          child: Row(
            children: [
              const SizedBox(width: 18),

              Assets.images.icTag.image(width: 31),
              const SizedBox(width: 5),
              Text(
                "index_node_revenue".tr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Assets.images.icArrowInfo.image(width: 22),
              Text('\u{1F4B0}', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 22),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建计数容器
  Widget _buildTasksCounterContainer(HomeController logic, String str,
      Color color, Color txtColor, FontWeight fontWeight) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(28), // 圆角
        onTap: () => logic.onChangeStorageOrPcdn(),
        child: Container(
          width: 120,
          height: 55,
          decoration: _roundedBoxDecoration(color),
          alignment: Alignment.center,
          child: Text(
            str.tr,
            style: TextStyle(
                color: txtColor, fontSize: 13, fontWeight: fontWeight),
          ),
        ),
      ),
    );
  }

  /// 构建"收益趋势"标题部分
  Widget _buildTrendTitle(BuildContext context, HomeController logic) {
    return Container(
      height: 55,
      decoration: _roundedBoxDecoration(AppColors.c1818),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Assets.images.icTag.image(width: 31),
          const SizedBox(width: 5),
          Text(
            "index_revenue_trend".tr,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          _buildTrendLegend(AppColors.btn, "FIL"),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  /// 构建收益趋势图表部分
  Widget _buildTrendChart(BuildContext context, HomeController logic) {
    return Container(
      height: 300,
      decoration: _roundedBoxDecoration(AppColors.c1818),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: MyLineChart(),
    );
  }

  /// 构建趋势图例
  Widget _buildTrendLegend(Color color, String label) {
    return Row(
      children: [
        Assets.images.icTag.image(width: 12, color: AppColors.cff0084),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(color: AppColors.tcCff, fontSize: 9)),
      ],
    );
  }

  /// 圆角框装饰器
  BoxDecoration _roundedBoxDecoration(Color color, {double radius = 28}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  double truncateToDecimalPlaces(double num, int fractionDigits) {
    int factor = pow(10, fractionDigits).toInt();
    return (num * factor).floor() / factor;
  }

  String formatNumber(double number, int fractionDigits) {
    return truncateToDecimalPlaces(number, fractionDigits)
        .toStringAsFixed(fractionDigits);
  }

  /// 构建收益卡片行
  Widget _buildIncomeCardsRow(BuildContext context, HomeController logic) {
    final agentController = Get.find<AgentController>();

    return Row(
      children: [
        Obx(() {
          final value = agentController.nodeInfo.value?.receivedIncome ?? 0;
          final value2 = agentController.nodeInfo.value?.remainder_income ?? 0;
          final v = value+ value2;
          final unit = v.toString().length > 6 ? ".." : "";
          return _buildIncomeCard(
              icon: Assets.images.icHomeIncome.image(width: 45),
              label: "index_totalIncome".tr,
              value: v,
              unit: "$unit FIL".tr,
              usdcValue: 0,
              usdcUnit: "$unit FIL".tr,
              type: 1);
        }),
        const SizedBox(width: 10),
        Obx(() {
          final value = agentController.last7DaysIncomeSum();
          final unit = value.toString().length > 6 ? ".." : "";
          return _buildIncomeCard(
              icon: Assets.images.icHomeIncome7.image(width: 45),
              label: "index_weekIncome".tr,
              value: value,
              unit: "$unit FIL".tr,
              usdcValue: 0,
              usdcUnit: "$unit FIL".tr,
              type: 1);
        }),
        const SizedBox(width: 10),
        Obx(() {
          final value = agentController.nodeInfo.value?.todayIncome ?? 0;
          final unit = value.toString().length > 6 ? ".." : "";
          return _buildIncomeCard(
              icon: Assets.images.icHomeIncomeToady.image(width: 45),
              label: "index_todayIncome".tr,
              value: value,
              unit: "$unit FIL".tr,
              usdcValue: 0,
              usdcUnit: "$unit FIL".tr,
              type: 1);
        }),
      ],
    );
  }

  /// 构建单个收益卡片
  Widget _buildIncomeCard({
    required Widget icon,
    required String label,
    required double value,
    required String unit,
    required double usdcValue,
    required String usdcUnit,
    required int type,
  }) {
    return Expanded(
      child: IncomeCard(
        icon: icon,
        label: label,
        value: value,
        unit: unit,
        usdcValue: usdcValue,
        usdcUnit: usdcUnit,
        type: type,
      ),
    );
  }
}

class IncomeCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final double value;
  final String unit;
  final double usdcValue;
  final String usdcUnit;
  final int type;

  const IncomeCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.usdcValue,
    required this.usdcUnit,
    required this.type,
  }) : super(key: key);

  double truncateToDecimalPlaces(double num, int fractionDigits) {
    int factor = pow(10, fractionDigits).toInt();
    return (num * factor).floor() / factor;
  }

  String formatNumber(double number, int fractionDigits) {
    return truncateToDecimalPlaces(number, fractionDigits)
        .toStringAsFixed(fractionDigits);
  }

  String getFirstSixTake(String input) {
    return input.length > 6 ? input.substring(0, 6) : input;
  }

  Widget _buildValueRow(String displayValue, String unitText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CustomTooltip(
          message: displayValue,
          preferredDirection: AxisDirection.up,
          sizeWidth: 0,
          fontSize: 15,
          child: Text(
            getFirstSixTake(displayValue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Transform.translate(
          offset: const Offset(0, -5),
          child: Text(
            unitText,
            style: const TextStyle(color: AppColors.tcC6ff, fontSize: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 241,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.c1818,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 29),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(label,
                style: const TextStyle(color: AppColors.cf9, fontSize: 12)),
            const Spacer(),
            if (type == 1) ...[
              _buildValueRow("$value", unit),
            ] else ...[
              _buildValueRow("$usdcValue", usdcUnit),
              if ((label != "index_weekIncome".tr &&
                      label != "index_todayIncome".tr) &&
                  value > 0)
                _buildValueRow("$value", unit),
            ],
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
