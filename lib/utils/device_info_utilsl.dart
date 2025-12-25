import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class DeviceInfoUtil {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  /// 获取设备信息
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    Map<String, dynamic> deviceData;
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData = await _readAndroidBuildData(androidInfo);
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData = _readIosDeviceInfo(iosInfo);
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macOsInfo = await _deviceInfoPlugin.macOsInfo;
        deviceData = await _readMacOsDeviceInfo(macOsInfo);
      } else if (Platform.isWindows) {
        WindowsDeviceInfo macOsInfo = await _deviceInfoPlugin.windowsInfo;
        deviceData = await _readWindowsDeviceInfo(macOsInfo);
      } else {
        deviceData = <String, dynamic>{
          'Error': 'Unsupported platform',
        };
      }
    } catch (e) {
      deviceData = <String, dynamic>{
        'Error': 'Failed to get platform version',
      };
    }

    return deviceData;
  }

  /// 获取应用版本信息
  static Future<Map<String, String>> getAppVersionInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  static Future<String> getUserIP() async {
    List<String> ipServices = [
      'https://www.ip.cn/api/index?ip=&type=0', // 'ipt' field
      'https://whois.pconline.com.cn/ipJson.jsp?ip=&json=true', // 'ipt' field
      'https://g3.letv.com/r?format=1', // 'host' field
      'https://test.ipw.cn/api/ip/myip?json', // 'IP' field
      'https://api.uomg.com/api/visitor.info?skey=1', // 'ip' field
      'https://vv.video.qq.com/checktime?otype=ojson', // 'ip' field
      'https://cdid.c-ctrip.com/model-poc2/h', // direct IP in response
      'https://ip.useragentinfo.com/json', // 'ip' field
      'https://api.qjqq.cn/api/Local' // 'data' -> 'idp' field
    ];

    Random random = Random();
    String? ipAddress;

    for (int i = 0; i < ipServices.length; i++) {
      String url = ipServices[random.nextInt(ipServices.length)];
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);

          // Handle different field names for each service
          if (jsonData.containsKey('ipt')) {
            ipAddress = jsonData['ipt'];
            break;
          }
          if (jsonData.containsKey('host')) {
            ipAddress = jsonData['host'];
            break;
          }
          if (jsonData.containsKey('IP')) {
            ipAddress = jsonData['IP'];
            break;
          }
          if (jsonData.containsKey('ip')) {
            ipAddress = jsonData['ip'];
            break;
          }
          if (jsonData.containsKey('data') &&
              jsonData['data'].containsKey('idp')) {
            ipAddress = jsonData['data']['idp'];
            break;
          }
          // Some APIs might return IP directly as a string (e.g., cdid.c-ctrip.com)
          if (response.body.trim().isNotEmpty &&
              response.body.contains(RegExp(r'^\d{1,3}(\.\d{1,3}){3}$'))) {
            ipAddress = response.body.trim();
            break;
          }
        }
      } catch (e) {
        // Ignore exception and try the next service
      }
    }

    // Return the IP if found, otherwise fallback to native method
    if (ipAddress != null) {
      return ipAddress;
    }
    return 'Unknown';
    // Fallback to native IP fetching if all services fail
    // try {
    //   var ip = await NativeTool.getIpAddress();
    //   return ip;
    // } catch (e) {
    //   return 'Unknown';
    // }
  }

  /// 解析 Android 设备信息
  static Future<Map<String, dynamic>> _readAndroidBuildData(
      AndroidDeviceInfo build) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'version': packageInfo.version,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'androidId': "",
      'systemFeatures': build.systemFeatures,
    };
  }

  /// 解析 iOS 设备信息
  static Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  static Future<Map<String, dynamic>> _readMacOsDeviceInfo(
      MacOsDeviceInfo data) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return <String, dynamic>{
      'version': packageInfo.version,
      'arch': data.arch,
      'model': data.model,
      'version.release': data.osRelease,
    };
  }

  static Future<Map<String, dynamic>> _readWindowsDeviceInfo(
      WindowsDeviceInfo data) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return <String, dynamic>{
      'version': packageInfo.version,
      'arch': data.releaseId,
      'model': data.productName,
      'version.release': data.buildNumber,
    };
  }

  static String getChipInfo() {
    String os = Platform.operatingSystem;
    String architecture = Platform.operatingSystemVersion;
    String chipInfo = '';
    if (os == 'macos') {
      if (architecture.contains('ARM64')) {
        chipInfo = _getMacChipInfo();
      } else {
        chipInfo = 'Intel Chip';
      }
    } else if (os == 'ios') {
      if (architecture.contains('ARM64')) {
        chipInfo = 'Apple A-series or M-series Chip';
      } else {
        chipInfo = 'Intel Chip';
      }
    } else {
      chipInfo = 'Unknown Chip';
    }

    return chipInfo;
  }

  static String _getMacChipInfo() {
    // 这里可以进一步细化，例如根据不同的MacBook型号推断芯片
    // 暂时返回 'Apple M1' 作为示例
    return 'Apple M1';
  }

  static String getOperatingSystem() {
    return Platform.operatingSystem;
  }

  static String getOperatingSystemVersion() {
    return Platform.operatingSystemVersion;
  }

  static String getDeviceModel() {
    return 'Unknown Model';
  }
}
