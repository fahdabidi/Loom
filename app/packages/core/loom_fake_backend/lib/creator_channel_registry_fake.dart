import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show CreatorChannelRecord, DemoLocalStore;

/// Implements [CreatorChannelRegistryApi] over [DemoLocalStore].
///
/// Writes `creator_channels` and `idempotency_records`.
class CreatorChannelRegistryFake implements CreatorChannelRegistryApi {
  const CreatorChannelRegistryFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<CreatorChannel> createChannel({
    required String ownerPassportId,
    required String displayName,
    required String vertical,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createChannel(
      ownerPassportId: ownerPassportId,
      displayName: displayName,
      vertical: vertical,
      idempotencyKey: idempotencyKey,
    );
    return _mapChannel(record);
  }

  @override
  Future<CreatorChannel> bindHandle({
    required String channelId,
    required String handle,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.bindHandle(
      channelId: channelId,
      handle: handle,
      idempotencyKey: idempotencyKey,
    );
    return _mapChannel(record);
  }

  @override
  Future<CreatorChannel?> getChannel(String channelId) async {
    await Future<void>.delayed(latency);
    final record = await _store.creatorChannelById(channelId);
    return record == null ? null : _mapChannel(record);
  }
}

CreatorChannel _mapChannel(CreatorChannelRecord record) {
  return CreatorChannel(
    id: record.id,
    ownerPassportId: record.ownerPassportId,
    displayName: record.displayName,
    handle: record.handle,
    vertical: record.vertical,
    createdAt: record.createdAt,
  );
}
