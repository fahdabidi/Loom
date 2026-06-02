import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show AdInventoryRecord, DemoLocalStore, PlaybackTokenRecord, ReceiptRecord;

class PlaybackAuthorizationFake implements PlaybackAuthorizationApi {
  const PlaybackAuthorizationFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<PlaybackAuthorization> authorize({
    required String passportId,
    required String contentId,
    required AdContext adContext,
    required EntitlementState entitlementState,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final content = await _store.contentById(contentId);
    if (content == null) {
      throw ApiError(
        code: 'content_not_found',
        message: 'No content exists for contentId=$contentId',
      );
    }
    final policy = await _store.creatorAdPolicy(content.creatorId);
    final ads = entitlementState == EntitlementState.noAdsPremium
        ? const <AdInventoryRecord>[]
        : await _store.adInventory(
            allowedCategories:
                policy?.allowedCategories ?? adContext.allowedCategories,
            blockedCategories: policy?.blockedCategories ?? const [],
            surface: 'watch',
          );
    final ad = ads.isEmpty ? null : ads.first;
    final adPlan = ad == null
        ? const AdPlan.none()
        : AdPlan(
            hasAd: true,
            adId: ad.id,
            brandName: ad.brandName,
            category: ad.category,
            format: ad.format,
            disclosure:
                'Contextual ad selected from creator policy and session intent; no behavioral targeting.',
            noBehavioralTargeting: true,
          );
    final token = await _store.createPlaybackToken(
      passportId: passportId,
      contentId: contentId,
      adPlan: _adPlanToJson(adPlan),
      idempotencyKey: idempotencyKey,
    );
    return _mapAuthorization(token);
  }

  @override
  Future<PlaybackCompletion> complete({
    required String authorizationId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final receipts = await _store.completePlayback(
      authorizationId: authorizationId,
      idempotencyKey: idempotencyKey,
    );
    return PlaybackCompletion(
      authorizationId: authorizationId,
      receipts: receipts.map(_mapReceipt).toList(growable: false),
    );
  }
}

PlaybackAuthorization _mapAuthorization(PlaybackTokenRecord record) {
  return PlaybackAuthorization(
    id: record.id,
    passportId: record.passportId,
    contentId: record.contentId,
    playbackToken: record.token,
    canPlay: true,
    adPlan: _adPlanFromJson(record.adPlan),
    expiresAt: record.expiresAt,
  );
}

Map<String, Object?> _adPlanToJson(AdPlan plan) {
  return {
    'hasAd': plan.hasAd,
    'adId': plan.adId,
    'brandName': plan.brandName,
    'category': plan.category,
    'format': plan.format,
    'disclosure': plan.disclosure,
    'noBehavioralTargeting': plan.noBehavioralTargeting,
  };
}

AdPlan _adPlanFromJson(Map<String, Object?> json) {
  if (json['hasAd'] != true) {
    return const AdPlan.none();
  }
  return AdPlan(
    hasAd: true,
    adId: json['adId']! as String,
    brandName: json['brandName']! as String,
    category: json['category']! as String,
    format: json['format']! as String,
    disclosure: json['disclosure']! as String,
    noBehavioralTargeting: json['noBehavioralTargeting']! as bool,
  );
}

ReceiptView _mapReceipt(ReceiptRecord record) {
  final type = switch (record.type) {
    'adImpression' => ReceiptType.adImpression,
    'aiUsage' => ReceiptType.aiUsage,
    'sourceAttribution' => ReceiptType.sourceAttribution,
    'payment' => ReceiptType.payment,
    'membership' => ReceiptType.membership,
    'premiumNoAd' => ReceiptType.premiumNoAd,
    'extensionHype' => ReceiptType.extensionHype,
    'discovery' => ReceiptType.discovery,
    'referral' => ReceiptType.referral,
    'campaignEntry' => ReceiptType.campaignEntry,
    'reward' => ReceiptType.reward,
    _ => ReceiptType.playback,
  };
  return ReceiptView(
    id: record.id,
    type: type,
    passportId: record.passportId,
    contentId: record.contentId,
    authorizationId: record.authorizationId,
    summary: record.summary,
    createdAt: record.createdAt,
  );
}
