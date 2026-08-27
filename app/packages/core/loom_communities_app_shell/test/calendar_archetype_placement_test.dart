import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';
import 'package:loom_workflow_engine/loom_workflow_engine.dart';

/// The `calendar` archetype, placed in tabs that are not called "calendar".
///
/// The point of making it an archetype rather than a tab convention: a
/// community names its own tabs, and a prayer time belongs on a schedule
/// whatever that schedule is called. Before this family existed the calendar
/// surface was reachable only by being an `event-rsvp`, so an item nobody
/// RSVPs to could not have one.
void main() {
  test('a calendar workflow renders a calendar in a tab named anything', () {
    for (final tabId in const ['prayer-times', 'fixtures', 'bin-collection']) {
      final tabs = _tabsFor(tabId: tabId, family: 'calendar');
      final tab = tabs.firstWhere((candidate) => candidate.tabId == tabId);
      expect(
        tab.rendererContract.rendererId,
        'CalendarTabSurface',
        reason: '"$tabId" binds only calendar workflows and must render one',
      );
    }
  });

  test('event-rsvp still reaches the calendar surface', () {
    // The new family must not displace the old one. Every shipped calendar in
    // the corpus is an event-rsvp, and they all still have to work.
    final tabs = _tabsFor(tabId: 'calendar', family: 'event-rsvp');
    final tab = tabs.firstWhere((candidate) => candidate.tabId == 'calendar');
    expect(tab.rendererContract.rendererId, 'CalendarTabSurface');
  });

  test('a tab named "calendar" holding forms is still a list', () {
    // The tab id has never been what decides this, and adding the archetype
    // must not quietly make it so.
    final tabs = _tabsFor(tabId: 'calendar', family: 'formEntry');
    final tab = tabs.firstWhere((candidate) => candidate.tabId == 'calendar');
    expect(tab.rendererContract.rendererId, isNot('CalendarTabSurface'));
  });

  test('calendar is a closed vocabulary without the RSVP actions', () {
    const resolver = ArchetypeResolver();
    for (final action in const [
      'view',
      'create',
      'edit',
      'cancel',
      'reopen',
      'set_reminder',
      'deliver_reminder',
      'propose_change',
      'record_outcome',
    ]) {
      expect(
        resolver.isActionInVocabulary('calendar', action),
        isTrue,
        reason: '$action must be legal for a calendar item',
      );
    }
    // The absence of these three is the entire difference from event-rsvp.
    for (final action in const [
      'respond',
      'withdraw_response',
      'join_waitlist',
    ]) {
      expect(
        resolver.isActionInVocabulary('calendar', action),
        isFalse,
        reason: 'nobody attends a calendar item, so $action must be illegal',
      );
      expect(
        resolver.isActionInVocabulary('event-rsvp', action),
        isTrue,
        reason: '$action must remain legal for event-rsvp',
      );
    }
  });

  test('calendar owns reminders and no attendance bookkeeping', () {
    final contract = ArchetypeResolver.contracts['calendar']!;
    expect(contract.bookkeeping, contains('reminderFanIds'));
    // A community wanting an attendance list has chosen the wrong family.
    expect(contract.bookkeeping, isNot(contains('goingFanIds')));
    expect(contract.bookkeeping, isNot(contains('waitlistFanIds')));
  });
}

/// Tab specs for an experience with one workflow bound to [tabId].
List<LoomAppShellTabSpec> _tabsFor({
  required String tabId,
  required String family,
}) {
  final machine = LoomWorkflowStateMachine.fromJson({
    'initialState': 'scheduled',
    'states': {
      'scheduled': {'label': 'Scheduled'},
    },
    'renderBindings': [
      {
        'states': ['scheduled'],
        'audience': 'any',
        'tabId': tabId,
        'cardSurfaceFamily': family,
        'bindingKind': 'primary',
      },
    ],
    'transitions': <Map<String, dynamic>>[],
    'instanceDataSchema': {
      'eventDate': {'type': 'date', 'writableBy': 'formEntry'},
      'eventTime': {'type': 'text', 'writableBy': 'formEntry'},
    },
  }, 'scheduled-item');

  return appShellTabsFor(
    experience: LoomExperienceDefinition(
      extensionId: 'ext_test',
      displayName: 'Test community',
      tagline: 'Scheduling things',
      accentColor: 0xFF285A7B,
      workflows: const [],
      workflowDefinitions: {'scheduled-item': machine},
    ),
    roleId: 'member',
    appShellConfiguration: {
      'tabs': [
        {'tabId': tabId, 'label': 'Schedule'},
      ],
    },
  );
}
