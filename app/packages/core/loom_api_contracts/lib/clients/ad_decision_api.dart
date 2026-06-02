import '../models/launch/launch_models.dart';

abstract class AdDecisionApi {
  Future<AdDecision> decideAds({
    required String contentId,
    required String adPosture,
    required String entitlementState,
    required String idempotencyKey,
  });

  Future<AdImpressionResult> recordAdImpression({
    required String decisionId,
    required String adId,
    required bool completed,
    required String idempotencyKey,
  });
}
