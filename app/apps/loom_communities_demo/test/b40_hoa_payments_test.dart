import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

void main() {
  group('M4.3 HOA payments', () {
    testWidgets('homeowner pays dues and sees receipt history', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'giving');

      expect(find.text('Payments'), findsWidgets);
      expect(find.byKey(const ValueKey('giving-tab-surface')), findsOneWidget);
      expect(find.text('\$450'), findsWidgets);
      expect(find.textContaining('Annual HOA dues'), findsWidgets);
      expect(find.textContaining('Recipient: Cedar Commons HOA'), findsOneWidget);
      expect(find.text('Payer: Avery Brooks'), findsOneWidget);
      expect(find.textContaining('Annual dues due July 31'), findsOneWidget);
      expect(find.textContaining('Member in good standing'), findsOneWidget);
      expect(find.byKey(const ValueKey('giving-action-pay')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('giving-receipt-hoa-dues-payment')),
        findsNothing,
      );

      await _tapVisible(tester, find.byKey(const ValueKey('giving-action-pay')));
      final submitFinder = find.byKey(
        const ValueKey('workflow-action-submit-hoa-dues-payment'),
      );
      expect(submitFinder, findsOneWidget);
      await _tapVisible(tester, submitFinder);

      await _tapTab(tester, 'giving');

      expect(
        find.byKey(const ValueKey('giving-receipt-hoa-dues-payment')),
        findsOneWidget,
      );
      expect(find.textContaining('\$450'), findsWidgets);
      expect(find.textContaining('complete'), findsWidgets);
      expect(find.text('Payment history'), findsOneWidget);
      expect(find.textContaining('Payment completed at '), findsOneWidget);
      expect(find.byKey(const ValueKey('giving-action-pay')), findsNothing);
    });

    testWidgets('board sees read-only dues ledger, not checkout action', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'giving');

      expect(find.text('Payments'), findsWidgets);
      expect(find.text('\$450'), findsWidgets);
      expect(find.textContaining('Annual HOA dues'), findsWidgets);
      expect(find.byKey(const ValueKey('giving-action-pay')), findsNothing);
      expect(find.byKey(const ValueKey('giving-checkout-hoa-dues-payment')), findsNothing);
      expect(
        find.byKey(const ValueKey('giving-readonly-hoa-dues-payment')),
        findsOneWidget,
      );
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
  await tester.tap(find.byKey(ValueKey('community-card-${fixture.communityId}')));
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b40_hoa_payments_');
  final uniqueId = tempDir.path.split(Platform.pathSeparator).last;
  final extensionId = 'ext_verify_hoa_payments_$uniqueId';
  final communityId = 'community_verify_hoa_payments_$uniqueId';
  final extensionFile = File('${tempDir.path}/$extensionId.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/$extensionId.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': extensionId,
      'displayName': 'Cedar Commons HOA',
      'version': '1.0.0',
      'permissions': ['payments.read', 'payments.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': communityId,
      'communityName': 'Cedar Commons HOA',
      'extensionId': extensionId,
      'seedDataFiles': ['seed/community.json'],
      'branding': {'accentColor': '#3E6B8F'},
      'experience': {
        'displayName': 'Cedar Commons HOA',
        'tagline': 'Run dues, documents, facilities, reviews, and exports.',
        'accentColor': '#3E6B8F',
        'roles': [
          {
            'roleId': 'hoa-homeowner',
            'label': 'Avery Brooks',
            'roleLabel': 'Homeowner',
            'description': 'Pays dues and reads governing documents.',
          },
          {
            'roleId': 'hoa-board',
            'label': 'HOA Board',
            'roleLabel': 'Board',
            'description': 'Reviews owner payments and requests.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'hoa-dues-payment',
            'title': 'Annual HOA dues',
            'entryText': 'Annual HOA dues of \$450 are due July 31.',
            'actionText': 'Pay annual HOA dues of \$450.',
            'resultText': 'HOA dues are paid and the receipt is recorded.',
            'givingPayment': {
              'amountLabel': '\$450',
              'purpose': 'Annual HOA dues',
              'recipient': 'Cedar Commons HOA',
              'cadence': 'Annual dues due July 31',
              'entitlement': 'Member in good standing',
            },
          },
        ],
        'personaPolicies': {
          'hoa-dues-payment': {
            'actorPersonaIds': ['hoa-homeowner'],
            'receiverPersonaIds': ['hoa-board'],
            'receiverEntryText': 'Homeowner dues payment is ready for ledger review.',
            'receiverActionText': 'Open ledger',
            'receiverResultText': 'Board reviewed the dues ledger entry.',
          },
        },
      },
    }),
  );
  return _PackagePairFixture(
    extensionPath: extensionFile.path,
    initializationPath: initializationFile.path,
    communityId: communityId,
  );
}

class _PackagePairFixture {
  const _PackagePairFixture({
    required this.extensionPath,
    required this.initializationPath,
    required this.communityId,
  });

  final String extensionPath;
  final String initializationPath;
  final String communityId;
}
