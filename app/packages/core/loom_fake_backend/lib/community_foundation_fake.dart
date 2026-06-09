import 'package:loom_api_contracts/loom_api_contracts.dart';

class CommunityFoundationFakeBackend {
  CommunityFoundationFakeBackend({DateTime? clock})
    : _clock = clock ?? DateTime.utc(2026, 6, 9, 12) {
    audit = CommunityAuditFake(_clock);
    rolePolicy = CommunityRolePolicyFake();
    passport = CommunityPassportFake(audit, _clock);
    coreVault = CommunityCoreVaultFake();
    protectedVault = CommunityProtectedVaultFake(rolePolicy, audit);
    connections = CommunityConnectionsFake(audit);
    receiptLedger = CommunityReceiptLedgerFake();
    eventBus = CommunityEventBusFake(_clock);
    keyManagement = CommunityKeyManagementFake(_clock);
    builderAppIds = CommunityBuilderAppIdFake(keyManagement, audit);
  }

  final DateTime _clock;

  late final CommunityAuditFake audit;
  late final CommunityRolePolicyFake rolePolicy;
  late final CommunityPassportFake passport;
  late final CommunityCoreVaultFake coreVault;
  late final CommunityProtectedVaultFake protectedVault;
  late final CommunityConnectionsFake connections;
  late final CommunityReceiptLedgerFake receiptLedger;
  late final CommunityEventBusFake eventBus;
  late final CommunityKeyManagementFake keyManagement;
  late final CommunityBuilderAppIdFake builderAppIds;
}

class CommunityAuditFake implements CommunityAuditApi {
  CommunityAuditFake(this._clock);

  final DateTime _clock;
  final Map<String, CommunityAuditEntry> _byIdempotency = {};
  final List<CommunityAuditEntry> _entries = [];

  @override
  Future<CommunityAuditEntry> appendAudit({
    required String actorId,
    required String componentId,
    required String action,
    required bool redacted,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final entry = CommunityAuditEntry(
      auditId: 'audit_${_entries.length + 1}',
      actorId: actorId,
      componentId: componentId,
      action: action,
      redacted: redacted,
      idempotencyKey: idempotencyKey,
      createdAt: _clock,
    );
    _byIdempotency[idempotencyKey] = entry;
    _entries.add(entry);
    return entry;
  }

  @override
  Future<List<CommunityAuditEntry>> listAudit({
    required String componentId,
  }) async {
    return _entries
        .where((entry) => entry.componentId == componentId)
        .toList(growable: false);
  }
}

class CommunityPassportFake implements CommunityPassportApi {
  CommunityPassportFake(this._audit, this._clock);

  final CommunityAuditApi _audit;
  final DateTime _clock;
  final Map<String, CommunityPassport> _passports = {};
  final Map<String, CommunityPassport> _byIdempotency = {};

  @override
  Future<CommunityPassport> createPassport({
    required String displayName,
    required String actorId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final audit = await _audit.appendAudit(
      actorId: actorId,
      componentId: 'passport-ledger',
      action: 'passport.create',
      redacted: false,
      idempotencyKey: 'audit_$idempotencyKey',
    );
    final passport = CommunityPassport(
      passportId: 'passport_${_passports.length + 1}',
      displayName: displayName,
      version: 1,
      createdAt: _clock,
      auditId: audit.auditId,
    );
    _passports[passport.passportId] = passport;
    _byIdempotency[idempotencyKey] = passport;
    return passport;
  }

  @override
  Future<CommunityPassport?> resolvePassport(String passportId) async {
    return _passports[passportId];
  }
}

class CommunityRolePolicyFake implements CommunityRolePolicyApi {
  final Map<String, Set<String>> _permissions = {};
  final Map<String, CommunityPermissionDecision> _byIdempotency = {};
  int _version = 0;

  @override
  Future<CommunityPermissionDecision> grantPermission({
    required String actorId,
    required String communityId,
    required String permission,
    required String grantedBy,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final key = _key(actorId, communityId);
    _permissions.putIfAbsent(key, () => <String>{}).add(permission);
    _version += 1;
    final decision = CommunityPermissionDecision(
      actorId: actorId,
      communityId: communityId,
      permission: permission,
      allowed: true,
      reason: 'granted by $grantedBy',
      version: _version,
    );
    _byIdempotency[idempotencyKey] = decision;
    return decision;
  }

  @override
  Future<CommunityPermissionDecision> effectivePermission({
    required String actorId,
    required String communityId,
    required String permission,
  }) async {
    final allowed = _permissions[_key(actorId, communityId)]?.contains(
      permission,
    ) ?? false;
    return CommunityPermissionDecision(
      actorId: actorId,
      communityId: communityId,
      permission: permission,
      allowed: allowed,
      reason: allowed ? 'granted' : 'missing grant',
      version: _version,
    );
  }

  String _key(String actorId, String communityId) {
    return '$actorId::$communityId';
  }
}

class CommunityCoreVaultFake implements CommunityCoreVaultApi {
  final Map<String, CommunityPreferenceRecord> _preferences = {};
  final Map<String, CommunityPreferenceRecord> _byIdempotency = {};

  @override
  Future<CommunityPreferenceRecord> setPreference({
    required String passportId,
    required String key,
    required String value,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final recordKey = '$passportId::$key';
    final nextVersion = (_preferences[recordKey]?.version ?? 0) + 1;
    final record = CommunityPreferenceRecord(
      passportId: passportId,
      key: key,
      value: value,
      version: nextVersion,
      updatedAt: DateTime.utc(2026, 6, 9, 12),
    );
    _preferences[recordKey] = record;
    _byIdempotency[idempotencyKey] = record;
    return record;
  }

  @override
  Future<CommunityPreferenceRecord?> getPreference({
    required String passportId,
    required String key,
  }) async {
    return _preferences['$passportId::$key'];
  }
}

class CommunityProtectedVaultFake implements CommunityProtectedVaultApi {
  CommunityProtectedVaultFake(this._policy, this._audit);

  final CommunityRolePolicyApi _policy;
  final CommunityAuditApi _audit;
  final Map<String, CommunityProtectedRecord> _records = {};
  final Map<String, CommunityProtectedRecord> _byIdempotency = {};

  @override
  Future<CommunityProtectedRecord> writeProtectedRecord({
    required String passportId,
    required String field,
    required String value,
    required CommunityProtectedVisibility visibility,
    required String actorId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final audit = await _audit.appendAudit(
      actorId: actorId,
      componentId: 'protected-visibility-vault',
      action: 'protected.write.$field',
      redacted: true,
      idempotencyKey: 'audit_$idempotencyKey',
    );
    final record = CommunityProtectedRecord(
      recordId: 'protected_${_records.length + 1}',
      passportId: passportId,
      field: field,
      redactedValue: value.isEmpty ? '' : '${value.substring(0, 1)}***',
      visibility: visibility,
      version: 1,
      auditId: audit.auditId,
    );
    _records[record.recordId] = record;
    _byIdempotency[idempotencyKey] = record;
    return record;
  }

  @override
  Future<CommunityProtectedRecord?> readProtectedRecord({
    required String recordId,
    required String actorId,
    required String communityId,
    required String requiredPermission,
  }) async {
    final record = _records[recordId];
    if (record == null) {
      return null;
    }
    if (record.visibility == CommunityProtectedVisibility.ownerOnly &&
        actorId == record.passportId) {
      return record;
    }
    final decision = await _policy.effectivePermission(
      actorId: actorId,
      communityId: communityId,
      permission: requiredPermission,
    );
    return decision.allowed ? record : null;
  }
}

class CommunityConnectionsFake implements CommunityConnectionsApi {
  CommunityConnectionsFake(this._audit);

  final CommunityAuditApi _audit;
  final Map<String, CommunityConnectionRecord> _connections = {};
  final Map<String, CommunityConnectionRecord> _byIdempotency = {};

  @override
  Future<CommunityConnectionRecord> invite({
    required String requesterPassportId,
    required String targetPassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    if (!await canInvite(
      requesterPassportId: requesterPassportId,
      targetPassportId: targetPassportId,
    )) {
      throw StateError('connection is blocked');
    }
    final record = await _write(
      requesterPassportId: requesterPassportId,
      targetPassportId: targetPassportId,
      state: CommunityConnectionState.invited,
      idempotencyKey: idempotencyKey,
    );
    return record;
  }

  @override
  Future<CommunityConnectionRecord> block({
    required String requesterPassportId,
    required String targetPassportId,
    required String idempotencyKey,
  }) async {
    return _write(
      requesterPassportId: requesterPassportId,
      targetPassportId: targetPassportId,
      state: CommunityConnectionState.blocked,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<bool> canInvite({
    required String requesterPassportId,
    required String targetPassportId,
  }) async {
    return _connections.values.every((record) {
      final samePair =
          record.requesterPassportId == requesterPassportId &&
          record.targetPassportId == targetPassportId;
      return !(samePair && record.state == CommunityConnectionState.blocked);
    });
  }

  Future<CommunityConnectionRecord> _write({
    required String requesterPassportId,
    required String targetPassportId,
    required CommunityConnectionState state,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final audit = await _audit.appendAudit(
      actorId: requesterPassportId,
      componentId: 'connections-graph',
      action: 'connection.${state.name}',
      redacted: false,
      idempotencyKey: 'audit_$idempotencyKey',
    );
    final record = CommunityConnectionRecord(
      connectionId: 'connection_${_connections.length + 1}',
      requesterPassportId: requesterPassportId,
      targetPassportId: targetPassportId,
      state: state,
      version: 1,
      auditId: audit.auditId,
    );
    _connections[record.connectionId] = record;
    _byIdempotency[idempotencyKey] = record;
    return record;
  }
}

class CommunityReceiptLedgerFake implements CommunityReceiptLedgerApi {
  final Map<String, CommunityReceiptRecord> _byIdempotency = {};
  final List<CommunityReceiptRecord> _receipts = [];

  @override
  Future<CommunityReceiptRecord> appendReceipt({
    required String passportId,
    required String kind,
    required int amountCents,
    required String currency,
    required String summary,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final receipt = CommunityReceiptRecord(
      receiptId: 'community_receipt_${_receipts.length + 1}',
      passportId: passportId,
      kind: kind,
      amountCents: amountCents,
      currency: currency,
      summary: summary,
      version: 1,
      createdAt: DateTime.utc(2026, 6, 9, 12),
    );
    _receipts.add(receipt);
    _byIdempotency[idempotencyKey] = receipt;
    return receipt;
  }

  @override
  Future<List<CommunityReceiptRecord>> listReceipts(String passportId) async {
    return _receipts
        .where((receipt) => receipt.passportId == passportId)
        .toList(growable: false);
  }
}

class CommunityEventBusFake implements CommunityEventBusApi {
  CommunityEventBusFake(this._clock);

  final DateTime _clock;
  final Map<String, CommunityEventEnvelope> _byIdempotency = {};
  final List<CommunityEventEnvelope> _events = [];

  @override
  Future<CommunityEventEnvelope> publish({
    required String type,
    required String sourceComponent,
    required String subjectId,
    required Map<String, String> payload,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final event = CommunityEventEnvelope(
      eventId: 'event_${_events.length + 1}',
      type: type,
      sourceComponent: sourceComponent,
      subjectId: subjectId,
      version: 1,
      payload: Map<String, String>.unmodifiable(payload),
      createdAt: _clock,
    );
    _events.add(event);
    _byIdempotency[idempotencyKey] = event;
    return event;
  }

  @override
  Future<List<CommunityEventEnvelope>> replay({
    required String type,
  }) async {
    return _events
        .where((event) => event.type == type)
        .toList(growable: false);
  }
}

class CommunityKeyManagementFake implements CommunityKeyManagementApi {
  CommunityKeyManagementFake(this._clock);

  final DateTime _clock;
  final Map<String, CommunitySigningKey> _keys = {};
  final Map<String, CommunitySigningKey> _byIdempotency = {};

  @override
  Future<CommunitySigningKey> issueSigningKey({
    required String ownerId,
    required String scope,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final key = CommunitySigningKey(
      keyId: 'key_${_keys.length + 1}',
      ownerId: ownerId,
      scope: scope,
      version: 1,
      createdAt: _clock,
    );
    _keys[key.keyId] = key;
    _byIdempotency[idempotencyKey] = key;
    return key;
  }

  @override
  Future<bool> verifyScope({
    required String keyId,
    required String scope,
  }) async {
    return _keys[keyId]?.scope == scope;
  }
}

class CommunityBuilderAppIdFake implements CommunityBuilderAppIdApi {
  CommunityBuilderAppIdFake(this._keys, this._audit);

  final CommunityKeyManagementApi _keys;
  final CommunityAuditApi _audit;
  final Map<String, CommunityBuilderApp> _apps = {};
  final Map<String, CommunityBuilderApp> _byIdempotency = {};

  @override
  Future<CommunityBuilderApp> registerBuilderApp({
    required String builderId,
    required String signingScope,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final key = await _keys.issueSigningKey(
      ownerId: builderId,
      scope: signingScope,
      idempotencyKey: 'key_$idempotencyKey',
    );
    final audit = await _audit.appendAudit(
      actorId: builderId,
      componentId: 'builder-app-id-service',
      action: 'builder-app.register',
      redacted: false,
      idempotencyKey: 'audit_$idempotencyKey',
    );
    final app = CommunityBuilderApp(
      appId: 'builder_app_${_apps.length + 1}',
      builderId: builderId,
      signingScope: signingScope,
      keyId: key.keyId,
      version: 1,
      auditId: audit.auditId,
    );
    _apps[app.appId] = app;
    _byIdempotency[idempotencyKey] = app;
    return app;
  }

  @override
  Future<bool> verifySigningScope({
    required String appId,
    required String signingScope,
  }) async {
    final app = _apps[appId];
    if (app == null || app.signingScope != signingScope) {
      return false;
    }
    return _keys.verifyScope(keyId: app.keyId, scope: signingScope);
  }
}
