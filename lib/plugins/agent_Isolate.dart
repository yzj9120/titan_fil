/**
 * Titan Agent 启动 & 监测
 */
import 'package:path/path.dart' as path;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../constants/constants.dart';
import '../models/status_result.dart';
import '../network/api_endpoints.dart';
import '../utils/FileLogger.dart';
import '../utils/download_agent.dart';
import '../utils/file_helper.dart';
import '../utils/preferences_helper.dart';

class AgentIsolate {
  static const vmName = "ubuntu-niulink";
  static const Duration commandTimeout = Duration(seconds: 15);
  static const Duration vmOperationTimeout = Duration(minutes: 2);
  static const List<String> processesList = ['agent.exe', 'controller.exe'];

  /// 检查multipass list 如果不存在

  static Future<StatusResult> isVmRunning() async {
    return await compute((_) => _checkVmStatus(), null);
  }

  static Future<StatusResult> forceStopVm(String name) async {
    return await compute((_) => _forceStopVm(name), null);
  }

  static Future<void> runAgent() async {
    final logsPath = await FileHelper.getLogsPath();
    final agentProcess = await FileHelper.getAgentProcessPath();
    final workingDir = await FileHelper.getWorkAgentPath();
    final map = {
      'serverUrl': ApiEndpoints.agentServerV4,
      'agentProcess': agentProcess,
      'workingDir': workingDir,
      'logsPath': logsPath,
    };
    final receivePort = ReceivePort();
    final isolateCompleter = Completer<void>();
    FileLogger.log('runAgent map:$map', tag: 'map');
    receivePort.listen((message) {
      FileLogger.log('runAgent:$message', tag: 'message');
    });
    await Isolate.spawn(_runAgent, [map, receivePort.sendPort]);
    await isolateCompleter.future;
  }

  static Future<StatusResult> bindKey() async {
    /// todo:hhh
    // final latestSubfolder = await FileHelper.getLatestSubfolder();
    // final libsPath = await FileHelper.getParentPath();
    // final controllerPath = path.join(latestSubfolder, AppConfig.controllerProcess);
    // final workingDir = path.join(libsPath, AppConfig.workingDir);
    final workingDir = await FileHelper.getWorkAgentPath();
    final controllerPath = await FileHelper.getControllerProcessPath();
    String key = await PreferencesHelper.getString(Constants.bindKey) ?? "";
    final serverUrl = ApiEndpoints.webServerURLV4;
    return await compute(
        (_) => _bindKey(
              {
                'controllerPath': controllerPath,
                'workingDir': workingDir,
                'key': key,
                'serverUrl': serverUrl,
              },
            ),
        null);
  }

  /// 杀死agent进程
  static Future<StatusResult> killProcesses() async {
    return await compute((_) => _killProcesses(), null);
  }

  /// 杀死main 监测
  static Future<StatusResult> killMainProcesses() async {
    return await compute((_) => _killMainProcesses(), null);
  }

  static Future<void> _runAgent(List<dynamic> args) async {
    final Map<String, String> params = args[0];
    final SendPort sendPort = args[1];
    String serverUrl = params['serverUrl'] ?? '';
    String logsPath = params['logsPath'] ?? '';
    String agentPath = params['agentProcess'] ?? '';
    String fullWorkingDir = params['workingDir'] ?? '';
    Process? process;
    try {
      ///执行成功后 会一直执行
      sendPort.send('runAgent start....');
      process = await Process.start(
        agentPath,
        [
          "--working-dir=$fullWorkingDir",
          "--server-url=$serverUrl",
          "--log-path=$logsPath",
          // "--key=sM7BFQRmg1HI",
        ],
        workingDirectory: fullWorkingDir,
        // runInShell: true,
        environment: {'AGENT_IS_BOX': 'true'},
      );
      // 设置超时（例如 3 秒），超时后强制终止进程
      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          debugPrint('_runAgent Process timed out after 5 minutes');
          throw TimeoutException('Process timed out after 3 minutes');
        },
      );

      // 读取 stdout 和 stderr
      final stdoutContent = await process.stdout.transform(utf8.decoder).join();
      final stderrContent = await process.stderr.transform(utf8.decoder).join();
      sendPort.send(
          'runAgent :exitCode=$exitCode;stdout:$stdoutContent;stderr=$stderrContent');
      if (exitCode == 0) {
        final obj = StatusResult(
          state: true,
          name: params.toString(),
          message: "runAgent ${stdoutContent}",
        );
        sendPort.send('runAgent ok :${obj.toString()}');
      } else {
        final obj = StatusResult(
          state: false,
          name: params.toString(),
          message: "runAgent failed: ${stderrContent}",
        );
        sendPort.send('runAgent failed :${obj.toString()}');
      }
    } on ProcessException catch (e) {
      final obj = StatusResult(
        name: params.toString(),
        state: false,
        message: "runAgent Process exception: ${e.message}",
      );
      sendPort.send('runAgent exception :${obj.toString()}');
    } on TimeoutException catch (e) {
      final obj = StatusResult(
        name: params.toString(),
        state: false,
        message: "runAgent timed out: ${e.message}",
      );
      sendPort.send('runAgent Timeout :${obj.toString()}');
    } catch (e) {
      final obj = StatusResult(
        name: params.toString(),
        state: false,
        message: "runAgent unexpected error: $e",
      );
      sendPort.send('runAgent error :${obj.toString()}');
    } finally {
      debugPrint('_runAgent Process finally');
    }
  }

  static Future<StatusResult> _bindKey(Map<String, String> args) async {
    try {
      String workingDir = args['workingDir']!;
      String key = args['key']!;
      String serverUrl = args['serverUrl']!;
      String exePath = args['controllerPath']!;
      final arguments = [
        "bind",
        "--working-dir=$workingDir",
        "--key=$key",
        "--web-url=$serverUrl",
      ];
      debugPrint("bind arguments:$arguments");
      final process = await Process.start(exePath, arguments);
      // 收集输出
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        return StatusResult(
          state: true,
          name: args.toString(),
          message: "bind key ok ${stdout.trim()}",
        );
      } else {
        return StatusResult(
          state: false,
          name: args.toString(),
          message: "bind key fail (exit code $exitCode): ${stderr.trim()}",
        );
      }
    } on ProcessException catch (e) {
      return StatusResult(
        state: false,
        name: args.toString(),
        message: "bind key Process exception: ${e.message}",
      );
    } catch (e) {
      return StatusResult(
        state: false,
        name: args.toString(),
        message: "bind key Unexpected error: $e",
      );
    }
  }

  static Future<StatusResult> _forceStopVm(String name) async {
    Process? process;
    try {
      final isWindows = Platform.isWindows;
      final pathEnv = isWindows
          ? Platform.environment['PATH'] ?? ''
          : '/usr/local/bin:/opt/homebrew/bin:${Platform.environment['PATH'] ?? ''}';
      // 启动multipass强制停止命令（参数必须拆分为数组）
      process = await Process.start(
        'multipass',
        ['stop', '--force', '${name.trim()}'],
        runInShell: isWindows, // Windows 下需要使用 shell 启动
        environment: {
          'PATH': pathEnv,
        },
      );
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill); // 超时后强制终止进程
          throw TimeoutException('forceStopVm timed out');
        },
      );
      // 获取错误输出流
      final stderr = await process.stderr.transform(utf8.decoder).join();
      // 检查退出码和错误输出
      if (exitCode != 0 || stderr.contains('error')) {
        return StatusResult(
            state: false,
            name: null,
            message: stderr.trim().isEmpty
                ? 'forceStopVm Unknown error occurred'
                : stderr.trim());
      }
      return StatusResult(state: true, message: "forceStopVm successfully");
    } on TimeoutException {
      return StatusResult(state: false, message: "forceStopVm time out");
    } on ProcessException catch (e) {
      return StatusResult(
          state: false,
          message: "forceStopVm Command execution failed: ${e.message}");
    } finally {
      process?.kill(); // 确保进程被回收
      return StatusResult(
          state: true,
          message: "forceStopVm finally block executed, process killed");
    }
  }

  static Future<StatusResult> _killProcesses() async {
    var processes = [AppConfig.agentProcess, AppConfig.controllerProcess];
    const timeout = Duration(seconds: 10);
    final results = await Future.wait(
      processes.map(
          (process) async => await _killProcessWithTimeout(process, timeout)),
    );
    return results.first;
  }

  static Future<StatusResult> _killMainProcesses() async {
    return await _killOldProcesses(
      processName: AppConfig.mainProcess,
      timeout: Duration(seconds: 5),
    );
  }

  static Future<StatusResult> _killOldProcesses({
    required String processName,
    required Duration timeout,
  }) async {
    if (!Platform.isMacOS && !Platform.isLinux) {
      try {
        final checkResult = await Process.run(
          'tasklist',
          ['/FI', 'IMAGENAME eq $processName'],
          runInShell: true,
        );
        final lines = checkResult.stdout
            .toString()
            .split('\n')
            .where((line) => line.trim().startsWith('$processName'))
            .toList();
        return StatusResult(
            state: lines.length > 1 ? true : false, message: "${lines.length}");
      } catch (e) {
        return StatusResult(state: false, message: "err:$e");
      }
    }
    try {
      final result =
          await Process.run('ps', ['-axo', 'pid,lstart,comm']).timeout(timeout);
      final lines = result.stdout
          .toString()
          .split('\n')
          .where((line) => line.contains(processName))
          .toList();
      return StatusResult(state: false, message: "$lines");

      if (lines.isEmpty) {
        return StatusResult(state: false, message: "$processName 未运行");
      }

      final processList = <Map<String, dynamic>>[];
      for (var line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length < 6) continue;

        final pid = parts[0];
        final dateStr = parts.sublist(1, 6).join(' ');
        final startTime = DateFormat("EEE MMM dd HH:mm:ss yyyy", "en_US")
            .parseLoose(dateStr); // 兼容解析失败场景
        processList.add({'pid': pid, 'start': startTime});
      }
      if (processList.length <= 1) {
        return StatusResult(state: false, message: "无旧进程可清理");
      }
      // 按启动时间升序，保留最后一个
      processList.sort(
          (a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));

      final oldPids = processList
          .take(processList.length - 1)
          .map((p) => p['pid'] as String);

      for (var pid in oldPids) {
        await Process.run('kill', ['-9', pid]);
      }
      return StatusResult(
        state: false,
        message: "清理旧进程成功（保留最新）",
        name: processName,
      );
    } catch (e) {
      return StatusResult(state: false, message: "处理失败: $e");
    }
  }

  static Future<StatusResult> _killProcessWithTimeout(
      String process, Duration timeout) async {
    Process? killProcess; // 需要保存Process对象以便超时终止
    if (Platform.isWindows) {
      try {
        // --- 检查进程是否存在 ---
        final checkResult = await Process.run(
          'tasklist',
          ['/FI', 'IMAGENAME eq $process'],
          runInShell: true,
        ).timeout(timeout);
        if (!checkResult.stdout.toString().contains(process)) {
          return StatusResult(state: true, message: "$process not running");
        }
        // --- 杀死进程 ---
        killProcess = await Process.start(
          'taskkill',
          ['/F', '/IM', process],
          runInShell: true,
        );
        final exitCode = await killProcess.exitCode.timeout(timeout);
        // 1. 读取输出（兼容非UTF-8数据）
        final stdoutBytes = await killProcess.stdout.toList();
        final stderrBytes = await killProcess.stderr.toList();
        // 尝试UTF-8解码，失败时转为16进制表示
        String safeDecode(List<int> bytes) {
          try {
            return utf8.decode(bytes, allowMalformed: true); // 允许损坏的UTF-8
          } catch (e) {
            return 'HEX:${bytes.map((b) => b.toRadixString(16)).join(' ')}';
          }
        }

        final stderrStr = safeDecode(stderrBytes.expand((x) => x).toList());
        if (exitCode == 0) {
          return StatusResult(
              state: true,
              message: "Successfully killed:${stdout}",
              name: " $process");
        } else {
          return StatusResult(
              state: false,
              message: "Failed to kill： ${stderrStr} (exit code $exitCode)",
              name: " $process");
        }
      } on TimeoutException {
        killProcess?.kill(ProcessSignal.sigkill);
        return StatusResult(
            state: false,
            message: "Timeout killing $process - forcing termination");
      } catch (e) {
        killProcess?.kill(); // 发生错误时也尝试清理
        return StatusResult(
            state: false, message: "Error killing $process: $e");
      }
    } else {
      // === macOS 新增逻辑 ===
      try {
        // 第一阶段：常规击杀
        // 第一阶段：检查进程是否存在
        final checkProcess =
            await Process.run('pgrep', ['-x', process]).timeout(timeout);
        if (checkProcess.exitCode != 0) {
          debugPrint("ℹ️ 进程 $process 不存在，无需处理");
          return StatusResult(state: true, message: "进程 $process 不存在");
        }
// 第二阶段：核打击
        debugPrint("💣 启动核打击方案...");
        await Process.run('pkill', ['-9', '-f', process]).timeout(timeout);
        await Process.run('killall', ['-9', process]).timeout(timeout);
// 第三阶段：清理战场
        await Future.delayed(Duration(seconds: 1));
        final verify = await Process.run('pgrep', ['-x', process]);
        if (verify.exitCode == 0) {
          debugPrint("🛑 进程 ${verify.stdout} 是金刚狼，请联系系统管理员");
          return StatusResult(
              state: false, message: "🛑 进程 ${verify.stdout} 是金刚狼，请联系系统管理员");
        }
        debugPrint("✅ 目标已从内存中抹除");
        return StatusResult(state: true, message: "✅ 目标已从内存中抹除");
      } on TimeoutException {
        debugPrint("🛑 Timeout killing $process");
        return StatusResult(state: false, message: "Timeout killing $process");
      } catch (e) {
        debugPrint("🛑 Error killing $process: ${e.toString()}");
        return StatusResult(
            state: false, message: "Error killing $process: ${e.toString()}");
      }
    }
  }

  static Future<StatusResult> stopMultiPassVm() async {
    Process? process;
    try {
      process = await Process.start(
        'multipass',
        ['stop', 'ubuntu-niulink'],
        runInShell: true,
      );
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('stopVM creation timed out');
        },
      );

      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();
// sendPort?.send('stopVM output:\nstdout: $stdout\nstderr: $stderr');
      if (exitCode != 0) {
        final errorMsg = "stopVM $vmName error: ${stderr.trim()}";
        return StatusResult(state: false, message: errorMsg);
      }
      return StatusResult(state: true, message: "stopVM $vmName ok");
    } on TimeoutException {
      return StatusResult(
          state: false, message: "stopVM timed out after 5 minutes");
    } on ProcessException catch (e) {
      return StatusResult(
          state: false,
          message: "stopVM Process exception while creating VM: ${e.message}");
    } catch (e) {
      return StatusResult(
          state: false, message: "stopVM Unexpected error creating: $e");
    } finally {
      process?.kill();
    }
  }

  /// 检查虚拟机状态（静态方法，用于 compute）
  static Future<StatusResult> _checkVmStatus() async {
    Process? process;
    final stopwatch = Stopwatch()..start(); // 计时器
    void log(String msg) {
      debugPrint("[VM_CHECK] ${stopwatch.elapsedMilliseconds}ms: $msg");
    }

    try {
      if (Platform.isWindows) {
        log("开始在 Windows 环境下检查...");
        try {
          // 显式指定 json 格式，防止 Windows 默认输出表格文本导致解析困难
          const cmd = 'multipass';
          const args = ['list', '--format', 'json'];
          log("执行命令: $cmd ${args.join(' ')}");
          process = await Process.start(
            cmd,
            args,
            runInShell: true,
          );
          log("进程已启动 (PID: ${process.pid}). 等待输出流...");
          // 使用 Future.wait 机制防止死锁，并设置总体超时
          final stdoutFuture = process.stdout.transform(utf8.decoder).join();
          final stderrFuture = process.stderr.transform(utf8.decoder).join();
          final exitCodeFuture = process.exitCode;

          log("开始等待 stdout, stderr 和 exitCode...");
          await Future.wait([stdoutFuture, stderrFuture, exitCodeFuture])
              .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              log("❌ 严重超时 (60s)！强制杀死进程...");
              process?.kill(ProcessSignal.sigkill);
              throw TimeoutException('multipass list Command timed out');
            },
          );

          final stdout = await stdoutFuture;
          final stderr = await stderrFuture;
          final exitCode = await exitCodeFuture;
          //
          // log("ExitCode: $exitCode");
          // log("Stdout (Raw): >>>$stdout<<<"); // 打印原始输出，检查是否为空或有换行
          // log("Stderr (Raw): >>>$stderr<<<");

          if (exitCode != 0) {
            log("❌ ExitCode 不为 0，返回失败");
            return StatusResult(
              state: false,
              message:
                  "Failed to run multipass list. ExitCode: $exitCode. Error: ${stderr.trim()}",
              name: null,
            );
          }

          const errorStr = "cannot connect to the multipass socket";
          if (stderr.contains(errorStr) || stdout.contains(errorStr)) {
            log("❌ 检测到 Socket 连接错误");
            return StatusResult(
              state: false,
              message: "Multipass socket error: $errorStr",
              name: null,
            );
          }

          // 解析逻辑
          log("开始解析数据...");
          try {
            // 尝试解析 JSON
            final dynamic decoded = json.decode(stdout);
            // log("JSON 解析成功，数据类型: ${decoded.runtimeType}");
            // 兼容处理：如果是 Map ({"list":[]}) 取 list 字段，如果是 List 直接用
            final List vmList =
                (decoded is Map) ? decoded['list'] : (decoded as List);

            final vmInfo = vmList.firstWhere(
              (vm) => vm['name'] == vmName,
              orElse: () => null,
            );

            if (vmInfo == null) {
              log("⚠️ 在列表中未找到名为 $vmName 的虚拟机");
              return StatusResult(
                state: true,
                message: "VM not found in JSON output",
                name: null,
              );
            }

            log("✅ 找到虚拟机: ${vmInfo['name']}, 状态: ${vmInfo['state']}");
            return StatusResult(
              state: true,
              message: "VM ${vmInfo['state']}",
              name: vmInfo['state'],
            );
          } on FormatException catch (e) {
            log("⚠️ JSON 解析失败 ($e)，尝试降级为文本解析...");
            // 降级文本解析
            final lines = stdout.split('\n');
            String state = 'unknown';
            bool found = false;
            for (final line in lines) {
              if (line.trim().startsWith(vmName)) {
                // log("文本行匹配: $line");
                final cols = line.trim().split(RegExp(r'\s+'));
                if (cols.length >= 2) {
                  state = cols[1];
                  found = true;
                }
                break;
              }
            }
            if (found) {
              log("✅ 文本解析成功，状态: $state");
              return StatusResult(
                state: true,
                message: "VM $state (fallback parsing)",
                name: state,
              );
            } else {
              log("❌ 文本解析也未找到虚拟机");
              return StatusResult(
                  state: true, message: "VM not found (text)", name: null);
            }
          }
        } catch (e, stack) {
          log("❌ Windows 分支内部发生未知错误: $e\n$stack");
          rethrow;
        }
      } else {
        process = await Process.start(
          '/usr/local/bin/multipass',
          ['list', '--format', 'json'],
          runInShell: false,
        );
        // 设置超时并获取输出
        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            process?.kill(ProcessSignal.sigkill);
            throw TimeoutException('multipass list command timed out');
          },
        );

        final stdout = await process.stdout.transform(utf8.decoder).join();
        final stderr = await process.stderr.transform(utf8.decoder).join();
        // 检查命令执行错误
        if (exitCode != 0) {
          return StatusResult(
            state: false,
            message: "multipass error: ${stderr.trim()}",
            name: null,
          );
        }

        // 检查socket连接错误
        const socketErrorStr = "cannot connect to the multipass socket";
        if (stderr.contains(socketErrorStr) ||
            stdout.contains(socketErrorStr)) {
          return StatusResult(
            state: false,
            message: "multipass socket connection error",
            name: null,
          );
        }

        try {
          final jsonMap = json.decode(stdout) as Map<String, dynamic>;
          FileLogger.log(" multipass .. jsonMap: $jsonMap");
          final vmList = jsonMap['list'] as List;
          final vm = vmList.firstWhere(
            (v) => v['name'] == vmName,
            orElse: () => null,
          );

          if (vm == null) {
            return StatusResult(
              state: true,
              message: "VM '$vmName' not found",
              name: null,
            );
          }
          // 获取状态并标准化
          final state = vm['state'].toString().toLowerCase();
          return StatusResult(
            state: state.isNotEmpty,
            message: "VM state: $state",
            name: state,
          );
        } on FormatException catch (e) {
          return StatusResult(
            state: false,
            message: "Invalid JSON format: ${e.message}",
            name: null,
          );
        }
      }
    } on TimeoutException catch (e) {
      log("🚨 捕获到超时异常: $e");
      return StatusResult(state: false, message: "Timeout: $e", name: null);
    } catch (e) {
      log("🚨 捕获到顶层异常: $e");
      return StatusResult(
          state: false, message: "Unexpected error: $e", name: null);
    } finally {
      log("清理资源 (process kill)");
      process?.kill();
    }
  }

  static Future<StatusResult> _checkVmStatus2() async {
    Process? process;
    try {
      if (Platform.isWindows) {
        try {
          final process = await Process.start(
            'multipass',
            ['list'],
            runInShell: true,
          );

          try {
            // 设置完整的超时控制
            final exitCode = await process.exitCode.timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                debugPrint("================xxxxxx");
                process.kill(ProcessSignal.sigkill);
                throw TimeoutException('multipass list Command timed out');
              },
            );

            // 同时对输出设置超时
            final stdout = await process.stdout
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 3));
            final stderr = await process.stderr
                .transform(utf8.decoder)
                .join()
                .timeout(const Duration(seconds: 3));

            if (exitCode != 0) {
              return StatusResult(
                state: false,
                message: "Failed to run multipass list: ${stderr.trim()}",
                name: null,
              );
            }

            const errorStr = "cannot connect to the multipass socket";
            final hasError =
                stderr.contains(errorStr) || stdout.contains(errorStr);
            // 优先尝试JSON解析
            try {
              final jsonData = json.decode(stdout) as List;
              final vmInfo = jsonData.firstWhere(
                (vm) => vm['name'] == vmName,
                orElse: () => null,
              );

              if (vmInfo == null) {
                return StatusResult(
                  state: true,
                  message: "VM not found in JSON output",
                  name: null,
                );
              }

              return StatusResult(
                state: !hasError,
                message: "VM ${vmInfo['state']}",
                name: vmInfo['state'],
              );
            } on FormatException catch (e) {
              // JSON解析失败时使用降级方案
              final lines = stdout.split('\n');
              String state = 'unknown';

              for (final line in lines) {
                if (line.contains(vmName)) {
                  final cols = line.trim().split(RegExp(r'\s+'));
                  if (cols.length >= 3) state = cols[1];
                  break;
                }
              }

              return StatusResult(
                state: !hasError,
                message: "VM $state (fallback parsing)",
                name: state,
              );
            }
          } finally {
            process.kill(); // 确保进程终止
          }
        } on TimeoutException catch (e) {
          return StatusResult(
            state: false,
            message: e.toString(),
            name: null,
          );
        } catch (e) {
          return StatusResult(
            state: false,
            message: "Unexpected error: ${e.toString()}",
            name: null,
          );
        }
      } else {
        process = await Process.start(
          '/usr/local/bin/multipass',
          ['list', '--format', 'json'],
          runInShell: false,
        );
        // 设置超时并获取输出
        final exitCode = await process.exitCode.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            process?.kill(ProcessSignal.sigkill);
            throw TimeoutException('multipass list command timed out');
          },
        );

        final stdout = await process.stdout.transform(utf8.decoder).join();
        final stderr = await process.stderr.transform(utf8.decoder).join();
        // 检查命令执行错误
        if (exitCode != 0) {
          return StatusResult(
            state: false,
            message: "multipass error: ${stderr.trim()}",
            name: null,
          );
        }

        // 检查socket连接错误
        const socketErrorStr = "cannot connect to the multipass socket";
        if (stderr.contains(socketErrorStr) ||
            stdout.contains(socketErrorStr)) {
          return StatusResult(
            state: false,
            message: "multipass socket connection error",
            name: null,
          );
        }

        try {
          final jsonMap = json.decode(stdout) as Map<String, dynamic>;
          FileLogger.log(" multipass .. jsonMap: $jsonMap");
          final vmList = jsonMap['list'] as List;
          final vm = vmList.firstWhere(
            (v) => v['name'] == vmName,
            orElse: () => null,
          );

          if (vm == null) {
            return StatusResult(
              state: true,
              message: "VM '$vmName' not found",
              name: null,
            );
          }
// 获取状态并标准化
          final state = vm['state'].toString().toLowerCase();
          return StatusResult(
            state: state.isNotEmpty,
            message: "VM state: $state",
            name: state,
          );
        } on FormatException catch (e) {
          return StatusResult(
            state: false,
            message: "Invalid JSON format: ${e.message}",
            name: null,
          );
        }
      }
    } on TimeoutException {
      return StatusResult(
          state: false, message: "isVmRunning Command timed out", name: null);
    } catch (e) {
      return StatusResult(
          state: false,
          message: "isVmRunning Unexpected error: ${e.toString()}",
          name: null);
    } finally {
      process?.kill();
    }
  }
}
