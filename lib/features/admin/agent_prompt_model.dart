class AgentPrompt {
  final String agentName;
  final String systemPrompt;
  final String updatedAt;

  AgentPrompt({
    required this.agentName,
    required this.systemPrompt,
    required this.updatedAt,
  });

  factory AgentPrompt.fromJson(Map<String, dynamic> json) {
    return AgentPrompt(
      agentName: json['agent_name'] ?? '',
      systemPrompt: json['system_prompt'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_name': agentName,
      'system_prompt': systemPrompt,
      'updated_at': updatedAt,
    };
  }
}
