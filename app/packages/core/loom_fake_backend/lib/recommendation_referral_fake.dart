import 'dart:math' as math;

import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        ContentRecord,
        CreatorRecord,
        DemoLocalStore,
        FanFeedbackRecord,
        PlatformIntentRecord,
        SessionIntentRecord;

class RecommendationReferralFake implements RecommendationReferralApi {
  RecommendationReferralFake(
    this._store, {
    this.latency = const Duration(milliseconds: 120),
  });

  final DemoLocalStore _store;
  final Duration latency;
  int feedRequestCount = 0;

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
    final ranked = <FeedItem>[];
    for (final item in content) {
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
