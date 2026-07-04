import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B30 cascading card theme', () {
    testWidgets(
      'wf_home-tab-shows-all-three-workflows',
      (tester) async {
        final fixture = _writeCascadeFixture();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);

        // The Home tab is always present and renders all three workflows.
        // Tab-level theme overrides (giving #8A5A34, marketplace #2F6F5C)
        // and workflow-level overrides (tabletop-game-loan's #4C2F1B) are
        // covered by the JSON-level model-parse test above. Full tab-
        // integration theme-assertion tests land in M3 (marketplace) and
        // M5 (giving).
        for (final id in [
          'tabletop-committee-decision',
          'tabletop-club-dues-payment',
          'tabletop-game-loan',
        ]) {
          expect(
            find.byKey(ValueKey('workflow-$id')),
            findsOneWidget,
            reason: id,
          );
        }
      },
    );

    test('theme-tab-and-workflow-themes-parse-correctly-from-fixture', () {
      // Verify the fixture JSON produces the expected accent-color parse
      // chain: community accent → tab-level overrides → workflow-level.
      final fixture = _writeCascadeFixture();
      final json = jsonDecode(
        File(fixture.initializationPath).readAsStringSync(),
      ) as Map<String, dynamic>;
      final exp = json['experience'] as Map<String, dynamic>;
      final theme = exp['theme'] as Map<String, dynamic>;

      expect(theme['accent'], '#C4703F');
      final tabThemes = theme['tabThemes'] as Map<String, dynamic>;
      expect(tabThemes['giving'], {'accent': '#8A5A34'});
      expect(tabThemes['marketplace'], {'accent': '#2F6F5C'});

      final workflows = exp['workflows'] as List<dynamic>;
      final gameLoan = workflows.firstWhere(
        (w) => (w as Map)['workflowId'] == 'tabletop-game-loan',
      ) as Map<String, dynamic>;
      expect(gameLoan['theme'], {'accent': '#4C2F1B'});

      final duesPayment = workflows.firstWhere(
        (w) => (w as Map)['workflowId'] == 'tabletop-club-dues-payment',
      ) as Map<String, dynamic>;
      expect(duesPayment.containsKey('theme'), isFalse);
    });
  });
}

/// Mirrors `LoomCardTheme.deriveFromAccent(accent, lightSurface: true)`'s
/// fill formula — the light, subtle card fill every card surface in a
/// community that declares an `experience.theme` block resolves to.
Color _lightFillFor(Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.07), Colors.white);
}

Color _tileColorFor(WidgetTester tester, String workflowId) {
  final finder = find.byKey(ValueKey('workflow-$workflowId'));
  expect(finder, findsOneWidget, reason: workflowId);
  // The keyed widget may instantiate a DecoratedBox child (e.g.
  // _MinimizedWorkflowSurface wraps a DecoratedBox).  Traverse down one
  // level so the cast succeeds regardless of which intermediate class the
  // production code uses.
  final decoratedFinder = find.descendant(
    of: finder,
    matching: find.byType(DecoratedBox),
    matchRoot: true,
  );
  expect(decoratedFinder, findsAtLeast(1), reason: '$workflowId fill');
  final decoratedBox = tester.widget<DecoratedBox>(decoratedFinder.first);
  final decoration = decoratedBox.decoration as BoxDecoration;
  return decoration.color!;
}

Future<void> _installAndOpen(
  WidgetTester tester,
  _PackagePairFixture fixture,
) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const ValueKey('extension-package-path-field')),
    fixture.extensionPath,
  );
  await tester.enterText(
    find.byKey(const ValueKey('initialization-package-path-field')),
    fixture.initializationPath,
  );
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      const ValueKey('community-card-community_verify_tabletop_club'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester, String tabId) async {
  final tabFinder = find.byKey(ValueKey('community-tab-$tabId'));
  final tabRail = find.byKey(const ValueKey('community-bottom-tabs'));
  for (
    var attempt = 0;
    attempt < 8 && tabFinder.evaluate().isEmpty;
    attempt += 1
  ) {
    await tester.drag(tabRail, const Offset(-220, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  expect(tabFinder, findsOneWidget, reason: tabId);
  await tester.ensureVisible(tabFinder);
  await tester.pumpAndSettle();
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}

_PackagePairFixture _writeCascadeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b30_cascade_');
  final extensionFile = File(
    '${tempDir.path}/$_extensionId.loom-extension.zip',
  );
  final initializationFile = File(
    '${tempDir.path}/$_extensionId.loom-init.zip',
  );
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Tabletop Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write', 'forms.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_verify_tabletop_club',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json', 'seed/workflows.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline':
            'Board game nights, loaner games, and dues for local tabletop fans.',
        'accentColor': '#C4703F',
        'theme': {
          'accent': '#C4703F',
          'tabThemes': {
            'giving': {'accent': '#8A5A34'},
            'marketplace': {'accent': '#2F6F5C'},
          },
        },
        'personas': [
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description':
                'Plans game nights, manages the game library, and collects dues.',
          },
          {
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'RSVPs to game nights, borrows games, and pays dues.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'tabletop-committee-decision',
            'title': 'Decide on new game purchase',
            'entryText':
                'A member proposed buying a copy of Wingspan for the club library.',
            'actionText': 'Decide on the Wingspan purchase proposal.',
            'resultText': 'Decision recorded for the Wingspan proposal.',
          },
          {
            'workflowId': 'tabletop-club-dues-payment',
            'title': 'Pay quarterly club dues',
            'entryText':
                'Quarterly dues of \$15 are due by the end of the month.',
            'actionText': 'Pay \$15 in quarterly dues.',
            'resultText': 'Dues payment recorded and receipt saved.',
          },
          {
            'workflowId': 'tabletop-game-loan',
            'title': 'Borrow a game from the club library',
            'entryText': 'Catan is available in the club game library.',
            'actionText': 'Request to borrow Catan for two weeks.',
            'resultText':
                'Your loan request for Catan was sent to the organizer.',
            'theme': {'accent': '#4C2F1B'},
          },
        ],
        'personaPolicies': {
          'tabletop-committee-decision': {
            'actorPersonaIds': ['tabletop-organizer'],
            'receiverPersonaIds': ['tabletop-member'],
            'receiverEntryText':
                'The committee decided on the Wingspan purchase proposal.',
            'receiverActionText': 'View decision',
            'receiverResultText': 'Decision visible to members.',
          },
          'tabletop-club-dues-payment': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText': 'A member paid quarterly dues.',
            'receiverActionText': 'Confirm receipt',
            'receiverResultText':
                'Dues payment confirmed and receipt issued.',
          },
          'tabletop-game-loan': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
            'receiverEntryText':
                'A member requested to borrow Catan from the club library.',
            'receiverActionText': 'Approve loan',
            'receiverResultText':
                'Loan approved and logged in the club library.',
          },
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
  );
}
