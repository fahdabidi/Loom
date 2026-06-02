enum ExternalSourceType { youtube, twitch, discord, blog, webpage }

enum EmbedKind { youtubeIframe, link }

class EmbedDescriptor {
  const EmbedDescriptor({
    required this.kind,
    required this.externalId,
    required this.sourceUrl,
  });

  final EmbedKind kind;
  final String externalId;
  final String sourceUrl;
}

class ExternalTargetRef {
  const ExternalTargetRef({
    required this.referenceId,
    required this.sourceType,
    required this.externalId,
  });

  final String referenceId;
  final ExternalSourceType sourceType;
  final String externalId;
}

class ExternalContentCandidate {
  const ExternalContentCandidate({
    required this.targetRef,
    required this.originalTitle,
    required this.summary,
    required this.thumbnailRef,
    required this.sourceUrl,
    required this.sourceAttribution,
    required this.rightsBasis,
    required this.searchIndexable,
    required this.aiQueryable,
    required this.embedDescriptor,
    required this.createdAt,
    this.creatorId,
    this.creatorName,
    this.accurateMatchLabel,
    this.creatorNote,
  });

  final ExternalTargetRef targetRef;
  final String originalTitle;
  final String summary;
  final String thumbnailRef;
  final String sourceUrl;
  final String sourceAttribution;
  final String rightsBasis;
  final bool searchIndexable;
  final bool aiQueryable;
  final EmbedDescriptor embedDescriptor;
  final DateTime createdAt;
  final String? creatorId;
  final String? creatorName;
  final String? accurateMatchLabel;
  final String? creatorNote;
}
