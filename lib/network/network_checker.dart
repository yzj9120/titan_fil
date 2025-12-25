import 'package:connectivity_plus/connectivity_plus.dart';

/**
 * 网络状态监测
 */

class NetworkChecker {
  /// 检查是否有网络连接
  static Future<bool> hasInternetConnection() async {
    final List<ConnectivityResult> connectivityResults =
        await Connectivity().checkConnectivity();
    // 只要有一个网络连接，就返回 true
    return connectivityResults
        .any((result) => result != ConnectivityResult.none);
  }

  static Future<String> getNetworkType() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    // 检查 connectivityResult 是否包含指定的网络类型
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      return 'Bluetooth';
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      return 'No Internet';
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      return 'Other';
    } else {
      return 'Unknown';
    }
  }

  /// 监听网络状态变化（可选）
  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged;
}
