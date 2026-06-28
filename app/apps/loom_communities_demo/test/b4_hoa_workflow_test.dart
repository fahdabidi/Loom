import 'package:flutter_test/flutter_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';

import 'workflow_test_harness.dart';

void main() {
  test('wf_hoa-headline', () async {
    final harness = await DemoWorkflowHarness.create(
      handle: 'cedar-hoa',
      displayName: 'Cedar Commons HOA',
      category: 'hoa',
      extensionId: 'ext_hoa',
      cardAssetId: 'asset_card_hoa',
      logoAssetId: 'asset_logo_hoa',
      accentColor: '#3E6B8F',
    );
    await harness.grant('documents.write');

    final dues = await harness.economic.wallet.recordPayment(
      communityId: harness.communityId,
      passportId: harness.memberId,
      kind: CommunityPaymentKind.dues,
      amountCents: 45000,
      idempotencyKey: 'b4-dues-payment',
    );
    final document = await harness.ops.documents.uploadDocument(
      communityId: harness.communityId,
      title: 'Community Rules',
      body: 'Architectural changes require committee approval.',
      visibility: CommunityDocumentVisibility.members,
      actorPassportId: harness.ownerId,
      idempotencyKey: 'b4-rules-document',
    );
    final visibleDocs = await harness.ops.documents.visibleDocuments(
      communityId: harness.communityId,
      actorPassportId: harness.memberId,
      includeRestricted: false,
    );
    final reservation = await harness.ops.facilities.reserveFacility(
      communityId: harness.communityId,
      facilityId: 'clubhouse_room_a',
      passportId: harness.memberId,
      amountCents: 7500,
      idempotencyKey: 'b4-facility-reservation',
    );
    final reservationPayment = await harness.economic.wallet.recordPayment(
      communityId: harness.communityId,
      passportId: harness.memberId,
      kind: CommunityPaymentKind.reservation,
      amountCents: reservation.amountCents,
      idempotencyKey: 'b4-reservation-payment',
    );
    final request = await harness.ops.caseTasks.openCase(
      communityId: harness.communityId,
      title: 'Fence color architectural request',
      assigneePassportId: harness.ownerId,
      idempotencyKey: 'b4-architectural-request',
    );
    final review = await harness.engine.workflows.startWorkflow(
      workflowId: 'hoa_architectural_review',
      firstStep: 'submitted',
      idempotencyKey: 'b4-workflow-start',
    );
    final committeeReview = await harness.engine.workflows.transition(
      workflowRunId: review.workflowRunId,
      nextStep: 'committee-review',
      complete: false,
      idempotencyKey: 'b4-workflow-review',
    );
    final decision = await harness.engine.workflows.transition(
      workflowRunId: review.workflowRunId,
      nextStep: 'approved',
      complete: true,
      idempotencyKey: 'b4-workflow-approved',
    );
    final resolved = await harness.ops.caseTasks.transitionCase(
      caseId: request.caseId,
      status: CommunityCaseStatus.resolved,
      actorPassportId: harness.ownerId,
      idempotencyKey: 'b4-case-resolved',
    );
    final notification = await harness.experience.notifications.deliver(
      passportId: harness.memberId,
      channel: 'push',
      subject: 'Architectural request approved',
      dedupeKey: 'b4-architectural-decision',
    );
    final export = await harness.ops.exports.assemble(
      communityId: harness.communityId,
      redactProtectedData: false,
      idempotencyKey: 'b4-export',
    );
    harness.shell.openExtension('local:ext_hoa@latest');

    expect(dues.kind, CommunityPaymentKind.dues);
    expect(dues.amountCents, 45000);
    expect(visibleDocs.single.documentId, document.documentId);
    expect(reservation.status, CommunityReservationStatus.held);
    expect(reservationPayment.amountCents, reservation.amountCents);
    expect(committeeReview.state, CommunityWorkflowState.waiting);
    expect(decision.state, CommunityWorkflowState.completed);
    expect(resolved.status, CommunityCaseStatus.resolved);
    expect(notification.delivered, isTrue);
    expect(export.documentIds, contains(document.documentId));
    expect(export.componentIds, contains('case-task-service'));
    expect(export.componentIds, contains('facilities-service'));
    expect(export.componentIds, contains('wallet-dues-donations'));
    expect(export.componentIds, contains('receipt-ledger'));
    expect(harness.shell.openExtensionId, 'local:ext_hoa@latest');
  });
}
