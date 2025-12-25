class LogEntry {
  final String level;
  final String ts;
  final String msg;
  final String logger;

  LogEntry(
      {required this.level,
      String? ts,
      required this.msg,
      required this.logger})
      : ts = ts ?? DateTime.now().toString();

  Map<String, dynamic> toJson() {
    return {
      'level': level.toString().split('.').last,
      'ts': ts,
      'msg': msg,
      'logger': logger,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: json['level'] as String,
      ts: json['ts'] as String,
      msg: json['msg'] as String,
      logger: json['logger'] as String,
    );
  }

  @override
  String toString() {
    return 'LogEntry{level: $level, ts: $ts, msg: $msg, logger: $logger}';
  }
}
