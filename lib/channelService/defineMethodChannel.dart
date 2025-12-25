import 'dart:async';

import 'package:flutter/services.dart';

import '../plugins/native_app.dart';

class DefineMethodChannel {
  static const MethodChannel _channel =
      MethodChannel('com.titan_fil.titanNetwork/defineChannel');

  static Future<int> getDiskCapacity() async {
    try {
      return await _channel.invokeMethod('getDiskCapacity');
    } on PlatformException catch (e) {
      return 0;
    }
  }

  static Future<int> getFreeDiskSpace() async {
    try {
      return await _channel.invokeMethod('getFreeDiskSpace');
    } on PlatformException catch (e) {
      return 0;
    }
  }

  static Future<int> getAvailableDiskSpace() async {
    try {
      return await _channel.invokeMethod('getAvailableDiskSpace');
    } on PlatformException catch (e) {
      return 0;
    }
  }

  static Future<String?> getTotalDiskSpaceReadable() async {
    try {
      return await _channel.invokeMethod('getTotalDiskSpaceReadable');
    } on PlatformException catch (e) {
      return null;
    }
  }

  static Future<String?> getFreeDiskSpaceReadable() async {
    try {
      return await _channel.invokeMethod('getFreeDiskSpaceReadable');
    } on PlatformException catch (e) {
      return null;
    }
  }

  static Future<String?> getSizeReadable(String folderPath) async {
    try {
      return await _channel
          .invokeMethod('getSizeReadable', {'folderPath': folderPath});
    } on PlatformException catch (e) {
      return null;
    }
  }

  static Future<void> relaunchApp() async {
    try {
      await _channel.invokeMethod('relaunchApp');
    } on PlatformException catch (e) {
      print("Failed to relaunch app: '${e.message}'.");
    }
  }

  static Future<Map<String, dynamic>> runAgent() async {
    try {
      final result = await _channel.invokeMethod('runAgent');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      } else {
        return {'success': false, 'message': 'Unexpected result type'};
      }
    } on PlatformException catch (e) {
      print("Failed to relaunch app: '${e.message}'.");
      return {
        'success': false,
        'message': 'Unexpected result error:${e.message}'
      };
    }
  }

  static Future<void> relaunchMac() async {
    try {
      await _channel.invokeMethod('relaunchMac');
    } on PlatformException catch (e) {
      print("Failed to relaunch app: '${e.message}'.");
    }
  }

  // 检查是否安装了 Multipass
  static Future<bool> isMultipassInstalled() async {
    try {
      return await _channel.invokeMethod('isMultipassInstalled');
    } on PlatformException catch (e) {
      print("Failed to check Multipass installation: ${e.message}");
      return false;
    }
  }

  // 安装 Multipass
  static Future<bool> installMultipass() async {
    try {
      return await _channel.invokeMethod('installMultipass');
    } on PlatformException catch (e) {
      print("Failed to install Multipass: ${e.message}");
      return false;
    }
  }
  static Future<dynamic> runMultipassList() async {
    try {
      return await _channel.invokeMethod('runMultipassList');
    } on PlatformException catch (e) {
      print("Failed to install Multipass: ${e.message}");
      return false;
    }
  }



  static Future<Map<String, dynamic>> installSbinMultipass() async {
    try {
      final result = await _channel.invokeMethod('installSbinMultipass');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      } else {
        return {'success': false, 'message': 'Unexpected result type'};
      }
    } on PlatformException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'PlatformException occurred'
      };
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  final StreamController<Map<String, dynamic>> _appLifecycleController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get appLifecycleStream =>
      _appLifecycleController.stream;

  void intNative() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAppLifecycleChanged' &&
          call.arguments == 'terminating') {
        await NativeApp.onExit();
        return true;
      }
      return null;
    });
  }
}
