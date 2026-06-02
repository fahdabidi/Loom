import '../external_content/external_content_models.dart';
import '../recommendation_referral/discovery_models.dart';

enum AiSearchItemType { creator, external }

class AiSearchRequestConfig {
  const AiSearchRequestConfig({
    required this.provider,
    required this.preferCreators,
    required this.externalSourcesEnabled,
    required this.enabledSources,
  });

  final String provider;
  final bool preferCreators;
  final bool externalSourcesEnabled;
  final List<ExternalSourceType> enabledSources;
}

class AiSearchResult {
  const AiSearchResult({
    required this.runId,
    required this.query,
    required this.neutralityLabel,
    required this.searchReceiptId,
    required this.items,
    required this.generatedAt,
  });

  final String runId;
  final String query;
  final String neutralityLabel;
  final String searchReceiptId;
  final List<AiSearchItem> items;
  final DateTime generatedAt;
}

class AiSearchItem {
  const AiSearchItem({
    required this.id,
    required this.type,
    required this.originalTitle,
    required this.summary,
    required this.thumbnailRef,
    required this.rankReason,
    required this.titleRiskSignals,
    required this.sourceAttribution,
    required this.score,
    this.creatorTile,
    this.externalTargetRef,
    this.embedDescriptor,
    this.accurateMatchLabel,
    this.creatorNote,
  });

  final String id;
  final AiSearchItemType type;
  final String originalTitle;
  final String summary;
  final String thumbnailRef;
  final String rankReason;
  final List<String> titleRiskSignals;
  final String sourceAttribution;
  final double score;
  final ContentTile? creatorTile;
  final ExternalTargetRef? externalTargetRef;
  final EmbedDescriptor? embedDescriptor;
  final String? accurateMatchLabel;
  final String? creatorNote;
}
