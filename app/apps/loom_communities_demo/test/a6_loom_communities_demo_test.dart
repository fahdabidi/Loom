import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

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

    await tester.tap(find.byKey(const ValueKey('empty-add-community-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
    await tester.pumpAndSettle();

    expect(find.text('Neighborhood Book Club'), findsOneWidget);
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
      find.text('Extension package must end with .loom-extension.zip.'),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_local-loader-validates-package-pair', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(
      find.text('Installed Neighborhood Book Club from local packages'),
      findsOneWidget,
    );
    expect(find.text('Neighborhood Book Club'), findsOneWidget);
  });

  testWidgets('vt_demo-app_cards-after-load and card image after load', (
    tester,
  ) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(find.text('Neighborhood Book Club'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-card-community_book_club')),
      findsOneWidget,
    );
  });

  testWidgets('vt_demo-app_card-image-after-load', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);

    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('vt_demo-app_open-local-extension', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await _installLocalCommunity(tester);
    await tester.tap(find.byKey(const ValueKey('community-card-community_book_club')));
    await tester.pumpAndSettle();

    expect(find.text('Opening Neighborhood Book Club'), findsOneWidget);
  });

  testWidgets('vt_demo-app_duplicate-local-import-status', (tester) async {
    await tester.pumpWidget(const LoomCommunitiesDemoApp());

    await _installLocalCommunity(tester);
    expect(
      find.text('Installed Neighborhood Book Club from local packages'),
      findsOneWidget,
    );

    await _installLocalCommunity(tester);
    expect(
      find.text('Updated Neighborhood Book Club from local packages'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('community-card-community_book_club')),
      findsOneWidget,
    );
  });
}

Future<void> _installLocalCommunity(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('add-community-button')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('load-local-community-button')));
  await tester.pumpAndSettle();
}
