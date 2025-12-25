class DateTimeUtils {
  /// 将 Unix 时间戳转换为 "MM-dd" 格式
  static String formatToMonthDay(int timestamp) {
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    var str =
        "${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    return str;
  }

  /// 将 Unix 时间戳转换为 "yyyy-MM-dd" 格式
  static String formatToYearMonthDay(int timestamp) {
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
