import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets(
    'wf_multi-persona-workflow-evidence',
    (tester) async {
      for (final target in loomEvidenceTargets) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await installEvidenceTarget(tester, target);
        await openEvidenceTarget(tester, target);

        final experience = experienceForExtensionId(
          target.extensionId,
          displayName: target.communityName,
        );
        final personas = personasForExtensionId(target.extensionId);
        final roleIds = personas.map((persona) => persona.roleId).toSet();

        for (final workflow in experience.workflows) {
          final policy = personaPolicyForWorkflow(
            target.extensionId,
            workflow.workflowId,
          );
          expect(policy.actorRoleIds, isNotEmpty);

          await selectPersona(tester, policy.actorRoleIds.first);
          await completeWorkflow(tester, workflow);

          for (final actorRoleId in policy.actorRoleIds.skip(1)) {
            await selectPersona(tester, actorRoleId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(ValueKey('workflow-result-${workflow.workflowId}')),
              findsOneWidget,
            );
          }

          for (final receiverRoleId in policy.receiverRoleIds) {
            await selectPersona(tester, receiverRoleId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(
                ValueKey('workflow-receive-button-${workflow.workflowId}'),
              ),
              findsOneWidget,
            );
            await receiveWorkflow(tester, workflow);
          }

          for (final readOnlyRoleId in policy.readOnlyRoleIds) {
            await selectPersona(tester, readOnlyRoleId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(ValueKey('workflow-read-only-${workflow.workflowId}')),
              findsOneWidget,
            );
          }

          final explicitRoleIds = {
            ...policy.actorRoleIds,
            ...policy.receiverRoleIds,
            ...policy.readOnlyRoleIds,
          };
          for (final disabledRoleId in roleIds.difference(explicitRoleIds)) {
            await selectPersona(tester, disabledRoleId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(ValueKey('workflow-disabled-${workflow.workflowId}')),
              findsOneWidget,
            );
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
