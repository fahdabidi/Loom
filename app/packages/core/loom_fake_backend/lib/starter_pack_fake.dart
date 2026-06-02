import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show BulkFollowJobRecord, CreatorRecord, DemoLocalStore;

class StarterPackFake implements StarterPackApi {
  const StarterPackFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<StarterPack> getStarterPack({
    required String channelId,
    required String passportId,
    int limit = 6,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.starterPack(channelId);
    final creators = {
      for (final creator in await _store.creators()) creator.id: creator,
    };
    final selected = record.memberIds.take(limit + 1).toList(growable: false);
    final members = <StarterPackMember>[];
    for (final memberId in selected) {
      final creator = creators[memberId];
      if (creator == null) {
        continue;
      }
      final follow = await _store.followForPassportCreator(
        passportId: passportId,
        creatorId: memberId,
      );
      members.add(
        _mapMember(
          creator,
          sourceChannelId: channelId,
          defaultSelected: record.defaultSelectedIds.contains(memberId),
          alreadyFollowing: follow != null && !follow.blocked,
        ),
      );
    }
    return StarterPack(
      sourceChannelId: channelId,
      starterPackToken: record.starterPackToken,
      members: members,
    );
  }

  @override
  Future<BulkFollowResult> bulkFollow({
    required String channelId,
    required String passportId,
    required List<String> channelIds,
    required String followVisibility,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapBulkFollow(
      await _store.bulkFollow(
        channelId: channelId,
        passportId: passportId,
        channelIds: channelIds,
        followVisibility: followVisibility,
        idempotencyKey: idempotencyKey,
      ),
    );
  }
}

StarterPackMember _mapMember(
  CreatorRecord creator, {
  required String sourceChannelId,
  required bool defaultSelected,
  required bool alreadyFollowing,
}) {
  final isSource = creator.id == sourceChannelId;
  return StarterPackMember(
    channelId: creator.id,
    handle: creator.handle,
    displayName: creator.displayName,
    avatarRef: creator.avatarRef,
    role: isSource
        ? StarterPackMemberRole.source
        : StarterPackMemberRole.recommended,
    recommendationReason: isSource
        ? null
        : 'Recommended by the creator-led discovery graph.',
    defaultSelected: defaultSelected,
    alreadyFollowing: alreadyFollowing,
  );
}

BulkFollowResult _mapBulkFollow(BulkFollowJobRecord record) {
  return BulkFollowResult(
    followed: record.followedIds,
    alreadyFollowing: record.alreadyFollowingIds,
    feedReady: record.feedReady,
  );
}
