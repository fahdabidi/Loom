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
        final personaIds = personas.map((persona) => persona.personaId).toSet();

        for (final workflow in experience.workflows) {
          final policy = personaPolicyForWorkflow(
            target.extensionId,
            workflow.workflowId,
          );
          expect(policy.actorPersonaIds, isNotEmpty);

          await selectPersona(tester, policy.actorPersonaIds.first);
          await completeWorkflow(tester, workflow);

          for (final actorPersonaId in policy.actorPersonaIds.skip(1)) {
            await selectPersona(tester, actorPersonaId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(ValueKey('workflow-result-${workflow.workflowId}')),
              findsOneWidget,
            );
          }

          for (final receiverPersonaId in policy.receiverPersonaIds) {
            await selectPersona(tester, receiverPersonaId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(
                ValueKey('workflow-receive-button-${workflow.workflowId}'),
              ),
              findsOneWidget,
            );
            await receiveWorkflow(tester, workflow);
          }

          for (final readOnlyPersonaId in policy.readOnlyPersonaIds) {
            await selectPersona(tester, readOnlyPersonaId);
            await scrollToWorkflowCard(tester, workflow);
            expect(
              find.byKey(ValueKey('workflow-read-only-${workflow.workflowId}')),
              findsOneWidget,
            );
          }

          final explicitPersonaIds = {
            ...policy.actorPersonaIds,
            ...policy.receiverPersonaIds,
            ...policy.readOnlyPersonaIds,
          };
          for (final disabledPersonaId in personaIds.difference(
            explicitPersonaIds,
          )) {
            await selectPersona(tester, disabledPersonaId);
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

