class IpData {
  final String remoteAddr;
  final String xForwardedFor;
  final String xRealIp;

  IpData({
    required this.remoteAddr,
    required this.xForwardedFor,
    required this.xRealIp,
  });

  factory IpData.fromJson(Map<String, dynamic> json) {
    return IpData(
      remoteAddr: json['RemoteAddr'] ?? '',
      xForwardedFor: json['X-Forwarded-For'] ?? '',
      xRealIp: json['X-Real-IP'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RemoteAddr': remoteAddr,
      'X-Forwarded-For': xForwardedFor,
      'X-Real-IP': xRealIp,
    };
  }

  @override
  String toString() {
    return 'IpData{remoteAddr: $remoteAddr, xForwardedFor: $xForwardedFor, xRealIp: $xRealIp}';
  }
}
