import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../channelService/defineMethodChannel.dart';
import '../constants/constants.dart';
import '../services/log_service.dart';
import '../utils/FileLogger.dart';
import '../widgets/loading_indicator.dart';
import 'agent_Isolate.dart';
import 'multipass_plugin.dart';

class NativeApp {
  static const String titanStorage = "titanStorage";

  static final logUtils = LoggerFactory.createLogger(LoggerName.t3);

  static Future<void> batchVerifyCertificates(List<String> urls) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    final results = <String>[];
    logBuffer.writeln("batchVerifyCertificates...");
    for (var url in urls) {
      try {
        // 确保 URL 是 HTTPS 且格式正确
        final parsedUrl = Uri.parse(url);
        if (!parsedUrl.isAbsolute || parsedUrl.scheme != 'https') {
          final msg = "[$url]: Invalid URL (must be HTTPS)";
          logBuffer.writeln(msg);
          continue;
        }
        // 执行 curl 命令
        final result = await Process.run(
          'curl',
          [
            '-v', // 显示详细输出（包括证书信息）
            // '--fail', // 如果 HTTP 状态码 >=400 则返回错误
            // '--silent', // 不显示进度条
            // '--connect-timeout', '5', // 连接超时 5 秒
            url,
          ],
          runInShell: true,
        ).timeout(const Duration(seconds: 10));
        // 合并 stdout 和 stderr
        final output = result.stdout.toString() + result.stderr.toString();
        // 分析结果
        if (result.exitCode == 0) {
          // 成功标志
          if (output.contains("SSL certificate verify ok")) {
            final msg = "[$url]: verify ok";
            logBuffer.writeln(msg);
          } else {
            // 如果没有明确验证信息但退出码为0，默认成功
            final msg = "[$url]: Success";
            logBuffer.writeln(msg);
          }
        } else {
          // 失败标志
          if (output.contains("certificate verify failed") ||
              output.contains("SSL:") && output.contains("verify error")) {
            final msg = "[$url]: verify failed";
            logBuffer.writeln(msg);
          } else if (output.contains("Could not resolve host")) {
            final msg = "[$url]: Could not resolve host";
            logBuffer.writeln(msg);
          } else if (output.contains("Connection timed out")) {
            final msg = "[$url]: Connection timed out";
            logBuffer.writeln(msg);
          } else {
            final msg =
                "[$url]: Failed (exit code ${result.exitCode}): ${output.length > 200 ? output.substring(0, 200) + '...' : output}";
            logBuffer.writeln(msg);
          }
        }
      } catch (e) {
        final msg = "[$url] Error: ${e.toString()}";
        logBuffer.writeln(msg);
      }
    }
    _log(logBuffer.toString());
    logBuffer.clear();
  }

  /// 从 curl 输出中提取 HTTP 状态码
  static int? _extractHttpStatus(String output) {
    final regExp = RegExp(r'HTTP/\d\.\d (\d{3})');
    final match = regExp.firstMatch(output);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// 检查是否为 Windows Home 版
  static Future<bool> isWindowsHome() async {
    return true;
    String edition = await _getWindowsEdition();
    _log("Edition: $edition");
    return edition.contains("Core") || edition.contains("Home");
  }

  /// 读取 Windows 版本
  static Future<String> _getWindowsEdition() async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_fetchWindowsEdition, receivePort.sendPort);
    return await receivePort.first;
  }

  static Future<void> _fetchWindowsEdition(SendPort sendPort) async {
    if (!Platform.isWindows) {
      sendPort.send("");
      return;
    }

    Process? process;
    try {
      process = await Process.start(
        'C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
        [
          '-Command',
          '(Get-ItemProperty -Path "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion").EditionID'
        ],
      );

      // 等待进程结束或超时
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill); // 强制终止
          throw TimeoutException('PowerShell timeout');
        },
      );

      final stdout = await process.stdout
          .transform(utf8.decoder)
          .join(); // 使用 join() 读取全部输出
      final stderr = await process.stderr
          .transform(utf8.decoder)
          .join(); // 使用 join() 读取全部错误

      if (exitCode == 0) {
        final edition = stdout.trim();
        sendPort.send(edition.isEmpty ? "Unknown" : edition);
      } else {
        sendPort.send("PowerShell error: $stderr");
      }
    } on TimeoutException {
      sendPort.send("get Windows timeout");
    } on ProcessException catch (e) {
      sendPort.send("not start PowerShell: $e");
    } finally {
      process?.kill(); // 确保进程被终止
    }
  }

  /// 查询注册表来检测管理员权限
  Future<bool> isAdministrator() async {
    // Mac 和 Linux 系统默认返回 true
    if (Platform.isMacOS || Platform.isLinux) {
      return true;
    }
    final receivePort = ReceivePort();
    await Isolate.spawn(_checkAdmin, receivePort.sendPort);
    return await receivePort.first;
  }

  /// 检查 Windows 系统是否具有管理员权限
  static Future<void> _checkAdmin(SendPort sendPort) async {
    if (!Platform.isWindows) {
      sendPort.send(true);
      return;
    }

    // 方法1：PowerShell检查（最准确）
    try {
      final psProcess = await Process.start(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          r'[bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)'
        ],
        runInShell: true,
      );

      final exitCode =
          await psProcess.exitCode.timeout(const Duration(seconds: 3));
      if (exitCode == 0) {
        final output = await psProcess.stdout.transform(utf8.decoder).join();
        if (output.trim().toLowerCase() == 'true') {
          sendPort.send(true);
          return;
        }
      }
    } catch (e) {
      debugPrint('PS check failed: $e');
    }

    // 方法2：whoami /groups 检查（快速回退）
    try {
      final whoamiProcess = await Process.start(
        'whoami',
        ['/groups'],
        runInShell: true,
      );

      final output = await whoamiProcess.stdout
          .transform(utf8.decoder)
          .timeout(const Duration(seconds: 2))
          .join();

      if (output.contains('S-1-5-32-544')) {
        // 管理员组SID
        sendPort.send(true);
        return;
      }
    } catch (e) {
      debugPrint('Whoami check failed: $e');
    }

    // 方法3：实际权限测试（终极检查）
    try {
      final testProcess = await Process.start(
        'sc',
        ['stop', 'winmgmt'], // 尝试停止需要管理员权限的服务
        runInShell: true,
      );

      final exitCode =
          await testProcess.exitCode.timeout(const Duration(seconds: 2));
      sendPort.send(exitCode == 0); // 只有管理员才能停止服务
    } catch (e) {
      debugPrint('Service check failed: $e');
      sendPort.send(false);
    }
  }

  /// 终止应用程序
  static Future<void> _quitApplication(String appName) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('killall', ['-9', appName]);
      } else if (Platform.isWindows) {
        await Process.run('taskkill', ['/f', '/im', '$appName.exe']);
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      debugPrint('quitApplication: $appName 出错：$e');
    }
  }

  /// 启动应用程序
  static Future<void> _startApplication(String appName) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('open', ["$appName.app"]);
      } else if (Platform.isWindows) {
        await Process.run('taskkill', ['/f', '/im', '$appName.exe']);
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      debugPrint('startApplication: $appName 出错：$e');
    }
  }



  ///重启程序
  static void restartApplication() async {
    try {
      if (Platform.isMacOS) {
        await DefineMethodChannel.relaunchApp();
      } else if (Platform.isWindows) {
        await AgentIsolate.killProcesses();
        var list = await MultiPassPlugin().getVmNames();
        await Future.wait(list.map((e) async {
          await AgentIsolate.forceStopVm(e);
        }));
        await MultiPassPlugin().killProcesses();
        String batchFilePath = 'start_main_run.bat';
        String fullPath = '${Directory.current.path}\\$batchFilePath';
        await Process.run(fullPath, []);
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      _quitApplication("titan_fil");
      _startApplication("titan_fil");
    }
  }

  static late Process copyFileProcess;

  static Future<String> copyFile(
      String sourcePath, String destinationPath) async {
    try {
      if (Platform.isMacOS) {
        copyFileProcess =
            await Process.start('cp', ['-R', "$sourcePath/", destinationPath]);
      } else if (Platform.isWindows) {
        var sourcePath2 = sourcePath.replaceAll(r'\', r'\\');
        var destinationPath2 = destinationPath.replaceAll(r'\', r'\\');
        List<String> command = [
          '/s',
          '/e',
          '/i',
          '/c',
          '/y',
          "$sourcePath2\\",
          destinationPath2
        ];
        copyFileProcess = await Process.start('xcopy', command);
        copyFileProcess.stdout.transform(utf8.decoder).listen((data) {});
        copyFileProcess.stderr.transform(utf8.decoder).listen((data) {});
      } else {
        throw Exception('Unsupported platform');
      }
      var res = await copyFileProcess.exitCode;
      return res == 0 ? "ok" : "kill";
    } catch (e) {
      return 'copyFile:error：$e';
    }
  }

  ///暂停复制
  void pauseCopy() {
    copyFileProcess.kill(ProcessSignal.sigstop);
  }

  ///恢复复制
  void resumeCopy() {
    copyFileProcess.kill(ProcessSignal.sigcont);
  }

  ///停止复制
  static Future<String> stopCopy() async {
    try {
      if (Platform.isMacOS) {
        copyFileProcess.kill();
      } else if (Platform.isWindows) {
        copyFileProcess.kill();
      } else {
        throw Exception('Unsupported platform');
      }
      return "ok";
    } catch (e) {
      return '：$e';
    }
  }

  ///删除文件
  static Future<int> deleteFile(String filePath) async {
    try {
      debugPrint("删除文件：：$filePath");
      if (Platform.isWindows) {
        var sourcePath = filePath.replaceAll(r'\', r'\\');
        var res =
            await Process.run('cmd', ['/c', 'rd', '/s', '/q', sourcePath]);
        return res.exitCode == 0 ? 0 : 3;
      } else {
        var res = await Process.run('rm', ['-rf', filePath]);
        return res.exitCode == 0 ? 0 : 3;
      }
    } catch (e) {
      debugPrint("deleteFile:error:$e");
      return 3;
    }
  }

  static Future<void> restartWindows() async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    // 平台检查
    if (!Platform.isWindows) {
      await DefineMethodChannel.relaunchMac();
      return;
    }
    try {
      logBuffer.writeln("restart command");

      // 执行重启命令
      final process = await Process.run('shutdown', ['/r', '/f', '/t', '0'])
          .timeout(Duration(seconds: 10));
      logBuffer.writeln("Command: $process");
      // 处理执行结果
      if (process.exitCode != 0) {
      } else {
        // 仅在成功时增加并保存计数器
        final prefs = await SharedPreferences.getInstance();
        int restartCount = prefs.getInt(Constants.restartWindowsCount) ?? 0;
        restartCount++;
        await prefs.setInt(Constants.restartWindowsCount, restartCount);
        logBuffer.writeln(
            "Restart command succeeded. Counter incremented to $restartCount");
      }
    } on TimeoutException {
      logBuffer.writeln("Restart command timed out after 10 seconds");
    } catch (e) {
      logBuffer.writeln("Critical restart error: ${e.toString()}");
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  static Future<void> onExit() async {
    final loading = LoadingIndicator();
    try {
      loading.showWithGet(message: "exiting_app".tr);
    } catch (error) {
      debugPrint("onExit:${error}");
    }

    try {
      await AgentIsolate.killProcesses();
      var list = await MultiPassPlugin().getVmNames();
      FileLogger.log('list:$list');
      await Future.wait(list.map((e) async {
        final result = await AgentIsolate.forceStopVm(e.trim());
        FileLogger.log('forceStopVm：$result');
        return result;
      }));
      FileLogger.log('forceStopVm：complete');
      await MultiPassPlugin().killProcesses();
      FileLogger.log('killProcesses：complete');
      loading.hide();
      exit(0);
    } catch (error) {
      debugPrint("onExit:${error}");
      exit(1);
    }
  }

  /// 复制文件或目录（跨平台）
  /// 返回值：
  /// - "ok"：复制成功
  /// - "timeout"：超时
  /// - 其他字符串：错误信息
  /// 复制文件夹（优先使用系统命令，失败则回退到 Dart 层复制）
  static Future<String> copyFileNew(String sourcePath, String destinationPath) async {
    try {
       late Process copyFileProcess;
      bool success = false;
      int exitCode = -1;

      if (Platform.isMacOS) {
        // macOS 使用 cp -R 命令
        copyFileProcess = await Process.start('cp', ['-R', '$sourcePath/', destinationPath]);
      } else if (Platform.isWindows) {
        // Windows 使用 xcopy 命令
        final args = ['/s', '/e', '/i', '/c', '/y', '$sourcePath\\', destinationPath];
        copyFileProcess = await Process.start('xcopy', args, runInShell: true);
      } else {
        throw Exception('Unsupported platform');
      }

      // 捕获输出（可用于调试）
      copyFileProcess.stdout.transform(utf8.decoder).listen((data) {
        if (data.contains('error') || data.contains('failed')) {
          print('⚠️ Copy output: $data');
        }
      });

      copyFileProcess.stderr.transform(utf8.decoder).listen((data) {
        print('❌ Copy error: $data');
      });

      // 等待命令执行结束
      exitCode = await copyFileProcess.exitCode;
      success = exitCode == 0;
      // ✅ 如果命令行复制成功
      if (success) {
        print('✅ Native copy completed successfully.');
        return "ok";
      }
      // ❌ 命令行失败，执行代码级复制回退方案
      print('⚠️ Native copy failed (exitCode=$exitCode). Falling back to Dart copy...');
      bool fallbackSuccess = await _copyWithDart(sourcePath, destinationPath);
      return fallbackSuccess ? "ok" : "fallback_failed";

    } catch (e, stackTrace) {
      print('❌ copyFileNew exception: $e\n$stackTrace');
      // 如果命令失败，直接尝试 Dart 级复制
      bool fallbackSuccess = await _copyWithDart(sourcePath, destinationPath);
      return fallbackSuccess ? "ok" : "fallback_failed";
    }
  }

  /// Dart 实现的递归文件复制（备用方案）
  static Future<bool> _copyWithDart(String sourcePath, String destinationPath) async {
    try {
      final srcDir = Directory(sourcePath);
      final destDir = Directory(destinationPath);

      if (!await srcDir.exists()) {
        print('⚠️ Source directory does not exist: $sourcePath');
        return false;
      }
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await for (var entity in srcDir.list(recursive: true)) {
        final relative = path.relative(entity.path, from: sourcePath);
        final newPath = path.join(destinationPath, relative);

        if (entity is File) {
          await File(entity.path).copy(newPath);
        } else if (entity is Directory) {
          await Directory(newPath).create(recursive: true);
        }
      }
      print('✅ Fallback copy completed successfully.');
      return true;
    } catch (e, stackTrace) {
      print('❌ Fallback copy failed: $e\n$stackTrace');
      return false;
    }
  }



  static void _log(String message, {bool warning = false}) {
    if (warning == false) {
      logUtils.info('[NativeApp] : $message');
    } else {
      logUtils.warning('[NativeApp Error] : $message');
    }
  }
}
