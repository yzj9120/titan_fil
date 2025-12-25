/**
 * 全局应用配置
 */
import 'dart:io';

import 'package:titan_fil/config/toml_config.dart';

class AppConfig {
  static bool get isDebug => TomlConfig.getUrl('BuildConfig.Env') == "debug";

  static const String workingDir = 'titan_fil_agent';
  static const String appTitle = 'Titan FIL';
  static String agentProcess = Platform.isMacOS ? 'agent' : "agent.exe";
  static String mainProcess =
      Platform.isMacOS ? 'titan_fil' : "titan_fil.exe";
  static String controllerProcess =
      Platform.isMacOS ? 'controller' : 'controller.exe';
  static String checkVmNamesProcess =
      Platform.isMacOS ? 'check_vm_names' : 'check_vm_names.exe';
  static const String officialWebsiteURL = "https://titannet.io";
  static const String tgURL = "https://t.me/titannet_dao";
  static const String twitterURL = "https://twitter.com/Titannet_dao";
  static const String discordURL = "https://discord.gg/titannetwork";
  static const String appDownloadURL = "https://www.titannet.io/download";

  static String cnPodoeUrl = "https://help.titanapp.info";
  static const String urlAddress = "/titan-network-zhong-wen";
  static const String cnUrl = "https://titannet.gitbook.io/titan-network-cn";
  static const String enUrl = "https://titannet.gitbook.io/titan-network-en";
  static String t4WebUrlZH =
      "$cnPodoeUrl/4-ce-jia-li-le-ce-shi-wang/zi-yuan-can-yu-zhi-nan";
  static String t4WebUrlEN = "$enUrl/galileo-testnet/participation-guide";
  static String t4WebWaitingAddress = "https://tally.so/r/3lV1xX";
  static String t4HomeHelpUrlCn =
      "$cnPodoeUrl/4-ce-jia-li-le-ce-shi-wang/titan-agent-an-zhuang-jiao-cheng/windows-xi-tong/windows-ke-shi-hua-ke-hu-duan-jiao-cheng";
  static String t4HomeHelpUrlEn =
      "$enUrl/galileo-testnet/titan-agent-installation-guide/windows/intall-titan-agent-on-windows-home";
  static String t4MajorHelpUrlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/titan-agent-an-zhuang-jiao-cheng/windows-xi-tong/windows-ke-shi-hua-ke-hu-duan-jiao-cheng";
  static String t4MajorHelpUrlEn =
      "$enUrl/galileo-testnet/titan-agent-installation-guide/windows/intall-titan-agent-on-windows-pro";
  static String walletUrlEn =
      "$enUrl/galileo-testnet/how-to-bind-your-earning-wallet";
  static String walletUrlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/ru-he-bang-ding-shou-yi-qian-bao";

  static String usdcWalletUrlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/chang-jian-wen-ti/ru-he-bang-ding-usdc-qian-bao";
  static String  usdcWalletUrlEn =
      "$enUrl/galileo-testnet/f.a.q./how-to-bind-your-usdc-wallet";

  static String t3urlCn =
      "$cnPodoeUrl$urlAddress/3-ce-ka-xi-ni-ce-shi-wang/guan-yu-ka-xi-ni-ce-shi-wang";
  static String t3urlEn = "$enUrl/cassini-testnet/about-cassini-testnet";
  static String t4urlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/guan-yu-jia-li-le-ce-shi-wang";
  static String t4urlEn = "$enUrl/galileo-testnet/about-galileo-testnet";
  static String helpCn2 =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/chang-jian-wen-ti/win-ke-hu-duan-jie-dian-yun-xing-chang-jian-wen-ti";
  static String helpEn2 =
      "https://titannet.gitbook.io/titan-network-en/galileo-testnet/f.a.q./faq-for-windows-gui-client";


  static String t4WebUrlNodeRewardsZH =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/chang-jian-wen-ti/xin-jie-dian-shang-ji-gong-le-cong-cheng-gong-yun-xing-dao-shou-yi-ti-sheng";
  static String t4WebUrlNodeRewardsEN = "$enUrl/galileo-testnet/f.a.q./how-to-increase-node-rewards";


  static String downCheckVmNames =
      "https://pcdn.titannet.io/test4/bin/check_vm_names";

  static String downAgentDarwin =
      "https://pcdn.titannet.io/test4/latest/agent-darwin.zip";

  static String downAgentDarwinArm64 =
      "https://pcdn.titannet.io/test4/latest/agent-darwin-arm64.zip";

  static String downAgentWindows =
      "https://pcdn.titannet.io/test4/latest/agent-windows.zip";

  static String downAgentDarwinMD5 =
      "https://pcdn.titannet.io/test4/latest/agent-darwin.zip.md5";

  static String downAgentDarwinArm64MD5 =
      "https://pcdn.titannet.io/test4/latest/agent-darwin-arm64.zip.md5";

  static String downAgentWindowsMD5 =
      "https://pcdn.titannet.io/test4/latest/agent-windows.zip.md5";

  static String downPSTools =
      "https://download.sysinternals.com/files/PSTools.zip";

  static void setEnUrl(String? url) {
    if (url != null && url.isNotEmpty && url != cnPodoeUrl) {
      cnPodoeUrl = url;
    }
  }
}
