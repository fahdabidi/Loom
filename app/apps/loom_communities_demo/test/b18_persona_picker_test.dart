import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  testWidgets('wf_demo-app-persona-picker', (tester) async {
    final target = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_mosque',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installMetadataEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    expect(
      find.byKey(const ValueKey('active-persona-mosque-admin')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('persona-picker-button')), findsOneWidget);

    await selectPersona(tester, 'mosque-member');

    expect(
      find.byKey(const ValueKey('active-persona-mosque-member')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workflow-waiting-mosque-announcement')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workflow-button-mosque-announcement')),
      findsNothing,
    );
  });
}
