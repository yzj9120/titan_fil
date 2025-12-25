class TimeUtils {
  static final TimeUtils _instance = TimeUtils._(); // 单例模式

  factory TimeUtils() {
    return _instance;
  }

  TimeUtils._();

  String formatDuration(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int remainingSeconds = totalSeconds % 3600;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else if (minutes > 0) {
      return '${minutes}分钟';
    } else {
      return '${seconds}秒';
    }
  }

  static List<String> formatTimeDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String oneOrTwoDigits(int n) {
      if (n >= 10 || n < 0) return "$n";
      return n == 0 ? "0" : "0$n"; // 如果小时为0，则显示0，否则显示实际的小时数
    }

    // String hoursText = localeController.locale() == 1 ? '小时 ' : 'hours ';
    // String minutesText = localeController.locale() == 1 ? '分钟 ' : 'minutes ';
    // String daysText = localeController.locale() == 1 ? '天 ' : 'days ';
    // String secondsText = localeController.locale() == 1 ? '秒' : 'seconds';

    List<String> result = [];

    if (duration.inDays >= 1) {
      result.add(
          oneOrTwoDigits(duration.inHours * duration.inDays.remainder(24)));
      result.add(twoDigits(duration.inMinutes.remainder(60)));
      result.add(twoDigits(duration.inSeconds.remainder(60)));
    } else if (duration.inHours >= 1) {
      result.add(oneOrTwoDigits(duration.inHours));
      result.add(twoDigits(duration.inMinutes.remainder(60)));
      result.add(twoDigits(duration.inSeconds.remainder(60)));
    } else if (duration.inMinutes >= 1) {
      result.add("00");
      result.add("${duration.inMinutes}");
      result.add(twoDigits(duration.inSeconds.remainder(60)));
    } else {
      result.add("00");
      result.add("00");
      result.add("${duration.inSeconds}");
    }

    return result;
  }

  static List<String> getTimeDifferenceString(DateTime targetTime) {
    DateTime now = DateTime.now();
    Duration difference = targetTime.difference(now);

    if (difference.isNegative) {
      return ["ok"];
    }
    return formatTimeDuration(difference);
  }
}
