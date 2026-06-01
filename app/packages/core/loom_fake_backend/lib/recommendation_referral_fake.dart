import 'dart:math' as math;

import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        ContentRecord,
        CreatorRecord,
        DemoLocalStore,
        FanFeedbackRecord,
        PlatformIntentRecord,
        ReceiptRecord,
        SessionIntentRecord;

class RecommendationReferralFake implements RecommendationReferralApi {
  RecommendationReferralFake(
    this._store, {
    this.latency = const Duration(milliseconds: 120),
  });

  final DemoLocalStore _store;
  final Duration latency;
  int feedRequestCount = 0;
  final Map<String, RecommendationManifest> _manifestsByKey = {};
  final Map<String, ReferralTerms> _termsByKey = {};
  final Map<String, DiscoveryReceipt> _discoveriesByKey = {};
  final Map<String, CreatorReferralReceipt> _referralsByKey = {};
  final Map<String, RecommendationManifest> _manifestsById = {};
  final Map<String, ReferralTerms> _termsById = {};
  final Map<String, DiscoveryReceipt> _discoveriesById = {};

  @override
  Future<List<PlatformIntent>> getStartupTiles({
    required String passportId,
  }) async {
    await Future<void>.delayed(latency);
    await _store.ensureDemoPassport(passportId: passportId);
    final records = await _store.platformIntents();
    return records.map(_mapPlatformIntent).toList(growable: false);
  }

  @override
  Future<SessionIntent> createSessionIntent({
    required String passportId,
    required String platformIntentId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createSessionIntent(
      passportId: passportId,
      platformIntentId: platformIntentId,
      idempotencyKey: idempotencyKey,
    );
    return _mapSessionIntent(
      record,
      await _store.platformIntentById(record.platformIntentId),
    );
  }

  @override
  Future<SessionIntent> switchSessionIntent({
    required String sessionIntentId,
    required String platformIntentId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.switchSessionIntent(
      sessionIntentId: sessionIntentId,
      platformIntentId: platformIntentId,
      idempotencyKey: idempotencyKey,
    );
    return _mapSessionIntent(
      record,
      await _store.platformIntentById(record.platformIntentId),
    );
  }

  @override
  Future<Page<FeedItem>> getFeed({
    required String sessionIntentId,
    String? cursor,
    int pageSize = 5,
  }) async {
    feedRequestCount++;
    await Future<void>.delayed(latency);
    final session = await _store.sessionIntentById(sessionIntentId);
    if (session == null) {
      throw StateError('No session intent exists for $sessionIntentId');
    }

    final creators = {
      for (final creator in await _store.creators()) creator.id: creator,
    };
    final feedback = await _store.feedbackForPassport(session.passportId);
    final profile = await _store.interestProfile(session.passportId);
    final externalCandidates = await _store.externalCandidates(
      interestIds: session.selectedInterestIds,
      limit: 50,
    );
    final externalScores = {
      for (final candidate in externalCandidates)
        candidate.contentId: candidate,
    };
    final suppressedContentIds = feedback
        .where((item) => item.action == 'dislike')
        .map((item) => item.contentId)
        .toSet();
    final blockedCreatorIds = <String>{
      ...profile.dislikedCreatorIds,
      ...profile.mutedProviderIds,
      ...feedback
          .where(
            (item) =>
                item.action == 'mute_creator' || item.action == 'block_creator',
          )
          .map((item) => item.creatorId),
    };

    final content = await _store.publicCatalog();
    final contentById = {for (final item in content) item.id: item};
    final recommendedContentIds = <String>{};
    final ranked = <FeedItem>[];
    for (final manifest in _manifestsById.values) {
      final item = contentById[manifest.contentId];
      final creator = creators[manifest.destinationCreatorId];
      if (item == null || creator == null) {
        continue;
      }
      if (suppressedContentIds.contains(item.id) ||
          blockedCreatorIds.contains(item.creatorId)) {
        continue;
      }
      recommendedContentIds.add(item.id);
      ranked.add(
        FeedItem(
          tile: _mapTile(item, creator),
          score: 1.25,
          providerId: manifest.id,
          providerLabel: manifest.disclosureLabel,
          isExternalCandidate: false,
          trendingLabel: 'Creator pick',
          explanation: ContentScoreExplanation(
            summary:
                '${manifest.sourceCreatorName} recommended ${manifest.destinationCreatorName}; referral terms and source are visible.',
            matchedSignals: [
              'Creator recommendation: ${manifest.note}',
              'Referral disclosure: ${manifest.disclosureLabel}',
            ],
            suppressedSignals: const ['Hidden affiliate boost', 'Paid ranking'],
            trendingVelocity: item.perfVelocity,
          ),
        ),
      );
    }
    for (final item in content) {
      if (recommendedContentIds.contains(item.id)) {
        continue;
      }
      if (suppressedContentIds.contains(item.id) ||
          blockedCreatorIds.contains(item.creatorId)) {
        continue;
      }
      final creator = creators[item.creatorId];
      if (creator == null) {
        continue;
      }
      final interests = _interestIdsForCreatorId(item.creatorId);
      final matches = interests
          .where(session.selectedInterestIds.contains)
          .toList(growable: false);
      final matchScore = matches.isEmpty
          ? 0.08
          : math.min(0.35, matches.length * 0.16);
      final external = externalScores[item.id];
      final externalScore = external == null ? 0.0 : external.score * 0.15;
      final trendingBoost = session.platformIntentId == 'intent_trending'
          ? item.perfVelocity * 0.22
          : item.perfVelocity * 0.12;
      final score =
          item.perfVelocity * 0.42 + matchScore + externalScore + trendingBoost;

      ranked.add(
        FeedItem(
          tile: _mapTile(item, creator),
          score: double.parse(score.toStringAsFixed(3)),
          providerId: external?.providerId ?? 'loom_native',
          providerLabel: external?.providerLabel ?? 'Loom native graph',
          isExternalCandidate: external != null,
          trendingLabel: _rankLabel(item.perfVelocity),
          explanation: ContentScoreExplanation(
            summary:
                'Ranked from summary fit, current intent, and transparent performance signals.',
            matchedSignals: [
              if (matches.isNotEmpty)
                'Intent match: ${matches.map(_labelForInterest).join(', ')}',
              'Summary-first quality: ${item.summary.split(' ').length} words',
              'Trending velocity: ${item.perfVelocity.toStringAsFixed(2)}',
              if (external != null) external.reason,
            ],
            suppressedSignals: const ['Paid placement', 'dark-pattern urgency'],
            trendingVelocity: item.perfVelocity,
          ),
        ),
      );
    }

    ranked.sort((a, b) => b.score.compareTo(a.score));
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final page = ranked.skip(offset).take(pageSize).toList(growable: false);
    final nextOffset = offset + page.length;
    return Page(
      items: page,
      nextCursor: nextOffset < ranked.length ? '$nextOffset' : null,
    );
  }

  @override
  Future<FeedbackEvent> submitFeedback({
    required String sessionIntentId,
    required String contentId,
    required FeedbackAction action,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.recordFeedback(
      sessionIntentId: sessionIntentId,
      contentId: contentId,
      action: _feedbackActionValue(action),
      idempotencyKey: idempotencyKey,
    );
    return _mapFeedback(record);
  }

  @override
  Future<RecommendationManifest> publishRecommendationManifest({
    required String sourceCreatorId,
    required String destinationCreatorId,
    required String contentId,
    required String note,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _manifestsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final creators = {
      for (final creator in await _store.creators()) creator.id: creator,
    };
    final destination = creators[destinationCreatorId];
    if (destination == null) {
      throw StateError(
        'No destination creator exists for $destinationCreatorId',
      );
    }
    final sourceName = _creatorName(creators, sourceCreatorId);
    final manifest = RecommendationManifest(
      id: 'rec_${_slug(sourceCreatorId)}_${_slug(destinationCreatorId)}_${_manifestsByKey.length + 1}',
      sourceCreatorId: sourceCreatorId,
      sourceCreatorName: sourceName,
      destinationCreatorId: destinationCreatorId,
      destinationCreatorName: destination.displayName,
      contentId: contentId,
      title: '${destination.displayName} creator pick',
      note: note,
      disclosureLabel: 'Recommended by $sourceName',
      version: 1,
      publishedAt: _now(),
    );
    _manifestsByKey[idempotencyKey] = manifest;
    _manifestsById[manifest.id] = manifest;
    return manifest;
  }

  @override
  Future<ReferralTerms> publishReferralTerms({
    required String sourceCreatorId,
    required String destinationCreatorId,
    required int windowDays,
    required int capCents,
    required int rewardCents,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _termsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final terms = ReferralTerms(
      id: 'terms_${_slug(sourceCreatorId)}_${_slug(destinationCreatorId)}_${_termsByKey.length + 1}',
      sourceCreatorId: sourceCreatorId,
      destinationCreatorId: destinationCreatorId,
      windowDays: windowDays,
      capCents: capCents,
      rewardCents: rewardCents,
      version: 1,
      publishedAt: _now(),
    );
    _termsByKey[idempotencyKey] = terms;
    _termsById[terms.id] = terms;
    return terms;
  }

  @override
  Future<DiscoveryReceipt> recordDiscovery({
    required String manifestId,
    required String passportId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _discoveriesByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final manifest = _manifestsById[manifestId];
    if (manifest == null) {
      throw StateError('No recommendation manifest exists for $manifestId');
    }
    final receipt = DiscoveryReceipt(
      id: 'disc_${_slug(manifestId)}_${_discoveriesByKey.length + 1}',
      manifestId: manifest.id,
      passportId: passportId,
      sourceCreatorId: manifest.sourceCreatorId,
      destinationCreatorId: manifest.destinationCreatorId,
      contentId: manifest.contentId,
      disclosure: manifest.disclosureLabel,
      createdAt: _now(),
    );
    _discoveriesByKey[idempotencyKey] = receipt;
    _discoveriesById[receipt.id] = receipt;
    await _store.ingestReceipts(
      idempotencyKey: 'receipt-$idempotencyKey',
      records: [
        ReceiptRecord(
          id: 'receipt_${receipt.id}',
          type: 'discovery',
          passportId: passportId,
          contentId: manifest.contentId,
          authorizationId: receipt.id,
          summary: '${manifest.disclosureLabel} discovery viewed.',
          createdAt: receipt.createdAt,
        ),
      ],
    );
    return receipt;
  }

  @override
  Future<CreatorReferralReceipt> recordReferralConversion({
    required String discoveryReceiptId,
    required String termsId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final existing = _referralsByKey[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final discovery = _discoveriesById[discoveryReceiptId];
    final terms = _termsById[termsId];
    if (discovery == null) {
      throw StateError('No discovery receipt exists for $discoveryReceiptId');
    }
    if (terms == null) {
      throw StateError('No referral terms exist for $termsId');
    }
    final sourceContentId = await _firstContentIdForCreator(
      discovery.sourceCreatorId,
    );
    final receipt = CreatorReferralReceipt(
      id: 'ref_${_slug(discoveryReceiptId)}_${_referralsByKey.length + 1}',
      termsId: terms.id,
      discoveryReceiptId: discovery.id,
      passportId: discovery.passportId,
      sourceCreatorId: discovery.sourceCreatorId,
      destinationCreatorId: discovery.destinationCreatorId,
      amountCents: terms.rewardCents,
      createdAt: _now(),
    );
    _referralsByKey[idempotencyKey] = receipt;
    await _store.ingestReceipts(
      idempotencyKey: 'receipt-$idempotencyKey',
      records: [
        ReceiptRecord(
          id: 'receipt_${receipt.id}',
          type: 'referral',
          passportId: receipt.passportId,
          contentId: sourceContentId,
          authorizationId: receipt.id,
          summary:
              'Referral conversion credited ${receipt.amountCents} cents from ${receipt.destinationCreatorId}.',
          createdAt: receipt.createdAt,
        ),
      ],
    );
    return receipt;
  }

  Future<String> _firstContentIdForCreator(String creatorId) async {
    final content = await _store.publicCatalog();
    for (final item in content) {
      if (item.creatorId == creatorId) {
        return item.id;
      }
    }
    return 'content_solar_001';
  }
}

PlatformIntent _mapPlatformIntent(PlatformIntentRecord record) {
  return PlatformIntent(
    id: record.id,
    label: record.label,
    description: record.description,
    interestIds: record.interestIds,
  );
}

SessionIntent _mapSessionIntent(
  SessionIntentRecord record,
  PlatformIntentRecord? platformIntent,
) {
  final label = platformIntent?.label ?? record.platformIntentId;
  final interestLabels = record.selectedInterestIds.map(_labelForInterest);
  return SessionIntent(
    id: record.id,
    passportId: record.passportId,
    platformIntentId: record.platformIntentId,
    label: label,
    selectedInterestIds: record.selectedInterestIds,
    startedAt: record.createdAt,
    disclosure: SessionIntentDisclosure(
      title: '$label feed',
      body:
          'This session uses explicit intent, public creator metadata, summary fit, and trending stats. Ads are excluded from ranking.',
      matchedInterests: interestLabels.toList(growable: false),
      excludedSignals: const ['Paid placement', 'private contact scraping'],
      providerLabels: const ['Loom native graph', 'Loom import bridge'],
    ),
  );
}

ContentTile _mapTile(ContentRecord content, CreatorRecord creator) {
  return ContentTile(
    contentId: content.id,
    creatorId: content.creatorId,
    creatorName: creator.displayName,
    title: content.title,
    summary: content.summary,
    contentTypeLabel: content.contentType == 'video' ? 'Video' : 'Post',
    thumbnailRef: content.thumbnailRef,
    createdAt: content.createdAt,
  );
}

FeedbackEvent _mapFeedback(FanFeedbackRecord record) {
  return FeedbackEvent(
    id: record.id,
    sessionIntentId: record.sessionIntentId,
    contentId: record.contentId,
    action: _feedbackActionFromValue(record.action),
    createdAt: record.createdAt,
  );
}

String _feedbackActionValue(FeedbackAction action) {
  switch (action) {
    case FeedbackAction.like:
      return 'like';
    case FeedbackAction.dislike:
      return 'dislike';
    case FeedbackAction.muteCreator:
      return 'mute_creator';
    case FeedbackAction.blockCreator:
      return 'block_creator';
  }
}

FeedbackAction _feedbackActionFromValue(String value) {
  switch (value) {
    case 'like':
      return FeedbackAction.like;
    case 'dislike':
      return FeedbackAction.dislike;
    case 'mute_creator':
      return FeedbackAction.muteCreator;
    case 'block_creator':
      return FeedbackAction.blockCreator;
  }
  return FeedbackAction.dislike;
}

List<String> _interestIdsForCreatorId(String creatorId) {
  if (creatorId.contains('solar')) {
    return const ['home_energy', 'solar_storage', 'personal_finance'];
  }
  if (creatorId.contains('ferment')) {
    return const ['fermentation', 'food_safety', 'weeknight_cooking'];
  }
  if (creatorId.contains('motion')) {
    return const ['mobility', 'strength_basics', 'joint_friendly_cardio'];
  }
  return const ['creator_tools'];
}

String _labelForInterest(String interestId) {
  switch (interestId) {
    case 'home_energy':
      return 'Home energy';
    case 'solar_storage':
      return 'Solar storage';
    case 'personal_finance':
      return 'Personal finance';
    case 'fermentation':
      return 'Fermentation';
    case 'food_safety':
      return 'Food safety';
    case 'weeknight_cooking':
      return 'Weeknight cooking';
    case 'mobility':
      return 'Mobility';
    case 'strength_basics':
      return 'Strength basics';
    case 'joint_friendly_cardio':
      return 'Joint-friendly cardio';
    case 'family_learning':
      return 'Family learning';
    case 'creator_tools':
      return 'Creator tools';
  }
  return interestId.replaceAll('_', ' ');
}

String _rankLabel(double velocity) {
  if (velocity >= 0.85) {
    return 'Rising fast';
  }
  if (velocity >= 0.7) {
    return 'Steady lift';
  }
  return 'Niche momentum';
}

String _creatorName(Map<String, CreatorRecord> creators, String creatorId) {
  return creators[creatorId]?.displayName ?? creatorId.replaceAll('_', ' ');
}

DateTime _now() => DateTime.now().toUtc();

String _slug(String value) {
  final cleaned = value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return cleaned.isEmpty ? 'item' : cleaned;
}
