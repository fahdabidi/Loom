import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

void main() {
  test('wf_persona-role-inventory-capability-matrix', () {
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      final personas = personasForExtensionId(target.extensionId);
      final matrix = personaWorkflowMatrixForExtensionId(target.extensionId);
      final dependencies = workflowDependenciesForExtensionId(
        target.extensionId,
      );

      expect(personas.length, greaterThanOrEqualTo(2));
      expect(matrix, hasLength(personas.length * experience.workflows.length));

      for (final workflow in experience.workflows) {
        final policy = personaPolicyForWorkflow(
          target.extensionId,
          workflow.workflowId,
        );
        expect(
          policy.actorPersonaIds,
          isNotEmpty,
          reason: '${target.extensionId}/${workflow.workflowId} has no actor',
        );
        for (final actorPersonaId in policy.actorPersonaIds) {
          expect(
            personas.map((persona) => persona.personaId),
            contains(actorPersonaId),
          );
        }
        for (final receiverPersonaId in policy.receiverPersonaIds) {
          expect(
            dependencies
                .where(
                  (dependency) =>
                      dependency.workflowId == workflow.workflowId &&
                      dependency.receiverPersonaId == receiverPersonaId,
                )
                .length,
            1,
          );
        }
      }

      for (final row in matrix) {
        expect(row.extensionId, target.extensionId);
        expect(row.workflowId, isNotEmpty);
        expect(row.personaId, isNotEmpty);
        expect(row.rationale, isNotEmpty);
      }
    }

    expect(
      personaWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        personaId: 'mosque-admin',
      ),
      LoomPersonaWorkflowState.actor,
    );
    expect(
      personaWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        personaId: 'mosque-member',
      ),
      LoomPersonaWorkflowState.receiver,
    );
  });
}
