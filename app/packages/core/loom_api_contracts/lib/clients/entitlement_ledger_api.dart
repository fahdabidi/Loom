import '../models/creator_metadata/phase2_models.dart';
import '../models/entitlement/entitlement_definition.dart';

abstract class EntitlementLedgerApi {
  Future<List<EntitlementDefinition>> registerMembershipTierDefinitions({
    required String channelId,
    required List<MembershipTier> tiers,
    required String idempotencyKey,
  });

  Future<List<EntitlementDefinition>> entitlementDefinitions(String channelId);
}
