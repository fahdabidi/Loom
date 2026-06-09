import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_fake_backend/loom_fake_backend.dart';
import 'package:loom_local_store/a4a_ops_store_schema.dart';
import 'package:loom_seed_data/community_experience_seed_data.dart';
import 'package:loom_seed_data/community_foundation_seed_data.dart';
import 'package:loom_seed_data/community_ops_seed_data.dart';
import 'package:loom_seed_data/community_registry_seed_data.dart';
import 'package:test/test.dart';

void main() {
  group('A4a ops/community validation tests', () {
    test('vt_case-task_transition', () async {
      final harness = await _harness();
      final opened = await harness.ops.caseTasks.openCase(
        communityId: harness.community.communityId,
        title: 'Approve clubhouse request',
        assigneePassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'case-open',
      );
      final transitioned = await harness.ops.caseTasks.transitionCase(
        caseId: opened.caseId,
        status: CommunityCaseStatus.resolved,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'case-resolve',
      );
      final events = await harness.foundation.eventBus.replay(
        type: 'community.case.transitioned',
      );

      expect(transitioned.status, CommunityCaseStatus.resolved);
      expect(transitioned.version, 2);
      expect(events.single.subjectId, opened.caseId);
    });

    test('vt_documents_permissions', () async {
      final harness = await _harnessWithDocumentWriter();
      await harness.ops.documents.uploadDocument(
        communityId: harness.community.communityId,
        title: communityOpsSeed.documentTitle,
        body: 'Member-facing operating notes.',
        visibility: CommunityDocumentVisibility.restricted,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'document-restricted',
      );
      final visibleWithoutGrant = await harness.ops.documents.visibleDocuments(
        communityId: harness.community.communityId,
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: true,
      );
      await harness.foundation.rolePolicy.grantPermission(
        actorId: communityFoundationSeed.memberPassportId,
        communityId: harness.community.communityId,
        permission: 'documents.restricted.read',
        grantedBy: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'grant-restricted-docs',
      );
      final visibleWithGrant = await harness.ops.documents.visibleDocuments(
        communityId: harness.community.communityId,
        actorPassportId: communityFoundationSeed.memberPassportId,
        includeRestricted: true,
      );

      expect(visibleWithoutGrant, isEmpty);
      expect(visibleWithGrant.single.title, communityOpsSeed.documentTitle);
      expect(
        A4aOpsStoreSchema.tables.map((table) => table.componentId),
        contains('documents-service'),
      );
    });

    test('vt_facilities_reservation', () async {
      final harness = await _harness();
      final reservation = await harness.ops.facilities.reserveFacility(
        communityId: harness.community.communityId,
        facilityId: communityOpsSeed.facilityId,
        passportId: communityFoundationSeed.memberPassportId,
        amountCents: 2500,
        idempotencyKey: 'reserve-clubhouse',
      );
      final all = await harness.ops.facilities.listReservations(
        harness.community.communityId,
      );

      expect(reservation.status, CommunityReservationStatus.held);
      expect(all.single.facilityId, communityOpsSeed.facilityId);
    });

    test('vt_import_dry-run', () async {
      final harness = await _harness();
      final preview = await harness.ops.imports.dryRun(
        sourceKind: communityOpsSeed.importSourceKind,
        records: _importRecords,
        sensitiveFields: const ['phone'],
        idempotencyKey: 'import-dry-run',
      );

      expect(preview.recordCount, _importRecords.length);
      expect(preview.sensitiveFieldCount, 1);
    });

    test('vt_import_commit', () async {
      final harness = await _harness();
      final result = await harness.ops.imports.commit(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        records: _importRecords,
        sensitiveFields: const ['phone'],
        idempotencyKey: 'import-commit',
      );

      expect(result.committedRecords, _importRecords.length);
      expect(result.protectedRecordIds, hasLength(_importRecords.length));
    });

    test('vt_export_assemble', () async {
      final harness = await _harnessWithDocumentWriter();
      final document = await harness.ops.documents.uploadDocument(
        communityId: harness.community.communityId,
        title: 'Exportable rules',
        body: 'Rules go here.',
        visibility: CommunityDocumentVisibility.members,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'document-exportable',
      );
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: false,
        idempotencyKey: 'export-assemble',
      );

      expect(bundle.documentIds, contains(document.documentId));
      expect(bundle.componentIds, contains('documents-service'));
      expect(bundle.redacted, isFalse);
    });

    test('vt_export_redaction', () async {
      final harness = await _harness();
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: true,
        idempotencyKey: 'export-redacted',
      );

      expect(bundle.redacted, isTrue);
      expect(bundle.componentIds, contains('protected-visibility-vault:redacted'));
    });

    test('vt_provider-transfer_execute-verify', () async {
      final harness = await _harness();
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: true,
        idempotencyKey: 'export-for-transfer',
      );
      final transfer = await harness.ops.providerTransfers.executeTransfer(
        communityId: harness.community.communityId,
        exportId: bundle.exportId,
        targetProviderId: communityOpsSeed.targetProviderId,
        idempotencyKey: 'transfer-execute',
      );
      final verified = await harness.ops.providerTransfers.verifyTransfer(
        transferId: transfer.transferId,
        idempotencyKey: 'transfer-verify',
      );

      expect(transfer.verified, isFalse);
      expect(transfer.rolledBack, isFalse);
      expect(verified.verified, isTrue);
      expect(verified.rolledBack, isFalse);
      expect(verified.version, 2);
    });

    test('vt_provider-transfer_rollback', () async {
      final harness = await _harness();
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: true,
        idempotencyKey: 'export-for-rollback',
      );
      final transfer = await harness.ops.providerTransfers.executeTransfer(
        communityId: harness.community.communityId,
        exportId: bundle.exportId,
        targetProviderId: communityOpsSeed.targetProviderId,
        idempotencyKey: 'transfer-rollback-execute',
      );
      final rolledBack = await harness.ops.providerTransfers.rollbackTransfer(
        transferId: transfer.transferId,
        reason: 'target verification failed',
        idempotencyKey: 'transfer-rollback',
      );

      expect(rolledBack.verified, isFalse);
      expect(rolledBack.rolledBack, isTrue);
      expect(rolledBack.version, 2);
    });

    test('vt_abuse-report_submit', () async {
      final harness = await _harness();
      final report = await harness.ops.abuseReports.submitReport(
        communityId: harness.community.communityId,
        reporterPassportId: communityFoundationSeed.memberPassportId,
        subjectId: 'post_unsafe',
        category: 'harassment',
        details: 'Sensitive report details.',
        idempotencyKey: 'abuse-report',
      );
      final audit = await harness.foundation.audit.listAudit(
        componentId: 'abuse-report-service',
      );

      expect(report.redacted, isTrue);
      expect(audit.single.redacted, isTrue);
    });

    test('vt_moderation_case-lifecycle', () async {
      final harness = await _harness();
      final report = await harness.ops.abuseReports.submitReport(
        communityId: harness.community.communityId,
        reporterPassportId: communityFoundationSeed.memberPassportId,
        subjectId: 'message_unsafe',
        category: 'spam',
        details: 'Spam details.',
        idempotencyKey: 'moderation-report',
      );
      final opened = await harness.ops.moderation.openModerationCase(
        reportId: report.reportId,
        policyVersion: communityOpsSeed.policyVersion,
        idempotencyKey: 'moderation-open',
      );
      final escalated = await harness.ops.moderation.transitionModerationCase(
        moderationCaseId: opened.moderationCaseId,
        status: CommunityModerationStatus.escalated,
        idempotencyKey: 'moderation-escalate',
      );

      expect(escalated.status, CommunityModerationStatus.escalated);
      expect(escalated.policyVersion, communityOpsSeed.policyVersion);
    });

    test('vt_incident_create', () async {
      final harness = await _harness();
      final incident = await harness.ops.incidents.createIncident(
        communityId: harness.community.communityId,
        subjectId: 'extension:${communityRegistrySeed.extensionId}',
        severity: CommunityIncidentSeverity.high,
        targetPackageId: communityOpsSeed.packageId,
        idempotencyKey: 'incident-create',
      );

      expect(incident.certificationAction, 'revoke:${communityOpsSeed.packageId}');
    });

    test('vt_dispute_open-case', () async {
      final harness = await _harness();
      final dispute = await harness.ops.disputes.openDispute(
        communityId: harness.community.communityId,
        subjectId: 'receipt_1',
        reason: 'duplicate charge',
        idempotencyKey: 'dispute-open',
      );
      final events = await harness.foundation.eventBus.replay(
        type: 'community.dispute.opened',
      );

      expect(dispute.status, CommunityModerationStatus.open);
      expect(events.single.subjectId, dispute.disputeId);
    });
  });

  group('A4a built-counterpart consumer contract tests', () {
    test('ct_documents__export_include-documents', () async {
      final harness = await _harnessWithDocumentWriter();
      final document = await harness.ops.documents.uploadDocument(
        communityId: harness.community.communityId,
        title: 'Export contract document',
        body: 'Included in bundle.',
        visibility: CommunityDocumentVisibility.members,
        actorPassportId: communityFoundationSeed.ownerActorId,
        idempotencyKey: 'contract-document-export',
      );
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: false,
        idempotencyKey: 'contract-export-documents',
      );

      expect(bundle.documentIds, contains(document.documentId));
    });

    test('ct_import__protected-vault_write', () async {
      final harness = await _harness();
      final result = await harness.ops.imports.commit(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        records: _importRecords,
        sensitiveFields: const ['phone'],
        idempotencyKey: 'contract-import-protected',
      );

      expect(result.protectedRecordIds, isNotEmpty);
      expect(
        () => harness.foundation.protectedVault.readProtectedRecord(
          recordId: result.protectedRecordIds.single,
          actorId: communityFoundationSeed.ownerActorId,
          communityId: harness.community.communityId,
          requiredPermission: 'protected.read',
        ),
        returnsNormally,
      );
    });

    test('ct_protected-vault__import-export_redaction', () async {
      final harness = await _harness();
      await harness.ops.imports.commit(
        communityId: harness.community.communityId,
        passportId: communityFoundationSeed.memberPassportId,
        records: _importRecords,
        sensitiveFields: const ['phone'],
        idempotencyKey: 'contract-import-redaction',
      );
      final bundle = await harness.ops.exports.assemble(
        communityId: harness.community.communityId,
        redactProtectedData: true,
        idempotencyKey: 'contract-export-redaction',
      );

      expect(bundle.redacted, isTrue);
      expect(bundle.componentIds, contains('protected-visibility-vault:redacted'));
    });

    test('ct_incident__certification_revoke', () async {
      final harness = await _harness();
      final incident = await harness.ops.incidents.createIncident(
        communityId: harness.community.communityId,
        subjectId: 'extension:${communityRegistrySeed.extensionId}',
        severity: CommunityIncidentSeverity.critical,
        targetPackageId: communityRegistrySeed.packageId,
        idempotencyKey: 'contract-incident-certification',
      );
      final events = await harness.foundation.eventBus.replay(
        type: 'community.incident.created',
      );

      expect(incident.certificationAction, 'revoke:${communityRegistrySeed.packageId}');
      expect(events.single.payload['certificationAction'], incident.certificationAction);
    });
  });

  group('A4a pending counterpart contract kits', () {
    test(
      'ct_case-task__workflow-engine_transition',
      () {},
      skip: 'workflow-engine is built in A5',
    );
    test(
      'ct_documents__search_index-visible-documents',
      () {},
      skip: 'search-service is built in A4b',
    );
    test(
      'ct_export__components_enumerate',
      () {},
      skip: 'data-schema-store is built in A5',
    );
    test(
      'ct_facilities__wallet_reservation-payment',
      () {},
      skip: 'wallet-dues-donations is built in A4b',
    );
    test(
      'ct_fraud__dispute_resolution-path',
      () {},
      skip: 'fraud-signal-service is built in A4b',
    );
  });
}

const _importRecords = [
  {'name': 'Nia', 'phone': '+1-555-0100'},
  {'name': 'Omar', 'phone': '+1-555-0101'},
];

Future<_OpsHarness> _harness() async {
  final foundation = CommunityFoundationFakeBackend();
  final registry = CommunityRegistryControlPlaneFakeBackend(foundation);
  final community = await registry.communityRegistry.registerCommunity(
    handle: communityRegistrySeed.handle,
    displayName: communityRegistrySeed.displayName,
    branding: CommunityBranding(
      logoAssetId: communityRegistrySeed.logoAssetId,
      cardImageAssetId: communityRegistrySeed.cardImageAssetId,
      accentColor: '#246B62',
      altText: 'Book club table',
    ),
    ownerPassportId: communityFoundationSeed.ownerActorId,
    idempotencyKey: 'a4a-register-community',
  );
  final experience = CommunityExperienceServicesFakeBackend(
    foundation: foundation,
    registry: registry,
  );
  final ops = CommunityOpsServicesFakeBackend(
    foundation: foundation,
    registry: registry,
    experience: experience,
  );
  return _OpsHarness(
    foundation: foundation,
    registry: registry,
    experience: experience,
    ops: ops,
    community: community,
  );
}

Future<_OpsHarness> _harnessWithDocumentWriter() async {
  final harness = await _harness();
  await harness.foundation.rolePolicy.grantPermission(
    actorId: communityFoundationSeed.ownerActorId,
    communityId: harness.community.communityId,
    permission: 'documents.write',
    grantedBy: 'system',
    idempotencyKey: 'grant-doc-write',
  );
  return harness;
}

class _OpsHarness {
  const _OpsHarness({
    required this.foundation,
    required this.registry,
    required this.experience,
    required this.ops,
    required this.community,
  });

  final CommunityFoundationFakeBackend foundation;
  final CommunityRegistryControlPlaneFakeBackend registry;
  final CommunityExperienceServicesFakeBackend experience;
  final CommunityOpsServicesFakeBackend ops;
  final CommunityProfile community;
}
