import 'dart:async';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:get/get.dart';

class NetworkMonitor {
  static Future<Map<String, dynamic>> checkNetworkStatus() async {
    String host = 'baidu.com';
    int totalPackets = 10;

    // 执行 Ping 测试
    List<double> latencies = await _performPingTest(host, totalPackets);
    int lostPackets = totalPackets - latencies.length;

    // 计算平均延迟、抖动和丢包率
    double avgPing = latencies.isNotEmpty
        ? latencies.reduce((a, b) => a + b) / latencies.length
        : double.infinity;
    double jitter = _calculateJitter(latencies);
    double lossRate = (lostPackets / totalPackets) * 100;

    print("lossRate=$lossRate");
    // 格式化为两位小数
    String formattedAvgPing = avgPing.toStringAsFixed(2);
    String formattedJitter = jitter.toStringAsFixed(2);

    // 评估网络质量
    Map<String, dynamic> networkQuality =
        _evaluateNetwork(avgPing, jitter, lossRate);

    return {
      "avgPing": formattedAvgPing,
      "jitter": formattedJitter,
      "lossRate": lossRate.toStringAsFixed(2),
      ...networkQuality
    };
  }

  /// 执行 Ping 测试
  static Future<List<double>> _performPingTest(String host, int count) async {
    // final ping = Ping(host, count: count, timeout: 10);

    // Windows 需要指定 encoding，macOS/Linux 不需要
    final ping = Platform.isWindows
        ? Ping(host, count: count, forceCodepage: true)
        : Ping(host, count: count);
    List<double> latencies = [];

    try {
      await ping.stream.forEach((event) {
        final responseTime = event.response?.time;
        if (responseTime != null) {
          latencies.add((responseTime.inMicroseconds ?? 0) / 1000.0);
          print('Ping: ${(responseTime.inMicroseconds ?? 0) / 1000.0} ms');
        } else {
          print('Ping 请求超时');
        }
      });
    } on TimeoutException {
      print('Ping 测试超时: 请求超过了最大等待时间');
    } catch (e) {
      print('Ping 测试出错: $e');
    }

    return latencies;
  }

  /// 计算抖动（Jitter）
  static double _calculateJitter(List<double> latencies) {
    if (latencies.length < 2) return 0.0;
    double jitter = 0.0;
    for (int i = 1; i < latencies.length; i++) {
      jitter += (latencies[i] - latencies[i - 1]).abs();
    }
    return jitter / (latencies.length - 1);
  }

  /// 评估网络质量
  static Map<String, dynamic> _evaluateNetwork(
      double avgPing, double jitter, double lossRate) {
    if (avgPing < 50 && jitter < 10 && lossRate < 2) {
      return {"des": "networkIsExcellent".tr, "type": 1}; //优秀
    } else if (avgPing < 100 && jitter < 20 && lossRate < 5) {
      return {"des": "networkIsGoodEarning".tr, "type": 2}; //良好
    } else if (avgPing < 200 && jitter < 30 && lossRate < 10) {
      return {"des": "networkIsFair".tr, "type": 3}; //一般
    } else {
      return {"des": "networkIsPoor".tr, "type": 4}; //差
    }
  }
}
