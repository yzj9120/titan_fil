import 'dart:convert';

class ApiResponse {
  final int code;
  final String msg;
  final dynamic data;

  ApiResponse({
    required this.code,
    required this.msg,
    this.data,
  });

  // 静态方法用于从 Dio 的响应创建 ApiResponse
  factory ApiResponse.fromResponse(ApiResponse response) {
    return ApiResponse(
      code: response.code ?? 500,
      msg: response.msg ?? "Unknown error",
      data: response.data ?? {},
    );
  }

  // 静态方法用于创建成功的 ApiResponse
  factory ApiResponse.success(dynamic data) {
    return ApiResponse(
      code: 200,
      msg: "Success",
      data: data,
    );
  }

  // 静态方法用于创建失败的 ApiResponse
  factory ApiResponse.error(String msg, {int code = 500}) {
    return ApiResponse(code: code, msg: msg, data: {});
  }

  @override
  String toString() {
    return jsonEncode({
      "code": code,
      "msg": msg,
      "data": data,
    });
  }
}
