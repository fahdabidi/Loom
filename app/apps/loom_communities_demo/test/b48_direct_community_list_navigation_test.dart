import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'b25_workflow_row_selection.dart';
import 'workflow_ui_test_harness.dart';

void main() {
  final target = loomEvidenceTargets.firstWhere(
    (target) => target.extensionId == 'ext_garden_club',
  );

  testWidgets(
    'direct community navigation returns from an entry surface without Back',
    (tester) async {
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installShippedEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);

      expect(
        find.byKey(const ValueKey('community-entry-gate')),
        findsOneWidget,
      );
      expect(find.byTooltip('Back'), findsNothing);

      await returnToCommunityListDirectly(tester);

      expect(find.text('Loom Communities'), findsOneWidget);
      expect(find.byKey(const ValueKey('community-list')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('add-community-button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'a covered Back is reported by the community boundary without dismissal',
    (tester) async {
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await installMetadataEvidenceTarget(tester, target);
      await openEvidenceTarget(tester, target);
      expect(find.byTooltip('Back'), findsOneWidget);

      final overlay = OverlayEntry(
        builder: (context) => const Positioned.fill(
          child: AbsorbPointer(
            child: ColoredBox(
              color: Colors.transparent,
              child: Center(
                child: Text('unexpected covering navigation surface'),
              ),
            ),
          ),
        ),
      );
      Overlay.of(
        tester.element(find.byType(LocalExtensionScreen)),
      ).insert(overlay);
      addTearDown(overlay.remove);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);

      final firstCommunity = await runB25CommunityScope<void>(() async {
        await openEvidenceTarget(tester, target);
      });
      final record = B25CommunityTraversalRecord.fromScope(
        scope: firstCommunity,
        phase: target.phase,
        communityId: target.communityId,
        communityName: target.communityName,
        extensionId: target.extensionId,
        lastRowWalked: 'garden-tool-loan/member',
      );
      final nextCommunity = await runB25CommunityScope<String>(
        () async => 'next community still runs',
      );

      expect(firstCommunity.completed, isFalse);
      expect(
        firstCommunity.failure!.reason,
        allOf(
          contains('Direct navigation reached the community-list widgets'),
          contains('not interactable'),
          contains('Observed surface'),
          contains('unexpected covering navigation surface'),
        ),
      );
      expect(
        find.text('unexpected covering navigation surface'),
        findsOneWidget,
      );
      expect(record.isIncomplete, isTrue);
      expect(record.reason, contains('Observed surface'));
      expect(nextCommunity.completed, isTrue);
      expect(nextCommunity.value, 'next community still runs');
    },
  );
}
