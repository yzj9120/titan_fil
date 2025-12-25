/**
 * 具体 API 请求
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../models/app_update_data.dart';
import '../models/check_info.dart';
import '../models/feedback.dart';
import '../models/ip_data.dart';
import '../models/ip_info.dart';
import '../models/node_bandwidths.dart';
import '../models/node_data.dart';
import '../models/node_income.dart';
import '../models/node_info.dart';
import '../models/notice_bean.dart';
import '../models/url_config.dart';
import '../models/user_data.dart';
import '../services/global_service.dart';
import '../utils/network_helper.dart';
import 'api_endpoints.dart';
import 'api_response.dart';
import 'http_client.dart';

class ApiService {
  static final HttpClientUtils _httpClient = HttpClientUtils();

  static Future<String> fetchNodeDetails(String nodeId) async {
    var linkUrl =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.nodeDetails}?node_id=${Uri.encodeComponent(nodeId)}";
    return linkUrl;
  }

  static Future<UserData?> getUserInfo(String key) async {
    final String url =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.userByKey}?key=$key";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return UserData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<bool> verifyKey(String key) async {
    var parameter = "?key=$key";
    var url =
        "${ApiEndpoints.nodeInfoURLV4}${ApiEndpoints.verifyKey}$parameter";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<NodeInfo?> fetchNodeInfo(String nodeId) async {
    var parameter = "?node_id=$nodeId";
    var url = "${ApiEndpoints.nodeInfoURLV4}${ApiEndpoints.nodeInfo}$parameter";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return NodeInfo.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<NodeData?> fetchNodeInfo2(String nodeId) async {
    var parameter = "?node_id=$nodeId";
    var url =
        "${ApiEndpoints.agentServerV4}${ApiEndpoints.nodeInfo2}$parameter";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return NodeData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<NodeIncomeData?> fetchNodeIncomes(
      String nodeId, int day) async {
    var parameter = "?node_id=$nodeId&day=$day";
    var url =
        "${ApiEndpoints.nodeInfoURLV4}${ApiEndpoints.nodeIncomes}$parameter";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return NodeIncomeData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<BandwidthData?> nodeBandwidths(
      String nodeId, String day) async {
    var parameter = "?node_id=$nodeId&date=$day";
    var url =
        "${ApiEndpoints.nodeInfoURLV4}${ApiEndpoints.nodeBandwidths}$parameter";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return BandwidthData.fromJson(response.data);
    } else {
      return null;
    }
  }



  static Future<NoticeBean?> notice() async {
    var url = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.notices}";
    final localeController = Get.find<GlobalService>().localeController;
    Map<String, String> headers = {
      'Lang': localeController.locale() == 1 ? "cn" : "en"
    };

    ApiResponse response =
        await _httpClient.request(url, method: "GET", headers: headers);

    if (response.code == 200) {
      return NoticeBean.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<ApiResponse> nodeRevenue(map) async {
    // 编码私钥并构造URL
    final String url =
        "${ApiEndpoints.webServerURLV3}${ApiEndpoints.nodeRevenue}";

    ApiResponse response =
        await _httpClient.request(url, method: 'POST', headers: {}, data: map);
    return response;
  }

  static Future<CheckInfo?> checkActivity({int maxRetries = 3}) async {
    int attempt = 0;
    final Duration initialDelay = Duration(seconds: 2);
    while (attempt < maxRetries) {
      try {
        final userIp = await NetworkHelper.getUserIP(forceRefresh: true);
        final String url =
            "${ApiEndpoints.webServerURLV4}${ApiEndpoints.checkActivity}?ip=$userIp";
        debugPrint("checkActivity attempt ${attempt + 1}: $url");
        ApiResponse response = await _httpClient.request(
          url,
          method: 'GET',
          headers: {},
        );
        debugPrint("check_activity attempt ${attempt + 1}: $response");
        if (response.code == 200) {
          return CheckInfo.fromJson(response.data);
        }
      } catch (e) {
        debugPrint("checkActivity attempt ${attempt + 1} failed: $e");
        if (attempt == maxRetries - 1) {
          rethrow;
        }
      }
      if (attempt < maxRetries - 1) {
        final delay = initialDelay * (attempt + 1);
        debugPrint("Retrying in ${delay.inSeconds} seconds...");
        await Future.delayed(delay);
      }
      attempt++;
    }
    return null;
  }

  static Future<Map<String, IpInfo>?> getLocation() async {
    try {
      final userIp = await NetworkHelper.getUserIP();
      debugPrint("userIp:$userIp");

      final String urlZh =
          "${ApiEndpoints.ipResolutionUrl}${ApiEndpoints.location}?ip=$userIp&lang=cn";
      final String urlEn =
          "${ApiEndpoints.ipResolutionUrl}${ApiEndpoints.location}?ip=$userIp&lang=en";

      final responses = await Future.wait([
        _httpClient.request(urlZh, method: 'GET', headers: {}),
        _httpClient.request(urlEn, method: 'GET', headers: {}),
      ]);
      final zhData = IpInfo.fromJson(responses[0].data);
      final enData = IpInfo.fromJson(responses[1].data);
      return {"cn": zhData, "en": enData};
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }

  static Future<AppUpdateData?> checkVersion() async {
    var parameter = "?platform=${Platform.isMacOS ? "mac" : "windows"}";
    var url =
        "${ApiEndpoints.webServerURLV3}${ApiEndpoints.checkVersion}$parameter";
    ApiResponse response =
        await _httpClient.request(url, method: "GET", isLangCode: false);

    if (response.code == 200) {
      return AppUpdateData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadImage(File filePath,
      {Function? onProgress}) async {
    try {
      var url = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.upload}";
      var response =
          await _httpClient.uploadImage(filePath, url, onProgress: (progress) {
        onProgress?.call(progress);
      });
      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<ApiResponse> report(
      Map<String, dynamic> map, String lang) async {
    var url = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.report}";
    final headers = {'Lang': lang};
    ApiResponse response = await _httpClient.request(url,
        method: "POST", data: jsonEncode(map), headers: headers);
    return response;
  }

  static Future<FeedbackData?> bugsList(String code) async {
    var url =
        "${ApiEndpoints.webServerURLV3}${ApiEndpoints.bugs}?page=1&size=10000&code=$code";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return FeedbackData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<ApiResponse> accountExists(account) async {
    final String url =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.accountExists}?account=$account";
    ApiResponse response =
        await _httpClient.request(url, method: 'GET', headers: {});
    return response;
  }

  ///注册的验证码 :0 登录的验证码:1
  static Future<ApiResponse> emailVerifyCode(email, int type) async {
    final String url =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.emailVerifyCode}";
    var map = {
      'email': email,
      'type': type,
    };
    ApiResponse response =
        await _httpClient.request(url, method: 'POST', headers: {}, data: map);
    return response;
  }

  static Future<ApiResponse> accountLogin(account, verifyCode) async {
    final String url =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.accountLogin}";
    var map = {
      'account': account,
      'verify_code': verifyCode,
    };
    ApiResponse response =
        await _httpClient.request(url, method: 'POST', headers: {}, data: map);
    return response;
  }

  static Future<ApiResponse> register(account, emailCode) async {
    final String url = "${ApiEndpoints.webServerURLV4}${ApiEndpoints.register}";
    var map = {
      'account': account,
      'verify_code': emailCode,
    };
    ApiResponse response =
        await _httpClient.request(url, method: 'POST', headers: {}, data: map);
    return response;
  }

  static Future<ApiResponse> queryT3Key(account) async {
    final String url =
        "${ApiEndpoints.storageURL}${ApiEndpoints.queryCode}?username=$account";
    ApiResponse response = await _httpClient.request(url, method: 'GET');
    return response;
  }

  static Future<ApiResponse> registerT3(account) async {
    final String url = "${ApiEndpoints.storageURL}${ApiEndpoints.registerT3}";
    var map = {'username': account};
    ApiResponse response =
        await _httpClient.request(url, method: 'POST', headers: {}, data: map);
    return response;
  }

  static Future<ApiResponse> queryT3Code(code) async {
    final String url =
        "${ApiEndpoints.webServerURLV3}${ApiEndpoints.queryT3Code}?code=$code";
    ApiResponse response =
        await _httpClient.request(url, method: 'GET', headers: {});
    return response;
  }

  static Future<ApiResponse> binding(hash, nodeId, sign, areaId) async {
    final String url = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.binding}";
    var map = {
      'hash': hash,
      'node_id': nodeId,
      'signature': sign,
      'area_id': areaId,
    };
    ApiResponse response = await _httpClient.request(url,
        method: 'POST', headers: {}, data: jsonEncode(map));
    return response;
  }

  static Future<ApiResponse> uploadLogFile(File logFile) async {
    final String url =
        "${ApiEndpoints.webServerURLV4}${ApiEndpoints.uploadLog}";
    final localeController = Get.find<GlobalService>().localeController;
    final lang = localeController.locale() == 1 ? "cn" : "en";
    ApiResponse response = await _httpClient.uploadFile(logFile, lang, url);
    return response;
  }

  static Future<urlConfig?> discord() async {
    //urlConfig
    final String url = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.discord}";
    ApiResponse response =
        await _httpClient.request(url, method: 'GET', headers: {});
    if (response.code == 200) {
      return urlConfig.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<ApiResponse> queryLocation() async {
    final String url =
        "https://api-test1.container1.titannet.io/api/v2/location?ip=114.114.114.114&lang=cn";
    ApiResponse response =
        await _httpClient.request(url, method: 'GET', headers: {});
    return response;
  }

  static Future<IpData?> fetchIps() async {
    var url = "https://gpt-server.bdnft.com/v5/getip";
    ApiResponse response = await _httpClient.request(
      url,
      method: "GET",
    );
    if (response.code == 200) {
      return IpData.fromJson(response.data);
    } else {
      return null;
    }
  }

  static Future<String?> gitbook() async {
    try {
      final requestUrl = "${ApiEndpoints.webServerURLV3}${ApiEndpoints.gitbook}";
      final response =
      await _httpClient.request(requestUrl, method: "GET", headers: null);
      if (response.code == 200 && response.data != null) {
        return response.data["url"] as String?;
      }
    } catch (e, stack) {
      // 这里可以打日志，方便排查
      debugPrint("gitbook request error: $e\n$stack");
    }
    return null;
  }

}
