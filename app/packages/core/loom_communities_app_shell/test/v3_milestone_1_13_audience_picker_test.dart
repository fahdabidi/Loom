import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _alexId = 'tabletop-alex';
const _beaId = 'tabletop-bea';
const _caraId = 'tabletop-cara';

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-audience-picker-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-audience-picker',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-event-invite-audience',
        'title': 'Event invitation audience',
        'entryText': 'Select members invited to the event.',
        'actionText': 'Update audience.',
        'resultText': 'Invitation audience saved.',
      },
    ],
    'personas': [
      {
        'personaId': _alexId,
        'label': 'Alex',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
      {
        'personaId': _beaId,
        'label': 'Bea',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
      {
        'personaId': _caraId,
        'label': 'Cara',
        'roleLabel': 'Member',
        'description': 'Tabletop Club member',
      },
    ],
    'audiencePicker': {
      'audienceId': 'tabletop-friday-invite',
      'title': 'Friday game night invitation',
      'invitedPersonaIds': [_caraId],
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

Future<void> _pumpUntilText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (find.text(text).evaluate().isNotEmpty) return;
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
  testWidgets('selection and chip removal update the invited-persona array', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-audience')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('audience-picker-member-$_alexId')),
    );

    expect(find.text('Invited persona ids: [$_caraId]'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audience-picker-chip-$_caraId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('audience-picker-member-$_beaId')),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('audience-picker-member-$_alexId')),
    );
    await _pumpUntilText(tester, 'Invited persona ids: [$_alexId, $_caraId]');

    expect(
      find.text('Invited persona ids: [$_alexId, $_caraId]'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('audience-picker-chip-$_alexId')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('audience-picker-chip-$_caraId')),
      findsOneWidget,
    );

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('audience-picker-chip-delete-$_alexId')),
    );
    await _pumpUntilText(tester, 'Invited persona ids: [$_caraId]');

    expect(find.text('Invited persona ids: [$_caraId]'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('audience-picker-chip-$_alexId')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('audience-picker-chip-$_caraId')),
      findsOneWidget,
    );
  });
}
