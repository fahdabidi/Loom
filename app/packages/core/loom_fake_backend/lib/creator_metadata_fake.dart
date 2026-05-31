import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    hide
        ContentManifest,
        CreatorAdPolicy,
        HostingContract,
        MembershipTier,
        MonetizationManifest;

/// Implements [CreatorMetadataApi] over [DemoLocalStore].
///
/// Seed tables used: `creators`, `content`.
class CreatorMetadataFake implements CreatorMetadataApi {
  const CreatorMetadataFake(
    this._store, {
    this.latency = const Duration(milliseconds: 120),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<Page<ContentSummaryView>> getPublicCatalog(
    String channelId, {
    String? cursor,
    int limit = 10,
  }) async {
    if (limit <= 0 || limit > 50) {
      throw const ApiError(
        code: 'invalid_limit',
        message: 'limit must be between 1 and 50',
      );
    }

    final creator = await _store.creatorById(channelId);
    if (creator == null) {
      throw ApiError(
        code: 'creator_not_found',
        message: 'No creator exists for channelId=$channelId',
      );
    }

    await Future<void>.delayed(latency);

    final start = int.tryParse(cursor ?? '0') ?? 0;
    final records = await _store.publicCatalogForCreator(channelId);
    final end = (start + limit).clamp(0, records.length);
    final pageRecords = records.sublist(start, end);
    final nextCursor = end < records.length ? end.toString() : null;

    return Page<ContentSummaryView>(
      items: pageRecords
          .map(
            (record) => ContentSummaryView(
              id: record.id,
              creatorId: record.creatorId,
              creatorDisplayName: creator.displayName,
              title: record.title,
              summary: record.summary,
              thumbnailRef: record.thumbnailRef,
              contentType: record.contentType == 'video'
                  ? ContentType.video
                  : ContentType.post,
            ),
          )
          .toList(growable: false),
      nextCursor: nextCursor,
    );
  }

  @override
  Future<CreatorChannelManifest> createChannelProfile({
    required String channelId,
    required String displayName,
    required String handle,
    required String description,
    required String category,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createChannelProfile(
      channelId: channelId,
      displayName: displayName,
      handle: handle,
      description: description,
      category: category,
      idempotencyKey: idempotencyKey,
    );
    return CreatorChannelManifest(
      channelId: record.channelId,
      displayName: record.displayName,
      handle: record.handle,
      description: record.description,
      category: record.category,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<HostingContract> attachHostingContract({
    required String channelId,
    required String provider,
    required String termsVersion,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.attachHostingContract(
      channelId: channelId,
      provider: provider,
      termsVersion: termsVersion,
      idempotencyKey: idempotencyKey,
    );
    return HostingContract(
      id: record.id,
      channelId: record.channelId,
      provider: record.provider,
      status: record.status,
      termsVersion: record.termsVersion,
      acceptedAt: record.acceptedAt,
    );
  }

  @override
  Future<ContentManifest> publishContent({
    required String channelId,
    required ContentType contentType,
    required String title,
    required String summary,
    required String thumbnailRef,
    required ContentAccessMode accessMode,
    required MonetizationMode monetizationMode,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    if (summary.trim().isEmpty) {
      throw const ApiError(
        code: 'summary_required',
        message: 'A creator-approved summary is required before publishing.',
      );
    }
    final record = await _store.publishContent(
      channelId: channelId,
      contentType: _contentTypeValue(contentType),
      title: title,
      summary: summary.trim(),
      thumbnailRef: thumbnailRef,
      accessMode: _accessModeValue(accessMode),
      monetizationMode: _monetizationModeValue(monetizationMode),
      idempotencyKey: idempotencyKey,
    );
    return _mapContentManifest(record);
  }

  @override
  Future<MonetizationManifest> updateMonetizationManifest({
    required String channelId,
    required bool membershipsEnabled,
    required List<String> memberOnlyContentIds,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.updateMonetizationManifest(
      channelId: channelId,
      membershipsEnabled: membershipsEnabled,
      memberOnlyContentIds: memberOnlyContentIds,
      idempotencyKey: idempotencyKey,
    );
    return MonetizationManifest(
      channelId: record.channelId,
      membershipsEnabled: record.membershipsEnabled,
      memberOnlyContentIds: record.memberOnlyContentIds,
      updatedAt: record.updatedAt,
    );
  }

  @override
  Future<List<MembershipTier>> defineMembershipTiers({
    required String channelId,
    required List<MembershipTierDraft> tiers,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final now = DateTime.utc(2026, 5, 31, 12);
    final records = await _store.defineMembershipTiers(
      channelId: channelId,
      tiers: [
        for (final (index, tier) in tiers.indexed)
          MembershipTierRecord(
            id: 'tier_${_slug(channelId)}_${index + 1}',
            channelId: channelId,
            name: tier.name,
            monthlyPriceCents: tier.monthlyPriceCents,
            benefits: tier.benefits,
            entitlementCode: tier.entitlementCode,
            createdAt: now,
          ),
      ],
      idempotencyKey: idempotencyKey,
    );
    return records.map(_mapMembershipTier).toList(growable: false);
  }

  @override
  Future<CreatorAdPolicy> setCreatorAdPolicy({
    required String channelId,
    required List<String> allowedCategories,
    required List<String> blockedCategories,
    required List<String> formats,
    required List<String> surfaces,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.setCreatorAdPolicy(
      channelId: channelId,
      allowedCategories: allowedCategories,
      blockedCategories: blockedCategories,
      formats: formats,
      surfaces: surfaces,
      idempotencyKey: idempotencyKey,
    );
    return _mapCreatorAdPolicy(record);
  }

  @override
  Future<AIContentPolicy> setAIContentPolicy({
    required String channelId,
    required bool archiveQaEnabled,
    required bool summariesEnabled,
    required bool citationRequired,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.setAiContentPolicy(
      channelId: channelId,
      archiveQaEnabled: archiveQaEnabled,
      summariesEnabled: summariesEnabled,
      citationRequired: citationRequired,
      idempotencyKey: idempotencyKey,
    );
    return _mapAiContentPolicy(record);
  }

  @override
  Future<List<ContentManifest>> contentManifests(String channelId) async {
    await Future<void>.delayed(latency);
    final records = await _store.contentManifests(channelId);
    return records.map(_mapContentManifest).toList(growable: false);
  }

  @override
  Future<List<MembershipTier>> membershipTiers(String channelId) async {
    await Future<void>.delayed(latency);
    final records = await _store.membershipTiers(channelId);
    return records.map(_mapMembershipTier).toList(growable: false);
  }

  @override
  Future<CreatorAdPolicy?> creatorAdPolicy(String channelId) async {
    await Future<void>.delayed(latency);
    final record = await _store.creatorAdPolicy(channelId);
    return record == null ? null : _mapCreatorAdPolicy(record);
  }

  @override
  Future<AIContentPolicy?> aiContentPolicy(String channelId) async {
    await Future<void>.delayed(latency);
    final record = await _store.aiContentPolicy(channelId);
    return record == null ? null : _mapAiContentPolicy(record);
  }
}

ContentManifest _mapContentManifest(ContentManifestRecord record) {
  return ContentManifest(
    id: record.id,
    channelId: record.channelId,
    title: record.title,
    summary: record.summary,
    contentType: record.contentType == 'video'
        ? ContentType.video
        : ContentType.post,
    accessMode: record.accessMode == 'membersOnly'
        ? ContentAccessMode.membersOnly
        : ContentAccessMode.public,
    monetizationMode: record.monetizationMode == 'membership'
        ? MonetizationMode.membership
        : MonetizationMode.free,
    thumbnailRef: record.thumbnailRef,
    schemaVersion: record.schemaVersion,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  );
}

MembershipTier _mapMembershipTier(MembershipTierRecord record) {
  return MembershipTier(
    id: record.id,
    channelId: record.channelId,
    name: record.name,
    monthlyPriceCents: record.monthlyPriceCents,
    benefits: record.benefits,
    entitlementCode: record.entitlementCode,
    createdAt: record.createdAt,
  );
}

CreatorAdPolicy _mapCreatorAdPolicy(CreatorAdPolicyRecord record) {
  return CreatorAdPolicy(
    channelId: record.channelId,
    allowedCategories: record.allowedCategories,
    blockedCategories: record.blockedCategories,
    formats: record.formats,
    surfaces: record.surfaces,
    updatedAt: record.updatedAt,
  );
}

AIContentPolicy _mapAiContentPolicy(AiContentPolicyRecord record) {
  return AIContentPolicy(
    channelId: record.channelId,
    archiveQaEnabled: record.archiveQaEnabled,
    summariesEnabled: record.summariesEnabled,
    citationRequired: record.citationRequired,
    updatedAt: record.updatedAt,
  );
}

String _contentTypeValue(ContentType type) {
  return type == ContentType.video ? 'video' : 'post';
}

String _accessModeValue(ContentAccessMode mode) {
  return mode == ContentAccessMode.membersOnly ? 'membersOnly' : 'public';
}

String _monetizationModeValue(MonetizationMode mode) {
  return mode == MonetizationMode.membership ? 'membership' : 'free';
}

String _slug(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'demo' : slug;
}
