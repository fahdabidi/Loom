import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, ExternalAccountRecord;

class ExternalAccountLinkFake implements ExternalAccountLinkApi {
  const ExternalAccountLinkFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<List<ExternalAccountLink>> listExternalAccounts({
    required String channelId,
  }) async {
    await Future<void>.delayed(latency);
    return (await _store.externalAccounts(
      channelId,
    )).map(_mapExternalAccount).toList(growable: false);
  }

  @override
  Future<ExternalAccountLink> linkExternalAccount({
    required String channelId,
    required String platform,
    required String handle,
    String? profileUrl,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapExternalAccount(
      await _store.linkExternalAccount(
        channelId: channelId,
        platform: platform,
        handle: handle,
        profileUrl: profileUrl,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<ExternalAccountLink> verifyExternalAccount({
    required String channelId,
    required String linkId,
    required String method,
    String? evidence,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    return _mapExternalAccount(
      await _store.verifyExternalAccount(
        channelId: channelId,
        linkId: linkId,
        method: method,
        evidence: evidence,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<void> unlinkExternalAccount({
    required String channelId,
    required String linkId,
  }) async {
    await Future<void>.delayed(latency);
    await _store.unlinkExternalAccount(channelId: channelId, linkId: linkId);
  }
}

ExternalAccountLink _mapExternalAccount(ExternalAccountRecord record) {
  return ExternalAccountLink(
    linkId: record.linkId,
    channelId: record.channelId,
    platform: record.platform,
    handle: record.handle,
    profileUrl: record.profileUrl,
    verificationState: record.verificationState,
    linkedAt: record.linkedAt,
  );
}
