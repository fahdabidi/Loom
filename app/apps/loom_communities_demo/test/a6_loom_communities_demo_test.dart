import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart'
    show currentCommunitySpecVersion;

void main() {
  testWidgets('vt_demo-app_add-community-button', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    expect(find.text('No communities installed'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-community-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('empty-add-community-button')),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_empty-state-cta-loads-community', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(
      tester,
      openButtonKey: const ValueKey('empty-add-community-button'),
    );

    expect(find.text('Garden Club'), findsOneWidget);
  });

  testWidgets('vt_demo-app_local-loader-opens', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await tester.tap(find.byKey(const ValueKey('add-community-button')));
    await tester.pumpAndSettle();

    expect(find.text('Add local community'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('extension-package-path-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('initialization-package-path-field')),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_local-loader-invalid-extension-error', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await tester.tap(find.byKey(const ValueKey('add-community-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('extension-package-path-field')),
      '/emulator/Download/book-club.zip',
    );
    await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Extension package must end with .loom-extension.zip.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_arbitrary-local-extension-loads-card', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(find.text('Garden Club'), findsOneWidget);
    expect(
      find.text('Coordinate garden events and plant exchange requests.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-card-community_garden_club')),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_local-loader-validates-package-pair', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(
      find.text('Installed Garden Club from local packages'),
      findsOneWidget,
    );
    expect(find.text('Garden Club'), findsOneWidget);
  });

  testWidgets('vt_demo-app_cards-after-load and card image after load', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(find.text('Garden Club'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-card-community_garden_club')),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_card-image-after-load', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(
      find.byKey(
        const ValueKey('community-card-identity-community_garden_club'),
      ),
      findsOneWidget,
    );
    expect(find.text('G'), findsNothing);
  });

  testWidgets('vt_demo-app_open-local-extension', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await _installLocalCommunity(tester);
    await tester.tap(
      find.byKey(const ValueKey('community-card-community_garden_club')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('local-extension-ext_garden_club')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('opened-community-identity-community_garden_club'),
      ),
      findsOneWidget,
    );
    expect(find.text('local:ext_garden_club@latest'), findsNothing);
    expect(
      find.text('local:ext_garden_club@latest', skipOffstage: false),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Local package details'),
      200,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 50,
    );
    await tester.tap(find.text('Local package details'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('seed/events.json'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('seed/events.json'), findsOneWidget);
  });

  testWidgets('vt_demo-app_duplicate-local-import-status', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);
    expect(
      find.text('Installed Garden Club from local packages'),
      findsOneWidget,
    );

    await _installLocalCommunity(tester);
    expect(
      find.text('Updated Garden Club from local packages'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-card-community_garden_club')),
      findsOneWidget,
    );
  });
}

Future<void> _installLocalCommunity(
  WidgetTester tester, {
  ValueKey<String> openButtonKey = const ValueKey('add-community-button'),
}) async {
  final fixture = _writeArbitraryPackagePair();
  await tester.tap(find.byKey(openButtonKey));
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
}

_PackagePairFixture _writeArbitraryPackagePair() {
  final tempDir = Directory.systemTemp.createTempSync('loom_widget_arbitrary_');
  final extensionFile = File('${tempDir.path}/garden-club.loom-extension.zip');
  final initializationFile = File('${tempDir.path}/garden-club.loom-init.zip');
  extensionFile.writeAsStringSync(
    jsonEncode({
      'schemaVersion': 1,
      'mode': 'local-demo',
      'extensionId': 'ext_garden_club',
      'displayName': 'Garden Club',
      'version': '1.0.0',
      'permissions': ['content.publish', 'events.write'],
      'assetIds': ['asset_card_garden'],
    }),
  );
  initializationFile.writeAsStringSync(
    jsonEncode({
      'specVersion': currentCommunitySpecVersion,
      'communityId': 'community_garden_club',
      'communityName': 'Garden Club',
      'extensionId': 'ext_garden_club',
      'seedDataFiles': ['seed/community.json', 'seed/events.json'],
      'branding': {
        'cardAssetId': 'asset_card_garden',
        'logoAssetId': 'asset_logo_garden',
        'heroImageAssetId': 'asset_hero_garden',
        'accentColor': '#3A7D44',
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
