class SystemCommand {
  final String operation;
  final String reason;

  SystemCommand({required this.operation, required this.reason});

  factory SystemCommand.fromJson(Map<String, dynamic> json) {
    return SystemCommand(
      operation: json['operation'] as String,
      reason: json['reason'] as String,
    );
  }
}
