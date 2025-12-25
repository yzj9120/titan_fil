import 'dart:convert';

class FeedbackData {
  final List<FeedbackItem> list;
  final int total;

  FeedbackData({required this.list, required this.total});

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    var list = json['list'] as List;
    return FeedbackData(
      list: list.map((i) => FeedbackItem.fromJson(i)).toList(),
      total: json['total'],
    );
  }
}

class FeedbackItem {
  final int id;
  bool checked;
  int angle;
  final String code;
  final String username;
  final String nodeId;
  final String email;
  final String telegramId;
  final String description;
  final int feedbackType;
  final String feedback;
  final List<String> pics;
  final String log;
  final String benefitLog;
  final int platform;
  final String version;
  final int state;
  final int reward;
  final String rewardType;
  final String operator;
  final String createdAt;
  final String updatedAt;

  FeedbackItem({
    required this.id,
    required this.checked,
    required this.angle,
    required this.code,
    required this.username,
    required this.nodeId,
    required this.email,
    required this.telegramId,
    required this.description,
    required this.feedbackType,
    required this.feedback,
    required this.pics,
    required this.log,
    required this.benefitLog,
    required this.platform,
    required this.version,
    required this.state,
    required this.reward,
    required this.rewardType,
    required this.operator,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'],
      checked: json['checked'] ?? false,
      angle: json['angle'] ?? 0,
      code: json['code'] ?? '',
      username: json['username'] ?? '',
      nodeId: json['node_id'] ?? '',
      email: json['email'] ?? '',
      telegramId: json['telegram_id'] ?? '',
      description: json['description'] ?? '',
      feedbackType: json['feedback_type'],
      feedback: json['feedback'] ?? '',
      pics: List<String>.from(
          json['pics'] != null ? jsonDecode(json['pics']) : []),
      log: json['log'] ?? '',
      benefitLog: json['benefit_log'] ?? '',
      platform: json['platform'],
      version: json['version'] ?? '',
      state: json['state'],
      reward: json['reward'],
      rewardType: json['reward_type'] ?? '',
      operator: json['operator'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FeedbackItem{id: $id, checked: $checked, angle: $angle, code: $code, username: $username, nodeId: $nodeId, email: $email, telegramId: $telegramId, description: $description, feedbackType: $feedbackType, feedback: $feedback, pics: $pics, log: $log, benefitLog: $benefitLog, platform: $platform, version: $version, state: $state, reward: $reward, rewardType: $rewardType, operator: $operator, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}
