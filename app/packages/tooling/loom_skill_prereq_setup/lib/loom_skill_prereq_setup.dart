class SkillPrereqToolRequirement {
  const SkillPrereqToolRequirement({
    required this.id,
    required this.requiredFor,
    required this.install,
    required this.verify,
  });

  final String id;
  final List<String> requiredFor;
  final String install;
  final String verify;
}

class SkillPrereqSetupContract {
  static const int schemaVersion = 1;
  static const List<String> supportedExecutionTargets = [
    'codex',
    'claude-code',
  ];

  const SkillPrereqSetupContract._();
}
