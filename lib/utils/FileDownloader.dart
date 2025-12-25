import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class FileDownloader {
  /// 下载文件并写入到指定路径，同时提供进度回调
  static Future<bool> download({
    required String fileUrl,
    required String savePath,
    CancelToken? cancelToken,
    Function(int received, int total)? onProgress,
  }) async {
    final dio = Dio();
    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      client.connectionTimeout = const Duration(seconds: 15);
      client.idleTimeout = const Duration(minutes: 5);
      client.maxConnectionsPerHost = 6;
      return client;
    };
    dio.httpClientAdapter = adapter;

    try {
      final response = await dio.get<ResponseBody>(
        fileUrl,
        options: Options(
          method: 'GET',
          responseType: ResponseType.stream,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null && status < 500,
        ),
        cancelToken: cancelToken,
      );

      final file = File(savePath);
      final sink = file.openWrite();

      final totalStr = response.headers.map['content-length']?.first;
      final total = totalStr != null ? int.tryParse(totalStr) ?? 0 : 0;
      int received = 0;

      final completer = Completer<bool>();

      final subscription = response.data!.stream.listen(
        (chunk) {
          received += chunk.length;
          sink.add(chunk);
          if (onProgress != null) {
            onProgress(received, total);
          }
        },
        onError: (e) async {
          debugPrint('Download stream error: $e');
          completer.completeError(e);
        },
        onDone: () {
          completer.complete(true);
        },
        cancelOnError: true,
      );

      try {
        await completer.future;
        return true;
      } catch (e) {
        await _handleDownloadFailure(savePath);
        return false;
      } finally {
        await sink.close();
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('Download canceled');
      } else {
        debugPrint('Download error: $e');
      }
      await _handleDownloadFailure(savePath);
      return false;
    } catch (e) {
      debugPrint('Unknown error: $e');
      await _handleDownloadFailure(savePath);
      return false;
    }
  }

  /// 删除下载失败产生的临时文件
  static Future<void> _handleDownloadFailure(String savePath) async {
    final file = File(savePath);
    if (await file.exists()) {
      try {
        await file.delete();
        debugPrint('Deleted: $savePath');
      } catch (e) {
        debugPrint('Failed to delete temp file: $e');
      }
    }
  }
}
