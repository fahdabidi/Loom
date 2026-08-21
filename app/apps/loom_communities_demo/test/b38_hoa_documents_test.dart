import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

import 'workflow_ui_test_harness.dart';

const _extensionId = 'ext_verify_hoa_documents';

void main() {
  group('M4.1 HOA document library', () {
    testWidgets('category navigation opens the minutes folder', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'documents');

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('documents-category-minutes')),
      );

      expect(find.byKey(const ValueKey('document-row-doc-board-minutes')), findsOneWidget);
      expect(find.text('April Board Minutes'), findsWidgets);
      expect(find.text('Community Rules'), findsNothing);
    });

    testWidgets('document detail supports embedded and external open', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'documents');

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey('document-open-embedded-doc-community-rules'),
        ),
      );
      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey('document-open-external-doc-community-rules'),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.startsWith('Avery Brooks at ') &&
              widget.data!.contains(' opened Community Rules embedded'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.startsWith('Avery Brooks at ') &&
              widget.data!.contains(' opened Community Rules external'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('document detail displays version and access state', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'documents');

      expect(find.text('Version: v2026.3'), findsOneWidget);
      expect(find.text('Access: available'), findsOneWidget);
      expect(find.text('Updated July 2026'), findsOneWidget);
    });

    testWidgets('restricted document renders access request gating', (
      tester,
    ) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'documents');

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('documents-category-covenants')),
      );
      expect(find.text('Access: restricted'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(
          find.byKey(const ValueKey('document-open-embedded-doc-ccr-amendment')),
        ).onPressed,
        isNull,
      );

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey('document-request-access-doc-ccr-amendment'),
        ),
      );

      expect(find.text('Access: access-requested'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.startsWith('Avery Brooks at ') &&
              widget.data!.contains(
                ' requested access to CCR Amendment Packet',
              ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('acknowledge records exact audit trail entry', (tester) async {
      final fixture = _writeFixture();
      await tester.pumpWidget(const LoomCommunitiesDemoApp());
      await _installAndOpen(tester, fixture);
      await selectPersona(tester, 'hoa-homeowner');
      await _tapTab(tester, 'documents');

      await _tapVisible(
        tester,
        find.byKey(
          const ValueKey('document-acknowledge-doc-community-rules'),
        ),
      );

      expect(find.text('Access: acknowledged'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.startsWith('Avery Brooks at ') &&
              widget.data!.contains(' acknowledged Community Rules'),
        ),
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
  await tester.tap(
    find.byKey(const ValueKey('community-card-community_verify_hoa_documents')),
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder, findsOneWidget);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

_PackagePairFixture _writeFixture() {
  final tempDir = Directory.systemTemp.createTempSync('loom_b38_hoa_docs_');
  final extensionFile = File('${tempDir.path}/$_extensionId.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/$_extensionId.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': _extensionId,
      'displayName': 'Cedar Commons HOA',
      'version': '1.0.0',
      'permissions': ['documents.read', 'documents.write'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': 'community_verify_hoa_documents',
      'communityName': 'Cedar Commons HOA',
      'extensionId': _extensionId,
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
            'description': 'Reviews documents and owner requests.',
          },
        ],
        'workflows': [
          {
            'workflowId': 'cedar-commons-document-library',
            'title': 'Governing docs library',
            'entryText':
                'Browse bylaws, covenants, and meeting minutes for Cedar Commons.',
            'actionText': 'Open the selected governing document.',
            'resultText': 'Document access and audit state are updated.',
            'documentLibrary': {
              'categories': ['bylaws', 'covenants', 'minutes'],
              'documents': [
                {
                  'documentId': 'doc-community-rules',
                  'title': 'Community Rules',
                  'category': 'bylaws',
                  'version': 'v2026.3',
                  'updatedLabel': 'Updated July 2026',
                  'accessState': 'available',
                  'summary':
                      'Member-visible rules, quiet hours, parking, and common-area policies.',
                },
                {
                  'documentId': 'doc-ccr-amendment',
                  'title': 'CCR Amendment Packet',
                  'category': 'covenants',
                  'version': 'v2026.1',
                  'updatedLabel': 'Board draft',
                  'accessState': 'restricted',
                  'summary':
                      'Board-reviewed covenant amendment packet requiring access approval.',
                },
                {
                  'documentId': 'doc-board-minutes',
                  'title': 'April Board Minutes',
                  'category': 'minutes',
                  'version': 'v2026.04',
                  'updatedLabel': 'Posted May 2',
                  'accessState': 'available',
                  'summary': 'Approved meeting minutes from the April board session.',
                },
              ],
            },
          },
        ],
        'personaPolicies': {
          'cedar-commons-document-library': {
            'actorPersonaIds': ['hoa-homeowner', 'hoa-board'],
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
