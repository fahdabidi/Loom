import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

void main() {
  test('wf_actor-identity-inventory-capability-matrix', () {
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      final actorIdentities = actorIdentitiesForExtensionId(target.extensionId);
      final matrix = roleWorkflowMatrixForExtensionId(target.extensionId);
      final dependencies = workflowDependenciesForExtensionId(
        target.extensionId,
      );

      expect(actorIdentities.length, greaterThanOrEqualTo(2));
      expect(
        matrix,
        hasLength(actorIdentities.length * experience.workflows.length),
      );

      for (final workflow in experience.workflows) {
        final policy = rolePolicyForWorkflow(
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
            actorIdentities.map((actorIdentity) => actorIdentity.roleId),
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
      roleWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        roleId: 'mosque-admin',
      ),
      LoomRoleWorkflowState.actor,
    );
    expect(
      roleWorkflowStateFor(
        extensionId: 'ext_mosque',
        workflowId: 'mosque-announcement',
        roleId: 'mosque-member',
      ),
      LoomRoleWorkflowState.receiver,
    );
  });
}
