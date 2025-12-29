import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/user_data.dart';

class BindPageState {
  // var t3Account = "";
  // var t4Account = "";
  var step = 1.obs;
  var bindStatus = (-1).obs;
  var email = "".obs;
  var key = "".obs;
  var agentId = "".obs;

  var load = false.obs;
  var emailCodeStatus = 0.obs;
  Rx<String> sndError = "".obs;
  var isNewUser = false;
  Rx<UserData> userData = UserData(
    address: "",
    account: "",
    addressEth: '',
  ).obs;

  // 邮箱输入框控制器
  final emailController = TextEditingController();

  // 验证码输入框控制器
  final List<TextEditingController> verifyControllers =
      List.generate(6, (index) => TextEditingController());

  // 验证码输入框焦点
  final List<FocusNode> verifyFocusNodes =
      List.generate(6, (index) => FocusNode());

  // 倒计时相关
  final RxInt countDown = 60.obs;
  final RxBool canResend = false.obs;

  // 获取完整的验证码
  String getVerifyCode() {
    return verifyControllers.map((c) => c.text).join();
  }

  // 验证码是否完整
  bool isVerifyCodeComplete() {
    return verifyControllers.every((c) => c.text.isNotEmpty);
  }

  // 释放资源
  void dispose() {
    emailController.dispose();
    for (var controller in verifyControllers) {
      controller.dispose();
    }
    for (var node in verifyFocusNodes) {
      node.dispose();
    }
  }
}
