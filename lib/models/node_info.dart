import 'dart:convert';

class NodeInfo {
  final String nodeId;
  final String nodeName;
  final String uuid;
  final int status;
  final int serviceStatus;
  final int createdAt;
  final int online;
  final double bandwidthDownPeak;
  final double bandwidthUpPeak;
  final double bandwidthDownLoad;
  final double bandwidthUpLoad;
  final int cpuCore;
  final double cpuUsage;
  final double memory;
  final double memoryUsage;
  final double storageSpace;
  final double storageSpaceUsage;
  final double income;
  final double todayIncome;
  final int updateAt;
  final String systemVer;
  final String appVer;
  final String new_app_ver;
  final String ip;
  final String location;
  final String address;
  final String addressEth;
  final String ipv4;
  final String ipv6;
  final String natTcp;
  final String natUdp;
  final String cpuModel;
  final int cpuFrequency;
  final String gpuModel;
  final String ramModel;
  final String storageModel;
  final double onlineRate;
  final double incomeU;
  final double todayIncomeLock;

  NodeInfo({
    required this.nodeId,
    required this.nodeName,
    required this.new_app_ver,
    required this.uuid,
    required this.status,
    required this.serviceStatus,
    required this.createdAt,
    required this.online,
    required this.bandwidthDownPeak,
    required this.bandwidthUpPeak,
    required this.bandwidthDownLoad,
    required this.bandwidthUpLoad,
    required this.cpuCore,
    required this.cpuUsage,
    required this.memory,
    required this.memoryUsage,
    required this.storageSpace,
    required this.storageSpaceUsage,
    required this.income,
    required this.todayIncome,
    required this.updateAt,
    required this.systemVer,
    required this.appVer,
    required this.ip,
    required this.location,
    required this.address,
    required this.addressEth,
    required this.ipv4,
    required this.ipv6,
    required this.natTcp,
    required this.natUdp,
    required this.cpuModel,
    required this.cpuFrequency,
    required this.gpuModel,
    required this.ramModel,
    required this.storageModel,
    required this.onlineRate,
    required this.incomeU,
    required this.todayIncomeLock,
  });

  /// 从 JSON 解析成 `NodeInfo`
  factory NodeInfo.fromJson(Map<String, dynamic> json) {
    return NodeInfo(
      nodeId: json["node_id"] ?? "",
      nodeName: json["node_name"] ?? "",
      uuid: json["uuid"] ?? "",
      status: json["status"] ?? 0,
      serviceStatus: json["service_status"] ?? 0,
      createdAt: json["created_at"] ?? 0,
      online: json["online"] ?? 0,
      bandwidthDownPeak: (json["bandwidth_down_peak"] ?? 0).toDouble(),
      bandwidthUpPeak: (json["bandwidth_up_peak"] ?? 0).toDouble(),
      bandwidthDownLoad: (json["bandwidth_down_load"] ?? 0).toDouble(),
      bandwidthUpLoad: (json["bandwidth_up_load"] ?? 0).toDouble(),
      cpuCore: json["cpu_core"] ?? 0,
      cpuUsage: (json["cpu_usage"] ?? 0).toDouble(),
      memory: (json["memory"] ?? 0).toDouble(),
      memoryUsage: (json["memory_usage"] ?? 0).toDouble(),
      storageSpace: (json["storage_space"] ?? 0).toDouble(),
      storageSpaceUsage: (json["storage_space_usage"] ?? 0).toDouble(),
      income: (json["income"] ?? 0).toDouble(),
      todayIncome: (json["today_income"] ?? 0).toDouble(),
      updateAt: json["update_at"] ?? 0,
      systemVer: json["system_ver"] ?? "",
      appVer: json["app_ver"] ?? "",
      new_app_ver: json["new_app_ver"] ?? "",
      ip: json["ip"] ?? "",
      location: json["location"] ?? "",
      address: json["address"] ?? "",
      addressEth: json["address_eth"] ?? "",
      ipv4: json["ipv4"] ?? "",
      ipv6: json["ipv6"] ?? "",
      natTcp: json["nat_tcp"] ?? "",
      natUdp: json["nat_udp"] ?? "",
      cpuModel: json["cpu_model"] ?? "",
      cpuFrequency: json["cpu_frequency"] ?? 0,
      gpuModel: json["gpu_model"] ?? "",
      ramModel: json["ram_model"] ?? "",
      storageModel: json["storage_model"] ?? "",
      onlineRate: (json["online_rate"] ?? 0).toDouble(),
      incomeU: (json["income_u"] ?? 0).toDouble(),
      todayIncomeLock: (json["today_income_lock"] ?? 0).toDouble(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      "node_id": nodeId,
      "node_name": nodeName,
      "uuid": uuid,
      "status": status,
      "service_status": serviceStatus,
      "created_at": createdAt,
      "online": online,
      "bandwidth_down_peak": bandwidthDownPeak,
      "bandwidth_up_peak": bandwidthUpPeak,
      "bandwidth_down_load": bandwidthDownLoad,
      "bandwidth_up_load": bandwidthUpLoad,
      "cpu_core": cpuCore,
      "cpu_usage": cpuUsage,
      "memory": memory,
      "memory_usage": memoryUsage,
      "storage_space": storageSpace,
      "storage_space_usage": storageSpaceUsage,
      "income": income,
      "today_income": todayIncome,
      "update_at": updateAt,
      "system_ver": systemVer,
      "app_ver": appVer,
      "ip": ip,
      "location": location,
      "address": address,
      "address_eth": addressEth,
      "ipv4": ipv4,
      "ipv6": ipv6,
      "nat_tcp": natTcp,
      "nat_udp": natUdp,
      "cpu_model": cpuModel,
      "cpu_frequency": cpuFrequency,
      "gpu_model": gpuModel,
      "ram_model": ramModel,
      "storage_model": storageModel,
      "online_rate": onlineRate,
      "income_u": incomeU,
      "today_income_lock": todayIncomeLock,
    };
  }

  /// 方便打印
  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
