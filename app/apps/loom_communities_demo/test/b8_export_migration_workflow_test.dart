import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_export-migration', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'portability-demo',
      displayName: 'Portability Demo Community',
      category: 'platform',
      extensionId: 'ext_export_migration',
      cardAssetId: 'asset_card_export_migration',
      logoAssetId: 'asset_logo_export_migration',
      accentColor: '#536878',
    );
    await harness.grant('documents.write');
    await harness.grant('protected.read');

    final document = await harness.ops.documents.uploadDocument(
      communityId: harness.communityId,
      title: 'Exportable community handbook',
      body: 'This handbook should be included in member export.',
      visibility: CommunityDocumentVisibility.members,
      actorPassportId: harness.ownerId,
      idempotencyKey: 'b8-export-document',
    );
    final payment = await harness.economic.wallet.recordPayment(
      communityId: harness.communityId,
      passportId: harness.memberId,
      kind: CommunityPaymentKind.dues,
      amountCents: 2500,
      idempotencyKey: 'b8-export-payment',
    );
    final schema = await harness.engine.dataSchemas.registerSchema(
      extensionId: 'ext_export_migration',
      schemaId: 'custom_member_note',
      indexableFields: const ['title'],
      exportable: true,
      idempotencyKey: 'b8-schema-exportable',
    );
    await harness.engine.dataSchemas.registerSchema(
      extensionId: 'ext_export_migration',
      schemaId: 'runtime_cache',
      indexableFields: const [],
      exportable: false,
      idempotencyKey: 'b8-schema-private',
    );
    final exportableSchemas = await harness.engine.dataSchemas.exportableSchemas(
      'ext_export_migration',
    );

    final preview = await harness.ops.imports.dryRun(
      sourceKind: 'legacy-csv',
      records: const [
        {'name': 'Aisha', 'phone': '555-0101'},
      ],
      sensitiveFields: const ['phone'],
      idempotencyKey: 'b8-import-preview',
    );
    final importResult = await harness.ops.imports.commit(
      communityId: harness.communityId,
      passportId: harness.memberId,
      records: const [
        {'name': 'Aisha', 'phone': '555-0101'},
      ],
      sensitiveFields: const ['phone'],
      idempotencyKey: 'b8-import-commit',
    );
    final replayedImport = await harness.ops.imports.commit(
      communityId: harness.communityId,
      passportId: harness.memberId,
      records: const [
        {'name': 'Aisha', 'phone': '555-0101'},
      ],
      sensitiveFields: const ['phone'],
      idempotencyKey: 'b8-import-commit',
    );
    final protectedImport = await harness.foundation.protectedVault
        .readProtectedRecord(
          recordId: importResult.protectedRecordIds.single,
          actorId: harness.ownerId,
          communityId: harness.communityId,
          requiredPermission: 'protected.read',
        );

    final fullExport = await harness.ops.exports.assemble(
      communityId: harness.communityId,
      redactProtectedData: false,
      idempotencyKey: 'b8-full-export',
    );
    final redactedExport = await harness.ops.exports.assemble(
      communityId: harness.communityId,
      redactProtectedData: true,
      idempotencyKey: 'b8-redacted-export',
    );
    final transfer = await harness.ops.providerTransfers.executeTransfer(
      communityId: harness.communityId,
      exportId: redactedExport.exportId,
      targetProviderId: 'provider_portable',
      idempotencyKey: 'b8-transfer-execute',
    );
    final verified = await harness.ops.providerTransfers.verifyTransfer(
      transferId: transfer.transferId,
      idempotencyKey: 'b8-transfer-verify',
    );
    final rollbackTransfer = await harness.ops.providerTransfers.executeTransfer(
      communityId: harness.communityId,
      exportId: redactedExport.exportId,
      targetProviderId: 'provider_rollback',
      idempotencyKey: 'b8-transfer-for-rollback',
    );
    final rolledBack = await harness.ops.providerTransfers.rollbackTransfer(
      transferId: rollbackTransfer.transferId,
      reason: 'target checksum mismatch',
      idempotencyKey: 'b8-transfer-rollback',
    );
    final receipts = await harness.foundation.receiptLedger.listReceipts(
      harness.memberId,
    );
    harness.shell.openExtension('local:ext_export_migration@latest');

    expect(preview.sensitiveFieldCount, 1);
    expect(importResult.protectedRecordIds, hasLength(1));
    expect(replayedImport.importId, importResult.importId);
    expect(protectedImport?.redactedValue, startsWith('5'));
    expect(exportableSchemas.single.schemaId, schema.schemaId);
    expect(fullExport.documentIds, contains(document.documentId));
    expect(fullExport.redacted, isFalse);
    expect(fullExport.checksum, isNotEmpty);
    expect(redactedExport.redacted, isTrue);
    expect(
      redactedExport.componentIds,
      contains('protected-visibility-vault:redacted'),
    );
    expect(redactedExport.componentIds, contains('wallet-dues-donations'));
    expect(redactedExport.componentIds, contains('receipt-ledger'));
    expect(receipts.single.receiptId, payment.receiptId);
    expect(verified.verified, isTrue);
    expect(verified.rolledBack, isFalse);
    expect(rolledBack.verified, isFalse);
    expect(rolledBack.rolledBack, isTrue);
    expect(harness.shell.openExtensionId, 'local:ext_export_migration@latest');
  });
}
