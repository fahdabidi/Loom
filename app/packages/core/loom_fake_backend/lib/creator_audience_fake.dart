import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_local_store/loom_local_store.dart'
    show
        AudienceInsightRecord,
        DataAccessReceiptRecord,
        DataGrantRequestRecord,
        DemoLocalStore,
        PermissionedInterestDataRecord;

/// Implements [CreatorAudienceApi] over [DemoLocalStore].
class CreatorAudienceFake implements CreatorAudienceApi {
  const CreatorAudienceFake(
    this._store, {
    this.latency = const Duration(milliseconds: 100),
  });

  final DemoLocalStore _store;
  final Duration latency;

  @override
  Future<DataGrantRequest> createDataGrantRequest({
    required String creatorId,
    required String passportId,
    required List<String> fields,
    required String purpose,
    required String retention,
    required String valueExchange,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.createDataGrantRequest(
      creatorId: creatorId,
      passportId: passportId,
      fields: fields,
      purpose: purpose,
      retention: retention,
      valueExchange: valueExchange,
      idempotencyKey: idempotencyKey,
    );
    return _mapRequest(record);
  }

  @override
  Future<List<DataGrantRequest>> pendingGrantRequests(String passportId) async {
    await Future<void>.delayed(latency);
    final records = await _store.pendingGrantRequests(passportId);
    return records.map(_mapRequest).toList(growable: false);
  }

  @override
  Future<PermissionedInterestData> queryPermissionedInterestData({
    required String creatorId,
    required String passportId,
    required String purpose,
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(latency);
    final record = await _store.queryPermissionedInterestData(
      creatorId: creatorId,
      passportId: passportId,
      purpose: purpose,
      idempotencyKey: idempotencyKey,
    );
    return _mapPermissionedInterestData(record);
  }

  @override
  Future<AudienceInsight> getAudienceInsights({
    required String creatorId,
  }) async {
    await Future<void>.delayed(latency);
    return _mapInsight(await _store.audienceInsight(creatorId));
  }

  @override
  Future<List<DataAccessReceipt>> dataAccessReceipts(String passportId) async {
    await Future<void>.delayed(latency);
    final records = await _store.dataAccessReceiptsForPassport(passportId);
    return records.map(_mapReceipt).toList(growable: false);
  }
}

DataGrantRequest _mapRequest(DataGrantRequestRecord record) {
  return DataGrantRequest(
    id: record.id,
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    passportId: record.passportId,
    fields: record.fields,
    purpose: record.purpose,
    retention: record.retention,
    valueExchange: record.valueExchange,
    state: _state(record.state),
    createdAt: record.createdAt,
    updatedAt: record.updatedAt,
  );
}

PermissionedInterestData _mapPermissionedInterestData(
  PermissionedInterestDataRecord record,
) {
  return PermissionedInterestData(
    creatorId: record.creatorId,
    passportId: record.passportId,
    fields: record.fields,
    values: record.values,
    receipt: _mapReceipt(record.receipt),
  );
}

AudienceInsight _mapInsight(AudienceInsightRecord record) {
  return AudienceInsight(
    creatorId: record.creatorId,
    approvedFanCount: record.approvedFanCount,
    topCategories: record.topCategories,
    permissionStatus: record.permissionStatus,
    updatedAt: record.updatedAt,
  );
}

DataAccessReceipt _mapReceipt(DataAccessReceiptRecord record) {
  return DataAccessReceipt(
    id: record.id,
    passportId: record.passportId,
    creatorId: record.creatorId,
    creatorName: record.creatorName,
    grantId: record.grantId,
    fields: record.fields,
    purpose: record.purpose,
    accessedAt: record.accessedAt,
  );
}

ConsentGrantState _state(String value) {
  return ConsentGrantState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => ConsentGrantState.pending,
  );
}
