import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _bookTarget = LoomEvidenceTarget(
  phase: 'B14',
  communityId: 'community_neighborhood_book_club',
  communityName: 'Neighborhood Book Club',
  handle: 'neighborhood-book-club',
  extensionId: 'ext_neighborhood_book_club',
  accentColor: '#5B3A29',
  seedDataFiles: <String>[],
);

void main() {
  testWidgets('book engine tabs preserve app behavior parity', (tester) async {
    const target = _bookTarget;

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installShippedEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    await _selectActorIdentity(tester, 'book-member');

    expect(find.byKey(const ValueKey('community-tab-books')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-tab-marketplace')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-tab-documents')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-tab-discussions')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);

    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-home')),
    );
    _expectDerivedHomeGenericListContract(tester, roleId: 'book-member');
    expect(
      find.byKey(const ValueKey('engine-native-list-root-home')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-selected-1')),
      findsOneWidget,
      reason:
          'The generated Home tab must render the shipped selected nomination '
          'through its statusTimeline archetype binding.',
    );
    expect(find.text('The Song of Achilles'), findsWidgets);

    await _selectTab(tester, 'books');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-books')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-books')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-draft-1')),
      findsNothing,
      reason:
          'Actor-only drafts owned by a different seeded individual must not '
          'leak to a newly created member account.',
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-submitted-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-selected-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('creatable-fab-book-nomination')),
      findsOneWidget,
    );

    await _selectTab(tester, 'calendar');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-calendar-root')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-calendar-root')),
      findsOneWidget,
    );
    expect(find.text('September book discussion'), findsWidgets);
    await _tapEngineAction(
      tester,
      instanceId: 'meeting-sept',
      transitionId: 'respond-going',
    );
    expect(_engineAction('meeting-sept', 'respond-maybe'), findsOneWidget);

    await _selectTab(tester, 'marketplace');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-marketplace-root')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-marketplace-root')),
      findsOneWidget,
    );
    expect(find.text('The Song of Achilles (paperback)'), findsWidgets);
    expect(find.text('Trivial Pursuit: Book Lovers Edition'), findsWidgets);
    expect(
      find.byKey(const ValueKey('marketplace-search-field')),
      findsOneWidget,
    );

    await _selectTab(tester, 'discussions');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-discussions')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-discussions')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-thread-circe')),
      findsOneWidget,
    );

    await _selectTab(tester, 'documents');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-documents')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-documents')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('document-library-facts-material-public-tile')),
      findsOneWidget,
    );
    expect(find.text('Circe Reading Guide'), findsWidgets);

    await _selectTab(tester, 'books');
    expect(
      find.byKey(const ValueKey('search-ai-answer-waiting-digest-open-tile')),
      findsOneWidget,
      reason:
          'Search is declared on Books, and the shipped package preserves the '
          'known platform-service answer gap as an explicit waiting state.',
    );
    expect(
      find.byKey(const ValueKey('search-ai-answer-sources-digest-open-tile')),
      findsOneWidget,
    );

    await _selectActorIdentity(tester, 'book-organizer');
    expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);
    await _selectTab(tester, 'admin');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-admin')),
    );
    expect(
      find.byKey(const ValueKey('engine-native-list-root-admin')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-submitted-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-pub-draft')),
      findsNothing,
      reason:
          'The seeded announcement draft belongs to another organizer '
          'account.',
    );
    expect(
      find.byKey(const ValueKey('export-wizard-state-badge-export-draft-tile')),
      findsNothing,
      reason: 'The seeded draft export is actor-only.',
    );
    expect(
      find.byKey(const ValueKey('creatable-fab-book-selection-publish')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('creatable-fab-book-export-metadata')),
      findsOneWidget,
    );
    await _tapEngineAction(
      tester,
      instanceId: 'nom-submitted-1',
      transitionId: 'select-for-ballot',
    );
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-submitted-1')),
      findsNothing,
    );

    await _selectActorIdentity(tester, 'book-member');
    expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);
    await _selectTab(tester, 'home');
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('engine-native-list-root-home')),
    );
    _expectDerivedHomeGenericListContract(tester, roleId: 'book-member');
    expect(
      find.byKey(const ValueKey('generic-instance-card-nom-selected-1')),
      findsOneWidget,
    );
  });
}

void _expectDerivedHomeGenericListContract(
  WidgetTester tester, {
  required String roleId,
}) {
  final screen = tester.widget<LocalExtensionScreen>(
    find.byType(LocalExtensionScreen),
  );
  final community = screen.community;
  final experience = experienceForExtensionId(
    community.extensionId,
    displayName: community.displayName,
    specVersion: community.specVersion,
    experienceConfiguration: community.experienceConfiguration,
  );
  final home = appShellTabsFor(
    experience: experience,
    roleId: roleId,
    appShellConfiguration: community.appShellConfiguration,
  ).singleWhere((tab) => tab.tabId == 'home');

  expect(home.rendererContractId, 'engine-native-generic-list');
  expect(home.rendererContract.rendererId, 'EngineNativeGenericListSurface');
}

Future<void> _selectTab(WidgetTester tester, String tabId) async {
  final tab = find.byKey(ValueKey('community-tab-$tabId'));
  final rail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (final offset in const [Offset(240, 0), Offset(-240, 0)]) {
    for (
      var attempt = 0;
      attempt < 16 && tab.evaluate().isEmpty;
      attempt += 1
    ) {
      await tester.drag(rail, offset, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  }
  expect(tab, findsOneWidget);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab, warnIfMissed: false);
  await _pumpForUi(tester);
}

Finder _engineAction(String instanceId, String transitionId) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.contains(instanceId) &&
        (key.value.endsWith('-action-$transitionId') ||
            key.value.endsWith('-$transitionId-$instanceId'));
  }, description: '$instanceId action $transitionId');
}

Future<void> _tapEngineAction(
  WidgetTester tester, {
  required String instanceId,
  required String transitionId,
}) async {
  final action = _engineAction(instanceId, transitionId).first;
  await _waitForFinder(tester, action);
  expect(action, findsOneWidget);
  await tester.ensureVisible(action);
  await _pumpForUi(tester);
  await tester.tap(action, warnIfMissed: false);
  await _pumpForUi(tester);
}

Future<void> _selectActorIdentity(WidgetTester tester, String fanId) async {
  await selectActorIdentity(tester, fanId);
}

Future<void> _pumpForUi(WidgetTester tester) async {
  for (var attempt = 0; attempt < 8; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _waitForFinder(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 150));
  }
}
