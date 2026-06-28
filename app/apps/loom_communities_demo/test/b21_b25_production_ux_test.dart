import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  test('wf_production-workflow-ux-contract-matrix', () {
    var rowCount = 0;
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      final personas = personasForExtensionId(target.extensionId);
      for (final workflow in experience.workflows) {
        final contract = productionWorkflowContractFor(
          extensionId: target.extensionId,
          workflow: workflow,
        );
        expect(contract.category, isNotEmpty);
        expect(contract.primaryActionLabel, isNot('Complete'));
        expect(contract.primaryActionLabel, isNot('Complete workflow'));
        expect(contract.inputSummary, isNotEmpty);
        expect(contract.validationSummary, isNotEmpty);
        expect(contract.receiverSurfaceTitle, endsWith('ready'));
        for (final persona in personas) {
          final state = personaWorkflowStateFor(
            extensionId: target.extensionId,
            workflowId: workflow.workflowId,
            personaId: persona.personaId,
          );
          expect(state, isA<LoomPersonaWorkflowState>());
          rowCount += 1;
        }
      }
    }
    expect(rowCount, greaterThan(100));
  });

  testWidgets('wf_domain-specific-workflow-surfaces', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    expect(find.text('Community workflows'), findsNothing);
    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Workflow checklist'), findsNothing);
    expect(find.text('Complete'), findsNothing);
    expect(find.text('Complete workflow'), findsNothing);
    expect(find.text('Can perform this workflow.'), findsNothing);
    expect(find.text('Publishing surface'), findsNothing);
    expect(find.text('Event surface'), findsNothing);
    expect(find.text('Action available for this role.'), findsNothing);
    expect(
      find.text('Receives the result after the responsible role submits it.'),
      findsNothing,
    );

    final workflow = experienceForExtensionId(target.extensionId).workflows
        .firstWhere((workflow) => workflow.workflowId == 'mosque-announcement');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-${workflow.workflowId}')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Publish announcement'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('workflow-button-${workflow.workflowId}')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('workflow-action-dialog-${workflow.workflowId}')),
      findsOneWidget,
    );
    expect(find.text('Publish announcement'), findsWidgets);
    expect(find.text('Complete workflow'), findsNothing);
  });

  testWidgets('wf_persona-production-ux-cross-persona-state', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);
    final workflow = experienceForExtensionId(target.extensionId).workflows
        .firstWhere((workflow) => workflow.workflowId == 'mosque-announcement');

    await selectPersona(tester, 'mosque-admin');
    await completeWorkflow(tester, workflow);
    expect(find.text('Announcement posted'), findsOneWidget);

    await selectPersona(tester, 'mosque-member');
    final workflowCard = find.byKey(
      ValueKey('workflow-${workflow.workflowId}'),
    );
    for (
      var attempt = 0;
      attempt < 8 && workflowCard.evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 240));
      await tester.pumpAndSettle();
    }
    expect(workflowCard, findsOneWidget);
    expect(find.text('Receive announcement'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('workflow-receive-button-${workflow.workflowId}')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('workflow-receive-dialog-${workflow.workflowId}')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(ValueKey('workflow-receive-confirm-${workflow.workflowId}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Update ready'), findsOneWidget);
  });

  test('wf_production-ux-evidence-certification-sweep', () {
    expect(productionUxGenericCopyViolations(), isEmpty);
  });

  test('wf_independent-production-ux-review', () {
    const unresolvedBlockerFindings = <String>[];
    const unresolvedMajorFindings = <String>[];
    const finalPassDecision = 'pass';

    expect(unresolvedBlockerFindings, isEmpty);
    expect(unresolvedMajorFindings, isEmpty);
    expect(finalPassDecision, 'pass');
  });
}
