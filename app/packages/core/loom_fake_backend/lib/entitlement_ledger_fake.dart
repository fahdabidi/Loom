import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    hide EntitlementDefinition, MembershipTier;

class EntitlementLedgerFake implements EntitlementLedgerApi {
  const EntitlementLedgerFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<EntitlementDefinition>> registerMembershipTierDefinitions({
    required String channelId,
    required List<MembershipTier> tiers,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final records = await _store.registerEntitlements(
      channelId: channelId,
      tiers: tiers
          .map(
            (tier) => MembershipTierRecord(
              id: tier.id,
              channelId: tier.channelId,
              name: tier.name,
              monthlyPriceCents: tier.monthlyPriceCents,
              benefits: tier.benefits,
              entitlementCode: tier.entitlementCode,
              createdAt: tier.createdAt,
            ),
          )
          .toList(growable: false),
      idempotencyKey: idempotencyKey,
    );
    return records.map(_mapEntitlement).toList(growable: false);
  }

  @override
  Future<List<EntitlementDefinition>> entitlementDefinitions(
    String channelId,
  ) async {
    await Future<void>.delayed(latency);
    final records = await _store.entitlementDefinitions(channelId);
    return records.map(_mapEntitlement).toList(growable: false);
  }
}

EntitlementDefinition _mapEntitlement(EntitlementDefinitionRecord record) {
  return EntitlementDefinition(
    id: record.id,
    channelId: record.channelId,
    tierId: record.tierId,
    code: record.code,
    createdAt: record.createdAt,
  );
}
