import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_communities_demo/main.dart';

import '../test/workflow_ui_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('load all example communities into visible demo app', (
    tester,
  ) async {
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
