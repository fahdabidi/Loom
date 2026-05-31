import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart' show DemoLocalStore;

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
}
