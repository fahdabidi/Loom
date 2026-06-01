import '../models/settlement/settlement_models.dart';

abstract class SettlementEngineApi {
  Future<String> runSettlement({required String idempotencyKey});

  Future<CreatorPayoutStatement> getCreatorPayoutStatement({
    required String creatorId,
  });

  Future<FanSubscriptionAllocationStatement> getFanSubscriptionAllocation({
    required String passportId,
  });
}
