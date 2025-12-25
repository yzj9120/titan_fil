import '../config/toml_config.dart';

/**
 * API 地址配置
 */

class ApiEndpoints {
  // 检测是否符合4测
  static String checkT4BaseUrl = "https://test4.titannet.io";

  //IP解析
  static String ipResolutionUrl = "https://api-test1.container1.titannet.io";

  static const String userByKey = '/api/network/user_by_key';
  static const String nodeDetails = '/nodeDetails';
  static const String nodeInfo = '/api/network/node_info';

  static const String nodeInfo2 = '/api/nodeinfo';

  //获取节点收益
  static const String nodeIncomes = '/api/network/node_incomes';

  //获取节点网络情况
  static const String nodeBandwidths = '/api/network/node_bandwidths';

  //验证key
  static const String verifyKey = '/api/network/user_by_key';

  // 监测更新
  static const String updates = '/api/network/client_updates';

  // 通知
  static const String notices = '/api/v1/user/ads/notices?platform=1';

  // t3收益
  static const String nodeRevenue = '/api/v2/device';
  static const String checkActivity = '/api/network/check_activity';
  static const String location = '/api/v2/location';
  static const String upload = '/api/v1/user/upload';
  static const String report = '/api/v1/user/bugs/report';
  static const String bugs = '/api/v1/user/bugs/list';

  static const String accountExists = '/api/network/account_exists';
  static const String emailVerifyCode = '/api/network/email_verify_code';
  static const String accountLogin = '/api/network/account_login';
  static const String register = '/api/network/register';

  //
  static const String queryCode = '/api/v1/user/code';
  static const String registerT3 = '/api/v1/storage/register_with_test4';
  static const String discord = '/api/v1/url/discord';

  //桌面监测更新
  static const String checkVersion = '/api/v2/app_version';
  static const String queryT3Code = '/api/v2/device/query_code';
  static const String binding = '/api/v2/device/binding';
  static const String uploadLog = '/api/network/upload_log';
  static const String gitbook = '/api/v1/url/gitbook';

  static String get webServerURLV4 =>
      TomlConfig.getUrl('Network.WebServerURLT4');

  static String get agentServerV4 =>
      TomlConfig.getUrl('Network.AgentServerURLT4');

  static String get nodeInfoURLV4 => TomlConfig.getUrl('Network.NodeInfoURLT4');

  static String get webServerURLV3 => TomlConfig.getUrl('Network.WebServerURL');

  static String get nodeInfoURLV3 => TomlConfig.getUrl('Network.NodeInfoURL');

  static String get locatorURL => TomlConfig.getUrl('Network.LocatorURL');

  static String get storageURL => TomlConfig.getUrl('Network.StorageURL');

  static String get bindServerURLV4 => TomlConfig.getUrl('Network.BindServerURLV4');
}
