import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_marketplace_dues_gate';

void main() {
  group('M3.2 Marketplace dues-current gate', () {
    testWidgets('dues-not-current member sees Waiting instead of borrow', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _tapTab(tester, 'marketplace');
      await _openListingDetail(tester, 'listing-root');

      expect(find.byKey(const ValueKey('marketplace-action-borrow')), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);
      expect(find.text('Request loan'), findsNothing);
    });

    testWidgets('paying dues updates Marketplace borrow from Waiting to enabled', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'tabletop-member');
      await _tapTab(tester, 'giving');

      await tester.ensureVisible(find.byKey(const ValueKey('giving-action-pay')));
      await tester.tap(find.byKey(const ValueKey('giving-action-pay')));
      await tester.pumpAndSettle();
      final submitFinder = find.byKey(
        const ValueKey('workflow-action-submit-tabletop-club-dues-payment'),
      );
      if (submitFinder.evaluate().isNotEmpty) {
        await tester.tap(submitFinder);
        await tester.pumpAndSettle();
      }

      await _tapTab(tester, 'marketplace');
      await _openListingDetail(tester, 'listing-root');

      expect(find.byKey(const ValueKey('marketplace-action-borrow')), findsOneWidget);
      expect(find.text('Request loan'), findsOneWidget);
      expect(find.text('Waiting'), findsNothing);
    });
  });
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
      const ValueKey('community-card-community_verify_marketplace_dues_gate'),
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
  await tester.tap(tabFinder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _openListingDetail(WidgetTester tester, String listingId) async {
  final card = find.byKey(ValueKey('marketplace-listing-$listingId'));
  await tester.ensureVisible(card);
  expect(card, findsOneWidget);
  await tester.tap(card, warnIfMissed: false);
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b37_dues_gate_');
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
      'permissions': ['content.publish', 'payments.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': 'community_verify_marketplace_dues_gate',
      'communityName': 'Tabletop Club',
      'extensionId': _extensionId,
      'seedDataFiles': ['seed/community.json'],
      'branding': {'accentColor': '#C4703F'},
      'experience': {
        'displayName': 'Tabletop Club',
        'tagline': 'Board game library and member dues.',
        'accentColor': '#C4703F',
        'personas': [
          {
            'personaId': 'tabletop-member',
            'label': 'Member',
            'roleLabel': 'Member',
            'description': 'Borrows games and pays dues.',
          },
          {
            'personaId': 'tabletop-organizer',
            'label': 'Organizer',
            'roleLabel': 'Organizer',
            'description': 'Runs the club.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'tabletop-club-dues-payment',
            'title': 'Quarterly club dues',
            'entryText': 'Quarterly club dues are due.',
            'actionText': 'Pay quarterly club dues of \$15.',
            'resultText': 'Your membership is current.',
            'givingPayment': {
              'amountLabel': '\$15',
              'purpose': 'Quarterly club dues',
              'recipient': 'Tabletop Club treasury',
            },
          },
          {
            'workflowId': 'tabletop-game-loan',
            'title': 'Borrow Root',
            'entryText': 'Borrow Root from the club library.',
            'actionText': 'Confirm loan request.',
            'resultText': 'Root is checked out to you.',
          },
        ],
        'marketplace': {
          'templates': {
            'duesGatedLoan': {
              'initialState': 'available',
              'states': {
                'available': {'label': 'Available', 'tone': 'positive'},
                'onLoan': {'label': 'On loan', 'tone': 'warning'},
              },
              'transitions': [
                {
                  'id': 'borrow',
                  'label': 'Request loan',
                  'from': ['available'],
                  'to': 'onLoan',
                  'allowedPersonaIds': ['tabletop-member'],
                  'requiresWorkflowsComplete': [
                    'tabletop-membership-dues-current',
                  ],
                  'linkedWorkflowId': 'tabletop-game-loan',
                  'setsHolderToActor': true,
                },
              ],
            },
          },
        },
        'marketplaceListings': [
          {
            'listingId': 'listing-root',
            'title': 'Root',
            'category': 'Strategy Games',
            'condition': 'Good',
            'availability': 'available',
            'template': 'duesGatedLoan',
          },
        ],
        'personaPolicies': {
          'tabletop-club-dues-payment': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
          },
          'tabletop-game-loan': {
            'actorPersonaIds': ['tabletop-member'],
            'receiverPersonaIds': ['tabletop-organizer'],
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

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
  });

  final String extensionPath;
  final String initializationPath;
}
