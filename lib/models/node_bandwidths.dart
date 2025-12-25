class BandwidthData {
  final String nodeId;
  final List<BandwidthRecord> list;

  BandwidthData({
    required this.nodeId,
    required this.list,
  });

  factory BandwidthData.fromJson(Map<String, dynamic> json) {
    return BandwidthData(
      nodeId: json['node_id'],
      list: (json['list'] as List)
          .map((item) => BandwidthRecord.fromJson(item))
          .toList(),
    );
  }
}

class BandwidthRecord {
  final int createdAt;
  final dynamic bandwidthDownload;
  final dynamic bandwidthUpload;

  @override
  String toString() {
    return 'BandwidthRecord{createdAt: $createdAt, bandwidthDownload: $bandwidthDownload, bandwidthUpload: $bandwidthUpload}';
  }

  BandwidthRecord({
    required this.createdAt,
    required this.bandwidthDownload,
    required this.bandwidthUpload,
  });

  factory BandwidthRecord.fromJson(Map<String, dynamic> json) {
    return BandwidthRecord(
      createdAt: json['created_at'],
      bandwidthDownload: json['bandwidth_down_load'],
      bandwidthUpload: json['bandwidth_up_load'],
    );
  }
}