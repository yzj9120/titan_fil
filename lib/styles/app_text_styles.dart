import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  // 基础字体样式（统一设置 fontFamily）
  static const TextStyle base = TextStyle(
    color: AppColors.text,
    textBaseline: TextBaseline.alphabetic,
  );

  // 标题类
  static final TextStyle heading = base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle tipTitle = base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.tipTitleColor,
  );

  static final TextStyle tipDescription = base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.tipDescriptionColor,
  );

  static final TextStyle textBold = base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.themeColor,
  );

  // 正文类
  static final TextStyle body = base.copyWith(fontSize: 16);

  static final TextStyle textPrompt = base.copyWith(
    fontSize: 14,
    color: Colors.white,
  );

  static final TextStyle textCff = base.copyWith(
    fontSize: 14,
    color: AppColors.tcCff,
  );

  static final TextStyle textStyle12 = base.copyWith(
    fontSize: 12,
    color: AppColors.cf9,
  );

  static final TextStyle textStyle11 = base.copyWith(
    fontSize: 11,
    color: AppColors.tcC6ff,
  );

  static final TextStyle textUnderline = base.copyWith(
    fontSize: 12,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.tipDescriptionColor,
    color: AppColors.tipDescriptionColor,
  );

  static final TextStyle textStyle10 = base.copyWith(
    fontSize: 11,
    color: AppColors.tcC6ff,
  );

  static final TextStyle textStyle15 = base.copyWith(
    fontSize: 15,
    color: Colors.white,
  );

  static final TextStyle textStyle15black = base.copyWith(
    fontSize: 15,
    color: Colors.black,
  );

  static final TextStyle textStyle13 = base.copyWith(
    fontSize: 13,
    color: Colors.white,
  );

  static final TextStyle textStyle13black = base.copyWith(
    fontSize: 13,
    color: Colors.black,
  );

  static final TextStyle textStyle10black = base.copyWith(
    fontSize: 11,
    color: AppColors.text,
  );

  static final TextStyle textStyle12white = base.copyWith(
    fontSize: 12,
    color: Colors.white,
  );

  static final TextStyle textStyle12gray = base.copyWith(
    fontSize: 12,
    color: AppColors.ff60,
  );

  static final TextStyle textStyle12black = base.copyWith(
    fontSize: 12,
    color: Colors.black,
  );

  static final TextStyle textStyle10blackbold = base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    height: 1,
  );

  static final TextStyle textStyle26 = base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static final TextStyle textStyleTip10 = base.copyWith(
    fontSize: 10,
    color: AppColors.tipDescriptionColor,
  );
  static final TextStyle textStyleTip10back = base.copyWith(
    fontSize: 10,
    color: AppColors.back1,
  );

  static final TextStyle textStyle10white = base.copyWith(
    fontSize: 10,
    color: AppColors.tipTitleColor,
  );
  static final TextStyle textStyle10Back = base.copyWith(
    fontSize: 10,
    color: AppColors.back1,
  );

  static final TextStyle textStyle9white = base.copyWith(
    fontSize: 9,
    color: AppColors.tipTitleColor,
  );
  static final TextStyle textStyle9Back = base.copyWith(
    fontSize: 9,
    color: AppColors.back1,
  );

  static final TextStyle textStyle29 = base.copyWith(
    fontSize: 18,
    color: AppColors.tipTitleColor,
  );

  // 按钮样式
  static final TextStyle button = base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
