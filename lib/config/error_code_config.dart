import 'package:get/get.dart';

class ErrorCodeConfig {
  // 错误代码常量
  static const int unknown = -1;
  static const int networkError = 1000;
  static const int invalidRequest = 1001;
  static const int emptyError = 1002;
  static const int urlEmptyError = 1003;
  static const int serverError = 1004;
  static const int noSchedulerFound = 1005;
  static const int jsonCatch = 1006;
  static const int deviceNotExist = 1007;
  static const int requestCatch = 1008;
  static const int invalidSignature = 1021;
  static const int deviceAlreadyBound = 1025;
  static const int invalidCode = 1026;
  static const int codeUntracked = -999;
  static const int codeRepoPathInvalid = -998;
  static const int codeClibRequestInvalid = -997;
  static const int codeClibResponseInvalid = -996;
  static const int codeSignHashEmpty = -995;
  static const int codeOpenPathError = -994;
  static const int codePrivateKeyError = -993;
  static const int codeConfigInvalid = -992;
  static const int codeConfigStoragePathInvalid = -991;
  static const int codeConfigLocalDiskLoadError = -990;
  static const int codeConfigFilePermissionError = -989;
  static const int codeDownloadFileFailed = -988;
  static const int codeNewEdgeAPIErr = -987;
  static const int codeEdgeRestartFailed = -986;
  static const int codeEdgeNetworkErr = -985;
  static const int codeWebServerErr = -984;
  static const int codeFreeUpDiskInProgress = -983;
  static const int codeReqDiskFreeErr = -982;
  static const int codeStateFreeUpDiskErr = -981;
  static const int daemonAlreadyStart = -980;
  static const int daemonStarting = -979;
  static const int daemonStartFailed = -978;
  static const int daemonIsStopped = -977;
  static const int daemonStopFailed = -976;

  // 错误码与错误消息映射
  static const Map<int, String> errorMessages = {
    requestCatch: 'error_request_catch',
    jsonCatch: 'error_json_catch',
    daemonAlreadyStart: 'error_daemon_already_start',
    daemonStarting: 'error_daemon_starting',
    daemonStartFailed: 'error_daemon_start_failed',
    daemonIsStopped: 'error_daemon_is_stopped',
    daemonStopFailed: 'error_daemon_stop_failed',
    invalidRequest: 'error_invalid_request',
    deviceNotExist: 'error_device_not_exist',
    serverError: 'error_server_error',
    invalidSignature: 'error_invalid_signature',
    deviceAlreadyBound: 'error_device_already_bound',
    noSchedulerFound: 'error_no_scheduler_found',
    invalidCode: 'error_invalid_code',
    networkError: 'error_networkNotConnected',
    emptyError: 'error_input_empty',
    urlEmptyError: 'error_urlEmptyError',
    codeUntracked: 'error_untracked',
    codeRepoPathInvalid: 'error_repo_path_invalid',
    codeClibRequestInvalid: 'error_clib_request_invalid',
    codeClibResponseInvalid: 'error_clib_response_invalid',
    codeSignHashEmpty: 'error_sign_hash_empty',
    codeOpenPathError: 'error_open_path_error',
    codePrivateKeyError: 'error_private_key_error',
    codeConfigInvalid: 'error_config_invalid',
    codeConfigStoragePathInvalid: 'error_config_storage_path_invalid',
    codeConfigLocalDiskLoadError: 'error_config_local_disk_load_error',
    codeConfigFilePermissionError: 'error_config_file_permission_error',
    codeDownloadFileFailed: 'error_download_file_failed',
    codeNewEdgeAPIErr: 'error_new_edge_api_err',
    codeEdgeRestartFailed: 'error_edge_restart_failed',
    codeEdgeNetworkErr: 'error_edge_network_err',
    codeWebServerErr: 'error_web_server_err',
    codeFreeUpDiskInProgress: 'error_free_up_disk_in_progress',
    codeReqDiskFreeErr: 'error_req_disk_free_err',
    codeStateFreeUpDiskErr: 'error_state_free_up_disk_err',
  };

  // 获取错误消息
  static String? getMessage(int code) {
    return (errorMessages[code])?.tr ?? null;
  }
}
