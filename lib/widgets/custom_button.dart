import 'package:flutter/material.dart';

import '../styles/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double fontSize;
  final Color bacColor;
  final Color textColor;
  final double height;
  final double width;
  final TextAlign textAlign;
  final bool showLoad;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16,
    this.height = 38,
    this.width = double.infinity,
    this.bacColor = AppColors.themeColor, // 默认绿色
    this.textColor = Colors.black,
    this.textAlign = TextAlign.center,
    this.showLoad = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget textview() {
      return Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      );
    }

    Widget loadview() {
      return SizedBox(
        width: 15,
        height: 15,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bacColor, // 按钮背景色
        elevation: 0, // 去掉阴影
        padding: EdgeInsets.zero, // 去掉默认内边距
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40), // 圆角
        ),
      ),
      child: Container(
        height: height,
        width: width,
        alignment: Alignment.center,
        child: showLoad
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [loadview(), SizedBox(width: 5), textview()],
              )
            : textview(),
      ),
    );
  }
}
