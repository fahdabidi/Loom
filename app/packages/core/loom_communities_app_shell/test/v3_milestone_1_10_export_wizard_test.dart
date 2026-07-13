import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _memberId = 'tabletop-member';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-export-wizard-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-export-wizard',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-export-records',
        'title': 'Tabletop Club export',
        'entryText': 'Review and transfer your club records.',
        'actionText': 'Start export.',
        'resultText': 'Export transfer completed.',
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
    'exportWizard': {
      'wizardId': 'tabletop-records-export',
      'scope': ['Members', 'Game library', 'Event RSVPs'],
    },
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
}

void main() {
  testWidgets('export steps unlock only after their engine transition', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    final exportTab = find.byKey(const ValueKey('community-tab-export'));
    await _tapVisible(tester, exportTab);
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('export-action-generate')),
    );

    expect(find.byKey(const ValueKey('export-wizard-stepper')), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('export-action-generate')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('export-action-transfer')), findsNothing);
    expect(find.byKey(const ValueKey('export-action-complete')), findsNothing);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('export-action-generate')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('export-action-transfer')),
    );

    expect(find.byKey(const ValueKey('export-action-generate')), findsNothing);
    expect(
      find.byKey(const ValueKey('export-action-transfer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('export-action-complete')), findsNothing);
  });
}
