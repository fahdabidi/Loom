import '../models/playback/playback_models.dart';

abstract class PlaybackAuthorizationApi {
  Future<PlaybackAuthorization> authorize({
    required String passportId,
    required String contentId,
    required AdContext adContext,
    required EntitlementState entitlementState,
    required String idempotencyKey,
  });

  Future<PlaybackCompletion> complete({
    required String authorizationId,
    required String idempotencyKey,
  });
}
