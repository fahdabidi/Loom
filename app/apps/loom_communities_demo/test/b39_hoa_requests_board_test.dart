import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  group('M4.2 HOA architectural requests', () {
    testWidgets('homeowner submits request and editable submitted fields render', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');

      expect(find.byKey(const ValueKey('hoa-request-form-entry')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hoa-request-project-description')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hoa-request-property-address')),
        findsOneWidget,
      );
      await _submitRequest(tester, 'Fence color update');

      expect(find.text('State: Submitted'), findsOneWidget);
      expect(find.text('Project: Fence color update'), findsOneWidget);
      expect(find.byKey(const ValueKey('hoa-request-action-withdraw')), findsOneWidget);
    });

    testWidgets('board dashboard queue opens same reviewer timeline', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Pergola review packet');

      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'admin');
      expect(find.byKey(const ValueKey('hoa-board-dashboard')), findsOneWidget);
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('hoa-board-queue-hoa-homeowner')),
      );

      expect(find.byKey(const ValueKey('hoa-request-timeline')), findsOneWidget);
      expect(find.text('Project: Pergola review packet'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hoa-request-action-start-review')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hoa-request-action-request-changes')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('hoa-request-action-approve')), findsOneWidget);
      expect(find.byKey(const ValueKey('hoa-request-action-reject')), findsOneWidget);
      expect(find.byKey(const ValueKey('hoa-request-action-withdraw')), findsNothing);
    });

    testWidgets('board request-changes sends homeowner back to editable form', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Solar panel sketch');

      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'admin');
      await _tapAction(tester, 'request-changes');

      expect(find.text('State: Changes needed'), findsOneWidget);
      expect(
        find.text('Reviewer note: Please revise the color sample and setback diagram.'),
        findsOneWidget,
      );

      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      expect(find.text('State: Changes needed'), findsOneWidget);
      expect(find.byKey(const ValueKey('hoa-request-form-entry')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('hoa-request-action-resubmit')),
        findsOneWidget,
      );
    });

    testWidgets('board approves and homeowner can reopen approved request', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Deck railing update');

      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'admin');
      await _tapAction(tester, 'approve');
      expect(find.text('State: Approved'), findsOneWidget);

      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      expect(find.byKey(const ValueKey('hoa-request-form-entry')), findsNothing);
      await _tapAction(tester, 'reopen');
      expect(find.text('State: Reopened'), findsOneWidget);
    });

    testWidgets('board rejects and homeowner can appeal', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Mailbox replacement');

      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'admin');
      await _tapAction(tester, 'reject');
      expect(find.text('State: Denied'), findsOneWidget);

      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _tapAction(tester, 'appeal');
      expect(find.text('State: Reopened'), findsOneWidget);
    });

    testWidgets('homeowner can withdraw a submitted request', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Patio light change');

      await _tapAction(tester, 'withdraw');
      expect(find.text('State: Withdrawn'), findsOneWidget);
      expect(find.byKey(const ValueKey('hoa-request-form-entry')), findsNothing);
    });

    testWidgets('homeowner can resubmit after reviewer send-back', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _submitRequest(tester, 'Garden wall update');

      await selectPersona(tester, 'hoa-board');
      await _tapTab(tester, 'admin');
      await _tapAction(tester, 'request-changes');

      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'requests');
      await _tapAction(tester, 'resubmit');
      expect(find.text('State: Submitted'), findsOneWidget);
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

Future<void> _submitRequest(WidgetTester tester, String project) async {
  await tester.enterText(
    find.byKey(const ValueKey('hoa-request-project-description')),
    project,
  );
  await _tapVisible(tester, find.byKey(const ValueKey('hoa-request-submit')));
}

Future<void> _tapAction(WidgetTester tester, String transitionId) async {
  await _tapVisible(
    tester,
    find.byKey(ValueKey('hoa-request-action-$transitionId')),
  );
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b39_hoa_requests_');
  final uniqueId = tempDir.path.split(Platform.pathSeparator).last;
  final extensionId = 'ext_verify_hoa_requests_$uniqueId';
  final communityId = 'community_verify_hoa_requests_$uniqueId';
  final extensionFile = File('${tempDir.path}/$extensionId.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/$extensionId.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': extensionId,
      'displayName': 'Cedar Commons HOA',
      'version': '1.0.0',
      'permissions': ['requests.read', 'requests.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'communityId': communityId,
      'communityName': 'Cedar Commons HOA',
      'extensionId': extensionId,
      'seedDataFiles': ['seed/community.json'],
      'branding': {'accentColor': '#3E6B8F'},
      'experience': {
        'displayName': 'Cedar Commons HOA',
        'tagline': 'Run dues, documents, facilities, reviews, and exports.',
        'accentColor': '#3E6B8F',
        'personas': [
          {
            'personaId': 'hoa-homeowner',
            'label': 'Avery Brooks',
            'roleLabel': 'Homeowner',
            'description': 'Submits architectural requests.',
          },
          {
            'personaId': 'hoa-board',
            'label': 'HOA Board',
            'roleLabel': 'Board',
            'description': 'Reviews owner architectural requests.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'cedar-commons-architectural-request',
            'title': 'Architectural request',
            'entryText': 'Submit exterior changes for board review.',
            'actionText': 'Track review status and next steps.',
            'resultText': 'Board decision and owner follow-up are recorded.',
            'architecturalRequest': {
              'projectTypes': [
                'Fence',
                'Deck',
                'Solar',
                'Paint',
                'Landscape',
              ],
              'defaultProjectDescription': 'Fence color update',
              'defaultPropertyAddress': '42 Cedar Loop',
              'defaultRequestedCompletionDate': '2026-08-15',
              'defaultAttachments': 'site-plan.pdf',
            },
          },
        ],
        'personaPolicies': {
          'cedar-commons-architectural-request': {
            'actorPersonaIds': ['hoa-homeowner'],
            'receiverPersonaIds': ['hoa-board'],
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
