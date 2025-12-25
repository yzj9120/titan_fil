import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:titan_fil/extension/extension.dart';
import 'package:titan_fil/widgets/LoadingWidget.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../gen/assets.gen.dart';
import '../../../models/log_entry.dart';
import '../../../styles/app_colors.dart';
import 'logs_controller.dart';
import 'logs_state.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LogsController());
    final state = controller.state;

    return VisibilityDetector(
        key: Key('my-logs'),
        onVisibilityChanged: (VisibilityInfo info) {
          controller.onVisibilityChanged(info);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopButtonBar(context, controller, state),
              const SizedBox(height: 12),
              _buildLogContentArea(controller, state),
            ],
          ),
        ));
  }

  Widget _buildTopButtonBar(
      BuildContext context, LogsController controller, LogsState state) {
    return Row(
      children: [
        Container(
          width: controller.globalService.localeController.isChineseLocale()
              ? 720
              : 670,
          height: 55,
          decoration: BoxDecoration(
            color: AppColors.c1818,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              const SizedBox(width: 23),
              Assets.images.icTag.image(width: 31),
              const SizedBox(width: 5),
              Text(
                "settings_logs_select_date".tr,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(width: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  onTap: () async {
                    controller.onSelectTime(context);
                  },
                  child: Container(
                    width: 157,
                    height: 29,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E0E0E), // 等价于 #0E0E0E
                      borderRadius: BorderRadius.circular(6), // 四个角都是6px
                      border: Border.all(
                        color: const Color(0xFF474747), // 边框颜色 #474747
                        width: 1, // 边框宽度1px
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 20),
                        Obx(() => Text(
                              '${state.selectedTime.value}',
                              style: TextStyle(
                                  fontWeight: state.currentTime ==
                                          state.selectedTime.value
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                  color: state.currentTime ==
                                          state.selectedTime.value
                                      ? Colors.white38
                                      : AppColors.themeColor,
                                  fontSize: 13),
                            )),
                        Spacer(),
                        Icon(
                          Icons.expand_more,
                          color: const Color(0xFF474747),
                          size: 20,
                        )
                      ],
                    ), // 可以添加子组件
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildSubmitButton(context, controller),
        SizedBox(width: 10),
        _buildOpenLogDirectoryButton(controller),
      ],
    );
  }

  Widget _buildDateScrollList(LogsController controller, LogsState state) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          return Row(
            children: state.dateList.mapIndexed((index, date) {
              return _buildDateButton(controller, state, index, date);
            }).toList(),
          );
        }),
      ),
    );
  }

  Widget _buildDateButton(
      LogsController controller, LogsState state, int index, String date) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => controller.onChangeSelect(index, date),
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: state.selectedIndex.value == index
                  ? AppColors.themeColor
                  : Colors.transparent,
              width: 1,
              style: BorderStyle.solid, // 可选 dashed（虚线）
            ),
          ),
        ),
        child: Text(
          "$date.log",
          style: TextStyle(
            color: state.selectedIndex.value == index
                ? AppColors.themeColor
                : Colors.white,
            fontSize: state.selectedIndex.value == index ? 13 : 12,
            fontWeight: state.selectedIndex.value == index
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, LogsController controller) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          controller.onSendLogs(context);
        },
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.themeColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Text(
            'settings_logs_send'.tr,
            style: TextStyle(
              color: AppColors.background,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenLogDirectoryButton(LogsController controller) {
    return SizedBox(
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.themeColor),
        ),
        onPressed: controller.onOpenLogDirectory,
        child: Text(
          'open_log_directory'.tr,
          style: TextStyle(color: AppColors.themeColor, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildLogContentArea(LogsController controller, LogsState state) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.c1818,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Obx(() {
          return Column(
            children: [
              _buildDateScrollList(controller, state),
              if (state.isLoading.value) ...[
                SizedBox(height: 300),
                Center(child: LoadingWidget())
              ] else if (state.logs.isEmpty) ...[
                SizedBox(height: 300),
                Center(
                    child: Text('not_data'.tr,
                        style: TextStyle(color: Colors.white38, fontSize: 12)))
              ] else ...{
                Expanded(
                  child: ListView.builder(
                    itemCount: state.logs.length,
                    itemBuilder: (context, index) =>
                        _buildLogItem(state.logs[index]),
                  ),
                )
              }
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogItem(LogEntry log) {
    var color = Colors.blue;
    if (log.level == Level.WARNING.name || log.level == 'warning') {
      color = Colors.orange;
    } else if (log.level == Level.SEVERE.name || log.level == 'ERROR') {
      color = Colors.red;
    }
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      title: Text('${log.level} - ${log.ts}',
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      subtitle: Text(log.msg,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}
