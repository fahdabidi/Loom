import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show CrossPostRecord, CrossPostTargetRecord, DemoLocalStore;

class CrossPostingFake implements CrossPostingApi {
  const CrossPostingFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<CrossPost>> listCrossPosts({required String channelId}) async {
    await Future<void>.delayed(latency);
    return (await _store.crossPosts(
      channelId,
    )).map(_mapCrossPost).toList(growable: false);
  }

  @override
  Future<CrossPost> createCrossPost({
    required String channelId,
    required List<String> targetLinkIds,
    required String message,
    String? announcementId,
    String? contentRef,
    String? captureLinkUrl,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapCrossPost(
      await _store.createCrossPost(
        channelId: channelId,
        targetLinkIds: targetLinkIds,
        message: message,
        announcementId: announcementId,
        contentRef: contentRef,
        captureLinkUrl: captureLinkUrl,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<CrossPost> getCrossPost({
    required String channelId,
    required String crossPostId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapCrossPost(await _store.advanceCrossPost(crossPostId));
  }
}

CrossPost _mapCrossPost(CrossPostRecord record) {
  return CrossPost(
    crossPostId: record.crossPostId,
    channelId: record.channelId,
    message: record.message,
    createdAt: record.createdAt,
    targets: record.targets.map(_mapTarget).toList(growable: false),
    announcementId: record.announcementId,
    contentRef: record.contentRef,
    captureLinkUrl: record.captureLinkUrl,
  );
}

CrossPostTarget _mapTarget(CrossPostTargetRecord record) {
  return CrossPostTarget(
    targetLinkId: record.targetLinkId,
    platform: record.platform,
    deliveryStatus: record.deliveryStatus,
    externalPostUrl: record.externalPostUrl,
    message: record.message,
  );
}
