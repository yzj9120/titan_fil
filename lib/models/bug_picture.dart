class BugPicture {
  String url;
  int type;
  double progress = 0.0;

  BugPicture({
    required this.url,
    required this.type,
    required this.progress,
  });

  factory BugPicture.fromJson(Map<String, dynamic> json) {
    return BugPicture(
      url: json['url'],
      type: json['type'],
      progress: json['progress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'progress': progress,
    };
  }
}
