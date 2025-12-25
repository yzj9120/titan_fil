import 'dart:convert';

class CheckInfo {
  final bool open;
  final String clientIp;

  CheckInfo({
    required this.open,
    required this.clientIp,
  });

  /// 从 JSON 解析成 `NodeInfo`
  factory CheckInfo.fromJson(Map<String, dynamic> json) {
    return CheckInfo(
      open: json["open"] ?? false,
      clientIp: json["client_ip"] ?? "",
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {"open": open};
  }

  /// 方便打印
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
