import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart';

class SettlementEngineFake implements SettlementEngineApi {
  const SettlementEngineFake(
    this._store, {
    this.latency = const Duration(milliseconds: 120),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<String> runSettlement({required String idempotencyKey}) async {
    await Future<void>.delayed(latency);
    return _store.runSettlement(idempotencyKey: idempotencyKey);
  }

  @override
  Future<CreatorPayoutStatement> getCreatorPayoutStatement({
    required String creatorId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapPayout(await _store.creatorPayoutStatement(creatorId));
  }

  @override
  Future<FanSubscriptionAllocationStatement> getFanSubscriptionAllocation({
    required String passportId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapAllocation(await _store.allocationStatement(passportId));
  }
}

CreatorPayoutStatement _mapPayout(CreatorPayoutStatementRecord record) {
  return CreatorPayoutStatement(
    id: record.id,
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    totalCents: record.totalCents,
    bySource: record.bySource.map(_mapBreakdown).toList(growable: false),
    byIntent: record.byIntent.map(_mapBreakdown).toList(growable: false),
    recentReceipts: record.recentReceipts.map(_mapReceipt).toList(),
    updatedAt: record.updatedAt,
  );
}

FanSubscriptionAllocationStatement _mapAllocation(
  FanAllocationStatementRecord record,
) {
  return FanSubscriptionAllocationStatement(
    id: record.id,
    passportId: record.passportId,
    totalCents: record.totalCents,
    allocations: record.allocations.map(_mapAllocationLine).toList(),
    updatedAt: record.updatedAt,
  );
}

RevenueBreakdown _mapBreakdown(RevenueBreakdownRecord record) {
  return RevenueBreakdown(label: record.label, amountCents: record.amountCents);
}

AllocationLine _mapAllocationLine(AllocationLineRecord record) {
  return AllocationLine(
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    amountCents: record.amountCents,
    reason: record.reason,
  );
}

ReceiptView _mapReceipt(ReceiptRecord record) {
  return ReceiptView(
    id: record.id,
    type: _receiptType(record.type),
    passportId: record.passportId,
    contentId: record.contentId,
    authorizationId: record.authorizationId,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}

ReceiptType _receiptType(String value) {
  switch (value) {
    case 'adImpression':
      return ReceiptType.adImpression;
    case 'aiUsage':
      return ReceiptType.aiUsage;
    case 'sourceAttribution':
      return ReceiptType.sourceAttribution;
    case 'payment':
      return ReceiptType.payment;
    case 'membership':
      return ReceiptType.membership;
    case 'premiumNoAd':
      return ReceiptType.premiumNoAd;
    case 'discovery':
      return ReceiptType.discovery;
    case 'referral':
      return ReceiptType.referral;
    case 'campaignEntry':
      return ReceiptType.campaignEntry;
    case 'reward':
      return ReceiptType.reward;
    case 'playback':
    default:
      return ReceiptType.playback;
  }
}
