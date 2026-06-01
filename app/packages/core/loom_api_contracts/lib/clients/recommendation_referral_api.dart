import '../models/recommendation_referral/discovery_models.dart';
import '../models/recommendation_referral/referral_models.dart';
import '../models/shared/page.dart';

abstract class RecommendationReferralApi {
  Future<List<PlatformIntent>> getStartupTiles({required String passportId});

  Future<SessionIntent> createSessionIntent({
    required String passportId,
    required String platformIntentId,
    required String idempotencyKey,
  });

  Future<SessionIntent> switchSessionIntent({
    required String sessionIntentId,
    required String platformIntentId,
    required String idempotencyKey,
  });

  Future<Page<FeedItem>> getFeed({
    required String sessionIntentId,
    String? cursor,
    int pageSize = 5,
  });

  Future<FeedbackEvent> submitFeedback({
    required String sessionIntentId,
    required String contentId,
    required FeedbackAction action,
    required String idempotencyKey,
  });

  Future<RecommendationManifest> publishRecommendationManifest({
    required String sourceCreatorId,
    required String destinationCreatorId,
    required String contentId,
    required String note,
    required String idempotencyKey,
  });

  Future<ReferralTerms> publishReferralTerms({
    required String sourceCreatorId,
    required String destinationCreatorId,
    required int windowDays,
    required int capCents,
    required int rewardCents,
    required String idempotencyKey,
  });

  Future<DiscoveryReceipt> recordDiscovery({
    required String manifestId,
    required String passportId,
    required String idempotencyKey,
  });

  Future<CreatorReferralReceipt> recordReferralConversion({
    required String discoveryReceiptId,
    required String termsId,
    required String idempotencyKey,
  });
}
