import 'package:flutter/material.dart';

class SolidCircleWithNumber extends StatelessWidget {
  final double size; // 圆的大小
  final Color color; // 圆的颜色
  final int number; // 显示的数字
  final Color textColor; // 文字颜色
  final double fontSize; // 文字大小

  const SolidCircleWithNumber({
    Key? key,
    required this.size,
    required this.color,
    required this.number,
    this.textColor = Colors.white,
    this.fontSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
        Text(
          number.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
