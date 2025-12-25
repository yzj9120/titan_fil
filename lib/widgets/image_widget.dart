import 'dart:io';

import 'package:flutter/cupertino.dart';

class ImageWidget extends StatefulWidget {
  final String imagePath;
  final String? defaultImagePath;
  final double? width;
  final double? height;
  final BoxFit
      boxFit; //fill(全图显示且填充满，图片可能会拉伸)，contain（全图显示但不充满，显示原比例），cover（显示可能拉伸，也可能裁剪，充满）
  final double radius;
  final Color? color;
  final bool enabledDefineColor; // 是否填充背景色
  final Color? defineColor; //背景色
  final double? defineWidth; //默认图片宽度
  final double? defineHeight; //默认图片高度
  final bool errorEnabledBGColor; //是否开启错误背景色
  const ImageWidget(
      {super.key,
      this.imagePath = '',
      this.height,
      this.width,
      this.defaultImagePath,
      this.boxFit = BoxFit.cover,
      this.radius = 0,
      this.color,
      this.errorEnabledBGColor = false,
      this.enabledDefineColor = false,
      this.defineColor,
      this.defineHeight,
      this.defineWidth});

  @override
  ImageWidgetState createState() => ImageWidgetState();
}

class ImageWidgetState extends State<ImageWidget> {
  int loadImageType = 1; //1 加载工程图片  2 加载网络图片  3 加载本地图片
  void onCheckImagePathType() {
    if (widget.imagePath.isNotEmpty) {
      if (widget.imagePath.startsWith("http")) {
        loadImageType = 2;
        // checkImagePathEnabled();
      } else if (widget.imagePath.startsWith("assets")) {
        loadImageType = 1;
      } else {
        loadImageType = 3;
      }
    } else {
      loadImageType = 4;
    }
  }

  int netImageLoadType = 1; //网络加载类型

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onRefreshView() {
    if (loadImageType == 2 && mounted) {
      setState(() {
        netImageLoadType = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    onCheckImagePathType();
    return ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Container(
          color: widget.enabledDefineColor ? widget.defineColor : null,
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          child: _buildImage(),
        ));
  }

  Widget _buildImage() {
    Widget image;
    switch (loadImageType) {
      case 2:
        image = Image.network(
          widget.imagePath,
          width: widget.width,
          height: widget.height,
          fit: widget.boxFit,
          color: widget.color,
        );
        break;
      case 3:
        image = Image.file(
          File(widget.imagePath),
          width: widget.width,
          height: widget.height,
          fit: widget.boxFit,
          color: widget.color,
        );
        break;
      case 4:
        image = Image.asset(
          widget.imagePath,
          width: widget.defineWidth ?? widget.width,
          height: widget.defineHeight ?? widget.height,
          fit: widget.boxFit,
          color: widget.color,
        );
        break;
      default:
        image = Image.asset(
          widget.imagePath,
          width: widget.width,
          height: widget.height,
          fit: widget.boxFit,
          color: widget.color,
        );
    }
    return image;
  }
}
