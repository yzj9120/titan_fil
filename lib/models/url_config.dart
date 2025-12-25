import 'dart:convert';

class urlConfig {
  final String url;

  urlConfig({
    required this.url,
  });

  /// 从 JSON 解析成 `NodeInfo`
  factory urlConfig.fromJson(Map<String, dynamic> json) {
    return urlConfig(
      url: json["url"] ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {"url": url};
  }

  /// 方便打印
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
