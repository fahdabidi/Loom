import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  test('persona tab resolver keeps shell defaults and filters admin tabs', () {
    final experience = experienceForExtensionId('ext_mosque');

    final adminTabs = appShellTabsFor(
      experience: experience,
      personaId: 'mosque-admin',
    );
    final memberTabs = appShellTabsFor(
      experience: experience,
      personaId: 'mosque-member',
    );

    expect(adminTabs.map((tab) => tab.tabId), containsAll(['home', 'admin']));
    expect(adminTabs.last.tabId, 'messages');
    expect(memberTabs.map((tab) => tab.tabId), isNot(contains('admin')));
    expect(memberTabs.map((tab) => tab.tabId), containsAll(['home', 'messages']));
  });

  testWidgets('wf_app-shell-persona-tabs-customization', (tester) async {
    final target = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_mosque',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    expect(find.byKey(const ValueKey('community-bottom-tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('community-tab-messages')), findsOneWidget);
    expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('community-tab-messages')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('messages-tab-surface')), findsOneWidget);

    await selectPersona(tester, 'mosque-member');

    expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);
    expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('community-tab-messages')), findsOneWidget);
  });
}
