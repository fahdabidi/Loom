import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'community_experience_fake.dart';
import 'community_foundation_fake.dart';
import 'community_registry_fake.dart';

class CommunityOpsServicesFakeBackend {
  CommunityOpsServicesFakeBackend({
    required this.foundation,
    required this.registry,
    required this.experience,
  }) {
    caseTasks = CommunityCaseTaskFake(foundation.eventBus);
    documents = CommunityDocumentsFake(foundation.rolePolicy);
    facilities = CommunityFacilitiesFake(foundation.eventBus);
    imports = CommunityImportFake(foundation.protectedVault);
    exports = CommunityExportFake(documents);
    providerTransfers = CommunityProviderTransferFake(exports);
    abuseReports = CommunityAbuseReportFake(foundation.audit);
    moderation = CommunityModerationFake();
    incidents = CommunityIncidentFake(foundation.eventBus);
    disputes = CommunityDisputeFake(foundation.eventBus);
  }

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;

  late final CommunityCaseTaskFake caseTasks;
  late final CommunityDocumentsFake documents;
  late final CommunityFacilitiesFake facilities;
  late final CommunityImportFake imports;
  late final CommunityExportFake exports;
  late final CommunityProviderTransferFake providerTransfers;
  late final CommunityAbuseReportFake abuseReports;
  late final CommunityModerationFake moderation;
  late final CommunityIncidentFake incidents;
  late final CommunityDisputeFake disputes;
}

class CommunityCaseTaskFake implements CommunityCaseTaskApi {
  CommunityCaseTaskFake(this._events);

  final CommunityEventBusApi _events;
  final Map<String, CommunityCaseTask> _cases = {};
  final Map<String, CommunityCaseTask> _byIdempotency = {};

  @override
  Future<CommunityCaseTask> openCase({
    required String communityId,
    required String title,
    required String? assigneePassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final task = CommunityCaseTask(
      caseId: 'case_${_cases.length + 1}',
      communityId: communityId,
      title: title,
      status: CommunityCaseStatus.open,
      assigneePassportId: assigneePassportId,
      version: 1,
    );
    _cases[task.caseId] = task;
    _byIdempotency[idempotencyKey] = task;
    await _events.publish(
      type: 'community.case.opened',
      sourceComponent: 'case-task-service',
      subjectId: task.caseId,
      payload: {'communityId': communityId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return task;
  }

  @override
  Future<CommunityCaseTask> transitionCase({
    required String caseId,
    required CommunityCaseStatus status,
    required String actorPassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final current = _cases[caseId];
    if (current == null) {
      throw StateError('unknown case: $caseId');
    }
    final updated = CommunityCaseTask(
      caseId: current.caseId,
      communityId: current.communityId,
      title: current.title,
      status: status,
      assigneePassportId: current.assigneePassportId,
      version: current.version + 1,
    );
    _cases[caseId] = updated;
    _byIdempotency[idempotencyKey] = updated;
    await _events.publish(
      type: 'community.case.transitioned',
      sourceComponent: 'case-task-service',
      subjectId: caseId,
      payload: {'status': status.name, 'actor': actorPassportId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return updated;
  }

  @override
  Future<List<CommunityCaseTask>> listCases(String communityId) async {
    return _cases.values
        .where((task) => task.communityId == communityId)
        .toList(growable: false);
  }
}

class CommunityDocumentsFake implements CommunityDocumentsApi {
  CommunityDocumentsFake(this._policy);

  final CommunityRolePolicyApi _policy;
  final Map<String, CommunityDocument> _documents = {};
  final Map<String, CommunityDocument> _byIdempotency = {};

  @override
  Future<CommunityDocument> uploadDocument({
    required String communityId,
    required String title,
    required String body,
    required CommunityDocumentVisibility visibility,
    required String actorPassportId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final decision = await _policy.effectivePermission(
      actorId: actorPassportId,
      communityId: communityId,
      permission: 'documents.write',
    );
    if (!decision.allowed) {
      throw StateError('missing documents.write');
    }
    final document = CommunityDocument(
      documentId: 'document_${_documents.length + 1}',
      communityId: communityId,
      title: title,
      body: body,
      visibility: visibility,
      version: 1,
    );
    _documents[document.documentId] = document;
    _byIdempotency[idempotencyKey] = document;
    return document;
  }

  @override
  Future<List<CommunityDocument>> visibleDocuments({
    required String communityId,
    required String actorPassportId,
    required bool includeRestricted,
  }) async {
    final decision = await _policy.effectivePermission(
      actorId: actorPassportId,
      communityId: communityId,
      permission: 'documents.restricted.read',
    );
    return _documents.values.where((document) {
      final sameCommunity = document.communityId == communityId;
      final visible =
          document.visibility != CommunityDocumentVisibility.restricted ||
          (includeRestricted && decision.allowed);
      return sameCommunity && visible;
    }).toList(growable: false);
  }
}

class CommunityFacilitiesFake implements CommunityFacilitiesApi {
  CommunityFacilitiesFake(this._events);

  final CommunityEventBusApi _events;
  final Map<String, CommunityFacilityReservation> _reservations = {};
  final Map<String, CommunityFacilityReservation> _byIdempotency = {};

  @override
  Future<CommunityFacilityReservation> reserveFacility({
    required String communityId,
    required String facilityId,
    required String passportId,
    required int amountCents,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final reservation = CommunityFacilityReservation(
      reservationId: 'reservation_${_reservations.length + 1}',
      communityId: communityId,
      facilityId: facilityId,
      passportId: passportId,
      status: amountCents > 0
          ? CommunityReservationStatus.held
          : CommunityReservationStatus.confirmed,
      amountCents: amountCents,
      version: 1,
    );
    _reservations[reservation.reservationId] = reservation;
    _byIdempotency[idempotencyKey] = reservation;
    await _events.publish(
      type: 'community.facility.reserved',
      sourceComponent: 'facilities-service',
      subjectId: reservation.reservationId,
      payload: {'communityId': communityId, 'facilityId': facilityId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return reservation;
  }

  @override
  Future<List<CommunityFacilityReservation>> listReservations(
    String communityId,
  ) async {
    return _reservations.values
        .where((reservation) => reservation.communityId == communityId)
        .toList(growable: false);
  }
}

class CommunityImportFake implements CommunityImportApi {
  CommunityImportFake(this._protectedVault);

  final CommunityProtectedVaultApi _protectedVault;
  final Map<String, CommunityImportPreview> _previews = {};
  final Map<String, CommunityImportResult> _commits = {};

  @override
  Future<CommunityImportPreview> dryRun({
    required String sourceKind,
    required List<Map<String, String>> records,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  }) async {
    final existing = _previews[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final preview = CommunityImportPreview(
      importId: 'import_${_previews.length + 1}',
      sourceKind: sourceKind,
      recordCount: records.length,
      sensitiveFieldCount: sensitiveFields.length,
      warnings: records.isEmpty ? const ['empty import'] : const [],
    );
    _previews[idempotencyKey] = preview;
    return preview;
  }

  @override
  Future<CommunityImportResult> commit({
    required String communityId,
    required String passportId,
    required List<Map<String, String>> records,
    required List<String> sensitiveFields,
    required String idempotencyKey,
  }) async {
    final existing = _commits[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final protectedIds = <String>[];
    for (var recordIndex = 0; recordIndex < records.length; recordIndex += 1) {
      final record = records[recordIndex];
      for (final field in sensitiveFields) {
        final value = record[field];
        if (value == null) {
          continue;
        }
        final protected = await _protectedVault.writeProtectedRecord(
          passportId: passportId,
          field: field,
          value: value,
          visibility: CommunityProtectedVisibility.permissionGated,
          actorId: passportId,
          idempotencyKey: 'import_${idempotencyKey}_${recordIndex}_$field',
        );
        protectedIds.add(protected.recordId);
      }
    }
    final result = CommunityImportResult(
      importId: 'import_commit_${_commits.length + 1}',
      committedRecords: records.length,
      protectedRecordIds: List<String>.unmodifiable(protectedIds),
      version: 1,
    );
    _commits[idempotencyKey] = result;
    return result;
  }
}

class CommunityExportFake implements CommunityExportApi {
  CommunityExportFake(this._documents);

  final CommunityDocumentsApi _documents;
  final Map<String, CommunityExportBundle> _byIdempotency = {};

  @override
  Future<CommunityExportBundle> assemble({
    required String communityId,
    required bool redactProtectedData,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final documents = await _documents.visibleDocuments(
      communityId: communityId,
      actorPassportId: 'export-service',
      includeRestricted: false,
    );
    final componentIds = <String>[
      'community-registry',
      'case-task-service',
      'documents-service',
      'facilities-service',
      'import-service',
      'export-service',
      'wallet-dues-donations',
      'receipt-ledger',
    ];
    if (redactProtectedData) {
      componentIds.add('protected-visibility-vault:redacted');
    }
    final bundle = CommunityExportBundle(
      exportId: 'export_${_byIdempotency.length + 1}',
      communityId: communityId,
      componentIds: List<String>.unmodifiable(componentIds),
      documentIds: documents.map((document) => document.documentId).toList(
        growable: false,
      ),
      redacted: redactProtectedData,
      checksum: 'checksum_${communityId}_${documents.length}_${redactProtectedData ? 'r' : 'full'}',
      version: 1,
    );
    _byIdempotency[idempotencyKey] = bundle;
    return bundle;
  }
}

class CommunityProviderTransferFake implements CommunityProviderTransferApi {
  CommunityProviderTransferFake(this._exports);

  final CommunityExportApi _exports;
  final Map<String, CommunityProviderTransfer> _transfers = {};
  final Map<String, CommunityProviderTransfer> _byIdempotency = {};

  @override
  Future<CommunityProviderTransfer> executeTransfer({
    required String communityId,
    required String exportId,
    required String targetProviderId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    await _exports.assemble(
      communityId: communityId,
      redactProtectedData: true,
      idempotencyKey: 'transfer_export_$idempotencyKey',
    );
    final transfer = CommunityProviderTransfer(
      transferId: 'transfer_${_transfers.length + 1}',
      communityId: communityId,
      exportId: exportId,
      targetProviderId: targetProviderId,
      verified: false,
      rolledBack: false,
      version: 1,
    );
    _transfers[transfer.transferId] = transfer;
    _byIdempotency[idempotencyKey] = transfer;
    return transfer;
  }

  @override
  Future<CommunityProviderTransfer> verifyTransfer({
    required String transferId,
    required String idempotencyKey,
  }) async {
    final current = _transfers[transferId];
    if (current == null) {
      throw StateError('unknown transfer: $transferId');
    }
    final verified = CommunityProviderTransfer(
      transferId: current.transferId,
      communityId: current.communityId,
      exportId: current.exportId,
      targetProviderId: current.targetProviderId,
      verified: true,
      rolledBack: false,
      version: current.version + 1,
    );
    _transfers[transferId] = verified;
    return verified;
  }

  @override
  Future<CommunityProviderTransfer> rollbackTransfer({
    required String transferId,
    required String reason,
    required String idempotencyKey,
  }) async {
    final current = _transfers[transferId];
    if (current == null) {
      throw StateError('unknown transfer: $transferId');
    }
    final rolledBack = CommunityProviderTransfer(
      transferId: current.transferId,
      communityId: current.communityId,
      exportId: current.exportId,
      targetProviderId: current.targetProviderId,
      verified: false,
      rolledBack: true,
      version: current.version + 1,
    );
    _transfers[transferId] = rolledBack;
    return rolledBack;
  }
}

class CommunityAbuseReportFake implements CommunityAbuseReportApi {
  CommunityAbuseReportFake(this._audit);

  final CommunityAuditApi _audit;
  final Map<String, CommunityAbuseReport> _reports = {};
  final Map<String, CommunityAbuseReport> _byIdempotency = {};

  @override
  Future<CommunityAbuseReport> submitReport({
    required String communityId,
    required String reporterPassportId,
    required String subjectId,
    required String category,
    required String details,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final audit = await _audit.appendAudit(
      actorId: reporterPassportId,
      componentId: 'abuse-report-service',
      action: 'abuse.report.$category',
      redacted: true,
      idempotencyKey: 'audit_$idempotencyKey',
    );
    final report = CommunityAbuseReport(
      reportId: 'abuse_${_reports.length + 1}',
      communityId: communityId,
      reporterPassportId: reporterPassportId,
      subjectId: subjectId,
      category: category,
      redacted: audit.redacted && details.isNotEmpty,
      version: 1,
    );
    _reports[report.reportId] = report;
    _byIdempotency[idempotencyKey] = report;
    return report;
  }
}

class CommunityModerationFake implements CommunityModerationApi {
  final Map<String, CommunityModerationCase> _cases = {};
  final Map<String, CommunityModerationCase> _byIdempotency = {};

  @override
  Future<CommunityModerationCase> openModerationCase({
    required String reportId,
    required String policyVersion,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final moderationCase = CommunityModerationCase(
      moderationCaseId: 'moderation_${_cases.length + 1}',
      reportId: reportId,
      status: CommunityModerationStatus.open,
      policyVersion: policyVersion,
      version: 1,
    );
    _cases[moderationCase.moderationCaseId] = moderationCase;
    _byIdempotency[idempotencyKey] = moderationCase;
    return moderationCase;
  }

  @override
  Future<CommunityModerationCase> transitionModerationCase({
    required String moderationCaseId,
    required CommunityModerationStatus status,
    required String idempotencyKey,
  }) async {
    final current = _cases[moderationCaseId];
    if (current == null) {
      throw StateError('unknown moderation case: $moderationCaseId');
    }
    final updated = CommunityModerationCase(
      moderationCaseId: current.moderationCaseId,
      reportId: current.reportId,
      status: status,
      policyVersion: current.policyVersion,
      version: current.version + 1,
    );
    _cases[moderationCaseId] = updated;
    return updated;
  }
}

class CommunityIncidentFake implements CommunityIncidentApi {
  CommunityIncidentFake(this._events);

  final CommunityEventBusApi _events;
  final Map<String, CommunityIncidentRecord> _incidents = {};
  final Map<String, CommunityIncidentRecord> _byIdempotency = {};

  @override
  Future<CommunityIncidentRecord> createIncident({
    required String communityId,
    required String subjectId,
    required CommunityIncidentSeverity severity,
    required String? targetPackageId,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final certificationAction =
        (targetPackageId != null &&
            (severity == CommunityIncidentSeverity.high ||
                severity == CommunityIncidentSeverity.critical))
        ? 'revoke:$targetPackageId'
        : null;
    final incident = CommunityIncidentRecord(
      incidentId: 'incident_${_incidents.length + 1}',
      communityId: communityId,
      subjectId: subjectId,
      severity: severity,
      certificationAction: certificationAction,
      version: 1,
    );
    _incidents[incident.incidentId] = incident;
    _byIdempotency[idempotencyKey] = incident;
    await _events.publish(
      type: 'community.incident.created',
      sourceComponent: 'incident-service',
      subjectId: incident.incidentId,
      payload: {
        'communityId': communityId,
        if (certificationAction != null) 'certificationAction': certificationAction,
      },
      idempotencyKey: 'event_$idempotencyKey',
    );
    return incident;
  }
}

class CommunityDisputeFake implements CommunityDisputeApi {
  CommunityDisputeFake(this._events);

  final CommunityEventBusApi _events;
  final Map<String, CommunityDisputeCase> _disputes = {};
  final Map<String, CommunityDisputeCase> _byIdempotency = {};

  @override
  Future<CommunityDisputeCase> openDispute({
    required String communityId,
    required String subjectId,
    required String reason,
    required String idempotencyKey,
  }) async {
    final existing = _byIdempotency[idempotencyKey];
    if (existing != null) {
      return existing;
    }
    final dispute = CommunityDisputeCase(
      disputeId: 'dispute_${_disputes.length + 1}',
      communityId: communityId,
      subjectId: subjectId,
      reason: reason,
      status: CommunityModerationStatus.open,
      version: 1,
    );
    _disputes[dispute.disputeId] = dispute;
    _byIdempotency[idempotencyKey] = dispute;
    await _events.publish(
      type: 'community.dispute.opened',
      sourceComponent: 'dispute-service',
      subjectId: dispute.disputeId,
      payload: {'communityId': communityId},
      idempotencyKey: 'event_$idempotencyKey',
    );
    return dispute;
  }
}
