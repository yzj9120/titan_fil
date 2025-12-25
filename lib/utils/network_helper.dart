import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../constants/constants.dart';

class NetworkHelper {
  static String? _cachedIP; // 内存缓存

  static http.Client getHttpClient() {
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  /// 获取用户IP地址（优先使用缓存）
  static Future<String> getUserIP({bool forceRefresh = false}) async {
    // 如果强制刷新或者内存中没有缓存
    if (!forceRefresh && _cachedIP != null && _cachedIP!.isNotEmpty) {
      return _cachedIP!;
    }

    // 检查本地存储
    String ip = await PreferencesHelper.getString(Constants.locationIp) ?? "";
    if (ip.isNotEmpty) {
      _cachedIP = ip; // 更新内存缓存
      return ip;
    }

    // 从网络获取
    ip = await _fetchIPFromNetwork();
    if (ip != 'Unknown') {
      await _cacheIP(ip); // 缓存新获取的IP
    }

    return ip;
  }

  /// 从网络服务获取IP
  static Future<String> _fetchIPFromNetwork() async {
    List<String> ipServices = [
      'https://whois.pconline.com.cn/ipJson.jsp?ip=&json=true',
      'https://g3.letv.com/r?format=1',
      'https://test.ipw.cn/api/ip/myip?json',
      'https://api.uomg.com/api/visitor.info?skey=1',
      'https://vv.video.qq.com/checktime?otype=ojson',
      'https://cdid.c-ctrip.com/model-poc2/h',
    ];

    final client = getHttpClient();
    for (String url in ipServices) {
      try {
        final response = await client.get(Uri.parse(url)).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException("请求超时"),
        );

        if (response.statusCode == 200) {
          final ip = _extractIP(response.body);
          if (ip != null && ip.isNotEmpty) {
            return ip;
          }
        }
      } catch (e) {
        continue;
      }
    }
    return 'Unknown';
  }

  /// 缓存IP地址（内存和本地存储）
  static Future<void> _cacheIP(String ip) async {
    _cachedIP = ip; // 内存缓存
    await PreferencesHelper.setString(Constants.locationIp, ip);
  }

  /// 清除缓存的IP地址
  static Future<void> clearCachedIP() async {
    _cachedIP = null;
    await PreferencesHelper.remove(Constants.locationIp);
  }

  /// 获取当前缓存的IP（可能为null）
  static String? get cachedIP => _cachedIP;

  /// 提取 IP 地址的逻辑
  static String? _extractIP(String body) {
    try {
      final jsonData = json.decode(body);
      if (jsonData is Map) {
        if (jsonData.containsKey('ipt')) return jsonData['ipt'];
        if (jsonData.containsKey('host')) return jsonData['host'];
        if (jsonData.containsKey('IP')) return jsonData['IP'];
        if (jsonData.containsKey('ip')) return jsonData['ip'];
        if (jsonData.containsKey('data') && jsonData['data'] is Map) {
          return jsonData['data']['ip'];
        }
      }
    } catch (_) {
      // fallback: 正则直接提取 IP
      final reg = RegExp(r'(\d{1,3}\.){3}\d{1,3}');
      final match = reg.firstMatch(body);
      if (match != null) return match.group(0);
    }

    return null;
  }
}