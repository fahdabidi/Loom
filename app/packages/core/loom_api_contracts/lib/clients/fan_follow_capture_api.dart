import '../models/launch/launch_models.dart';

abstract class FanFollowCaptureApi {
  Future<CaptureLink> createCaptureLink({
    required String channelId,
    required String channel,
    required bool starterPackEnabled,
    DateTime? expiresAt,
    required String idempotencyKey,
  });

  Future<CaptureLandingView> resolveCaptureLink({
    required String token,
    required String passportId,
  });

  Future<ReFollowResult> recordReFollow({
    required String token,
    required String passportId,
    required String followVisibility,
    required String idempotencyKey,
  });
}
