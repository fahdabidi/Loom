import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show DemoLocalStore, FanPassportRecord, FollowRecord;

/// Implements [FanPassportApi] over [DemoLocalStore].
///
/// Seed tables used: `creators`; writes `fan_passports`, `personas`,
/// `follows`, `consent_grants`, and `idempotency_records`.
class FanPassportFake implements FanPassportApi {
  const FanPassportFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<FanPassportClaim> createPassport({
    required String displayName,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createPassport(
      displayName: displayName,
      idempotencyKey: idempotencyKey,
    );
    return _mapPassport(record);
  }

  @override
  Future<FanPassportClaim?> getPassport(String passportId) async {
    await Future<void>.delayed(latency);
    final record = await _store.fanPassportById(passportId);
    return record == null ? null : _mapPassport(record);
  }

  @override
  Future<Persona> setPersona({
    required String passportId,
    required String label,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.setPersona(
      passportId: passportId,
      label: label,
      idempotencyKey: idempotencyKey,
    );
    return Persona(
      id: record.id,
      passportId: record.passportId,
      label: record.label,
      isActive: record.isActive,
    );
  }

  @override
  Future<FollowView> createFollow({
    required String passportId,
    required String creatorId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createFollow(
      passportId: passportId,
      creatorId: creatorId,
      visibility: visibility.name,
      idempotencyKey: idempotencyKey,
    );
    return _mapFollow(record);
  }

  @override
  Future<FollowView> setFollowVisibility({
    required String followId,
    required FollowVisibility visibility,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.setFollowVisibility(
      followId: followId,
      visibility: visibility.name,
      idempotencyKey: idempotencyKey,
    );
    return _mapFollow(record);
  }

  @override
  Future<FollowView?> unfollow({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.unfollowCreator(
      passportId: passportId,
      creatorId: creatorId,
      idempotencyKey: idempotencyKey,
    );
    return record == null ? null : _mapFollow(record);
  }

  @override
  Future<FollowView> blockCreator({
    required String passportId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.blockCreator(
      passportId: passportId,
      creatorId: creatorId,
      idempotencyKey: idempotencyKey,
    );
    return _mapFollow(record);
  }

  @override
  Future<ConsentGrant> createConsentGrant({
    required String passportId,
    required String grantType,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createConsentGrant(
      passportId: passportId,
      grantType: grantType,
      idempotencyKey: idempotencyKey,
    );
    return ConsentGrant(
      id: record.id,
      passportId: record.passportId,
      grantType: record.grantType,
      createdAt: record.createdAt,
    );
  }

  @override
  Future<List<FollowView>> listFollows(String passportId) async {
    await Future<void>.delayed(latency);
    final records = await _store.followsForPassport(passportId);
    return records.map(_mapFollow).toList(growable: false);
  }
}

FanPassportClaim _mapPassport(FanPassportRecord record) {
  return FanPassportClaim(
    id: record.id,
    displayName: record.displayName,
    activePersonaId: record.activePersonaId,
    createdAt: record.createdAt,
  );
}

FollowView _mapFollow(FollowRecord record) {
  return FollowView(
    id: record.id,
    passportId: record.passportId,
    creatorId: record.creatorId,
    creatorDisplayName: record.creatorDisplayName,
    visibility: record.visibility == FollowVisibility.public.name
        ? FollowVisibility.public
        : FollowVisibility.private,
    blocked: record.blocked,
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  );
}
