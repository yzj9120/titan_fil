import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:titan_fil/utils/preferences_helper.dart';

import '../config/app_config.dart';
import '../constants/constants.dart';
import '../plugins/native_app.dart';
import 'LoggerUtil.dart';

/// 文件路径工具类
class FileHelper {
  // 常量定义目录/文件名
  static const String _titanL2Dir = "titanL2";
  static const String _titanL4Dir = "titanL4";
  static const String _logsDir = "logs";
  static const String _sharedPrefsFile = "shared_preferences.json";

  static Future<String> getParentPath() async {
    if (Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      return dir.parent.parent.path;
    } else {
      if (kDebugMode) {
        return path.join(r'E:\hz\t4\libs');
      }
      return Directory.current.parent.path;
    }
  }

  static Future<String> getCurrentPath() async {
    if (Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      return dir.parent.parent.path;
    } else {
      if (kDebugMode) {
        return path.join(r'E:\hz\t4\libs');
      }
      return Directory.current.path;
    }
  }

  static Future<String> getLogsPath() async {
    return await _getAppSupportDirLogs();
  }

  /// 老的安装agent工作相关目录
  static Future<String> getWorkAgentPath() async {
    String titan_work_agent_path = "";
    if (Platform.isMacOS) {
      String libsPath = await getParentPath();
      titan_work_agent_path = path.join(libsPath, AppConfig.workingDir);
    } else {
      titan_work_agent_path = await FileHelper.getAppSupportDir();
      final Directory dir = Directory(titan_work_agent_path);
      if (!dir.existsSync()) {
        throw Exception('目录不存在: $titan_work_agent_path');
      }
    }

    return titan_work_agent_path;
  }

  static Future<String> getOldWorkAgentPath() async {
    String libsPath = await getParentPath();
    final String workingDir = path.join(libsPath, AppConfig.workingDir);
    final Directory dir = Directory(workingDir);
    if (!dir.existsSync()) {
      throw Exception('目录不存在: $workingDir');
    }
    return workingDir;
  }

  /// controller程序的路径
  static Future<String> getControllerProcessPath() async {
    final latestSubfolder = await _getLatestSubfolder();
    final controllerPath =
        path.join(latestSubfolder, AppConfig.controllerProcess);
    return controllerPath;
  }

  /// agent程序的路径
  static Future<String> getAgentProcessPath() async {
    final libPath = await getWorkAgentPath();
    final v = path.join(libPath, AppConfig.agentProcess);
    return v;
  }

  /// check_vm_names程序的路径
  static Future<String> getVmNamesProcessPath() async {
    final libPath = await getWorkAgentPath();
    final v = path.join(libPath, AppConfig.checkVmNamesProcess);
    return v;
  }

  /// 获取 [titan-agent] 下最新修改的子文件夹（A 或 B）
  static Future<String> _getLatestSubfolder() async {
    final String workingDir = await getWorkAgentPath();
    // 获取 A 和 B 文件夹
    final Directory folderA = Directory(path.join(workingDir, 'A'));
    final Directory folderB = Directory(path.join(workingDir, 'B'));
    if (!folderA.existsSync() && !folderB.existsSync()) {
      throw Exception('A 和 B 文件夹均不存在');
    }
    DateTime? lastModifiedA =
        folderA.existsSync() ? folderA.statSync().modified : null;
    DateTime? lastModifiedB =
        folderB.existsSync() ? folderB.statSync().modified : null;
    if (lastModifiedA == null) {
      return folderB.path; // 只有 B 存在
    } else if (lastModifiedB == null) {
      return folderA.path; // 只有 A 存在
    } else {
      return lastModifiedA.isAfter(lastModifiedB) ? folderA.path : folderB.path;
    }
  }

  /// 一次性初始化所有 Titan 相关目录，返回路径映射
  static Future<String> initAllTitanDirs() async {
    final appL2 = await getAppSupportDirTitanL2();
    final appL4 = await getAppSupportDirTitanL4();
    final installL2 = await getInstallationDirTitanL2();
    final installL4 = await getInstallationDirTitanL4();
    final logs = await getLogsPath();
    final parentPath = await getParentPath();
    final currentPath = await getCurrentPath();
    final String workingDir = await getWorkAgentPath();
    final Map<String, String> paths = {
      "AppSupport_TitanL2": appL2,
      "AppSupport_TitanL4": appL4,
      "Install_TitanL2": installL2,
      "Install_TitanL4": installL4,
      "logs": logs,
      "parentPath": parentPath,
      "currentPath": currentPath,
      "workingDir": workingDir,
    };

    LoggerUtil.paths(paths, title: 'Titan Directories');

    return jsonEncode(paths);
  }

  /// 确保目录存在（不存在则创建）
  /// [basePath] 基础路径
  /// [folderName] 要创建的文件夹名称
  /// 返回：创建好的完整目录路径
  static Future<String> _ensureDirectoryExists(
    String basePath,
    String folderName,
  ) async {
    try {
      final folderPath = path.join(basePath, folderName); // 拼接完整路径
      final directory = Directory(folderPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } catch (e) {
      throw Exception('创建目录 $folderName 失败: $e'); // 抛出带描述的异常
    }
  }

  //------------------ 应用支持目录 ------------------//

  /// 获取App支持目录下的TitanL2路径
  /// 示例（Windows）: C:\Users\Admin\AppData\Roaming\com.titan_fil\titan_fil\titanL2
  /// 示例（macOS）: ~/Library/Application Support/com.titan_fil/titanL2
  static Future<String> getAppSupportDirTitanL2() async {
    final dir = await getApplicationSupportDirectory(); // 获取平台对应的应用支持目录
    return _ensureDirectoryExists(dir.path, _titanL2Dir);
  }

  static Future<String> getAppSupportDir() async {
    final dir = await getApplicationSupportDirectory();
    final v = path.join(dir.path, AppConfig.workingDir);
    return v;
    // return _ensureDirectoryExists(dir.path, AppConfig.workingDir);
  }

  /// 获取App支持目录下的TitanL4路径
  /// 示例路径格式同上，末尾为titanL4
  static Future<String> getAppSupportDirTitanL4() async {
    final dir = await getApplicationSupportDirectory();
    return _ensureDirectoryExists(dir.path, _titanL4Dir);
  }

  static Future<String> _getAppSupportDirLogs() async {
    final dir = await getApplicationSupportDirectory();
    return _ensureDirectoryExists(dir.path, _logsDir);
  }

  //------------------ 安装目录 ------------------//

  /// 获取TitanL2的安装目录路径（MacOS特殊处理）
  /// 非MacOS：使用当前工作目录（如D:\titan_fil\titanL2）
  /// MacOS：仍使用应用支持目录（苹果应用沙箱限制）
  static Future<String> getInstallationDirTitanL2() async {
    final basePath = Platform.isMacOS
        ? (await getApplicationSupportDirectory()).path // MacOS特殊处理
        : Directory.current.path; // 其他平台使用当前目录
    return _ensureDirectoryExists(basePath, _titanL2Dir);
  }

  /// 获取TitanL4的安装目录路径（规则同TitanL2）
  static Future<String> getInstallationDirTitanL4() async {
    final basePath = Platform.isMacOS
        ? (await getApplicationSupportDirectory()).path
        : Directory.current.path;
    return _ensureDirectoryExists(basePath, _titanL4Dir);
  }

  //------------------ 其他工具方法 ------------------//

  /// 获取shared_preferences.json文件路径（如果存在）
  /// 返回：文件完整路径或null（文件不存在时）
  static Future<String?> getSharedPreferencesPath() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final filePath = path.join(dir.path, _sharedPrefsFile);
      return await File(filePath).exists() ? filePath : null;
    } catch (e) {
      return null; // 出错时静默返回null
    }
  }

  /// 文件压缩
  static Future<File> compressLogs(List<File> logFiles, String zipName) async {
    final Archive archive = Archive();
    for (final file in logFiles) {
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(
        path.basename(file.path), // 保留原始文件名
        bytes.length,
        bytes,
      ));
    }
    final zipBytes = ZipEncoder().encode(archive)!;
    final logsDir = await _getAppSupportDirLogs();
    final zipPath = path.join(logsDir, "$zipName.zip");
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipBytes);
    return zipFile;
  }

  /// 删除指定的zip文件
  static Future<void> deleteZipFile(String zipFilePath) async {
    debugPrint('deleteZipFile: $zipFilePath');
    final file = File(zipFilePath);
    try {
      if (await file.exists()) {
        await file.delete();
        debugPrint('deleteZipFile 文件删除成功: $zipFilePath');
      } else {
        debugPrint('deleteZipFile 文件不存在: $zipFilePath');
      }
    } catch (e) {
      debugPrint('deleteZipFile 删除文件失败: $e');
    }
  }

  static Future<void> onDeleteFile(String filePath) async {
    // 指定要删除的文件路径
    File file = File(filePath);
    // 检查文件是否存在
    if (await file.exists()) {
      // 删除文件
      await file.delete();
      if (kDebugMode) {
        debugPrint('File deleted: $filePath');
      }
    } else {
      if (kDebugMode) {
        debugPrint('File does not exist at path: $filePath');
      }
    }
  }

  static bool _isProcessing = false;

  static Future<String> selectFolder() async {
    if (_isProcessing) {
      return "";
    }
    _isProcessing = true;
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      var directory = Directory(selectedDirectory);
      String realPath = directory.resolveSymbolicLinksSync();
      if (Platform.isMacOS) {
        realPath = "$realPath/${NativeApp.titanStorage}";
      } else {
        realPath = path.join(realPath, NativeApp.titanStorage);
      }
      _isProcessing = false;
      return realPath;
    }
    _isProcessing = false;
    return "";
  }

  static Future<int> findFile(String filePath) async {
    try {
      Directory directory = Directory(filePath);
      int itemCount = await countItems(directory);
      return itemCount;
    } catch (e) {
      return 0;
    }
  }

  static Future<int> countItems(Directory directory) async {
    int count = 0;
    await for (FileSystemEntity entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File || entity is Directory) {
        count++;
      }
    }
    return count;
  }

  static Future<String> moveFolder(
    String sourcePath,
    String storagePath,
    double folderSize, {
    Function? onStartDeleteFile,
    Function? onEndDeleteFile,
  }) async {
    var result = await NativeApp.copyFile(sourcePath, storagePath);
    if (result == "ok") {
      //正常拷贝成功
      await PreferencesHelper.setString(Constants.copyFileStatus, "ok");
      return "ok";
    } else if (result == "kill") {
      //拷贝异常
      String hasKill =
          await PreferencesHelper.getString(Constants.copyFileStatus) ?? "";
      if (hasKill == "cancel") {
        await PreferencesHelper.setString(Constants.copyFileStatus, "cancel");
        return "cancel";
      } else {
        await PreferencesHelper.setString(Constants.copyFileStatus, "kill");
        return "kill";
      }
    }
    return result;
  }

  /// 清理日志
  static Future<void> clearStorage() async {
    String hasKill =
        await PreferencesHelper.getString(Constants.copyFileStatus) ?? "";

    debugPrint("clearStorage...$hasKill");

    if (hasKill == 'kill') {
      // 移除中断
      String failurePath =
          await PreferencesHelper.getString(Constants.failurePath) ?? "";
      await compute(NativeApp.deleteFile, failurePath);
      await PreferencesHelper.setString(Constants.copyFileStatus, "");
    } else if (hasKill == 'ok') {
      // 正常完成
      String path = await PreferencesHelper.getString(Constants.oldPath) ?? "";

      /// 当文件被使用时：文件就无法迁移
      await compute(NativeApp.deleteFile, path);
      await PreferencesHelper.setString(Constants.copyFileStatus, "");
    } else if (hasKill == 'cancel') {
      // 取消
      String newPath =
          await PreferencesHelper.getString(Constants.cancelPath) ?? "";
      await compute(NativeApp.deleteFile, newPath);
      await PreferencesHelper.setString(Constants.copyFileStatus, "");
    }
  }

  ///  win 系统： await getApplicationSupportDirectory();可以获取shared_preferences的地址：
  ///  mac 系统：await getApplicationSupportDirectory();无法获取：保存位置位于：Users/dq/Library/Preferences/com.titan_fil.titanNetwork.plist
  static Future<void> deletePrefsFileIfExists() async {
    // 获取应用支持目录
    Directory appDocDir = await getApplicationSupportDirectory();
    String folderPath = appDocDir.path;
    String filePath = path.join(folderPath, "shared_preferences.json");
    // 检查文件是否存在
    File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 定义一个常量 Key，用于存储迁移状态
  static const String _kMigrationCompleteKey =
      "key_agent_migration_completed_v1";

  /// 逻辑流程：
  /// 1. 确定【新版本】的固定存储位置 (Target)。
  /// 2. 尝试寻找【老版本】的旧数据位置 (Source)。
  /// 3. 如果找到旧数据 -> 尝试将其【迁移/复制】到新位置。
  /// 4. 如果没找到或复制失败 -> 【兜底】新建一个空的新目录，保证程序不崩。
  static Future<bool> initializeWorkDir(StringBuffer? logBuffer) async {
    // 这个逻辑只针对 Windows 文件系统迁移，Mac/Linux 跳过
    if (!Platform.isWindows) {
      logBuffer?.writeln('⚠️ initializeWorkDir only runs on Windows.');
      return false;
    }
    // 这是新版本规定的固定目录 (如 AppData/Roaming/...)
    // [Step 1] 确定目标目录 (Target Directory)
    String targetDirPath = "";
    try {
      // 1. 尝试获取标准的 AppData 路径
      targetDirPath = await FileHelper.getAppSupportDir();
    } catch (e) {
      logBuffer?.writeln('⚠️ Failed to get standard AppSupport path: $e');
      // 如果系统路径获取失败，尝试使用当前 exe 所在的目录下的 _agent_fallback 文件夹
      try {
        String currentPath = await FileHelper.getCurrentPath();
        targetDirPath =
            path.join(currentPath, "${AppConfig.workingDir}_fallback");
        logBuffer
            ?.writeln('⚠️ Switching to fallback target path: $targetDirPath');
      } catch (e2) {
        // 如果连当前路径都获取不到（简直不可能），那才是真的没救了
        logBuffer?.writeln('❌ Fatal: Failed to get ANY target path: $e2');
        return false;
      }
    }
    // 拿到路径对象
    final Directory targetDir = Directory(targetDirPath);
    debugPrint("工作地址：" + targetDirPath);
    // 开始核心业务逻辑
    try {
      bool hasMigrated =
          await PreferencesHelper.getBool(_kMigrationCompleteKey) ?? false;
      // 如果标记显示“已完成”，并且目标目录确实存在
      if (hasMigrated && await targetDir.exists()) {
        logBuffer
            ?.writeln('✅ Migration already completed previously. Skipping.');
        return true; // 直接返回，不再执行后续耗时操作
      }
      // [Step 2] 寻找源目录 (Source Directory)
      String sourceDir = "";
      bool oldDirFound = false;
      // --- 策略 A: 尝试读取安装记录文件 ---
      // 安装包通常会留一个 txt 记录上次安装在哪
      const String lastAppPath = 'last_install_path.txt';
      try {
        final String libsPath = await FileHelper.getCurrentPath();
        final File configFile = File(path.join(libsPath, lastAppPath));
        // 如果记录文件存在
        if (await configFile.exists()) {
          // 读取内容并去除空格
          final String recordedPath = (await configFile.readAsString()).trim();
          if (recordedPath.isNotEmpty) {
            // 猜测 1: _agent 文件夹在安装目录【内部】
            sourceDir = path.join(recordedPath, AppConfig.workingDir);
            // 验证猜测 1 是否正确
            if (!await Directory(sourceDir).exists()) {
              // 猜测 2: _agent 文件夹在安装目录的【同级/父级】
              sourceDir =
                  path.join(path.dirname(recordedPath), AppConfig.workingDir);
            }
          }
        }
      } catch (e) {
        // 读取记录文件失败也没关系，仅仅是记录日志，继续尝试策略 B
        logBuffer?.writeln('Log: Reading last_install_path failed: $e');
      }

      // --- 策略 B: 备用方案 (Fallback) ---
      // 如果策略 A 没找到路径，或者路径无效，尝试根据【当前 exe 位置】推断
      if (!await Directory(sourceDir).exists()) {
        try {
          // 获取当前运行目录的父级，拼接 _agent
          // 适用于绿色版或便携版场景
          String currentParent = await getParentPath();
          sourceDir = path.join(currentParent, AppConfig.workingDir);
        } catch (e) {
          logBuffer?.writeln('Log: Guessing fallback path failed: $e');
        }
      }

      // [Step 3] 最终确认源目录是否存在
      oldDirFound = await Directory(sourceDir).exists();
      // [Step 4] 执行迁移 或 新建

      if (oldDirFound) {
        // === 分支 1: 找到了老数据 ===
        debugPrint('Found source directory: $sourceDir');
        try {
          // 4.1 确保目标目录的父级结构存在 (防止 Copy 时找不到路径)
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
          logBuffer?.writeln('Migrating to: $targetDirPath');
          // 4.2 调用 Native (C++) 层进行高性能文件复制
          // 注意：Native 层应该实现“覆盖(Overwrite)”逻辑，保证新版生效
          final result = await NativeApp.copyFileNew(sourceDir, targetDirPath);
          if (result == "ok") {
            // === 成功 ===
            await PreferencesHelper.setBool(_kMigrationCompleteKey, true);
            logBuffer?.writeln('✅ Migration successful.');
            return true;
          } else {
            // === 失败 (Native 返回错误) ===
            // 可能是文件被占用或磁盘满。记录错误，然后去“兜底”
            await PreferencesHelper.setBool(_kMigrationCompleteKey, false);
            logBuffer?.writeln(
                '⚠️ Migration failed ($result). fallback to create empty dir.');
            return await _ensureCleanTargetDir(targetDir, logBuffer);
          }
        } catch (e) {
          // === 异常 (Dart 层报错) ===
          logBuffer?.writeln('⚠️ Migration exception: $e');
          // 发生异常也不能让 App 崩，去“兜底”
          return await _ensureCleanTargetDir(targetDir, logBuffer);
        }
      } else {
        // === 分支 2: 没找到老数据 (新用户) ===
        debugPrint('Source not found. Creating new empty directory.');
        // 避免下次启动还去到处找老目录
        // 直接新建一个空的目录给 App 用
        bool success = await _ensureCleanTargetDir(targetDir, logBuffer);
        if (success) {
          await PreferencesHelper.setBool(_kMigrationCompleteKey, true);
        }
        return success;
      }
    } catch (e, stackTrace) {
      // [Step 5] 严重错误捕获 (全局安全网)
      // 捕获所有未预料到的崩溃 (如权限被拒绝 AccessDenied)
      logBuffer?.writeln('❌ Critical Init Error: $e\n$stackTrace');
      // 最后的抢救：尝试强行创建一个目录，死马当活马医
      try {
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } catch (_) {
        // 如果连这也失败了，那就真没办法了，但在日志里留下了痕迹
      }
      return false;
    }
  }

  /// 作用：不管之前发生了什么（复制失败、源不存在），
  /// 只要保证 Target 目录在磁盘上是存在的，App 就不会闪退。
  static Future<bool> _ensureCleanTargetDir(
      Directory targetDir, StringBuffer? logBuffer) async {
    try {
      if (!await targetDir.exists()) {
        // 如果目录不存在，创建它
        logBuffer?.writeln('Creating empty target directory...');
        await targetDir.create(recursive: true);
      } else {
        // 如果目录已经存在（可能是之前残留的），那就直接用
        logBuffer?.writeln('Target directory already exists (fallback).');
      }
      return true;
    } catch (e) {
      // 创建目录都失败了（极少见，除非磁盘坏了或权限极严）
      logBuffer?.writeln('❌ Failed to create target directory: $e');
      return false;
    }
  }
}
