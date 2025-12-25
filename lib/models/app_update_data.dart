class AppUpdateData {
  final String cid;
  final String description;
  final String minVersion;
  final int size;
  final String url;
  final String version;
  final String downUrl;
  final String fileName;
  final String filePath;
  final bool isForceUpdate;
  final List<String> devices;

  AppUpdateData({
    required this.cid,
    required this.description,
    required this.minVersion,
    required this.size,
    required this.url,
    required this.version,
    required this.downUrl,
    required this.fileName,
    required this.filePath,
    required this.isForceUpdate,
    required this.devices,
  });

  factory AppUpdateData.fromJson(Map<String, dynamic> json) {
    return AppUpdateData(
      cid: json['cid'] ?? '',
      description: json['description'] ?? '',
      minVersion: json['min_version'] ?? '',
      size: json['size'] ?? 0,
      url: json['url'] ?? '',
      version: json['version'] ?? '',
      downUrl: json['download_url'] ?? '',
      fileName: json['file_name'] ?? '',
      filePath: json['file_path'] ?? '',
      isForceUpdate: json['is_force_update'] ?? false,
      devices: (json['devices'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList()
          ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cid': cid,
      'description': description,
      'min_version': minVersion,
      'size': size,
      'url': url,
      'version': version,
      'download_url': downUrl,
      'file_name': fileName,
      'file_path': filePath,
      'is_force_update': isForceUpdate,
      'devices': devices,
    };
  }
}
