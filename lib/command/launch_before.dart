import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

import '../config/toml_config.dart';
import '../constants/constants.dart';
import '../controllers/app_controller.dart';
import '../controllers/locale_controller.dart';
import '../l10n/translation.dart';
import '../services/global_service.dart';
import '../services/log_service.dart';
import '../utils/FileLogger.dart';
import '../utils/file_helper.dart';
import '../utils/preferences_helper.dart';
import 'dart:async';

class LaunchBeforeCommand {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);
  static final logBuffer = StringBuffer();

  /// SDK 初始化
  static Future<void> setUp() async {
    logBuffer.clear();
    final stopwatch = Stopwatch()..start();

    // 初始化 SharedPreferences (包含特殊的重试逻辑)
    await _safeRun(() async {
      try {
        await PreferencesHelper.init();
        logBuffer.writeln("init sp complete");
      } catch (e) {
        logBuffer.writeln("init sp error: $e. Retrying after delete...");
        // 如果初始化失败，尝试删除文件后重试
        await FileHelper.deletePrefsFileIfExists();
        await PreferencesHelper.init();
        logBuffer.writeln("init sp retry complete");
      }
    }, "init PreferencesHelper");

    // ==========================================================
    // 第一阶段：关键文件系统初始化 (必须最先执行)
    // ==========================================================
    // 如果工作目录都没准备好，后续的日志和配置都会失败，所以这里单独 await
    await _safeRun(
          () => FileHelper.initializeWorkDir(logBuffer),
      "initializeWorkDir",
      timeout: const Duration(seconds: 30), // 文件操作超时短一点
    );

    // ==========================================================
    // 第二阶段：核心基础设施 (并行执行，提升速度)
    // ==========================================================
    // 这些任务互不依赖，同时跑
    await Future.wait([
      _initPackageInfo(),
      _initDeviceInfo(),
      _safeRun(FileHelper.initAllTitanDirs, "init titan dirs"),
      _initConfigAndLogs(), // 配置、日志、SP缓存归为一类
    ]);

    // ==========================================================
    // 第三阶段：依赖注入与状态管理 (依赖上面的 Config/SP)
    // ==========================================================
    await _initServicesAndControllers();

    // ==========================================================
    // 第四阶段：国际化与最终设置
    // ==========================================================
    await _initLocalization();

    stopwatch.stop();
    logBuffer.writeln("Setup completed in ${stopwatch.elapsedMilliseconds}ms");

    // 统一输出日志
    if (logBuffer.isNotEmpty) {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  // ----------------------------------------------------------------
  // 子任务逻辑封装
  // ----------------------------------------------------------------

  static Future<void> _initPackageInfo() async {
    await _safeRun(() async {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      logBuffer.writeln('init packageInfo :${packageInfo.version}');
    }, "init packageInfo");
  }

  static Future<void> _initDeviceInfo() async {
    await _safeRun(() async {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? deviceId;

      if (Platform.isWindows) {
        var windowsInfo = await deviceInfo.windowsInfo;
        // 处理 Windows Device ID 的花括号
        deviceId = windowsInfo.deviceId.replaceAll("{", "").replaceAll("}", "").trim();
      } else if (Platform.isMacOS) {
        var macInfo = await deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID;
      }

      if (deviceId != null) {
        logBuffer.writeln("deviceId:$deviceId");
        await PreferencesHelper.setString(Constants.deviceId, deviceId);
      }
    }, "init deviceInfo");
  }

  static Future<void> _initConfigAndLogs() async {
    // 1. 加载 Toml 配置
    await _safeRun(() async {
      await TomlConfig.load();
      TomlConfig.updateConfigToml();
      logBuffer.writeln('TomlConfig loaded & updated');
    }, "init TomlConfig");

    // 2. 初始化日志服务
    await _safeRun(() => FileLogger.init(), "FileLogger init");
    await _safeRun(() async {
      final logService = LogService();
      await logService.init();
    }, "LogService init");


  }

  static Future<void> _initServicesAndControllers() async {
    await _safeRun(() async {
      // Get.put 通常是同步内存操作，非常快，放在一起即可
      Get.put(LocaleController());
      Get.put(AppController());
      Get.put(GlobalService());
      logBuffer.writeln('init controller complete');
    }, "init controllers");
  }

  static Future<void> _initLocalization() async {
    await _safeRun(() async {
      await Translation.loadTranslations();
      logBuffer.writeln('init load translations complete');
    }, "load translations");

    // 检查本地是否有强制语言配置文件
    await _safeRun(() async {
      String batchFilePath = 'userlanguage.txt';
      String libsPath = await FileHelper.getCurrentPath();
      String fullPath = path.join(libsPath, batchFilePath);
      final file = File(fullPath);

      if (await file.exists()) {
        final language = (await file.readAsString()).trim();
        logBuffer.writeln('Found userlanguage.txt: $language');

        // 只有在 GlobalService 注册成功后才调用，防止空指针
        if (Get.isRegistered<GlobalService>()) {
          if (language == "zh") {
            Get.find<GlobalService>().localeController.changeLocale('zh', 'CN');
          } else {
            Get.find<GlobalService>().localeController.changeLocale('en', 'US');
          }
        }
        await file.delete();
      }
    }, "init user language override");
  }

  // ----------------------------------------------------------------
  // 核心工具方法
  // ----------------------------------------------------------------

  /// 通用安全执行包装器
  /// [task] 要执行的异步任务
  /// [taskName] 任务名称，用于日志记录
  /// [timeout] 默认 30 秒超时，防止某个步骤卡死导致 APP 无法启动
  static Future<void> _safeRun(
      FutureOr<dynamic> Function() task,
      String taskName,
      {Duration timeout = const Duration(seconds: 30)}
      ) async {
    try {
      // 使用 Future.value 包裹 task() 以兼容同步和异步函数
      // timeout() 方法确保如果 task 卡住，会抛出 TimeoutException
      await Future.value(task()).timeout(timeout, onTimeout: () {
        throw TimeoutException('Task timed out after ${timeout.inSeconds}s');
      });
    } catch (e) {
      // 无论是 Timeout 还是逻辑错误，都记录日志并允许程序继续运行
      logBuffer.writeln('$taskName error/timeout: $e');
    }
  }

  static void _log(String message) {
    _logger.info("[BeforeCommand]$message");
  }
}