import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_demo_local_backend/loom_demo_local_backend.dart';

LocalInstalledCommunity _timelineCommunity() => const LocalInstalledCommunity(
  communityId: 'v3-timeline-community',
  displayName: 'Tabletop Club',
  extensionId: 'v3-status-timeline',
  logoAssetId: null,
  cardImageAssetId: null,
  heroImageAssetId: null,
  accentColor: '#4a3b2a',
  experienceConfiguration: {
    'workflows': [
      {
        'workflowId': 'tabletop-status-timeline-workflow',
        'title': 'Friday event',
        'entryText': 'Follow the event status.',
        'actionText': 'View timeline.',
        'resultText': 'Timeline viewed.',
      },
    ],
    'personas': [
      {
        'personaId': 'tabletop-member',
        'label': 'Member',
        'roleLabel': 'Member',
        'description': 'Member',
      },
    ],
    'statusTimeline': {
      'timelineId': 'friday-event',
      'title': 'Friday event status',
      'events': [
        {
          'eventId': 'created',
          'timestamp': '2026-07-10T10:00:00.000Z',
          'label': 'Event created',
        },
        {
          'eventId': 'opened',
          'timestamp': '2026-07-11T10:00:00.000Z',
          'label': 'RSVP opened',
        },
        {
          'eventId': 'confirmed',
          'timestamp': '2026-07-12T10:00:00.000Z',
          'label': 'Venue confirmed',
        },
      ],
    },
  },
);

LocalInstalledCommunity _detailCommunity({required bool authorized}) =>
    LocalInstalledCommunity(
      communityId: authorized ? 'v3-protected-owner' : 'v3-protected-outsider',
      displayName: 'Tabletop Club',
      extensionId: authorized ? 'v3-protected-owner' : 'v3-protected-outsider',
      logoAssetId: null,
      cardImageAssetId: null,
      heroImageAssetId: null,
      accentColor: '#4a3b2a',
      experienceConfiguration: {
        'workflows': const [
          {
            'workflowId': 'tabletop-protected-detail-workflow',
            'title': 'Tournament venue',
            'entryText': 'View protected venue details.',
            'actionText': 'View details.',
            'resultText': 'Details viewed.',
          },
        ],
        'personas': [
          {
            'personaId': authorized ? 'tabletop-owner' : 'tabletop-outsider',
            'label': authorized ? 'Owner' : 'Outsider',
            'roleLabel': 'Member',
            'description': 'Member',
          },
        ],
        'protectedDetail': {
          'detailId': 'venue-code',
          'title': 'Tournament venue details',
          'ownerPersonaId': 'tabletop-owner',
          'assignedTo': const ['tabletop-helper'],
          'fullDetail': 'The venue access code is 4829.',
        },
      },
    );

Widget _host(LocalInstalledCommunity community) => MaterialApp(
  home: LocalExtensionScreen(community: community, seedDataFiles: const []),
);
Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  testWidgets('timeline nodes are timestamped and chronological', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_timelineCommunity()));
    await _tap(tester, find.byKey(const ValueKey('community-tab-timeline')));
    await _until(
      tester,
      find.byKey(const ValueKey('status-timeline-node-confirmed')),
    );
    final created = tester.getTopLeft(
      find.byKey(const ValueKey('status-timeline-node-created')),
    );
    final opened = tester.getTopLeft(
      find.byKey(const ValueKey('status-timeline-node-opened')),
    );
    final confirmed = tester.getTopLeft(
      find.byKey(const ValueKey('status-timeline-node-confirmed')),
    );
    expect(created.dy, lessThan(opened.dy));
    expect(opened.dy, lessThan(confirmed.dy));
    expect(find.text('2026-07-10T10:00:00.000Z'), findsOneWidget);
    expect(find.text('2026-07-11T10:00:00.000Z'), findsOneWidget);
    expect(find.text('2026-07-12T10:00:00.000Z'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('status-timeline-line-created')),
      findsOneWidget,
    );
  });

  testWidgets('protected detail distinguishes authorized and masked viewers', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_detailCommunity(authorized: true)));
    await _tap(tester, find.byKey(const ValueKey('community-tab-details')));
    await _until(tester, find.byKey(const ValueKey('protected-detail-full')));
    expect(find.byKey(const ValueKey('protected-detail-full')), findsOneWidget);
    expect(find.text('The venue access code is 4829.'), findsOneWidget);
    expect(find.byKey(const ValueKey('protected-detail-masked')), findsNothing);

    await tester.pumpWidget(_host(_detailCommunity(authorized: false)));
    await _tap(tester, find.byKey(const ValueKey('community-tab-details')));
    await _until(tester, find.byKey(const ValueKey('protected-detail-masked')));
    expect(
      find.byKey(const ValueKey('protected-detail-masked')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('protected-detail-lock')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('protected-detail-why-hidden')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('protected-detail-full')), findsNothing);
    expect(find.text('The venue access code is 4829.'), findsNothing);
  });
}
