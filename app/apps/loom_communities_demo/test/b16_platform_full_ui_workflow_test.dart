import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  final platformExtensionIds = {
    'ext_platform_social',
    'ext_ad_off',
    'ext_export_migration',
  };

  for (final target in loomEvidenceTargets.where(
    (target) => platformExtensionIds.contains(target.extensionId),
  )) {
    testWidgets('wf_${target.extensionId}_platform-full-ui-workflow-evidence', (
      tester,
    ) async {
      await completeTargetWorkflows(tester, target);
    });
  }
}
