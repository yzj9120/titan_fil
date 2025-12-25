import 'dart:convert';

class NodeData {
  final Node node;
  // final List<App> apps;
  // final List<Map<String, int>> onlineStatistics;

  NodeData({
    required this.node,
    // required this.apps,
    // required this.onlineStatistics,
  });

  factory NodeData.fromJson(Map<String, dynamic> json) {
    return NodeData(
      node: Node.fromJson(json['node']),
      // apps: List<App>.from(json['apps'].map((x) => App.fromJson(x))),
      // onlineStatistics: List<Map<String, int>>.from(
      //   json['onlineStatistics'].map((x) => Map<String, int>.from(x)),
      // ),
    );
  }
}

class Node {
  // final String id;
  // final String uuid;
  // final String os;
  // final String platform;
  // final String platformVersion;
  // final String arch;
  // final int bootTime;
  // final String macs;
  // final String cpuModuleName;
  // final int cpuCores;
  // final int cpuMhz;
  // final double cpuUsage;
  // final String gpu;
  // final int totalMemory;
  // final int usedMemory;
  // final int availableMemory;
  // final String memoryModel;
  // final int netIRate;
  // final int netORate;
  // final String baseboard;
  // final int totalDisk;
  // final int freeDisk;
  // final String diskModel;
  // final String lastActivityTime;
  // final String ip;
  // final String version;
  // final String channel;
  final int serviceState;
  final int state;
  // final int onlineDuration;
  // final double onlineRate;
  // final int cGroup;
  // final String cGroupOut;

  Node({
    // required this.id,
    // required this.uuid,
    // required this.os,
    // required this.platform,
    // required this.platformVersion,
    // required this.arch,
    // required this.bootTime,
    // required this.macs,
    // required this.cpuModuleName,
    // required this.cpuCores,
    // required this.cpuMhz,
    // required this.cpuUsage,
    // required this.gpu,
    // required this.totalMemory,
    // required this.usedMemory,
    // required this.availableMemory,
    // required this.memoryModel,
    // required this.netIRate,
    // required this.netORate,
    // required this.baseboard,
    // required this.totalDisk,
    // required this.freeDisk,
    // required this.diskModel,
    // required this.lastActivityTime,
    // required this.ip,
    // required this.version,
    // required this.channel,
    required this.serviceState,
    required this.state,
    // required this.onlineDuration,
    // required this.onlineRate,
    // required this.cGroup,
    // required this.cGroupOut,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      // id: json['ID'],
      // uuid: json['UUID'],
      // os: json['OS'],
      // platform: json['Platform'],
      // platformVersion: json['PlatformVersion'],
      // arch: json['Arch'],
      // bootTime: json['BootTime'],
      // macs: json['Macs'],
      // cpuModuleName: json['CPUModuleName'],
      // cpuCores: json['CPUCores'],
      // cpuMhz: json['CPUMhz'],
      // cpuUsage: json['CPUUsage'].toDouble(),
      // gpu: json['Gpu'],
      // totalMemory: json['TotalMemory'],
      // usedMemory: json['UsedMemory'],
      // availableMemory: json['AvailableMemory'],
      // memoryModel: json['MemoryModel'],
      // netIRate: json['NetIRate'],
      // netORate: json['NetORate'],
      // baseboard: json['Baseboard'],
      // totalDisk: json['TotalDisk'],
      // freeDisk: json['FreeDisk'],
      // diskModel: json['DiskModel'],
      // lastActivityTime: json['LastActivityTime'],
      // ip: json['IP'],
      // version: json['Version'],
      // channel: json['Channel'],
      serviceState: json['ServiceState'],
      state: json['State'],
      // onlineDuration: json['OnlineDuration'],
      // onlineRate: json['OnlineRate'].toDouble(),
      // cGroup: json['CGroup'],
      // cGroupOut: json['CGroupOut'],
    );
  }
}

class App {
  final String appName;
  final String md5;
  final Map<String, dynamic> metric;
  final String lastActivityTime;
  final String nodeId;

  App({
    required this.appName,
    required this.md5,
    required this.metric,
    required this.lastActivityTime,
    required this.nodeId,
  });

  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      appName: json['AppName'],
      md5: json['MD5'],
      metric: jsonDecode(json['Metric']),
      lastActivityTime: json['LastActivityTime'],
      nodeId: json['NodeID'],
    );
  }
}
