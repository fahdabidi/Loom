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
          policy.actorRoleIds,
          isNotEmpty,
          reason: '${target.extensionId}/${workflow.workflowId} has no actor',
        );
        for (final actorRoleId in policy.actorRoleIds) {
          expect(
            personas.map((persona) => persona.roleId),
            contains(actorRoleId),
          );
        }
        for (final receiverRoleId in policy.receiverRoleIds) {
          expect(
            dependencies
                .where(
                  (dependency) =>
                      dependency.workflowId == workflow.workflowId &&
                      dependency.receiverRoleId == receiverRoleId,
                )
                .length,
            1,
          );
        }
      }

      for (final row in matrix) {
        expect(row.extensionId, target.extensionId);
        expect(row.workflowId, isNotEmpty);
        expect(row.roleId, isNotEmpty);
        expect(row.rationale, isNotEmpty);
      }
    }

    expect(
      personaWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        roleId: 'mosque-admin',
      ),
      LoomPersonaWorkflowState.actor,
    );
    expect(
      personaWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        roleId: 'mosque-member',
      ),
      LoomPersonaWorkflowState.receiver,
    );
  });
}
