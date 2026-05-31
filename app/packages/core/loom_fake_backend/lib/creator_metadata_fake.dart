import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart';

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
}
