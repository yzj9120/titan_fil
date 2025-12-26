import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:titan_fil/plugins/native_app.dart';

import '../models/Steps.dart';
import '../models/steps_warp.dart';
import '../services/log_service.dart';
import '../utils/file_helper.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/message_dialog.dart';
import 'agent_Isolate.dart';
import 'base_plugin.dart';
import 'macos_pligin.dart';

class MultiPassPlugin extends BasePlugin {
  static final MultiPassPlugin _instance = MultiPassPlugin._internal();
  static final logUtils = LoggerFactory.createLogger(LoggerName.t3);

  factory MultiPassPlugin() {
    return _instance;
  }

  MultiPassPlugin._internal();

  Future<Map<String, dynamic>> runCommand(
    String command,
    List<String> args, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final isWindows = Platform.isWindows;
      final pathEnv = isWindows
          ? Platform.environment['PATH'] ?? ''
          : '/usr/local/bin:/opt/homebrew/bin:${Platform.environment['PATH'] ?? ''}';
      final process = await Process.start(
        command,
        args,
        runInShell: isWindows, // Windows 下需要使用 shell 启动
        environment: {
          'PATH': pathEnv,
        },
      );

      // 捕获输出
      final stdoutFuture =
          process.stdout.transform(SystemEncoding().decoder).join();
      final stderrFuture =
          process.stderr.transform(SystemEncoding().decoder).join();

      // 等待进程退出（含超时）
      final exitCode = await process.exitCode.timeout(timeout);

      final stdoutStr = await stdoutFuture;
      final stderrStr = await stderrFuture;
      if (exitCode == 0) {
        return {
          'status': true,
          'msg': stdoutStr.trim(),
        };
      } else {
        return {
          'status': false,
          'msg': stderrStr.trim().isNotEmpty
              ? stderrStr.trim()
              : 'Command failed with exit code $exitCode',
        };
      }
    } on TimeoutException {
      return {
        'status': false,
        'msg': 'Command timed out after ${timeout.inSeconds} seconds',
      };
    } catch (e) {
      return {
        'status': false,
        'msg': 'Failed to run command: $e',
      };
    }
  }

  Future<String?> getMultipassPathFromProcess({int timeoutSeconds = 5}) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    try {
      logBuffer.writeln('where multipass');
      // 检查是否在PATH环境变量中
      final whereProcess =
          await Process.run('where', ['multipass'], runInShell: true)
              .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
        return ProcessResult(0, 1, '', 'Timeout exceeded');
      });
      logBuffer.writeln(
          'exitCode:${whereProcess.exitCode};stdout:${whereProcess.stdout}:stderr:${whereProcess.stderr}');

      if (whereProcess.exitCode == 0) {
        return whereProcess.stdout.toString().split('\n').first.trim();
      }

      // 尝试直接调用获取版本（验证是否安装）
      final versionProcess =
          await Process.run('multipass', ['--version'], runInShell: true)
              .timeout(Duration(seconds: timeoutSeconds), onTimeout: () {
        logBuffer.writeln('multipass --version Timeout');
        return ProcessResult(0, 1, '', 'Timeout exceeded');
      });

      if (versionProcess.exitCode == 0) {
        return 'multipass'; // 表示已在PATH中
      }

      return null;
    } catch (e) {
      logBuffer.writeln('error: $e');
      return null;
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  //process = await Process.start('multipass', ['get', 'local.driver']);

  /// **检查 Multipass 是否安装
  Future<bool> isMultiPassInstalled() async {
    if (!Platform.isWindows) {
      bool status = await MacOsPlugin.checkAndInstallMultipass();
      return status;
    }

    Process? process;

    // 方法1：检查命令是否存在
    try {
      final whereResult = await Process.run('where', ['multipass'])
          .timeout(Duration(seconds: 2));
      if (whereResult.exitCode == 0) {
        return true;
      }
    } catch (e) {
      debugPrint('where command failed: $e');
    }
    // 方法2：检查版本（备用）
    try {
      process = await Process.start(
        'multipass',
        ['--version'],
      );

      // Set 5-second timeout
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('Multipass version check timed out');
        },
      );
      final versionOutput =
          (await process.stdout.transform(utf8.decoder).join()).trim();
      final errorOutput =
          (await process.stderr.transform(utf8.decoder).join()).trim();
      if (exitCode == 0) {
        return true;
      } else {
        return false;
      }
    } on TimeoutException {
      return false;
    } on ProcessException catch (e) {
      return false;
    } catch (e) {
      return false;
    } finally {
      process?.kill();
    }
  }

  /// **安装 Multipass**
  Future<void> installMultiPass({
    int timeoutSeconds = 600,
  }) async {
    final logBuffer = StringBuffer();
    logBuffer.clear();

    if (!Platform.isWindows) {
      logBuffer.writeln("MultiPass installation is only supported on Windows");
      await MacOsPlugin.installMultipassPkg();
      return;
    }

    if (await isMultiPassInstalled()) {
      logBuffer.writeln("MultiPass is already installed");
      return;
    }

    final exeName = 'multipass-1.15.0+win-win64.msi';
    final libsPath = await FileHelper.getCurrentPath();
    final installerPath = '${libsPath}\\$exeName';
    // print("installerPath===$installerPath");

    if (!File(installerPath).existsSync()) {
      logBuffer.writeln("MultiPass installer not found at: $installerPath");
      return;
    }

    try {
      logBuffer.writeln("Launching MultiPass installer with full UI...");
      // 关键点：直接运行 MSI，不添加任何静默参数
      final process = await Process.start(
          'msiexec.exe', ['/i', installerPath, '/L*V', 'multipass_install.log'],
          runInShell: true);

      // 超时控制
      final exitCode = await process.exitCode.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );

      if (exitCode == 0) {
        logBuffer.writeln("MultiPass installed successfully");
      } else if (exitCode == -1) {
        logBuffer
            .writeln("Installation timed out after $timeoutSeconds seconds");
      } else {
        logBuffer.writeln("Installation failed with error code: $exitCode");
      }
    } on TimeoutException {
      logBuffer.writeln("Installation process timed out");
    } catch (e) {
      logBuffer.writeln("Installation error: $e");
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  ///验证VM指向状态
  Future<Map<String, dynamic>> getMultiPassLocalDrive() async {
    if (!Platform.isWindows) {
      return {'status': true, 'error': null};
    }
    Process? process;
    try {
      process = await Process.start('multipass', ['get', 'local.driver']);
      // Set timeout for command execution
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('Multipass command timed out');
        },
      );

      final stdout =
          (await process.stdout.transform(utf8.decoder).join()).trim();
      final stderr =
          (await process.stderr.transform(utf8.decoder).join()).trim();

      // Handle command failures
      if (exitCode != 0) {
        return {
          'status': false,
          'error': stderr.isNotEmpty
              ? stderr
              : 'Command failed with exit code $exitCode'
        };
      }

      // Check for socket connection error
      if (stdout
          .contains("get failed: cannot connect to the multipass socket")) {
        return {'status': false, 'error': 'Cannot connect to Multipass socket'};
      }

      // Determine expected driver based on Windows edition
      final isWindowsHome = await NativeApp.isWindowsHome();
      final expectedDriver = isWindowsHome ? 'virtualbox' : 'hyperv';
      final status = stdout.toLowerCase().contains(expectedDriver);
      return {
        'status': status,
        'error': status ? null : 'Incorrect driver configured'
      };
    } on TimeoutException {
      return {'status': false, 'error': 'Operation timed out'};
    } on ProcessException catch (e) {
      return {
        'status': false,
        'error': 'Failed to execute command: ${e.message}'
      };
    } catch (e) {
      return {'status': false, 'error': 'Unexpected error: $e'};
    } finally {
      process?.kill();
    }
  }

  ///检查 Multipass 是否运行
  Future<bool> checkAndStartMultiPassService() async {
    final logBuffer = StringBuffer();
    logBuffer.clear();
    Process? listProcess;
    try {
      logBuffer.writeln('checkAndStartMultiPassService multipass list');

      listProcess = await Process.start('multipass', ['list']);
      final exitCode = await listProcess.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          listProcess?.kill(ProcessSignal.sigkill);
          throw TimeoutException('Multipass list command timed out');
        },
      );
      logBuffer.writeln(
          'exitCode:${listProcess.exitCode};stdout:${listProcess.stdout}:stderr:${listProcess.stderr}');

      if (exitCode == 0) {
        //final output = await listProcess.stdout.transform(utf8.decoder).join();
        return true;
      }
      // If not running, attempt to start
      logBuffer.writeln(' service not running - attempting to start');
      Process? startProcess;
      try {
        logBuffer.writeln('multipass start');
        startProcess = await Process.start('multipass', ['start']);
        final startExitCode = await startProcess.exitCode.timeout(
          const Duration(seconds: 30), // Longer timeout for starting service
          onTimeout: () {
            startProcess?.kill(ProcessSignal.sigkill);
            throw TimeoutException('Multipass start command timed out');
          },
        );
        logBuffer.writeln(
            'exitCode:${listProcess.exitCode};stdout:${listProcess.stdout}:stderr:${listProcess.stderr}');
        if (startExitCode == 0) {
          return true;
        } else {
          return false;
        }
      } finally {
        startProcess?.kill();
      }
    } on TimeoutException {
      logBuffer.writeln('Service check/start operation timed out');
      return false;
    } on ProcessException catch (e) {
      logBuffer.writeln('Process execution failed: ${e.message}');
      return false;
    } catch (e) {
      logBuffer.writeln('Unexpected error: $e');
      return false;
    } finally {
      listProcess?.kill();
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  ///纠正VM指向状态
  Future<bool> setMultiPassDriver() async {
    if (!Platform.isWindows) {
      return false;
    }
    final logBuffer = StringBuffer();
    logBuffer.clear();
    Process? process;
    try {
      final map = await AgentIsolate.isVmRunning();
      logBuffer.writeln('local.driver Checking isVmRunning :$map ');
      var status2 = map.state;
      if (!status2) {
        return false;
      }
      // Set the driver to VirtualBox
      process = await Process.start(
        'multipass',
        ['set', 'local.driver=virtualbox'],
        runInShell: Platform.isWindows,
      );
      logBuffer.writeln(
          'exitCode:${process.exitCode};stdout:${process.stdout}:stderr:${process.stderr}');
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('Driver setting timed out');
        },
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      final error = await process.stderr.transform(utf8.decoder).join();

      logBuffer.writeln(
          'Driver set command - ExitCode: $exitCode, Output: $output;error:$error');

      if (exitCode != 0) {
        return false;
      }
      // Verify the driver was actually set
      final driverCheck = await getMultiPassLocalDrive();
      logBuffer.writeln('driverCheck: $driverCheck');
      if (driverCheck['status'] as bool) {
        return true;
      }
      return false;
    } on TimeoutException {
      logBuffer.writeln('operation timed out');
      return false;
    } on ProcessException catch (e) {
      logBuffer.writeln('Failed to execute driver set command: ${e.message}');
      return false;
    } catch (e) {
      logBuffer.writeln('Unexpected error setting driver: $e');
      return false;
    } finally {
      process?.kill();
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  Future<List<String>> getVmNames() async {
    const Duration timeoutDuration = Duration(seconds: 5);
    //todo:hhh
    // final libsPath = await FileHelper.getParentPath();
    // final workingDir = path.join(libsPath, AppConfig.workingDir);
    // final exePath = path.join(workingDir, AppConfig.checkVmNamesProcess);
    // final ppath = path.join(workingDir, "apps");
    final workingDir = await FileHelper.getWorkAgentPath();
    final ppath = path.join(workingDir, "apps");
    final exePath = await FileHelper.getVmNamesProcessPath();
    final logBuffer = StringBuffer();
    logBuffer.clear();
    logBuffer.writeln("getVmNames path: $exePath");
    try {
      if (!await File(exePath).exists()) {
        throw Exception("Executable not found: $exePath");
      }
      final result = await Process.start(
        exePath,
        [ppath],
        runInShell: true,
      );
      logBuffer.writeln(
          'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');
      final stdout = result.stdout.transform(utf8.decoder);
      final stderr = result.stderr.transform(utf8.decoder);
      final stdoutLines = <String>[];
      final stderrLines = <String>[];
      final stdoutFuture = stdout.forEach((line) {
        stdoutLines.add(line);
      });
      final stderrFuture = stderr.forEach((line) {
        stderrLines.add(line);
      });
      final exitCode =
          await result.exitCode.timeout(timeoutDuration, onTimeout: () {
        result.kill();
        throw TimeoutException('time out (${timeoutDuration.inSeconds}秒)');
      });
      await Future.wait([stdoutFuture, stderrFuture]);
      if (exitCode == 0) {
        logBuffer.writeln('[SUCCESS] Command executed successfully');
        return stdoutLines;
      } else {
        logBuffer.writeln("[ERROR] Command failed with exit code $exitCode");
        throw Exception(
            "Command failed. Error output: ${stderrLines.join('\n')}");
      }
    } on TimeoutException catch (e) {
      logBuffer.writeln("[TIMEOUT] ${e.message}");
      return [];
    } catch (e) {
      logBuffer.writeln("[ERROR] ${e.toString()}");
      return [];
    } finally {
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  /// 停止multipassd.exe进程
  Future<void> killProcesses() async {
    final logBuffer = StringBuffer();
    logBuffer.clear();

    if (!Platform.isWindows) {
      logBuffer.writeln('killProcesses: multipassd');
      try {
        final checkProcess = await Process.run('pgrep', ['-x', 'multipassd'])
            .timeout(Duration(seconds: 5));
        logBuffer.writeln(
            'exitCode:${checkProcess.exitCode};stdout:${checkProcess.stdout}:stderr:${checkProcess.stderr}');
        if (checkProcess.exitCode != 0) {
          return;
        }
        await Process.run('pkill', ['-9', '-f', "multipassd"])
            .timeout(Duration(seconds: 5));
        await Process.run('killall', ['-9', "multipassd"])
            .timeout(Duration(seconds: 5));
        // 第三阶段：清理战场
        await Future.delayed(Duration(seconds: 1));
        final verify = await Process.run('pgrep', ['-x', "multipassd"])
            .timeout(Duration(seconds: 5));
        logBuffer
            .writeln('verify: multipassd ${verify.exitCode};${verify.stdout}');
        return;
      } on TimeoutException {
        logBuffer.writeln('timed out');
      } catch (e) {
        logBuffer.writeln('Error:$e');
        return;
      } finally {
        _log(logBuffer.toString());
        logBuffer.clear();
      }
    } else {
      const String processName = 'multipassd.exe';
      const Duration timeout = Duration(seconds: 5);
      Process? checkProcess;
      Process? killProcess;

      try {
        logBuffer.writeln('killProcesses:$processName is running...');
        // Check if process exists
        checkProcess = await Process.start(
          'tasklist',
          ['/FI', 'IMAGENAME eq $processName'],
          runInShell: true,
        );

        final checkExitCode = await checkProcess.exitCode.timeout(timeout);

        // Safely read output with proper encoding handling
        String checkOutput = '';
        try {
          checkOutput = await checkProcess.stdout
              .transform(const Utf8Decoder(allowMalformed: true))
              .join();
        } catch (e) {
          logBuffer.writeln('Error reading process output: $e');
        }

        if (checkExitCode != 0 || !checkOutput.contains(processName)) {
          logBuffer.writeln('not running - skipping termination');
          return;
        }

        logBuffer.writeln('killProcesses: Terminating process $processName...');

        // Kill the process
        killProcess = await Process.start(
          'taskkill',
          ['/F', '/IM', processName],
          runInShell: true,
        );

        final killExitCode = await killProcess.exitCode.timeout(timeout);
        logBuffer.writeln('killExitCode  $killExitCode...');
        if (killExitCode == 0) {
        } else {
          try {
            final errorOutput = await killProcess.stderr
                .transform(const Utf8Decoder(allowMalformed: true))
                .join();
            logBuffer.writeln(
                'Failed to terminate process. Error: ${errorOutput.trim()}');
          } catch (e) {
            logBuffer.writeln(
                ' Failed to terminate process (could not read error output: $e)');
          }
        }
      } on TimeoutException {
        logBuffer.writeln('timed out');
      } on ProcessException catch (e) {
        logBuffer.writeln('error: ${e}');
      } catch (e) {
        logBuffer.writeln('Unexpected error: ${e.toString()}');
      } finally {
        try {
          await checkProcess?.kill();
          await killProcess?.kill();
        } catch (e) {
          logBuffer.writeln('cleaning up process handles: $e');
        }
        logBuffer.writeln('killProcesses: Operation completed');
        _log(logBuffer.toString());
        logBuffer.clear();
        return;
      }
    }
  }

  /// 检查 MultiPass 服务是否正在运行
  Future<void> checMultipassService() async {
    const checkTimeout = Duration(seconds: 5); // 服务检查超时 - Service check timeout
    const startTimeout =
        Duration(seconds: 10); // 服务启动超时 - Service start timeout
    const serviceName = 'Multipass';
    final logBuffer = StringBuffer();
    logBuffer.clear();

    if (Platform.isWindows) {
      try {
        //检查是否运行
        Future<bool> _checkServiceRunning(Duration timeout) async {
          final process = await Process.start('net', ['query', serviceName]);
          try {
            final exitCode = await process.exitCode.timeout(timeout);
            return exitCode == 0;
          } finally {
            process.kill();
          }
        }

        //启动
        Future<bool> _startService(Duration timeout) async {
          final process = await Process.start('net', ['start', serviceName]);
          logBuffer.writeln("net start");
          logBuffer.writeln(
              'exitCode:${process.exitCode};stdout:${process.stdout}:stderr:${process.stderr}');

          try {
            final exitCode = await process.exitCode.timeout(timeout);
            return exitCode == 0;
          } finally {
            process.kill();
          }
        }

        //停止
        Future<bool> _stopService(Duration timeout) async {
          final process = await Process.start('net', ['stop', serviceName]);
          logBuffer.writeln("net stop:");
          logBuffer.writeln(
              'exitCode:${process.exitCode};stdout:${process.stdout}:stderr:${process.stderr}');

          try {
            final exitCode = await process.exitCode.timeout(timeout);
            return exitCode == 0;
          } finally {
            process.kill();
          }
        }

        // 1. 检查服务状态 - Check service status
        logBuffer.writeln('MultipassService: Checking service status');
        final isRunning = await _checkServiceRunning(checkTimeout);
        logBuffer.writeln('isRunning:$isRunning');
        if (isRunning) {
          await _stopService(checkTimeout);
        }

        // 2. 尝试启动服务 - Attempt to start service
        logBuffer.writeln(
          'Service not running. Attempting to start',
        );
        final startSuccess = await _startService(startTimeout);
        if (startSuccess) {
          return;
        }
        return;
      } on TimeoutException catch (e) {
        logBuffer.writeln('Operation timed out: ${e.message}');
        return;
      } on ProcessException catch (e) {
        logBuffer.writeln('Process error: ${e.message}');
        return;
      } catch (e) {
        logBuffer.writeln('Unexpected error: ${e.toString()}');
        return;
      } finally {
        _log(logBuffer.toString());
        logBuffer.clear();
      }
    } else {
      // macOS 新增逻辑
      logBuffer.writeln('MultipassService: Checking macOS daemon status');
      // 检查 Multipass 服务状态
      Future<bool> _checkDaemonRunning() async {
        try {
          logBuffer.writeln("launchctl:");

          final result = await Process.run(
                  'launchctl', ['list', '|', 'grep', 'multipass'],
                  runInShell: true)
              .timeout(checkTimeout);
          logBuffer.writeln(
              'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');

          return result.exitCode == 0;
        } catch (e) {
          logBuffer.writeln("launchctl e:$e");
          return false;
        }
      }

      // 启动 Multipass 服务
      Future<bool> _startDaemon() async {
        try {
          logBuffer.writeln("multipassd:verbosity");

          final result = await Process.run(
                  'multipassd', ['--verbosity', 'debug'],
                  runInShell: true)
              .timeout(startTimeout);
          logBuffer.writeln(
              'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');

          return result.exitCode == 0;
        } catch (e) {
          logBuffer.writeln('verbosity e: $e');
          return false;
        }
      }

      // 停止 Multipass 服务
      Future<bool> _stopDaemon() async {
        try {
          logBuffer.writeln("pkill:");

          final result = await Process.run('pkill', ['-9', '-f', 'multipassd'],
                  runInShell: false)
              .timeout(checkTimeout);
          logBuffer.writeln(
              'exitCode:${result.exitCode};stdout:${result.stdout}:stderr:${result.stderr}');

          return result.exitCode == 0;
        } catch (e) {
          logBuffer.writeln('pkill e: $e');
          return false;
        }
      }

      final isRunning = await _checkDaemonRunning();
      logBuffer.writeln('isRunning:$isRunning');
      if (isRunning) {
        await _stopDaemon();
      }
      await _startDaemon();
      _log(logBuffer.toString());
      logBuffer.clear();
    }
  }

  ///MultiPass 是否安装
  Future<StepsWarp> checkMultiPassInstalled(
      BuildContext ctx, int index, List<Steps> list) async {
    basicSteps = list;
    var isInstalled = await isMultiPassInstalled();
    var status = isInstalled;
    var statusText = isInstalled ? 'pcd_installed' : 'pcd_notInstalled';
    var description = "pcd_multiPassNotFind";
    var buttonText = "pcd_installNow";
    Completer<StepsWarp> completer = Completer<StepsWarp>();

    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false, des: description, txt: buttonText);
      //await Future.delayed(const Duration(seconds: 2));
      checkMultiPassInstalled(ctx, index, getBasicSteps());
    }

    var retryCount = 0;

    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);
      await installMultiPass();
      await Future.delayed(const Duration(seconds: 2));
      var isInstalled = await isMultiPassInstalled();
      statusText = isInstalled ? 'pcd_installed' : 'pcd_notInstalled';
      loading.hide();
      description = 'pcd_multiPassNotFind2';
      retryCount++;

      await updateStep(index, status, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_reinstall" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);
      if (Platform.isWindows) {
        if (isInstalled) {
          MessageDialog.show(
            context: ctx,
            config: MessageDialogConfig(
                titleKey: "gentleReminder".tr,
                messageKey: "pcd_task_restartComputer".tr,
                iconType: DialogIconType.error,
                buttonTextKey: "pcd_task_restart".tr,
                onAction: () {
                  NativeApp.restartWindows();
                },
                cancelButtonTextKey: "cancel".tr,
                onCancel: () {}),
          );
          return;
        }
      }
      if (!completer.isCompleted) {
        completer.complete(StepsWarp(
            stepCurrent: isInstalled ? index + 1 : index,
            list: getBasicSteps(),
            status: isInstalled));
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    await updateStep(index, status, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);
    if (!isInstalled) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    }
    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  ///验证VM指向状态
  Future<StepsWarp> checkLocalDrive(
      BuildContext ctx, int index, List<Steps> list) async {
    basicSteps = list;
    var map = await getMultiPassLocalDrive();
    var status = map["status"] ?? false;
    var statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
    var description = map["error"] ?? "pcd_localDriverError";
    var buttonText = "pcd_correctNow";
    Completer<StepsWarp> completer = Completer<StepsWarp>();

    ///重试
    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false, des: description, txt: buttonText);
      //await Future.delayed(const Duration(seconds: 2));
      checkLocalDrive(ctx, index, getBasicSteps());
    }

    //去设置：
    var retryCount = 0;

    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);

      // 杀死multiPassed
      await MultiPassPlugin().killProcesses();
      await Future.delayed(const Duration(seconds: 2));
      // 停止multiPass服务+ 重启multiPass服务
      await MultiPassPlugin().checMultipassService();
      await Future.delayed(const Duration(seconds: 2));
      await setMultiPassDriver();

      var map = await getMultiPassLocalDrive();
      status = map["status"] ?? false;
      final err = map["error"] ?? "";
      statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
      await Future.delayed(const Duration(seconds: 2));
      loading.hide();
      if (err
          .toString()
          .contains("get failed: cannot connect to the multipass socket")) {
        description = "pcd_localDriverError2";
      }
      retryCount++;

      await updateStep(index, status, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_correctNow" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);
      if (!completer.isCompleted) {
        completer.complete(StepsWarp(
            stepCurrent: status ? index + 1 : index,
            list: getBasicSteps(),
            status: status));
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    await updateStep(index, status, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);
    if (!status) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    }
    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  /// 检查容器的状态
  Future<StepsWarp> checkVmRunning(
      BuildContext ctx, int index, List<Steps> list) async {
    basicSteps = list;
    final map = await AgentIsolate.isVmRunning();

    var status = map.state ?? false;
    var description = map.message ?? "pcd_localDriverError2";
    var statusText = status ? 'pcd_runningNormally' : 'pcd_runningFailed';
    var buttonText = "pcd_correctNow";
    Completer<StepsWarp> completer = Completer<StepsWarp>();

    ///重试
    Future<void> retry() async {
      await updateStep(index, false, statusText,
          isActive: false, des: description, txt: buttonText);
      checkVmRunning(ctx, index, getBasicSteps());
    }

    //去设置：
    var retryCount = 0;
    Future<void> method() async {
      final loading = LoadingIndicator();
      loading.show(ctx, showText: false);
      if (!status) {
        await MultiPassPlugin().killProcesses();
        await Future.delayed(const Duration(seconds: 2));
        // 停止multiPass服务+ 重启multiPass服务
        await MultiPassPlugin().checMultipassService();
        await Future.delayed(const Duration(seconds: 2));
      }
      final map = await AgentIsolate.isVmRunning();
      var status2 = map.state ?? false;
      var statusText = status2 ? 'pcd_runningNormally' : 'pcd_runningFailed';
      await Future.delayed(const Duration(seconds: 2));
      loading.hide();
      retryCount++;

      await updateStep(index, status2, statusText,
          des: description,
          txt: retryCount <= 2 ? "pcd_correctNow" : "pcd_task_restart",
          onTap: retryCount <= 2 ? method : () => NativeApp.restartWindows(),
          onRetry: null);
      if (!completer.isCompleted) {
        completer.complete(StepsWarp(
            stepCurrent: status2 ? index + 1 : index,
            list: getBasicSteps(),
            status: status2));
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    await updateStep(index, status, statusText,
        des: description, txt: buttonText, onTap: method, onRetry: retry);
    if (!status) {
      globalService.pcdnMonitoringStatus.value = 5;
      return completer.future;
    }
    return StepsWarp(
        stepCurrent: index + 1, list: getBasicSteps(), status: true);
  }

  void _log(String message, {bool warning = false}) {
    if (warning == false) {
      debugPrint('[Multipass Plugin] : $message');
    } else {
      debugPrint('[Multipass Plugin Error] : $message');
    }
  }
}
