/**
 * 全局应用配置
 */
import 'dart:io';

import 'package:titan_fil/config/toml_config.dart';

class AppConfig {
  static bool get isDebug => TomlConfig.getUrl('BuildConfig.Env') == "debug";

  static const String workingDir = 'titan_fil_agent';
  static const String appTitle = 'Titan FIL';
  static String agentProcess = Platform.isMacOS ? 'filagent' : "filagent.exe";
  static String mainProcess = Platform.isMacOS ? 'titan_fil' : "titan_fil.exe";
  static String controllerProcess =
      Platform.isMacOS ? 'filcontroller' : 'filcontroller.exe';
  static String checkVmNamesProcess =
      Platform.isMacOS ? 'check_vm_names' : 'check_vm_names.exe';
  static const String officialWebsiteURL = "https://titannet.io";

  static String cnPodoeUrl = "https://help.titanapp.info";
  static const String cnUrl = "https://titannet.gitbook.io/titan-network-cn";
  static const String enUrl = "https://titannet.gitbook.io/titan-network-en";

  static const String urlAddress = "/titan-network-zhong-wen";
  static String t4WebUrlZH = "$cnPodoeUrl/4-ce-jia-li-le-ce-shi-wang/zi-yuan-can-yu-zhi-nan";
  static String t4WebUrlEN = "$enUrl/galileo-testnet/participation-guide";
  static String t4WebWaitingAddress = "https://tally.so/r/3lV1xX";

  static String t4HomeHelpUrlCn =
      "https://help.titanapp.info/titan-network-zhong-wen/titan-fil/titanfil-agent-an-zhuang-jiao-cheng/windows-xi-tong/cliwindows-chang-jian-wen-ti";
  static String t4HomeHelpUrlEn =
      "https://help.titanapp.info/titan-network-en/titan-fil/titan-fil-agent-installation-guide/windows/faq-for-windows";

  static String walletUrlEn =
      "$enUrl/galileo-testnet/how-to-bind-your-earning-wallet";
  static String walletUrlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/ru-he-bang-ding-shou-yi-qian-bao";

  static String usdcWalletUrlCn =
      "$cnPodoeUrl$urlAddress/4-ce-jia-li-le-ce-shi-wang/chang-jian-wen-ti/ru-he-bang-ding-usdc-qian-bao";
  static String usdcWalletUrlEn =
      "$enUrl/galileo-testnet/f.a.q./how-to-bind-your-usdc-wallet";


  static String t4urlCn =
      "https://titannet.gitbook.io/titan-network-cn/titan-fil/titanfil-zi-yuan-can-yu-zhi-nan";
  static String t4urlEn = "https://titannet.gitbook.io/titan-network-cn/titan-network-en/titan-fil/titan-fil-agent-installation-guide";
  static String helpCn2 =
      "https://help.titanapp.info/titan-network-zhong-wen/titan-fil/titanfil-ke-shi-hua-ke-hu-duan-jie-dian-yun-xing-chang-jian-wen-ti";
  static String helpEn2 =
      "https://help.titanapp.info/titan-network-en/titan-fil/faq-for-titan-fil-gui-client";

  static String t4WebUrlNodeRewardsZH =
      "https://help.titanapp.info/titan-network-zhong-wen/titan-fil/titanfil-xin-jie-dian-shang-ji-gong-le-cong-cheng-gong-yun-xing-dao-shou-yi-ti-sheng";

  static String t4WebUrlNodeRewardsEN = "https://help.titanapp.info/titan-network-en/titan-fil/how-to-increase-titan-fil-node-rewards";

  static String downCheckVmNames =
      "https://pcdn.titannet.io/test4/bin/check_vm_names";

  static String downAgentDarwin =
      "https://pcdn.titannet.io/filpcdn/bin/filagent/filagent-darwin.zip";

  static String downAgentDarwinArm64 =
      "https://pcdn.titannet.io/filpcdn/bin/filagent/filagent-darwin-arm64.zip";

  static String downAgentWindows =
      "https://pcdn.titannet.io/filpcdn/bin/filagent/filagent-windows.zip";

  static String downAgentDarwinMD5 =
      "https://pcdn.titannet.io/filpcdn/bin/agent-darwin.zip.md5";

  static String downAgentDarwinArm64MD5 =
      "https://pcdn.titannet.io/filpcdn/bin/agent-darwin-arm64.zip.md5";

  static String downAgentWindowsMD5 =
      "https://pcdn.titannet.io/filpcdn/bin/agent-windows.zip.md5";

  static String downPSTools =
      "https://download.sysinternals.com/files/PSTools.zip";


  static String keyWebUrlZH =
      "https://help.titanapp.info/titan-network-zhong-wen/titan-fil/ru-he-huo-qu-key";
  static String keyWebUrlEN =
      "https://help.titanapp.info/titan-network-en/titan-fil/how-to-get-the-key";

}
