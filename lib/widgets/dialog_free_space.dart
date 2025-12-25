import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:titan_fil/gen/assets.gen.dart';
import 'package:titan_fil/widgets/toast_dialog.dart';

import '../styles/app_colors.dart';

/// 释放空间对话框组件
class FreeSpaceDialog {
  final BuildContext context;
  final VoidCallback onConfirm;
  final TextEditingController controller;
  final double folderSize;

  /// 构造函数
  FreeSpaceDialog({
    required this.context,
    required this.onConfirm,
    required this.controller,
    required this.folderSize,
  });

  /// 显示对话框
  void show() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          content: _buildDialogContent(),
        );
      },
    );
  }

  /// 构建对话框内容
  Widget _buildDialogContent() {
    return Container(
      width: 360,
      height: _calculateDialogHeight(),
      decoration: _buildDialogDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderIcon(),
          _buildTitleText(),
          _buildUsageText(),
          _buildInputField(),
          _buildConfirmButton(),
          const SizedBox(height: 16),
          _buildCancelButton(),
        ],
      ),
    );
  }

  /// 计算对话框高度（根据语言适配）
  double _calculateDialogHeight() {
    return Get.locale?.languageCode == 'zh' ? 387 : 365;
  }

  /// 对话框装饰样式
  BoxDecoration _buildDialogDecoration() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 24, 24, 24),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// 顶部图标
  Widget _buildHeaderIcon() {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(top: 20),
      child: Assets.images.icLogo2.image(),
    );
  }

  final ButtonStyle _cancelButtonStyle = OutlinedButton.styleFrom(
    side: BorderSide(color: AppColors.themeColor, width: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
  );

  /// 标题文本
  Widget _buildTitleText() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Text(
        'settings_storage_free_space_tip'.tr,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 使用量文本
  Widget _buildUsageText() {
    return Container(
      margin: const EdgeInsets.only(top: 21),
      child: Text(
        'settings_storage_titan_used_space'.tr.replaceAll(" * ", "$folderSize"),
        style: const TextStyle(fontSize: 13, color: Colors.white),
      ),
    );
  }

  /// 输入框组件
  Widget _buildInputField() {
    return Container(
      width: 320,
      height: 37,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF353535),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildInputLabel(),
          _buildTextField(),
          _buildUnitLabel(),
        ],
      ),
    );
  }

  /// 输入框标签
  Widget _buildInputLabel() {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      child: Text(
        'settings_storage_freeing_space_name'.tr,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  /// 文本输入框
  Widget _buildTextField() {
    return Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          FilteringTextInputFormatter.deny(RegExp(r'^0+')),
        ],
        decoration: InputDecoration(
          enabledBorder: _textFieldBorder,
          disabledBorder: _textFieldBorder,
          focusedBorder: _textFieldBorder,
          contentPadding:
              const EdgeInsets.only(top: 0, bottom: 0, left: 2, right: 2),
          border: _textFieldBorder,
        ),
        onChanged: (value) => _handleInputChange(),
      ),
    );
  }

  /// 输入框边框样式
  final InputBorder _textFieldBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.transparent),
    borderRadius: BorderRadius.circular(10),
  );
  final ButtonStyle _actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.themeColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(50),
    ),
  );

  /// 单位标签
  Widget _buildUnitLabel() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: const Text(
        "GB",
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  /// 确认按钮

  Widget _buildConfirmButton() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      width: double.infinity,
      child: ElevatedButton(
        style: _actionButtonStyle,
        onPressed: () async {
          Navigator.of(context).pop();
          onConfirm();
        },
        child: Text(
          'settings_storage_apply_space_release'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// 取消按钮
  Widget _buildCancelButton() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(left: 20, right: 20),
      width: double.infinity,
      child: OutlinedButton(
        style: _cancelButtonStyle,
        onPressed: () {
          Navigator.of(context).pop();
          controller.text = "";
        },
        child: Text(
          'cancel'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 处理输入变化
  Future<bool> _handleInputChange() async {
    // 尝试解析输入文本为整数
    var text = int.tryParse(controller.text) ?? 0;
    // 如果输入值大于 0 且大于 folderSize，显示警告并返回 false
    if (text != 0 && text > folderSize) {
      controller.text = ""; // 清空文本框内容
      ToastHelper.showWarning(
        context,
        title: 'msg_dialog_error'.tr, // 错误标题
        message: "settings_storage_max_free_space"
            .tr
            .replaceAll("*", "${folderSize}GB"), // 替换占位符
        config: const ToastConfig(
          autoCloseDuration: Duration(seconds: 5), // 5秒后自动关闭
        ),
      );
      return false; // 返回 false
    }
    // 如果验证通过，返回 true
    return true;
  }
}
