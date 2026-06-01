enum ReceiptType {
  playback,
  adImpression,
  aiUsage,
  sourceAttribution,
  payment,
  membership,
  premiumNoAd,
}

class ReceiptView {
  const ReceiptView({
    required this.id,
    required this.type,
    required this.passportId,
    required this.contentId,
    required this.authorizationId,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final ReceiptType type;
  final String passportId;
  final String contentId;
  final String authorizationId;
  final String summary;
  final DateTime createdAt;
}
