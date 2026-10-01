import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_communities_demo/main.dart';

import '../test/workflow_ui_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('load all example communities into visible demo app', (
    tester,
  ) async {
    // This test pumps the widget tree directly rather than calling `main()`,
    // so it never installs the production engine factory and would hit the
    // production-engine gate's loud StateError. That gate is correct here:
    // this test only proves the shipped community packages render as cards
    // using the local engine's seeded content, not that the app reaches a
    // live backend. Opt in explicitly rather than converting to production
    // wiring -- live-backend coverage for this harness belongs to the
    // capture-harness ticket, not this content-rendering smoke test.
    debugForceLoomLocalBackend = true;
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await tester.pumpAndSettle();

    for (final target in loomEvidenceTargets) {
      await installShippedEvidenceTarget(tester, target);
    }

    for (final target in loomEvidenceTargets) {
      final card = find.byKey(ValueKey('community-card-${target.communityId}'));
      await tester.scrollUntilVisible(
        card,
        160,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 40,
      );
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(card, findsOneWidget);
    }
  });
}
