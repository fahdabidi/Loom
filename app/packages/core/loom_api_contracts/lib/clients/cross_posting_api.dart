import '../models/launch/launch_models.dart';

abstract class CrossPostingApi {
  Future<List<CrossPost>> listCrossPosts({required String channelId});

  Future<CrossPost> createCrossPost({
    required String channelId,
    required List<String> targetLinkIds,
    required String message,
    String? announcementId,
    String? contentRef,
    String? captureLinkUrl,
    required String idempotencyKey,
  });

  Future<CrossPost> getCrossPost({
    required String channelId,
    required String crossPostId,
  });
}
