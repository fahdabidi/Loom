import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

const _extensionId = 'ext_verify_tabletop_club';

void main() {
  group('B30 cascading card theme', () {
    testWidgets(
      'wf_community-tab-and-workflow-theme-overrides-cascade-correctly',
      (tester) async {
        final fixture = _writeCascadeFixture();
        await tester.pumpWidget(const LoomCommunitiesDemoApp());
        await _installAndOpen(tester, fixture);

        // No tab or workflow theme override anywhere for this workflow: it
        // must render with the plain community-derived accent (as the light
        // "modern card theme" fill this fixture's declared experience.theme
        // opts into — see LoomCardTheme.deriveFromAccent(lightSurface: true)).
        await _tapTab(tester, 'admin');
        expect(
          _tileColorFor(tester, 'tabletop-committee-decision'),
          _lightFillFor(const Color(0xffC4703F)),
        );

        // The Giving tab declares a tabThemes override; this workflow has no
        // theme of its own, so it must inherit the tab's accent, not the
        // community's.
        await _tapTab(tester, 'giving');
        expect(
          _tileColorFor(tester, 'tabletop-club-dues-payment'),
          _lightFillFor(const Color(0xff8A5A34)),
        );

        // The Marketplace tab also declares a (different) tabThemes
        // override, but this workflow declares its own theme on top of
        // that — the workflow-level override must win over both the tab
        // and community defaults.
        await _tapTab(tester, 'marketplace');
        expect(
          _tileColorFor(tester, 'tabletop-game-loan'),
          _lightFillFor(const Color(0xff4C2F1B)),
        );
      },
    );
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
  final decoratedBox = tester.widget<DecoratedBox>(finder);
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
  // The tab rail is horizontally scrollable; a widget matching by key can
  // exist off-screen. Without ensureVisible, tester.tap taps the widget's
  // current (possibly off-screen) coordinates, which can silently land on
  // whatever tab is actually on-screen at that position instead.
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
