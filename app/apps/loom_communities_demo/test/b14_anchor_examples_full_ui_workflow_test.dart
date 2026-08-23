import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  final anchorExtensionIds = {
    'ext_neighborhood_book_club',
    'ext_youth_soccer',
    'ext_cedar_commons_hoa',
    'ext_mosque',
  };

  for (final target in loomEvidenceTargets.where(
    (target) => anchorExtensionIds.contains(target.extensionId),
  )) {
    testWidgets('wf_${target.extensionId}_anchor-full-ui-workflow-evidence', (
      tester,
    ) async {
      await completeTargetWorkflows(tester, target);
    });
  }
}
