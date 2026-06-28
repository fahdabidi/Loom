import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('wf_garden-club-full-ui-workflow-evidence', (tester) async {
    final target = loomEvidenceTargets.singleWhere(
      (target) => target.extensionId == 'ext_garden_club',
    );

    await completeTargetWorkflows(tester, target);
  });
}
