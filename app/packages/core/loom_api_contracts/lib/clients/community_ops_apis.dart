enum CommunityCaseStatus { open, inProgress, blocked, resolved }

enum CommunityDocumentVisibility { public, members, restricted }

enum CommunityReservationStatus { held, confirmed, cancelled }

enum CommunityModerationStatus { open, escalated, resolved }

enum CommunityIncidentSeverity { low, medium, high, critical }

class CommunityCaseTask {
  const CommunityCaseTask({
    required this.caseId,
    required this.communityId,
    required this.title,
    required this.status,
    required this.assigneePassportId,
    required this.version,
  });

  final String caseId;
  final String communityId;
  final String title;
  final CommunityCaseStatus status;
  final String? assigneePassportId;
  final int version;
}

class CommunityDocument {
  const CommunityDocument({
    required this.documentId,
    required this.communityId,
    required this.title,
    required this.body,
    required this.visibility,
    required this.version,
  });

  final String documentId;
  final String communityId;
  final String title;
  final String body;
  final CommunityDocumentVisibility visibility;
  final int version;
}

class CommunityFacilityReservation {
  const CommunityFacilityReservation({
    required this.reservationId,
    required this.communityId,
    required this.facilityId,
    required this.passportId,
    required this.status,
    required this.amountCents,
    required this.version,
  });

  final String reservationId;
  final String communityId;
  final String facilityId;
  final String passportId;
  final CommunityReservationStatus status;
  final int amountCents;
  final int version;
}

class CommunityImportPreview {
  const CommunityImportPreview({
    required this.importId,
    required this.sourceKind,
    required this.recordCount,
    required this.sensitiveFieldCount,
    required this.warnings,
  });

  final String importId;
  final String sourceKind;
  final int recordCount;
  final int sensitiveFieldCount;
  final List<String> warnings;
}

class CommunityImportResult {
  const CommunityImportResult({
    required this.importId,
    required this.committedRecords,
    required this.protectedRecordIds,
    required this.version,
  });

  final String importId;
  final int committedRecords;
  final List<String> protectedRecordIds;
  final int version;
}

class CommunityExportBundle {
  const CommunityExportBundle({
    required this.exportId,
    required this.communityId,
    required this.componentIds,
    required this.documentIds,
    required this.redacted,
    required this.checksum,
    required this.version,
  });

  final String exportId;
  final String communityId;
  final List<String> componentIds;
  final List<String> documentIds;
  final bool redacted;
  final String checksum;
  final int version;
}

class CommunityProviderTransfer {
  const CommunityProviderTransfer({
    required this.transferId,
    required this.communityId,
    required this.exportId,
    required this.targetProviderId,
    required this.verified,
    required this.rolledBack,
    required this.version,
  });

  final String transferId;
  final String communityId;
  final String exportId;
  final String targetProviderId;
  final bool verified;
  final bool rolledBack;
  final int version;
}

class CommunityAbuseReport {
  const CommunityAbuseReport({
    required this.reportId,
    required this.communityId,
    required this.reporterPassportId,
    required this.subjectId,
    required this.category,
    required this.redacted,
    required this.version,
  });

  final String reportId;
  final String communityId;
  final String reporterPassportId;
  final String subjectId;
  final String category;
  final bool redacted;
  final int version;
}

class CommunityModerationCase {
  const CommunityModerationCase({
    required this.moderationCaseId,
    required this.reportId,
    required this.status,
    required this.policyVersion,
    required this.version,
  });

  final String moderationCaseId;
  final String reportId;
  final CommunityModerationStatus status;
  final String policyVersion;
  final int version;
}

class CommunityIncidentRecord {
  const CommunityIncidentRecord({
    required this.incidentId,
    required this.communityId,
    required this.subjectId,
    required this.severity,
    required this.certificationAction,
    required this.version,
  });

  final String incidentId;
  final String communityId;
  final String subjectId;
  final CommunityIncidentSeverity severity;
  final String? certificationAction;
  final int version;
}

class CommunityDisputeCase {
  const CommunityDisputeCase({
    required this.disputeId,
    required this.communityId,
    required this.subjectId,
    required this.reason,
    required this.status,
    required this.version,
  });

  final String disputeId;
  final String communityId;
  final String subjectId;
  final String reason;
  final CommunityModerationStatus status;
  final int version;
}

abstract class CommunityCaseTaskApi {
  Future<CommunityCaseTask> openCase({
    required String communityId,
    required String title,
    required String? assigneePassportId,
    required String idempotencyKey,
  });

  Future<CommunityCaseTask> transitionCase({
    required String caseId,
    required CommunityCaseStatus status,
    required String actorPassportId,
    required String idempotencyKey,
  });

  Future<List<CommunityCaseTask>> listCases(String communityId);
}

abstract class CommunityDocumentsApi {
  Future<CommunityDocument> uploadDocument({
    required String communityId,
    required String title,
    required String body,
    required CommunityDocumentVisibility visibility,
    required String actorPassportId,
    required String idempotencyKey,
  });

  Future<List<CommunityDocument>> visibleDocuments({
    required String communityId,
    required String actorPassportId,
    required bool includeRestricted,
  });
}

abstract class CommunityFacilitiesApi {
  Future<CommunityFacilityReservation> reserveFacility({
    required String communityId,
    required String facilityId,
    required String passportId,
    required int amountCents,
    required String idempotencyKey,
  });

  Future<List<CommunityFacilityReservation>> listReservations(
    String communityId,
  );
}

abstract class CommunityImportApi {
  Future<CommunityImportPreview> dryRun({
    required String sourceKind,
    required List<Map<String, String>> records,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  });

  Future<CommunityImportResult> commit({
    required String communityId,
    required String passportId,
    required List<Map<String, String>> records,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  });
}

abstract class CommunityExportApi {
  Future<CommunityExportBundle> assemble({
    required String communityId,
    required bool redactProtectedData,
    required String idempotencyKey,
  });
}

abstract class CommunityProviderTransferApi {
  Future<CommunityProviderTransfer> executeTransfer({
    required String communityId,
    required String exportId,
    required String targetProviderId,
    required String idempotencyKey,
  });

  Future<CommunityProviderTransfer> verifyTransfer({
    required String transferId,
    required String idempotencyKey,
  });

  Future<CommunityProviderTransfer> rollbackTransfer({
    required String transferId,
    required String reason,
    required String idempotencyKey,
  });
}

abstract class CommunityAbuseReportApi {
  Future<CommunityAbuseReport> submitReport({
    required String communityId,
    required String reporterPassportId,
    required String subjectId,
    required String category,
    required String details,
    required String idempotencyKey,
  });
}

abstract class CommunityModerationApi {
  Future<CommunityModerationCase> openModerationCase({
    required String reportId,
    required String policyVersion,
    required String idempotencyKey,
  });

  Future<CommunityModerationCase> transitionModerationCase({
    required String moderationCaseId,
    required CommunityModerationStatus status,
    required String idempotencyKey,
  });
}

abstract class CommunityIncidentApi {
  Future<CommunityIncidentRecord> createIncident({
    required String communityId,
    required String subjectId,
    required CommunityIncidentSeverity severity,
    required String? targetPackageId,
    required String idempotencyKey,
  });
}

abstract class CommunityDisputeApi {
  Future<CommunityDisputeCase> openDispute({
    required String communityId,
    required String subjectId,
    required String reason,
    required String idempotencyKey,
  });
}
