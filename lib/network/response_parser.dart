/**
 * API 响应解析
 */
import 'package:dio/dio.dart';

import 'api_response.dart';

class ResponseParser {
  // 解析响应数据的静态方法
  static ApiResponse parse(Response response) {
    try {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final code = data['code'] ?? data['ErrCode'];
        final message = data['msg'] ?? data['ErrMsg'];
        final payload = data['data'] ?? data['Data'];
        if (code == 0) {
          // 根据需要构造 ApiResponse
          return ApiResponse.success(payload);
        } else {
          return ApiResponse.error(code: code, message);
        }
      } else if (data is ApiResponse) {
        return data;
      } else {
        return ApiResponse.error('Invalid response format:$data');
      }
    } catch (e) {
      // 处理解析异常
      return ApiResponse.error('Response parsing error:$e');
    }
  }

  dynamic parseResponseData(dynamic data) {
    if (data == null) {
      return 'No Data';
    }

    if (data is Map<String, dynamic>) {
      // 处理 Map 类型的数据
      print("Data is a Map");
      return data; // 返回 Map 类型的响应数据
    } else if (data is List) {
      // 处理 List 类型的数据
      print("Data is a List");
      return data; // 返回 List 类型的响应数据
    } else if (data is String) {
      // 处理 String 类型的数据
      print("Data is a String");
      return data; // 返回 String 类型的响应数据
    } else if (data is int) {
      // 处理 Integer 类型的数据
      print("Data is an Integer");
      return data; // 返回 Integer 类型的响应数据
    } else {
      print("Unknown data type: ${data.runtimeType}");
      return 'Unknown Data Type';
    }
  }
}
