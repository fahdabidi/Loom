import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

const _going = ['alex', 'bea', 'cara', 'dee', 'eli'];

LocalInstalledCommunity _community() => const LocalInstalledCommunity(
  communityId: 'v3-tournament-ballot-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-tournament-ballot',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-tournament-ballot-workflow',
        'title': 'Tournament ballot',
        'entryText': 'Vote for the next tournament game.',
        'actionText': 'Cast your vote.',
        'resultText': 'Vote recorded.',
      },
    ],
    'personas': [
      {
        'personaId': 'alex',
        'label': 'Alex',
        'roleLabel': 'Member',
        'description': 'Member',
      },
    ],
    'tournamentBallot': {
      'eventId': 'tabletop-friday-tournament',
      'goingPersonaIds': _going,
      'candidates': [
        {'id': 'Catan', 'name': 'Catan', 'description': 'Trade game'},
        {'id': 'Azul', 'name': 'Azul', 'description': 'Tile game'},
        {'id': 'Wingspan', 'name': 'Wingspan', 'description': 'Bird game'},
      ],
    },
  },
);

Widget _host() => MaterialApp(
  home: LocalExtensionScreen(community: _community(), seedDataFiles: const []),
);

LocalInstalledCommunity _attendanceCommunity() => const LocalInstalledCommunity(
  communityId: 'v3-tournament-attendance-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-tournament-attendance',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'ballot',
        'title': 'Ballot',
        'entryText': 'Vote',
        'actionText': 'Vote',
        'resultText': 'Voted',
      },
    ],
    'personas': [
      {
        'personaId': 'bea',
        'label': 'Bea',
        'roleLabel': 'Member',
        'description': 'Member',
      },
    ],
    'tournamentBallot': {
      'eventId': 'attendance-event',
      'minimumAttendance': 3,
      'goingPersonaIds': ['alex'],
      'candidates': [
        {'id': 'Catan', 'name': 'Catan'},
      ],
    },
  },
);
Widget _attendanceHost() => MaterialApp(
  home: LocalExtensionScreen(
    community: _attendanceCommunity(),
    seedDataFiles: const [],
  ),
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _pumpUntilAbsent(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt += 1) {
    if (finder.evaluate().isEmpty) return;
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
  testWidgets('tapping a candidate opens and closes its detail dialog', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-ballot')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tournament-candidate-name-Catan')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('tournament-candidate-name-Catan')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tournament-candidate-detail-dialog')),
    );
    expect(
      find.byKey(
        const ValueKey('tournament-candidate-detail-description-Catan'),
      ),
      findsOneWidget,
    );
    expect(find.text('Trade game'), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('tournament-candidate-detail-close')),
    );
    expect(
      find.byKey(const ValueKey('tournament-candidate-detail-dialog')),
      findsNothing,
    );
  });
  testWidgets('RSVP updates formula-backed attendance', (tester) async {
    await tester.pumpWidget(_attendanceHost());
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('community-tab-ballot')),
    );
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('tournament-attendance')),
    );
    expect(find.text('Accepted: 1 / 3'), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('tournament-rsvp-going')),
    );
    await _pumpUntilFound(tester, find.text('Accepted: 2 / 3'));
    expect(find.text('Accepted: 2 / 3'), findsOneWidget);
  });
  testWidgets(
    'a genuine tie creates a real runoff ballot with only tied candidates',
    (tester) async {
      await tester.pumpWidget(_host());
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('community-tab-ballot')),
      );
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('tournament-vote-Catan')),
      );

      expect(
        find.byKey(const ValueKey('tournament-candidate-Catan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tournament-candidate-Azul')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tournament-candidate-Wingspan')),
        findsOneWidget,
      );

      // 2 votes Catan, 2 votes Azul, 1 vote Wingspan - a genuine 2-way tie.
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-vote-Catan')),
      );
      await _pumpUntilFound(tester, find.text('Catan: 1 votes'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-vote-Catan')),
      );
      await _pumpUntilFound(tester, find.text('Catan: 2 votes'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-vote-Azul')),
      );
      await _pumpUntilFound(tester, find.text('Azul: 1 votes'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-vote-Azul')),
      );
      await _pumpUntilFound(tester, find.text('Azul: 2 votes'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-vote-Wingspan')),
      );
      await _pumpUntilFound(tester, find.text('Wingspan: 1 votes'));

      await _tapVisible(
        tester,
        find.byKey(const ValueKey('tournament-close-vote')),
      );
      await _pumpUntilAbsent(
        tester,
        find.byKey(const ValueKey('tournament-candidate-Wingspan')),
      );

      expect(
        find.byKey(const ValueKey('tournament-candidate-Catan')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tournament-candidate-Azul')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('tournament-candidate-Wingspan')),
        findsNothing,
      );
      expect(find.text('Selected game: TBD'), findsOneWidget);
    },
  );
}
