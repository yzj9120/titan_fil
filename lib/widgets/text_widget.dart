import 'package:flutter/material.dart';

class TextWidget extends StatefulWidget {
  final String msg;
  final double fontSize;
  final Color? color;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final TextDecoration decoration;
  final Paint? foreground;
  final bool needClip;
  final double letterSpace;
  final double wordSpace;
  final double height;
  final int? maxLine;

  const TextWidget(
    this.msg, {
    super.key,
    this.fontSize = 14,
    this.textAlign = TextAlign.start,
    this.color,
    this.fontWeight = FontWeight.normal,
    this.maxLine,
    this.decoration = TextDecoration.none,
    this.foreground,
    this.needClip = false,
    this.letterSpace = 0,
    this.wordSpace = 0,
    this.height = 1,
  });

  @override
  TextWidgetState createState() => TextWidgetState();
}

class TextWidgetState extends State<TextWidget> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.msg,
      textAlign: widget.textAlign,
      overflow: widget.needClip ? TextOverflow.ellipsis : null,
      maxLines: widget.maxLine,
      style: TextStyle(
        fontFamily: 'MiSans',
        foreground: widget.foreground,
        decoration: widget.decoration,
        fontSize: widget.fontSize,
        color: widget.foreground == null ? widget.color ?? Colors.grey : null,
        fontWeight: widget.fontWeight,
        letterSpacing: widget.letterSpace,
        wordSpacing: widget.wordSpace,
        height: widget.height,

      ),
    );
  }
}
