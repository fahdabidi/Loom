import '../receipt/receipt_models.dart';

enum EntitlementState { adSupported, noAdsPremium }

class AdContext {
  const AdContext({
    required this.sessionIntentId,
    required this.intentLabel,
    required this.allowedCategories,
  });

  final String sessionIntentId;
  final String intentLabel;
  final List<String> allowedCategories;
}

class PlaybackAuthorization {
  const PlaybackAuthorization({
    required this.id,
    required this.passportId,
    required this.contentId,
    required this.playbackToken,
    required this.canPlay,
    required this.adPlan,
    required this.expiresAt,
  });

  final String id;
  final String passportId;
  final String contentId;
  final String playbackToken;
  final bool canPlay;
  final AdPlan adPlan;
  final DateTime expiresAt;
}

class AdPlan {
  const AdPlan({
    required this.hasAd,
    required this.adId,
    required this.brandName,
    required this.category,
    required this.format,
    required this.disclosure,
    required this.noBehavioralTargeting,
  });

  const AdPlan.none()
    : hasAd = false,
      adId = '',
      brandName = '',
      category = '',
      format = '',
      disclosure = 'No ad selected.',
      noBehavioralTargeting = true;

  final bool hasAd;
  final String adId;
  final String brandName;
  final String category;
  final String format;
  final String disclosure;
  final bool noBehavioralTargeting;
}

class PlaybackCompletion {
  const PlaybackCompletion({
    required this.authorizationId,
    required this.receipts,
  });

  final String authorizationId;
  final List<ReceiptView> receipts;
}
