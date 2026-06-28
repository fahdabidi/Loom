import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

void main() {
  test('wf_example-workflow-ux-evidence-harness', () {
    expect(loomEvidenceTargets, hasLength(10));
    expect(
      loomEvidenceTargets.map((target) => target.phase).toSet(),
      containsAll(['B13', 'B14', 'B15', 'B16']),
    );
    for (final target in loomEvidenceTargets) {
      final experience = experienceForExtensionId(
        target.extensionId,
        displayName: target.communityName,
      );
      expect(experience.workflows, isNotEmpty);
      for (final workflow in experience.workflows) {
        final screenshotNames = [
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_start',
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_action',
          '${target.phase}_${target.extensionId}_${workflow.workflowId}_complete',
        ];
        expect(screenshotNames.toSet(), hasLength(3));
      }
    }
  });
}
