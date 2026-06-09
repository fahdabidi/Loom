enum CommunityConnectionState { invited, connected, blocked }

enum CommunityProtectedVisibility { ownerOnly, permissionGated }

class CommunityPassport {
  const CommunityPassport({
    required this.passportId,
    required this.displayName,
    required this.version,
    required this.createdAt,
    required this.auditId,
  });

  final String passportId;
  final String displayName;
  final int version;
  final DateTime createdAt;
  final String auditId;
}

class CommunityPermissionDecision {
  const CommunityPermissionDecision({
    required this.actorId,
    required this.communityId,
    required this.permission,
    required this.allowed,
    required this.reason,
    required this.version,
  });

  final String actorId;
  final String communityId;
  final String permission;
  final bool allowed;
  final String reason;
  final int version;
}

class CommunityPreferenceRecord {
  const CommunityPreferenceRecord({
    required this.passportId,
    required this.key,
    required this.value,
    required this.version,
    required this.updatedAt,
  });

  final String passportId;
  final String key;
  final String value;
  final int version;
  final DateTime updatedAt;
}

class CommunityProtectedRecord {
  const CommunityProtectedRecord({
    required this.recordId,
    required this.passportId,
    required this.field,
    required this.redactedValue,
    required this.visibility,
    required this.version,
    required this.auditId,
  });

  final String recordId;
  final String passportId;
  final String field;
  final String redactedValue;
  final CommunityProtectedVisibility visibility;
  final int version;
  final String auditId;
}

class CommunityConnectionRecord {
  const CommunityConnectionRecord({
    required this.connectionId,
    required this.requesterPassportId,
    required this.targetPassportId,
    required this.state,
    required this.version,
    required this.auditId,
  });

  final String connectionId;
  final String requesterPassportId;
  final String targetPassportId;
  final CommunityConnectionState state;
  final int version;
  final String auditId;
}

class CommunityReceiptRecord {
  const CommunityReceiptRecord({
    required this.receiptId,
    required this.passportId,
    required this.kind,
    required this.amountCents,
    required this.currency,
    required this.summary,
    required this.version,
    required this.createdAt,
  });

  final String receiptId;
  final String passportId;
  final String kind;
  final int amountCents;
  final String currency;
  final String summary;
  final int version;
  final DateTime createdAt;
}

class CommunityAuditEntry {
  const CommunityAuditEntry({
    required this.auditId,
    required this.actorId,
    required this.componentId,
    required this.action,
    required this.redacted,
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String auditId;
  final String actorId;
  final String componentId;
  final String action;
  final bool redacted;
  final String idempotencyKey;
  final DateTime createdAt;
}

class CommunityEventEnvelope {
  const CommunityEventEnvelope({
    required this.eventId,
    required this.type,
    required this.sourceComponent,
    required this.subjectId,
    required this.version,
    required this.payload,
    required this.createdAt,
  });

  final String eventId;
  final String type;
  final String sourceComponent;
  final String subjectId;
  final int version;
  final Map<String, String> payload;
  final DateTime createdAt;
}

class CommunitySigningKey {
  const CommunitySigningKey({
    required this.keyId,
    required this.ownerId,
    required this.scope,
    required this.version,
    required this.createdAt,
  });

  final String keyId;
  final String ownerId;
  final String scope;
  final int version;
  final DateTime createdAt;
}

class CommunityBuilderApp {
  const CommunityBuilderApp({
    required this.appId,
    required this.builderId,
    required this.signingScope,
    required this.keyId,
    required this.version,
    required this.auditId,
  });

  final String appId;
  final String builderId;
  final String signingScope;
  final String keyId;
  final int version;
  final String auditId;
}

abstract class CommunityPassportApi {
  Future<CommunityPassport> createPassport({
    required String displayName,
    required String actorId,
    required String idempotencyKey,
  });

  Future<CommunityPassport?> resolvePassport(String passportId);
}

abstract class CommunityRolePolicyApi {
  Future<CommunityPermissionDecision> grantPermission({
    required String actorId,
    required String communityId,
    required String permission,
    required String grantedBy,
    required String idempotencyKey,
  });

  Future<CommunityPermissionDecision> effectivePermission({
    required String actorId,
    required String communityId,
    required String permission,
  });
}

abstract class CommunityCoreVaultApi {
  Future<CommunityPreferenceRecord> setPreference({
    required String passportId,
    required String key,
    required String value,
    required String idempotencyKey,
  });

  Future<CommunityPreferenceRecord?> getPreference({
    required String passportId,
    required String key,
  });
}

abstract class CommunityProtectedVaultApi {
  Future<CommunityProtectedRecord> writeProtectedRecord({
    required String passportId,
    required String field,
    required String value,
    required CommunityProtectedVisibility visibility,
    required String actorId,
    required String idempotencyKey,
  });

  Future<CommunityProtectedRecord?> readProtectedRecord({
    required String recordId,
    required String actorId,
    required String communityId,
    required String requiredPermission,
  });
}

abstract class CommunityConnectionsApi {
  Future<CommunityConnectionRecord> invite({
    required String requesterPassportId,
    required String targetPassportId,
    required String idempotencyKey,
  });

  Future<CommunityConnectionRecord> block({
    required String requesterPassportId,
    required String targetPassportId,
    required String idempotencyKey,
  });

  Future<bool> canInvite({
    required String requesterPassportId,
    required String targetPassportId,
  });
}

abstract class CommunityReceiptLedgerApi {
  Future<CommunityReceiptRecord> appendReceipt({
    required String passportId,
    required String kind,
    required int amountCents,
    required String currency,
    required String summary,
    required String idempotencyKey,
  });

  Future<List<CommunityReceiptRecord>> listReceipts(String passportId);
}

abstract class CommunityAuditApi {
  Future<CommunityAuditEntry> appendAudit({
    required String actorId,
    required String componentId,
    required String action,
    required bool redacted,
    required String idempotencyKey,
  });

  Future<List<CommunityAuditEntry>> listAudit({
    required String componentId,
  });
}

abstract class CommunityEventBusApi {
  Future<CommunityEventEnvelope> publish({
    required String type,
    required String sourceComponent,
    required String subjectId,
    required Map<String, String> payload,
    required String idempotencyKey,
  });

  Future<List<CommunityEventEnvelope>> replay({
    required String type,
  });
}

abstract class CommunityKeyManagementApi {
  Future<CommunitySigningKey> issueSigningKey({
    required String ownerId,
    required String scope,
    required String idempotencyKey,
  });

  Future<bool> verifyScope({
    required String keyId,
    required String scope,
  });
}

abstract class CommunityBuilderAppIdApi {
  Future<CommunityBuilderApp> registerBuilderApp({
    required String builderId,
    required String signingScope,
    required String idempotencyKey,
  });

  Future<bool> verifySigningScope({
    required String appId,
    required String signingScope,
  });
}
