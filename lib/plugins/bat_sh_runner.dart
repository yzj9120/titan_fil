import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;

import '../page/setting/pcdn_broadband/set_pcdn_broadband_controller.dart';
import '../services/log_service.dart';
import '../utils/FileLogger.dart';
import '../utils/file_helper.dart';

/**
 * Titan Agent 交互插件
 *
 */
class BatShRunner {
  static final _logger = LoggerFactory.createLogger(LoggerName.t3);

  static final BatShRunner _instance = BatShRunner._internal();

  factory BatShRunner() {
    return _instance;
  }

  BatShRunner._internal();

  Future<int> getFileSize(String file, {int defaultSize = 2}) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      String batchFilePath = 'get_files_size.bat';
      String libsPath = await FileHelper.getCurrentPath();
      String fullPath = path.join(libsPath, batchFilePath);
      if (!await File(fullPath).exists()) {
        logBuffer.writeln(
            'getFileSize:Batch file not found at $fullPath:call $defaultSize');
        _log(logBuffer.toString());
        return defaultSize;
      }
      logBuffer.writeln('getFileSize Running batch file at: $fullPath');
      final result = await Process.run(
        fullPath,
        [file],
        runInShell: false,
      );
      logBuffer.writeln(
          'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');

      if (result.exitCode != 0) {
        return defaultSize;
      }
      final output = result.stdout.toString().trim();
      final size = int.tryParse(output);
      if (size == null) {
        logBuffer.writeln('Invalid output format: $output');
        return defaultSize;
      }
      return size;
    } catch (e) {
      logBuffer.writeln('Error executing batch file: $e');
      return defaultSize;
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<void> isHyperVEnabled() async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      String batchFilePath = 'check_hypper_v.bat';
      String libsPath = await FileHelper.getCurrentPath();
      String fullPath = path.join(libsPath, batchFilePath);
      logBuffer.writeln('isHyperVEnabled run ptah: $fullPath');
      ProcessResult result = await Process.run(fullPath, []);
      logBuffer.writeln(
          'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');
    } catch (e) {
      logBuffer.writeln('Error in : $e');
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<Map<String, dynamic>?> getSystemInfo({String? drivePath}) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    Future<Map<String, dynamic>?> _handleResult(ProcessResult result) async {
      try {
        if ((result.stderr as String).trim().isNotEmpty) {
          logBuffer.writeln('getSystemInfo:${result.stderr}');
        }
        final jsonData = jsonDecode(result.stdout);
        return Map<String, dynamic>.from(jsonData);
      } catch (e) {
        logBuffer.writeln('getSystemInfo:error: $e');
        return null;
      }
    }

    try {
      String scriptName;
      List<String> cmdArgs;
      ProcessResult result;
      if (Platform.isMacOS || Platform.isLinux) {
        scriptName = 'system_info.sh';
        final executableDir = File(Platform.resolvedExecutable).parent.path;
        final resourceDir =
            Directory('$executableDir/../Resources').resolveSymbolicLinksSync();
        final scriptPath = '$resourceDir/$scriptName';
        logBuffer.writeln('getSystemInfo:scriptPath: $scriptPath');
        cmdArgs = [scriptPath];
        result = await Process.run('/bin/bash', cmdArgs);
      } else if (Platform.isWindows) {
        scriptName = 'get-systemInfo.bat';
        String libsPath = await FileHelper.getCurrentPath();
        final scriptPath = path.join(libsPath, scriptName);
        // 要查询的磁盘（可能为 null 或空字符串）
        String? driveLetter = drivePath; // 这里可以是 null 或空字符串
        // 构建参数列表
        List<String> arguments = ['/c', scriptPath];
        // 只有当 driveLetter 不为 null 且不为空时才添加参数
        if (driveLetter != null && driveLetter.isNotEmpty) {
          arguments.add(driveLetter);
        }
        FileLogger.log(':arguments:$arguments', tag: 'getSystemInfo');
        // 执行命令
        logBuffer.writeln('getSystemInfo:: $scriptPath');
        result = await Process.run('cmd.exe', arguments);
        FileLogger.log(
            "exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}");
      } else {
        logBuffer.writeln('当前平台不支持执行脚本');
        return null;
      }
      logBuffer.writeln(
          'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');
      final value = await _handleResult(result);
      FileLogger.log('value : $value', tag: 'getSystemInfo');
      return value;
    } catch (e) {
      FileLogger.log('Error in : $e', tag: 'getSystemInfo');
      logBuffer.writeln('Enabled Error in : $e');
      return null;
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<Map<String, dynamic>?> getCheckProxyIp() async {
    Future<Map<String, dynamic>?> _handleResult(ProcessResult result) async {
      try {
        final jsonData = jsonDecode(result.stdout);
        return Map<String, dynamic>.from(jsonData);
      } catch (e) {
        return null;
      }
    }

    final logBuffer = StringBuffer();
    logBuffer.clear();
    logBuffer.writeln('getCheckProxyIp:start;');
    const timeoutDuration = Duration(seconds: 30);
    try {
      String scriptName;
      List<String> cmdArgs;
      ProcessResult result;
      if (Platform.isMacOS || Platform.isLinux) {
        scriptName = 'check_proxy_ip.sh';
        final executableDir = File(Platform.resolvedExecutable).parent.path;
        final resourceDir =
        Directory('$executableDir/../Resources').resolveSymbolicLinksSync();
        final scriptPath = '$resourceDir/$scriptName';
        cmdArgs = [scriptPath];
        result =
        await Process.run('/bin/bash', cmdArgs).timeout(timeoutDuration);
        logBuffer.writeln('result;$result');
      } else if (Platform.isWindows) {
        scriptName = 'check_proxy_ip.bat';
        String libsPath = await FileHelper.getCurrentPath();
        final scriptPath = path.join(libsPath, scriptName);
        // 构建参数列表
        List<String> arguments = ['/c', scriptPath];
        result =
        await Process.run('cmd.exe', arguments).timeout(timeoutDuration);
        logBuffer.writeln('result;$result');
      } else {
        return null;
      }
      final value = await _handleResult(result);
      logBuffer.writeln('value;$value');
      return value;
    } catch (e) {
      logBuffer.writeln('catch;$e');
      return null;
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<CommandResult> runLimitScript(String uploadLimit, String downloadLimit,
      {String vbName = ""}) async {
    const timeoutDuration = Duration(seconds: 60);

    try {
      String scriptName;
      List<String> cmdArgs;
      ProcessResult result;

      if (Platform.isMacOS || Platform.isLinux) {
        scriptName = 'limit_multipass_vm.sh';
        final executableDir = File(Platform.resolvedExecutable).parent.path;
        final resourceDir =
            Directory('$executableDir/../Resources').resolveSymbolicLinksSync();
        final scriptPath = '$resourceDir/$scriptName';

        if (!File(scriptPath).existsSync()) {
          return CommandResult(
            success: false,
            exitCode: -1,
            stdout: "",
            stderr: "",
            errorMessage: 'Script not found: $scriptPath',
          );
        }
        cmdArgs = [scriptPath, "${uploadLimit}mbit", downloadLimit];
        result =
            await Process.run('/bin/bash', cmdArgs).timeout(timeoutDuration);
      } else if (Platform.isWindows) {
        // 1. 先尝试 set Limit
        final result = await runCommand([
          'bandwidthctl',
          vbName.trim(),
          'set',
          'Limit',
          '--limit',
          '${uploadLimit}m',
        ]);

        if (result.success) {
          return result; // 成功就直接返回
        }

  // 2. 如果 set 失败，尝试创建 Limit 分组
        final res = await runCommand([
          'bandwidthctl',
          vbName.trim(),
          'add',
          'Limit',
          '--type',
          'network',
          '--limit',
          '${uploadLimit}m',
        ]);
        await FileLogger.log('runLimitScript:res=$res');
        if (!res.success) {
          return res; // add 失败，提前结束
        }
        // 绑定带宽组到网卡1
        final res2 = await runCommand([
          'modifyvm',
          '${vbName.trim()}',
          '--nicbandwidthgroup1',
          'Limit',
        ]);
        await FileLogger.log('runLimitScript:res2=$res2');
        if (!res2.success) {
          return res2;
        }
        // 修改带宽限制为30m
        final res3 = await runCommand([
          'bandwidthctl',
          '${vbName.trim()}',
          'set',
          'Limit',
          '--limit',
          '${uploadLimit}m',
        ]);
        await FileLogger.log('runLimitScript:res3=$res3');
        if (!res3.success) {
          return res3;
        }
        // 解绑网卡带宽限制
        final res4 = await runCommand([
          'modifyvm',
          '${vbName.trim()}',
          '--nicbandwidthgroup1',
          'none',
        ]);
        await FileLogger.log('runLimitScript:res4=$res4');
        if (!res4.success) {
          return res4;
        }
        return CommandResult(
          success: true,
          exitCode: 0,
          stdout: "",
          stderr: "",
          errorMessage: '',
        );
      } else {
        return CommandResult(
          success: false,
          exitCode: -1,
          stdout: "",
          stderr: "",
          errorMessage: 'Unsupported platform: ${Platform.operatingSystem}',
        );
      }
      return CommandResult(
        success: result.exitCode == 0,
        exitCode: result.exitCode,
        stdout: result.stdout,
        stderr: result.stderr,
        errorMessage: result.stderr,
      );
    } catch (e, st) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: "",
        stderr: "",
        errorMessage: 'Exception: $e\n$st',
      );
    }
  }

  Future<CommandResult> runCommand(List<String> vboxmanageArgs) async {
    final vboxmanagePath = findVBoxManagePath();
    // final libsPath = await FileHelper.getParentPath();
    final workingDir = await FileHelper.getWorkAgentPath();
    final extractToPath =path.join(workingDir, "PSTools");
    final psexecPath = path.join(extractToPath, "psexec.exe");
    final workingDirectory = r'C:\Windows\System32';
    debugPrint("huangzhen:psexecPath="+psexecPath );
    final args = [
      '-accepteula',
      '-s',
      vboxmanagePath,
      ...vboxmanageArgs,
    ];

    try {
      final result = await Process.run(
        psexecPath,
        args,
        workingDirectory: workingDirectory,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('time out : psexec ${args.join(' ')}');
        },
      );
      debugPrint(
          'Process.run call with:\n  executable: $psexecPath\n  args: ${args.join(' ')}\n  workingDirectory: $workingDirectory');
      await FileLogger.log(
          'Process.run call with:\n  executable: $psexecPath\n  args: ${args.join(' ')}\n  workingDirectory: $workingDirectory');

      final success = result.exitCode == 0;
      return CommandResult(
        success: success,
        exitCode: result.exitCode,
        stdout: result.stdout.toString(),
        stderr: result.stderr.toString(),
        errorMessage: null,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: 'time out',
        errorMessage: e.toString(),
      );
    } catch (e) {
      return CommandResult(
        success: false,
        exitCode: -1,
        stdout: '',
        stderr: 'error',
        errorMessage: e.toString(),
      );
    }
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      _logger.info('[BatShRunner] : $message');
    } else {
      _logger.warning('[BatShRunner Error] : $message');
    }
  }

  String findVBoxManagePath() {
    final possiblePaths = [
      r'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe',
      r'C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe',
      // 可继续添加其他可能安装路径
    ];

    for (final p in possiblePaths) {
      if (File(p).existsSync()) {
        return p;
      }
    }
    // 如果没找到，返回命令名，依赖 PATH 环境变量
    return 'VBoxManage';
  }

}
