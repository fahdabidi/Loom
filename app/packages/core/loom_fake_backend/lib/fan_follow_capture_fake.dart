import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show CaptureLinkRecord, DemoLocalStore, ReFollowEventRecord;

class FanFollowCaptureFake implements FanFollowCaptureApi {
  const FanFollowCaptureFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<CaptureLink> createCaptureLink({
    required String channelId,
    required String channel,
    required bool starterPackEnabled,
    DateTime? expiresAt,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapCaptureLink(
      await _store.createCaptureLink(
        channelId: channelId,
        channel: channel,
        starterPackEnabled: starterPackEnabled,
        expiresAt: expiresAt,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<CaptureLandingView> resolveCaptureLink({
    required String token,
    required String passportId,
  }) async {
    await Future<void>.delayed(latency);
    final link = await _store.captureLinkByToken(token);
    if (link == null) {
      throw StateError('No capture link exists for token=$token');
    }
    final creator = await _store.creatorById(link.channelId);
    final follow = await _store.followForPassportCreator(
      passportId: passportId,
      creatorId: link.channelId,
    );
    final starterPack = await _store.starterPack(link.channelId);
    return CaptureLandingView(
      channelId: link.channelId,
      handle: creator?.handle ?? link.channelId,
      displayName: creator?.displayName ?? link.channelId,
      avatarRef: creator?.avatarRef ?? 'seed://avatars/${link.channelId}',
      tagline:
          'Follow ${creator?.displayName ?? link.channelId} on Loom and start from a populated feed.',
      alreadyFollowing: follow != null && !follow.blocked,
      starterPackToken: link.starterPackEnabled
          ? starterPack.starterPackToken
          : null,
    );
  }

  @override
  Future<ReFollowResult> recordReFollow({
    required String token,
    required String passportId,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapReFollow(
      await _store.recordReFollow(
        token: token,
        passportId: passportId,
        followVisibility: followVisibility,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

CaptureLink _mapCaptureLink(CaptureLinkRecord record) {
  return CaptureLink(
    token: record.token,
    channelId: record.channelId,
    url: record.url,
    channel: record.channel,
    qrPayload: record.qrPayload,
    starterPackEnabled: record.starterPackEnabled,
    createdAt: record.createdAt,
    expiresAt: record.expiresAt,
  );
}

ReFollowResult _mapReFollow(ReFollowEventRecord record) {
  return ReFollowResult(
    channelId: record.channelId,
    followState: record.followState == 'already_following'
        ? ReFollowState.alreadyFollowing
        : ReFollowState.followed,
    pairwiseCreatorFanId: record.pairwiseCreatorFanId,
    auditReceiptId: 'audit_${record.id}',
    createdAt: record.createdAt,
  );
}
