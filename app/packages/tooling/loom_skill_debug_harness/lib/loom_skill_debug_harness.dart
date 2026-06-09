class SkillDebugScenario {
  const SkillDebugScenario({
    required this.id,
    required this.mode,
    required this.promptFixturePath,
    required this.expectedPackagePath,
  });

  final String id;
  final String mode;
  final String promptFixturePath;
  final String expectedPackagePath;
}

class SkillDebugHarnessContract {
  static const int schemaVersion = 1;
  static const List<String> supportedModes = [
    'local-demo',
    'real-backend-publish',
  ];

  const SkillDebugHarnessContract._();
}
