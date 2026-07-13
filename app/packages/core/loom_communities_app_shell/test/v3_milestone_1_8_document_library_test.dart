import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-document-library-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-document-library',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-document-library',
        'title': 'Tabletop Club library',
        'entryText': 'Club policies and game-night resources.',
        'actionText': 'Browse the document library.',
        'resultText': 'Document library opened.',
        'documentLibrary': {
          'categories': ['Club policies', 'Game nights'],
          'documents': [
            {
              'documentId': 'tabletop-code-of-conduct',
              'title': 'Code of conduct',
              'category': 'Club policies',
              'version': 'v2.1',
              'updatedLabel': 'Updated Jul 8, 2026',
              'accessState': 'available',
            },
            {
              'documentId': 'tabletop-lending-policy',
              'title': 'Game lending policy',
              'category': 'Club policies',
              'version': 'v1.4',
              'updatedLabel': 'Updated Jun 27, 2026',
              'accessState': 'available',
            },
            {
              'documentId': 'tabletop-teach-a-game-guide',
              'title': 'Teach-a-game host guide',
              'category': 'Game nights',
              'version': 'v3.0',
              'updatedLabel': 'Updated Jul 10, 2026',
              'accessState': 'available',
            },
          ],
        },
      },
    ],
    'personas': [
      {
        'personaId': _memberId,
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
    ],
  },
);

Widget _host() => MaterialApp(
  home: LocalExtensionScreen(community: _community(), seedDataFiles: const []),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  testWidgets(
    'Tabletop document library lists categories and filters documents',
    (tester) async {
      await tester.pumpWidget(_host());
      await tester.tap(find.byKey(const ValueKey('community-tab-documents')));
      await tester.pump();
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('documents-category-Club policies')),
      );

      expect(
        find.byKey(const ValueKey('documents-category-Club policies')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('documents-category-Game nights')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('document-row-tabletop-code-of-conduct')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('document-row-tabletop-lending-policy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('document-row-tabletop-teach-a-game-guide')),
        findsNothing,
      );

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('documents-category-Game nights')),
      );

      expect(
        find.byKey(const ValueKey('document-row-tabletop-code-of-conduct')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('document-row-tabletop-lending-policy')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('document-row-tabletop-teach-a-game-guide')),
        findsOneWidget,
      );
    },
  );
}
