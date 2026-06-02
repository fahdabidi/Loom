import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, PremiumNoAdEventRecord, PremiumNoAdStatusRecord;

class PremiumNoAdFake implements PremiumNoAdApi {
  const PremiumNoAdFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<PremiumNoAdStatus> getPremiumNoAdStatus({
    required String fanId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapStatus(await _store.premiumNoAdStatus(fanId));
  }

  @override
  Future<PremiumNoAdViewResult> recordPremiumNoAdView({
    required String fanId,
    required String contentId,
    String? channelId,
    String? sessionIntent,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapEvent(
      await _store.recordPremiumNoAdView(
        passportId: fanId,
        contentId: contentId,
        channelId: channelId,
        sessionIntent: sessionIntent,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

PremiumNoAdStatus _mapStatus(PremiumNoAdStatusRecord record) {
  return PremiumNoAdStatus(
    fanId: record.passportId,
    active: record.active,
    entitlementId: record.entitlementId,
    since: record.since,
    renewsAt: record.renewsAt,
  );
}

PremiumNoAdViewResult _mapEvent(PremiumNoAdEventRecord record) {
  return PremiumNoAdViewResult(
    contentId: record.contentId,
    noAdApplied: record.noAdApplied,
    receiptId: record.receiptId,
  );
}
