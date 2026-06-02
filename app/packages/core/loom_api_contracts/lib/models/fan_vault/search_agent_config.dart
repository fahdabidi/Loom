import '../external_content/external_content_models.dart';

enum AiSearchProvider { anthropicClaude, openAi, googleGemini, custom }

class FanSearchAgentConfig {
  const FanSearchAgentConfig({
    required this.passportId,
    required this.provider,
    required this.mcpEndpoint,
    required this.connected,
    required this.preferCreators,
    required this.externalSourcesEnabled,
    required this.updatedAt,
  });

  final String passportId;
  final AiSearchProvider provider;
  final String mcpEndpoint;
  final bool connected;
  final bool preferCreators;
  final bool externalSourcesEnabled;
  final DateTime updatedAt;
}

class ExternalSourceConnection {
  const ExternalSourceConnection({
    required this.passportId,
    required this.sourceType,
    required this.connected,
    required this.displayName,
    required this.updatedAt,
  });

  final String passportId;
  final ExternalSourceType sourceType;
  final bool connected;
  final String displayName;
  final DateTime updatedAt;
}
