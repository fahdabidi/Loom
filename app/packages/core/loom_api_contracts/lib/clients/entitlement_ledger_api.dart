import '../models/creator_metadata/phase2_models.dart';
import '../models/entitlement/entitlement_definition.dart';
import '../models/entitlement/entitlement_grant.dart';

abstract class EntitlementLedgerApi {
  Future<List<EntitlementDefinition>> registerMembershipTierDefinitions({
    required String channelId,
    required List<MembershipTier> tiers,
    required String idempotencyKey,
  });

  Future<List<EntitlementDefinition>> entitlementDefinitions(String channelId);

  Future<EntitlementGrant> grantEntitlement({
    required String passportId,
    required String code,
    required String sourcePaymentIntentId,
    required String idempotencyKey,
    String? creatorId,
  });

  Future<EntitlementCheckResult> checkEntitlements({
    required String passportId,
    required List<String> codes,
  });
}
