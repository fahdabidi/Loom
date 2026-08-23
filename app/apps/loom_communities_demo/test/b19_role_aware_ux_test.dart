import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('wf_community-persona-aware-ux', (tester) async {
    final target = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_mosque',
    );
    final experience = experienceForExtensionId(
      target.extensionId,
      displayName: target.communityName,
    );
    final announcement = experience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'mosque-announcement',
    );
    final careRequest = experience.workflows.firstWhere(
      (workflow) => workflow.workflowId == 'mosque-care-request',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installMetadataEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    await selectActorIdentity(tester, 'mosque-admin');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-${announcement.workflowId}')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(ValueKey('workflow-button-${announcement.workflowId}')),
      findsOneWidget,
    );

    await selectActorIdentity(tester, 'mosque-member');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-${announcement.workflowId}')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(ValueKey('workflow-waiting-${announcement.workflowId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('workflow-button-${announcement.workflowId}')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-${careRequest.workflowId}')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(ValueKey('workflow-button-${careRequest.workflowId}')),
      findsOneWidget,
    );

    await selectActorIdentity(tester, 'mosque-admin');
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('workflow-${careRequest.workflowId}')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.byKey(ValueKey('workflow-waiting-${careRequest.workflowId}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('workflow-button-${careRequest.workflowId}')),
      findsNothing,
    );
  });
}
