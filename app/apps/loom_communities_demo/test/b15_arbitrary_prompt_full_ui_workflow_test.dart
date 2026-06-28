import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  final generatedExtensionIds = {'ext_chess_club', 'ext_camera_club'};

  for (final target in loomEvidenceTargets.where(
    (target) => generatedExtensionIds.contains(target.extensionId),
  )) {
    testWidgets(
      'wf_${target.extensionId}_generated-full-ui-workflow-evidence',
      (tester) async {
        await completeTargetWorkflows(tester, target);
      },
    );
  }
}
