import 'package:flutter/cupertino.dart';
import 'package:titan_fil/styles/app_text_styles.dart';

import '../styles/app_colors.dart';

class UnderlinedText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color underlineColor;
  final double underlineHeight;
  final double underlineOffset;
  final TextAlign textAlign;

  const UnderlinedText({
    super.key,
    required this.text,
    this.textStyle,
    this.underlineColor = AppColors.themeColor,
    this.underlineHeight = 0.5,
    this.underlineOffset = 2,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          textAlign: textAlign,
          style: textStyle ?? AppTextStyles.textStyle10white.copyWith(
            color: AppColors.themeColor,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(0, underlineOffset),
            child: Container(
              height: underlineHeight,
              color: underlineColor,
            ),
          ),
        ),
      ],
    );
  }
}