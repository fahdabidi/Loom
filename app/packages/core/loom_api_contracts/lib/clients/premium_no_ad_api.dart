import '../models/launch/launch_models.dart';

abstract class PremiumNoAdApi {
  Future<PremiumNoAdStatus> getPremiumNoAdStatus({required String fanId});

  Future<PremiumNoAdViewResult> recordPremiumNoAdView({
    required String fanId,
    required String contentId,
    String? channelId,
    String? sessionIntent,
    required String idempotencyKey,
  });
}
