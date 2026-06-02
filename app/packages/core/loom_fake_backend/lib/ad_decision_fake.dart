import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show AdDecisionRecord, AdImpressionRecord, DemoLocalStore, SelectedAdRecord;

class AdDecisionFake implements AdDecisionApi {
  const AdDecisionFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<AdDecision> decideAds({
    required String contentId,
    required String adPosture,
    required String entitlementState,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapDecision(
      await _store.decideAds(
        contentId: contentId,
        adPosture: adPosture,
        entitlementState: entitlementState,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<AdImpressionResult> recordAdImpression({
    required String decisionId,
    required String adId,
    required bool completed,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapImpression(
      await _store.recordAdImpression(
        decisionId: decisionId,
        adId: adId,
        completed: completed,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

AdDecision _mapDecision(AdDecisionRecord record) {
  return AdDecision(
    decisionId: record.decisionId,
    contentId: record.contentId,
    ads: record.ads.map(_mapSelectedAd).toList(growable: false),
    policyVersion: record.policyVersion,
  );
}

SelectedAd _mapSelectedAd(SelectedAdRecord record) {
  return SelectedAd(
    adId: record.adId,
    brand: record.brand,
    category: record.category,
    disclosure: record.disclosure,
    selectionBasis: record.selectionBasis,
  );
}

AdImpressionResult _mapImpression(AdImpressionRecord record) {
  return AdImpressionResult(
    adId: record.adId,
    recorded: record.recorded,
    receiptId: record.receiptId,
  );
}
