import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart';

class ContentHostFake implements ContentHostApi {
  const ContentHostFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<PlaybackAsset> ingestMedia({
    required String channelId,
    required ContentType contentType,
    required String fileName,
    required String idempotencyKey,
  }) {
    return createPlaybackAsset(
      channelId: channelId,
      contentType: contentType,
      fileName: fileName,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<PlaybackAsset> createPlaybackAsset({
    required String channelId,
    required ContentType contentType,
    required String fileName,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final assetId = 'asset_${_slug(idempotencyKey)}';
    return PlaybackAsset(
      assetId: assetId,
      channelId: channelId,
      contentType: contentType,
      fileName: fileName,
      thumbnailRef: 'seed://studio/$assetId',
      createdAt: DateTime.utc(2026, 5, 31, 12),
    );
  }

  @override
  Future<ContentPerformanceMetadata> getContentPerformanceMetadata(
    String contentId,
  ) async {
    await Future<void>.delayed(latency);
    final record = await _store.contentPerformance(contentId);
    return ContentPerformanceMetadata(
      contentId: record.contentId,
      velocity: record.velocity,
      completionRate: record.completionRate,
      saves: record.saves,
      shares: record.shares,
      updatedAt: record.updatedAt,
    );
  }
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
