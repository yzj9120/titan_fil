import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';

extension EmojiTextExtension on String {
  /// 显示适配Windows/macOS的Emoji文本
  Widget toEmojiText({
    double fontSize = 14,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return Text(
      this,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        fontFamily: _getPlatformEmojiFont(),
      ),
    );
  }

  static String? _getPlatformEmojiFont() {
    if (Platform.isMacOS || Platform.isIOS) {
      return 'Apple Color Emoji';
    } else if (Platform.isWindows) {
      return 'Segoe UI Emoji';
    }
    return null; // 其他平台使用默认字体
  }
}

extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index++, element);
    }
  }
}

extension StringExtension on String {
  String get folderNameFromPath {
    return split('/').last;
  }

  String toDate() {
    try {
      final DateTime dateTime = DateTime.parse(this);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String fixAutoLines() {
    return Characters(this).join('\u{200B}');
  }

  String convertToWinPath() {
    if (contains('\\\\')) {
      return replaceAll('\\\\', '\\');
    } else {
      return this;
    }
  }

  String abbreviate({int maxLength = 30}) {
    if (length <= maxLength) return this;
    int partLength = (maxLength / 2).floor();
    return '${substring(0, partLength)}......${substring(length - partLength)}';
  }

  /// 向上取整（返回 int）
  int toCeil() {
    final num = double.tryParse(this);
    return num?.ceil() ?? 0;
  }

  /// 向下取整（返回 int）
  int toFloor() {
    final num = double.tryParse(this);
    return num?.floor() ?? 0;
  }

  /// 直接截断小数部分（返回 int）
  int toTruncate() {
    final num = double.tryParse(this);
    return num?.truncate() ?? 0;
  }

  /// 将字符串数字四舍五入到整数
  int toRoundToInt() {
    final num = double.tryParse(this);
    return num?.round() ?? 0; // 解析失败返回 0
  }

  /// 四舍五入到 N 位小数（返回 String）
  String toRoundToString(int decimals) {
    final num = double.tryParse(this);
    if (num == null) return "0.${'0' * decimals}"; // 默认值，如 "0.00"
    return num.toStringAsFixed(decimals);
  }

  /// 四舍五入到 N 位小数（返回 double）
  double toRoundToDouble(int decimals) {
    final num = double.tryParse(this);
    return double.tryParse(num?.toStringAsFixed(decimals) ?? '0') ?? 0.0;
  }
}

extension MapExtensions on Map<String, dynamic> {
  bool mapsEqual(Map<String, dynamic> other) {
    if (this.length != other.length) {
      return false;
    }
    for (var key in this.keys) {
      if (!other.containsKey(key) || this[key] != other[key]) {
        return false;
      }
    }
    return true;
  }
}

extension ListMapExtensions on List<Map<String, dynamic>> {
  bool containsMap(Map<String, dynamic> map) {
    for (var item in this) {
      if (item.mapsEqual(map)) {
        return true;
      }
    }
    return false;
  }
}

extension FileSizeExtension on double {
  String formatBytes() {
    const int KB = 1024;
    const int MB = KB * 1024;
    const int GB = MB * 1024;
    const int TB = GB * 1024;
    if (this >= TB) {
      return '${(this / TB).toStringAsFixed(2)}TB';
    } else if (this >= GB) {
      return '${(this / GB).toStringAsFixed(2)}GB';
    } else if (this >= MB) {
      return '${(this / MB).toStringAsFixed(2)}MB';
    } else if (this >= KB) {
      return '${(this / KB).toStringAsFixed(2)}KB';
    } else {
      if (this == 0 || this == 0.0) {
        return '0KB';
      }
      return '$this bytes';
    }
  }
}

///单位gb
extension SizeConverter on String {
  double toGB() {
    if (isEmpty) {
      throw ArgumentError('The size string cannot be empty.');
    }
    final sizePattern =
        RegExp(r'([0-9.]+)\s*(GB|MB|KB|TB)', caseSensitive: false);
    final match = sizePattern.firstMatch(this);

    if (match == null) {
      throw ArgumentError('Invalid size format: $this');
    }

    final sizeValue = double.parse(match.group(1)!);
    final unit = match.group(2)!.toUpperCase();

    double sizeInGB;
    switch (unit) {
      case 'GB':
        sizeInGB = sizeValue;
        break;
      case 'MB':
        sizeInGB = sizeValue / 1024;
        break;
      case 'KB':
        sizeInGB = sizeValue / (1024 * 1024);
        break;
      case 'TB':
        sizeInGB = sizeValue * 1024;
        break;
      default:
        throw ArgumentError('Unsupported unit: $unit');
    }

    // 保留两位小数并转换回 double
    return double.parse(sizeInGB.toStringAsFixed(2));
  }
}

extension TimeExtensions on double {
  String toTimeFormat() {
    if (this < 60) {
      return '${toStringAsFixed(2)} 秒';
    } else if (this < 3600) {
      double minutes = this / 60;
      return '${minutes.toStringAsFixed(2)} 分钟';
    } else {
      double hours = this / 3600;
      return '${hours.toStringAsFixed(2)} 小时';
    }
  }
}

extension DateTimeExtension on DateTime {
  String toLogFormat() {
    return '${year.toString()}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String formatted() {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    return "${year}-${twoDigits(month)}-${twoDigits(day)} "
        "${twoDigits(hour)}:${twoDigits(minute)}:${twoDigits(second)}";
  }
}

extension DoubleExtension on double {
  double toFixedTwo() {
    String valueStr = toString();
    int decimalIndex = valueStr.indexOf('.');
    if (decimalIndex == -1) {
      return this;
    }
    int decimalPlaces = valueStr.length - decimalIndex - 1;
    if (decimalPlaces > 3) {
      return double.parse(toStringAsFixed(2));
    } else {
      return this;
    }
  }

  /// 检查小数位数并返回 int（可选）
  int toIntFixed() {
    String valueStr = toString();
    int decimalIndex = valueStr.indexOf('.');
    if (decimalIndex == -1) {
      return toInt();
    }
    // 如果有小数部分，直接四舍五入
    return round();
  }
}

extension TimestampExtension on int {
  /// 转换为 "MM-dd" 格式
  String toMonthDay() {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(this * 1000).toLocal();
    var str =
        "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return str;
  }

  /// 转换为 "yyyy-MM-dd" 格式
  String toYearMonthDay() {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(this * 1000).toLocal();
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}

extension SizeUnitConverter on double {
  String removeUnit(String sizeWithUnit) {
    // 匹配数字（包括小数点和整数）
    final regex = RegExp(r'^(\d+\.?\d*)');
    final match = regex.firstMatch(sizeWithUnit);
    return match?.group(1) ?? sizeWithUnit; // 如果匹配失败，返回原字符串
  }

  /// 智能转换文件大小
  ///
  /// @param fromUnit 输入单位 (B/KB/MB/GB/TB)
  /// @param withUnit 是否返回带单位的结果
  /// @param round 是否取整
  /// @param fractionDigits 小数位数 (默认2位)
  ///
  /// 返回: 根据配置返回String或double
  dynamic convertSize({
    required String fromUnit,
    bool withUnit = false,
    bool round = false,
    int fractionDigits = 2,
  }) {
    // 1. 转换为字节
    final bytes = _toBytes(fromUnit);
    // 2. 计算最适合的单位
    final result = _calculateBestUnit(bytes, fractionDigits);
    // 3. 处理取整
    var value = round ? result.value.round() : result.value;
    // 4. 返回结果
    return withUnit
        ? '${value.toStringAsFixed(round ? 0 : fractionDigits)} ${result.unit}'
        : value;
  }

  double _toBytes(String fromUnit) {
    switch (fromUnit.toUpperCase()) {
      case 'B':
        return this;
      case 'KB':
        return this * 1024;
      case 'MB':
        return this * pow(1024, 2);
      case 'GB':
        return this * pow(1024, 3);
      case 'TB':
        return this * pow(1024, 4);
      default:
        throw ArgumentError('Invalid unit: $fromUnit');
    }
  }

  _UnitResult _calculateBestUnit(double bytes, int fractionDigits) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double value = bytes;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }

    return _UnitResult(
        double.parse(value.toStringAsFixed(fractionDigits)), units[unitIndex]);
  }
}

class _UnitResult {
  final double value;
  final String unit;

  _UnitResult(this.value, this.unit);
}
