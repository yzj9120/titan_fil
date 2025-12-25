import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'api_response.dart';

/**
 * 错误处理
 *
 */

class ErrorHandler {
  static ApiResponse handleError(DioException error) {
    // Handle different error types
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        // 连接超时错误
        return ApiResponse.error('connectionTimeout'.tr);
      case DioExceptionType.sendTimeout:
        // 请求超时错误
        return ApiResponse.error('requestTimeout'.tr);
      case DioExceptionType.receiveTimeout:
        // 响应超时错误
        return ApiResponse.error('responseTimeout'.tr);
      case DioExceptionType.badCertificate:
        // 证书错误
        return ApiResponse.error('badCertificate'.tr);
      case DioExceptionType.badResponse:
        // 服务器响应错误（如 4xx、5xx 错误）
        return ApiResponse.error(
          '${"badResponse".tr}:[${error.response?.statusCode}]',
        );
      case DioExceptionType.cancel:
        // 请求被取消
        return ApiResponse.error('cancelled'.tr);
      case DioExceptionType.connectionError:
        // 网络错误
        return ApiResponse.error('networkError'.tr);
      case DioExceptionType.unknown:
        // 未知错误
        return ApiResponse.error('unknownError'.tr);
      default:
        // 其他未知错误
        return ApiResponse.error("$error");
    }
  }
}
