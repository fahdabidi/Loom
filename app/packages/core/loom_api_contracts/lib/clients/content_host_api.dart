import '../models/content_host/content_host_models.dart';
import '../models/creator_metadata/content_summary_view.dart';

abstract class ContentHostApi {
  Future<PlaybackAsset> ingestMedia({
    required String channelId,
    required ContentType contentType,
    required String fileName,
    required String idempotencyKey,
  });

  Future<PlaybackAsset> createPlaybackAsset({
    required String channelId,
    required ContentType contentType,
    required String fileName,
    required String idempotencyKey,
  });

  Future<ContentPerformanceMetadata> getContentPerformanceMetadata(
    String contentId,
  );
}
