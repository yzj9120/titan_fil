/**
 * 主界面控制器
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:titan_fil/utils/preferences_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../config/app_config.dart';
import '../../constants/constants.dart';
import '../../network/api_response.dart';
import '../../network/api_service.dart';
import '../../plugins/agent_plugin.dart';
import '../../services/global_service.dart';
import '../../services/log_service.dart';
import '../../services/pcdn_service.dart';
import '../../utils/app_helper.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/toast_dialog.dart';
import 'bind_state.dart';

class BindController extends GetxController {
  final BindPageState state = BindPageState();
  final GlobalService globalService = Get.find<GlobalService>();
  static final _logger3 = LoggerFactory.createLogger(LoggerName.t3);
  final logBuffer = StringBuffer();

  Timer? _timer;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  @override
  void onReady() {
    _setupVerifyCodeListeners();
    super.onReady();
  }

  @override
  void onClose() {
    _timer?.cancel();
    state.dispose();
    super.onClose();
  }

  Future<void> init() async {
    logBuffer.clear();
    logBuffer.writeln("bing account:");
    state.load.value = false;
    await initValue();
    await getPageInfoStatus();
    state.load.value = true;
  }

  // 获取t4绑定结果：通过缓存的hasT4Bind判断
  Future<bool> pcdnBindStatus() async {
    final value = await PreferencesHelper.getBool(Constants.hasT4Bind) ?? false;
    return value;
  }

  Future<String> getPCDNKey() async {
    final value = await PreferencesHelper.getString(Constants.bindKey) ?? "";
    return value;
  }

  Future<String?> getPCDNAccount() async {
    final key = await getPCDNKey();
    if (key.isNotEmpty) {
      try {
        //mQFWviNLBmJ2 //sM7BFQRmg1HI
        final response = await ApiService.getUserInfo(key);
        if (response != null) {
          state.userData.value = response;
          return response.account;
        }
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> initValue({int retryCount = 0}) async {
    const maxRetries = 5;
    // 2. 检查是否满足终止条件
    if (retryCount >= maxRetries) {
      return; // 终止递归
    }
    // 3. 不满足条件时，延迟后重试
    await Future.delayed(Duration(seconds: 1));
    await initValue(retryCount: retryCount + 1);
  }

  Future<void> getPageInfoStatus() async {
    /// 最后通过节点ID查询
    final t4key = await getPCDNKey();

    /// 如果KEY存在表明已经绑定，因为不管是否绑定了，key存在都会自动绑定
    bool hasT4Bind = t4key.isNotEmpty;
    logBuffer.writeln('hasBind: t4:${hasT4Bind}');
    if (hasT4Bind) {
      // 状态2: 仅 T4 绑定
      final value = await getPCDNAccount();
      if (value != null && value.isNotEmpty) {
        state.email.value = value;
        state.bindStatus.value = 0;
      } else {
        state.bindStatus.value = 1;
      }
    } else {
      //  T4 都未绑定
      state.bindStatus.value = 1;
    }
    logBuffer.writeln("email:${state.email.value}");
    debugPrint(
        "bindStatus:${state.bindStatus.value}:email:${state.email.value}");
  }

  void onViewOpen(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl =
        isChineseLocale ? AppConfig.walletUrlCn : AppConfig.walletUrlEn;
    AppHelper.openUrl(context, webUrl);
  }

  void onViewOpenUSDC(BuildContext context) {
    bool isChineseLocale = globalService.localeController.isChineseLocale();
    var webUrl =
        isChineseLocale ? AppConfig.usdcWalletUrlCn : AppConfig.usdcWalletUrlEn;
    AppHelper.openUrl(context, webUrl);
  }

  void onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0;
    if (isVisible) {
      if (state.bindStatus.value == 0) {
        getPageInfoStatus();
      }
    }
  }

  // 重置验证码相关状态
  void resetVerifyCode() {
    // 清空所有输入框
    for (var controller in state.verifyControllers) {
      controller.clear();
    }
    // 重置倒计时
    startTimer();
    // 将焦点设置到第一个输入框
    if (Get.context != null) {
      FocusScope.of(Get.context!).requestFocus(state.verifyFocusNodes[0]);
    }
  }

  void onAddStep() {
    state.step.value++;
    if (state.step.value > 4) {
      state.step.value = 4;
    }
  }

  void onClearStep() {
    state.step.value = 1;
    // 重置验证码状态
    resetVerifyCode();
  }

  // 设置验证码输入框的监听
  void _setupVerifyCodeListeners() {
    for (var i = 0; i < 6; i++) {
      state.verifyControllers[i].addListener(() {
        if (state.verifyControllers[i].text.length == 1) {
          if (i < 5) {
            FocusScope.of(Get.context!)
                .requestFocus(state.verifyFocusNodes[i + 1]);
          } else {
            // 最后一个输入框输入完成，收起键盘
            FocusScope.of(Get.context!).unfocus();
          }
        }
      });
    }
  }

  // 开始倒计时
  void startTimer() {
    _timer?.cancel();
    state.countDown.value = 60;
    state.canResend.value = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countDown.value > 1) {
        state.countDown.value--;
      } else {
        timer.cancel();
        state.canResend.value = true;
      }
    });
  }

  // 重新发送验证码
  void resendVerifyCode(BuildContext ctx) {
    if (state.canResend.value) {
      // 清空所有输入框
      for (var controller in state.verifyControllers) {
        controller.clear();
      }
      // 重新开始倒计时
      startTimer();
      // 将焦点设置到第一个输入框
      if (Get.context != null) {
        FocusScope.of(Get.context!).requestFocus(state.verifyFocusNodes[0]);
      }
      _sendEmailCode(ctx);
      // TODO: 添加重新发送验证码的API调用
    }
  }

  bool validateEmail(String email) {
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  bool validatePassword(String password) {
    // 密码的正则表达式：8-12 位，必须包含大写字母、小写字母、数字，允许符号，不能有中文
    String pattern =
        r'^(?=.*\d)(?=.*[a-zA-Z])(?=.*[.~!@#$%^&*])[\da-zA-Z.~!@#$%^&*]{8,12}$';
    RegExp regExp = RegExp(pattern);

    // 检查密码是否符合正则表达式
    return regExp.hasMatch(password);
  }

  // 验证并提交验证码
  Future<void> submitVerifyCode(BuildContext context) async {
    if (!state.isVerifyCodeComplete()) {
      _onErrorMsg(context, "bind_code_empty_error".tr);
      return;
    }
    logBuffer.clear(); // 清空所有内容
    String code = state.getVerifyCode();
    logBuffer.writeln("bind smsCode:$code");
    if (code.length != 6) {
      _onErrorMsg(context, "bind_email_length_error".tr);
      return;
    }
    final loading = LoadingIndicator();
    loading.show(context, message: "bind_loading".tr);
    final email = state.email.value;
    ApiResponse accountExistsRes = await ApiService.accountExists(email);

    ///查询是否是新用户
    logBuffer.writeln("accountExists:${accountExistsRes.toString()}");
    if (accountExistsRes.code != 200) {
      loading.hide();
      _onErrorMsg(context, accountExistsRes.msg);
      _log("exit 1:${logBuffer.toString()}");
      return;
    }
    //{"code":200,"msg":"Success","data":{"exists":false}}
    final exists = accountExistsRes.data['exists'];
    if (exists) {
      ///老用户- 登录
      ApiResponse accountLoginRes = await ApiService.accountLogin(email, code);

      ///老用户- 登录-获取pcdn_key
      logBuffer.writeln("accountLogin:${accountLoginRes.toString()}");
      if (accountLoginRes.code != 200) {
        loading.hide();
        _onErrorMsg(context, accountLoginRes.msg);
        _log("exit 2:${logBuffer.toString()}");
        return;
      }
      final t4key = accountLoginRes.data['key'];
      await _onHandBind(context, loading, t4key, email);
    } else {
      /// 新用户-注册获取 key:
      ApiResponse registerRes = await ApiService.register(email, code);

      ///bind 新用户-注册获取 key
      logBuffer.writeln("register:${registerRes.toString()}");
      if (registerRes.code == 200) {
        final t4Key = registerRes.data['key'];
        await _onHandBind(context, loading, t4Key, email);
      } else {
        loading.hide();
        _onErrorMsg(context, registerRes.msg);
        _log("exit 3:${logBuffer.toString()}");
      }
    }
  }

  Future<void> _onHandBind(BuildContext context, LoadingIndicator loading,
      String nodeKey, String email) async {
    logBuffer.writeln("start bing: $nodeKey; $email");

    /// 绑定4测key :
    final result = await AgentPlugin().bindKey(nodeKey);
    logBuffer.writeln("bind bindT4: $result");
    try {
      await initValue();
      await getPageInfoStatus();
      loading.hide();
    } catch (e) {
      loading.hide();
      _onErrorMsg(context, 'error:$e');
      _log("exit 8:${logBuffer.toString()}");
    }
  }

  ///发送验证码
  Future<bool> _sendEmailCode(BuildContext ctx) async {
    final loading = LoadingIndicator();
    loading.show(ctx, message: "bind_code_snd".tr);
    FocusManager.instance.primaryFocus?.unfocus();
    int type = 0;
    final email = state.email.value;
    // 验证是否新用户
    ApiResponse accountExistsRes = await ApiService.accountExists(email);
    _log('_sendEmailCode: accountExistsRes:${accountExistsRes}');
    if (accountExistsRes.code == 200) {
      final exists = accountExistsRes.data['exists'];
      if (exists == true) {
        type = 1;
      }
    }
    state.emailCodeStatus.value = 1;
    // 发送验证码
    ApiResponse codeRes = await ApiService.emailVerifyCode(email, type);
    _log('_sendEmailCode: emailVerifyCode:${codeRes}');
    loading.hide();
    if (codeRes.code == 200) {
      state.emailCodeStatus.value = 2;
      return true;
    } else {
      state.emailCodeStatus.value = 3;
      state.sndError.value = (codeRes.msg ?? null)!;
      _onErrorMsg(ctx, "${codeRes.msg}");
      return false;
    }
  }

  /// 下一步
  Future<void> onCreateEmail(BuildContext context, String email) async {
    var nextStatus = false;
    var isSuccess = false;
    if (globalService.agentId.isNotEmpty) {
      ///启动过不需要启动4测即可绑定
    } else {
      /// 没有启动过 再启动一次
      final pcdService = PCDNService.getInstance();
      bool isOpen = globalService.pcdnMonitoringStatus.value == 3;
      pcdService.startAutoEarningProcess(context, isOpen: isOpen);
    }
    //邮箱
    if (email.isEmpty) {
      _onErrorMsg(context, "bind_email_empty_error".tr);
      return;
    }
    //验证是否是邮箱
    if (!validateEmail(email)) {
      _onErrorMsg(context, "bind_email_format_error".tr);
      return;
    }
    state.email.value = email;
    final result = await _sendEmailCode(context);
    if (result) {
      onAddStep();
      startTimer();
    }
  }

  void _onErrorMsg(BuildContext context, String msg) {
    ToastHelper.showWarning(
      context,
      title: 'msg_dialog_error'.tr, // 错误标题
      message: msg,
      config: const ToastConfig(
        autoCloseDuration: Duration(seconds: 5),
      ),
    );
  }

  void _log(dynamic message, {bool w = true}) {
    if (w) {
      _logger3.info("[Bind]:$message");
    } else {
      _logger3.warning("[Bind]:$message");
    }
  }
}
