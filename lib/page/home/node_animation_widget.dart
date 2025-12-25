import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import 'home_controller.dart';

class NodeAnimationWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HomeController>();
    final stats = logic.globalService;
    return RepaintBoundary(
      child: Obx(() {
        bool agentStatus = stats.isAgentRunning.value;
        final gifPath = (agentStatus)
            ? "assets/json/node_start.json"
            : "assets/json/node_stop.json";

        return Container(
          height: 320,
          child: Lottie.asset(gifPath, key: ValueKey(gifPath)),
          // child: GifView.asset(
          //   gifPath,
          //   key: ValueKey(gifPath), // 关键：确保路径变更时重新构建组件
          // ),
        );
      }),
    );
  }
}
