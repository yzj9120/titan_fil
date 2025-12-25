class StatusResult {
  final bool state; // 操作是否成功
  final String? name; // 虚拟机状态名称
  final String message; // 详细信息或错误消息

  StatusResult({
    required this.state,
    this.name,
    required this.message,
  });

  // 从Map转换
  factory StatusResult.fromMap(Map<String, dynamic> map) {
    return StatusResult(
      state: map['state'] as bool,
      name: map['name'] as String?,
      message: map['message'] as String,
    );
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'name': name,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'StatusResult{state: $state, name: $name, message: $message}';
  }
}
