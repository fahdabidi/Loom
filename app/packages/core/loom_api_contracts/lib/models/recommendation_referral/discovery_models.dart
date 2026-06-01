class PlatformIntent {
  const PlatformIntent({
    required this.id,
    required this.label,
    required this.description,
    required this.interestIds,
  });

  final String id;
  final String label;
  final String description;
  final List<String> interestIds;
}

class SessionIntent {
  const SessionIntent({
    required this.id,
    required this.passportId,
    required this.platformIntentId,
    required this.label,
    required this.selectedInterestIds,
    required this.disclosure,
    required this.startedAt,
  });

  final String id;
  final String passportId;
  final String platformIntentId;
  final String label;
  final List<String> selectedInterestIds;
  final SessionIntentDisclosure disclosure;
  final DateTime startedAt;
}

class SessionIntentDisclosure {
  const SessionIntentDisclosure({
    required this.title,
    required this.body,
    required this.matchedInterests,
    required this.excludedSignals,
    required this.providerLabels,
  });

  final String title;
  final String body;
  final List<String> matchedInterests;
  final List<String> excludedSignals;
  final List<String> providerLabels;
}

class ContentTile {
  const ContentTile({
    required this.contentId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.summary,
    required this.contentTypeLabel,
    required this.thumbnailRef,
    required this.createdAt,
  });

  final String contentId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String summary;
  final String contentTypeLabel;
  final String thumbnailRef;
  final DateTime createdAt;
}

class ContentScoreExplanation {
  const ContentScoreExplanation({
    required this.summary,
    required this.matchedSignals,
    required this.suppressedSignals,
    required this.trendingVelocity,
  });

  final String summary;
  final List<String> matchedSignals;
  final List<String> suppressedSignals;
  final double trendingVelocity;
}

class FeedItem {
  const FeedItem({
    required this.tile,
    required this.score,
    required this.explanation,
    required this.providerId,
    required this.providerLabel,
    required this.isExternalCandidate,
    required this.trendingLabel,
  });

  final ContentTile tile;
  final double score;
  final ContentScoreExplanation explanation;
  final String providerId;
  final String providerLabel;
  final bool isExternalCandidate;
  final String trendingLabel;
}

enum FeedbackAction { like, dislike, muteCreator, blockCreator }

class FeedbackEvent {
  const FeedbackEvent({
    required this.id,
    required this.sessionIntentId,
    required this.contentId,
    required this.action,
    required this.createdAt,
  });

  final String id;
  final String sessionIntentId;
  final String contentId;
  final FeedbackAction action;
  final DateTime createdAt;
}
