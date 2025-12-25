class AgentParams {
  final String exePath;
  final String agentPath;
  final String workingDir;
  final String serverUrl;
  final String key;

  AgentParams({
    required this.exePath,
    required this.agentPath,
    required this.workingDir,
    required this.serverUrl,
    required this.key,
  });

  @override
  String toString() {
    return 'AgentParams{exePath: $exePath, agentPath: $agentPath, workingDir: $workingDir, serverUrl: $serverUrl, key: $key}';
  }
}
