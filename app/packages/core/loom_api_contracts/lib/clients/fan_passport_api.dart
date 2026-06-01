import '../models/fan_passport/consent_grant.dart';
import '../models/fan_passport/fan_passport_claim.dart';
import '../models/fan_passport/follow_view.dart';
import '../models/fan_passport/persona.dart';

abstract class FanPassportApi {
  Future<FanPassportClaim> createPassport({
    required String displayName,
    required String idempotencyKey,
  });

  Future<FanPassportClaim?> getPassport(String passportId);

  Future<Persona> setPersona({
    required String passportId,
    required String label,
    required String idempotencyKey,
  });

  Future<FollowView> createFollow({
    required String passportId,
    required String creatorId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  });

  Future<FollowView> setFollowVisibility({
    required String followId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  });

  Future<FollowView?> unfollow({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  });

  Future<FollowView> blockCreator({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  });

  Future<ConsentGrant> createConsentGrant({
    required String passportId,
    required String grantType,
    required String idempotencyKey,
  });

  Future<List<FollowView>> listFollows(String passportId);
}
