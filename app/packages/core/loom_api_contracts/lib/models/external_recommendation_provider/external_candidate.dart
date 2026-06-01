class ExternalRecommendationCandidate {
  const ExternalRecommendationCandidate({
    required this.providerId,
    required this.providerLabel,
    required this.contentId,
    required this.interestIds,
    required this.score,
    required this.reason,
  });

  final String providerId;
  final String providerLabel;
  final String contentId;
  final List<String> interestIds;
  final double score;
  final String reason;
}
