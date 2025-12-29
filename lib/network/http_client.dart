/**
 * 通用 HTTP 请求封装
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:titan_fil/constants/constants.dart';
import 'package:titan_fil/network/response_parser.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../services/log_service.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'error_handler.dart';
import 'network_checker.dart';

class HttpClientUtils {
  final Dio _dio;
  static final _logger4 = LoggerFactory.createLogger(LoggerName.t4);

  HttpClientUtils() : _dio = Dio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
    //final adapter = IOHttpClientAdapter();
    // adapter.createHttpClient = () {
    //   final context = SecurityContext.defaultContext; // 加载系统根证书
    //   final client = HttpClient(context: context);
    //   return client;
    // };

    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    _dio.httpClientAdapter = adapter;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logResponse(response);
        final apiResponse = ResponseParser.parse(response);
        response.data = apiResponse;
        return handler.next(response);
      },
      onError: (e, handler) {
        _logError(e);
        return handler.next(e);
      },
    ));
  }

  // 统一的请求方法
  Future<ApiResponse> request(
    String url, {
    String method = 'GET',
    bool isLangCode = true,
    bool isCN = false,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      // **检测网络状态**
      bool hasInternet = await NetworkChecker.hasInternetConnection();
      if (!hasInternet) {
        return ApiResponse.error("No Internet Connection");
      }
      Response response;
      var langCode = 'en';
      try {
        langCode = (await SharedPreferences.getInstance())
                .getString(Constants.langCode) ??
            'en';
        if (isCN && langCode == "zh") {
          langCode = "cn";
        }
      } catch (e) {
        _log("langCode :error:$e");
      }
      final headersWithToken = {
        if (isLangCode) 'lang': langCode,
        if (headers != null) ...headers,
      };
      debugPrint("huangzhen:headersWithToken=${headersWithToken}");
      // 设置请求选项
      final options = Options(headers: headersWithToken, method: method);
      // 针对 GET 方法，允许传递 body
      if (method == 'GET') {
        response = await _dio.request(
          url,
          queryParameters: queryParameters, // URL 参数
          data: data, // 请求体
          options: options,
        );
      } else if (method == 'POST') {
        response = await _dio.post(
          url,
          data: data,
          options: options,
        );
      } else {
        // 其他 HTTP 方法
        response = await _dio.request(
          url,
          data: data,
          options: options,
        );
      }
      ApiResponse result = ResponseParser.parse(response);
      return ApiResponse.fromResponse(result);
    } catch (e) {
      var logs = StringBuffer()
        ..writeln("Error:$e")
        ..writeln("API: $url");
      _log(logs, w: true);
      if (e is DioException) {
        final apiResponse = ErrorHandler.handleError(e);
        return apiResponse;
      }
      return ApiResponse.error('$e');
    }
  }

  /// 使用 `dio` 上传文件
  Future<ApiResponse> uploadLogFile(File logFile, String nodeId) async {
    try {
      // 构造上传的 FormData，包含文件和额外的参数
      FormData formData = FormData.fromMap({
        'logFile':
            await MultipartFile.fromFile(logFile.path, filename: 'log.txt'),
        'nodeId': nodeId,
      });
      // 发送 POST 请求上传文件
      Response response =
          await _dio.post("https://your-server-url.com/upload", data: formData);
      // 判断响应的状态码
      if (response.statusCode == 200) {
        // 上传成功，返回统一的 ApiResponse
        ApiResponse result = ResponseParser.parse(response);
        return ApiResponse.fromResponse(result);
      } else {
        // 服务器返回错误，构造并返回 ApiResponse
        return ApiResponse.error("Failed to upload log file:$response.data");
      }
    } catch (e) {
      // 捕获异常，返回错误的 ApiResponse
      return ApiResponse.error(
          "Exception occurred while uploading log file:${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> uploadImage(File image, String url,
      {Function(double)? onProgress}) async {
    String fileName = image.path.split('/').last;
    var uri = Uri.parse(url);
    var request = http.MultipartRequest('POST', uri)
      ..fields['path'] = 'reports'
      ..files.add(await http.MultipartFile.fromPath('file', image.path,
          filename: fileName));
    var streamedResponse = await request.send();
    int totalBytes = streamedResponse.contentLength ?? 0;
    int bytesUploaded = 0;
    var completer = Completer<Map<String, dynamic>>();
    List<int> responseBytes = [];
    streamedResponse.stream.listen(
      (value) {
        responseBytes.addAll(value);
        bytesUploaded += value.length;
        double progress = bytesUploaded / totalBytes;
        // print('上传进度: ${(progress * 100).toStringAsFixed(2)}%');
        onProgress?.call(progress);
      },
      onDone: () {
        if (streamedResponse.statusCode == 200) {
          var responseString = utf8.decode(responseBytes);
          completer.complete(jsonDecode(responseString));
        } else {
          completer.complete({
            'code': streamedResponse.statusCode,
            'msg': 'Failed to upload data',
          });
        }
      },
      onError: (error) {
        completer.complete({
          'code': streamedResponse.statusCode,
          'msg': '$error',
        });
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// 使用 `dio` 下载文件
  Future<void> downloadFile({
    required String fileUrl,
    required String savePath,
    required String extractToPath,
    bool saveEtag = true,
    bool hasZip = true,
    Function(int received, int total)? onProgress,
  }) async {
    File? downloadedFile;
    try {
      bool hasInternet = await NetworkChecker.hasInternetConnection();
      if (!hasInternet) {
        _log("downloadFile No Internet Connection");
        return;
      }
      downloadedFile = File(savePath);
      _log(
          "downloadFile url:$fileUrl; extractToPath=$extractToPath;downloadedFile=$downloadedFile");
      Dio dio = Dio();
      final adapter = IOHttpClientAdapter();
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        client.connectionTimeout = const Duration(seconds: 15);
        client.idleTimeout = const Duration(minutes: 2);
        client.maxConnectionsPerHost = 6;
        return client;
      };
      dio.httpClientAdapter = adapter;
      Response response = await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          method: 'GET',
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 5),
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        _log("Download successful: $savePath");
        if (saveEtag) {
          final etag = response.headers.value('etag');
          final str = "${etag.toString().replaceAll('"', '')}";
          await PreferencesHelper.setString(Constants.md5, str);
          _log("ETag: $str");
        }
        if (!hasZip) {
          return;
        }
        final success = await unzipFile(savePath, extractToPath);
        if (!success) {
          // 创建解压目录（如果不存在）
          final extractDir = Directory(extractToPath);
          if (!extractDir.existsSync()) {
            extractDir.createSync(recursive: true);
          }
          // 读取ZIP文件
          final bytes = await File(savePath).readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          // 解压到目标目录
          for (final file in archive) {
            final filename = '$extractToPath/${file.name}';
            if (file.isFile) {
              final data = file.content as List<int>;
              await File(filename)
                ..create(recursive: true)
                ..writeAsBytes(data);
            } else {
              await Directory(filename).create(recursive: true);
            }
          }
        }
      } else {
        _log("downloadFile failed: ${response.statusCode}");
        if (downloadedFile.existsSync()) {
          await downloadedFile.delete();
          _log("Deleted partially downloaded file due to failure");
        }
      }
    } catch (e) {
      _log("downloadFile Exception during download or unzip: ${e.toString()}");
      if (downloadedFile != null && downloadedFile.existsSync()) {
        await downloadedFile.delete();
        _log("Deleted partially downloaded file due to exception");
      }
    }
  }

  Future<bool> unzipFile(String zipPath, String extractTo) async {
    final dir = Directory(extractTo);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    try {
      final process = await Process.start(
        'tar',
        ['-xf', zipPath, '-C', extractTo],
        runInShell: true,
      );
      final out = await process.stdout.transform(utf8.decoder).join();
      final err = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        _log("unzipFile: $extractTo, out: $out");
        return true;
      } else {
        _log("unzipFile error($exitCode): $err", w: true);
        return false;
      }
    } catch (e) {
      _log("unzipFile catch: $e");
      return false;
    }
  }

  Future<ApiResponse> uploadFile(File logFile, String lang, String url) async {
    String filepathName = p.basename(logFile.path);
    var tempFile;
    final client = http.Client();
    try {
      if (filepathName.toLowerCase().endsWith('.zip')) {
        tempFile = logFile;
      } else {
        tempFile = await _createUploadCopy(logFile); // 拷贝副本
      }
      final fileStream = tempFile.openRead();
      final fileSize = await tempFile.length();
      final fileName = tempFile.path.split('/').last;
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll({'lang': lang})
        ..files.add(http.MultipartFile(
          'file',
          fileStream,
          fileSize,
          filename: fileName,
        ));
      // 🟢 日志：开始上传
      // 将字节转换为 MB 并保留2位小数
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      _log(' uploadFile: $fileName;[$sizeMB MB]');
      final response =
          await client.send(request).timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();
      _log('uploadFile: $responseBody');
      // 解析 JSON 响应
      final responseJson = jsonDecode(responseBody) as Map<String, dynamic>;
      final responseCode = responseJson['code'] as int;
      final responseMsg = responseJson['msg'] as String;

      // ✅ 上传成功（HTTP 200 且 code=0）
      if (response.statusCode == 200 && responseCode == 0) {
        _log('uploadFile responseBody: $responseBody');
        return ApiResponse.success(responseJson);
      }
      _log('uploadFile error: [$responseCode] $responseMsg', w: true);
      return ApiResponse.error('${responseMsg}', code: responseCode);
    } catch (e, stack) {
      _log('uploadFile catch:: $e\n$stack');
      return ApiResponse.error('uploadFile failed:: ${e.toString()}');
    } finally {
      client.close();
      await tempFile?.delete();
    }
  }

// 创建临时副本（优化版）
  Future<File> _createUploadCopy(File original) async {
    final tempDir = await Directory.systemTemp.createTemp();
    final copy = File('${tempDir.path}/${original.path.split('/').last}');
    // 使用原子操作复制
    await original.openRead().pipe(copy.openWrite());
    // 验证副本
    if (await original.length() != await copy.length()) {
      throw Exception('文件副本不完整');
    }
    return copy;
  }

  // 响应日志输出
  void _logResponse(Response response) {
    final requestOptions = response.requestOptions;
    final requestUrl = requestOptions.uri.toString();
    if (requestUrl.contains("node_bandwidths")) {
      return;
    }
    final logs = StringBuffer()
      ..writeln("Method: ${requestOptions.method}")
      ..writeln("API: $requestUrl")
      ..writeln("Body: ${_sanitizeData(requestOptions.data)}")
      ..writeln("Data: ${_sanitizeData(response.data)}");
    _log(logs);
  }

  // 错误日志输出
  void _logError(DioError error) {
    var requestOptions = error.requestOptions;
    var logs = StringBuffer()
      ..writeln("Error:$error")
      ..writeln("API: ${requestOptions.uri.toString()}")
      ..writeln("Details: ${_sanitizeData(error.response?.data)}");
    final requestUrl = requestOptions.uri.toString();
    _log(logs, w: true);
  }

  // 数据清理方法，避免直接输出可能敏感或无法序列化的数据
  String _sanitizeData(dynamic data) {
    if (data == null) return "No Data";
    if (data is Map || data is List) {
      return jsonEncode(data);
    }
    return data.toString();
  }

  String _cleanUrl(String url) {
    int queryIndex = url.indexOf('?');
    if (queryIndex != -1) {
      // 截取 '?' 前的部分
      return url.substring(0, queryIndex);
    }
    // 如果没有 '?'，返回原 URL
    return url;
  }

  static void _log(dynamic message, {bool w = false}) {
    if (!w) {
      _logger4.info("[HttpClient]:$message");
    } else {
      _logger4.warning("[HttpClient]:$message");
    }
  }
}
