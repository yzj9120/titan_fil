import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

/// Native FFI 绑定类，负责调用本地动态库方法
class _Nativel2Bindings {
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  _Nativel2Bindings(DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  _Nativel2Bindings.fromLookup(
      Pointer<T> Function<T extends NativeType>(String symbolName) lookup)
      : _lookup = lookup;

  /// 释放由 `JSONCall` 分配的 C 字符串
  void freeCString(Pointer<Char> jsonStrPtr) {
    _freeCString(jsonStrPtr);
  }

  late final _freeCStringPtr =
      _lookup<NativeFunction<Void Function(Pointer<Char>)>>('FreeCString');
  late final void Function(Pointer<Char>) _freeCString =
      _freeCStringPtr.asFunction();

  /// 调用 JSON 处理的本地方法
  Pointer<Char> jsonCall(Pointer<Char> jsonStrPtr) {
    return _jsonCall(jsonStrPtr);
  }

  late final _jsonCallPtr =
      _lookup<NativeFunction<Pointer<Char> Function(Pointer<Char>)>>(
          'JSONCall');
  late final Pointer<Char> Function(Pointer<Char>) _jsonCall =
      _jsonCallPtr.asFunction();
}

/// JSON 调用的响应数据结构
class _JSONCallRsp {
  _JSONCallRsp(this.requestID, this.rsp);
  final int requestID;
  final String rsp;
}

/// JSON 调用的上下文数据结构
class _JSONCallContext {
  _JSONCallContext(this.requestID, this.args);
  final int requestID;
  final String args;
}

/// JSON 调用执行器，封装本地 FFI 调用逻辑
class _JSONCallExecutor {
  _JSONCallExecutor(this._context);
  final _JSONCallContext _context;

  _JSONCallRsp doNativeCall() {
    String result = _ffiDirectInvoke(_context.args);
    return _JSONCallRsp(_context.requestID, result);
  }

  /// 直接调用 FFI 绑定的 JSONCall 方法
  String _ffiDirectInvoke(String args) {
    final _Nativel2Bindings bindings = NativeBinder().bindings;
    final argsPtr = args.toNativeUtf8().cast<Char>();
    final Pointer<Char> resultPtr = bindings.jsonCall(argsPtr);
    final String result = resultPtr.cast<Utf8>().toDartString();

    malloc.free(argsPtr);
    bindings.freeCString(resultPtr);

    return result;
  }
}

/// 单例模式的本地库绑定类
class NativeBinder {
  static final NativeBinder _instance = NativeBinder._internal();
  late final _Nativel2Bindings bindings;
  static const String _libName = 'gol2';

  NativeBinder._internal() {
    bindings = _Nativel2Bindings(_loadDynamicLib());
  }

  factory NativeBinder() => _instance;

  DynamicLibrary _loadDynamicLib() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$_libName.dylib');
    } else if (Platform.isAndroid || Platform.isLinux) {
      return DynamicLibrary.open('lib$_libName.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('$_libName.dll');
    }
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }
}

/// 使用 Isolate 进行 JSONCall 异步调用
class IsolateCallAgent {
  static final IsolateCallAgent _instance = IsolateCallAgent._internal();

  factory IsolateCallAgent() => _instance;
  IsolateCallAgent._internal() {
    _helperIsolateSendPortFuture = _initIsolate();
  }

  int _nextJSONCallRequestId = 0;
  final Map<int, Completer<String>> _jsonCallRequests = {};
  late Future<SendPort> _helperIsolateSendPortFuture;

  Future<SendPort> _initIsolate() async {
    final Completer<SendPort> completer = Completer<SendPort>();
    final ReceivePort receivePort = ReceivePort();

    receivePort.listen((dynamic data) {
      if (data is SendPort) {
        completer.complete(data);
      } else if (data is _JSONCallRsp) {
        _jsonCallRequests.remove(data.requestID)?.complete(data.rsp);
      } else {
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      }
    });

    await Isolate.spawn((SendPort mainSendPort) {
      final ReceivePort isolateReceivePort = ReceivePort();
      isolateReceivePort.listen((dynamic data) {
        if (data is _JSONCallContext) {
          final result = _JSONCallExecutor(data).doNativeCall();
          mainSendPort.send(result);
        }
      });
      mainSendPort.send(isolateReceivePort.sendPort);
    }, receivePort.sendPort);

    return completer.future;
  }

  Future<String> isolateJsonCall(String args) async {
    final SendPort sendPort = await _helperIsolateSendPortFuture;
    final int requestId = _nextJSONCallRequestId++;
    final _JSONCallContext request = _JSONCallContext(requestId, args);
    final Completer<String> completer = Completer<String>();
    _jsonCallRequests[requestId] = completer;
    sendPort.send(request);
    return completer.future;
  }
}

/// 提供外部 JSONCall 调用接口的 FFI 服务
class FFIService {
  static final FFIService _instance = FFIService._internal();
  factory FFIService() => _instance;
  FFIService._internal();

  Future<String> jsonCall(String args) async {
    return await IsolateCallAgent().isolateJsonCall(args);
  }

  Future<String> setServiceStartupCmd(String cmd) async {
    return jsonEncode({"code": 0, "msg": "only support android"});
  }
}
