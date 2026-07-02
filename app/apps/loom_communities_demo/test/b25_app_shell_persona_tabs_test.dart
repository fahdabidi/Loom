import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_demo/main.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  test('app shell tabs declare tab-native renderer contracts', () {
    final experience = experienceForExtensionId('ext_camera_club');
    final tabs = appShellTabsFor(
      experience: experience,
      personaId: 'camera-organizer',
    );

    final contractsByTab = {
      for (final tab in tabs) tab.tabId: tab.rendererContract,
    };

    expect(contractsByTab['home']!.rendererId, 'HomeTabSurfaceStack');
    expect(contractsByTab['calendar']!.rendererId, 'CalendarTabSurface');
    expect(contractsByTab['marketplace']!.rendererId, 'MarketplaceTabSurface');
    expect(contractsByTab['messages']!.rendererId, 'MessagesTabSurface');

    expect(
      contractsByTab['calendar']!.requiredAnatomy,
      contains('month or week/date strip'),
    );
    expect(
      contractsByTab['marketplace']!.requiredAnatomy,
      contains('browse/search/filter header'),
    );
    expect(
      contractsByTab['messages']!.requiredAnatomy,
      contains('message composer'),
    );
  });

  test('card surfaces map to tab-native renderer targets', () {
    final experience = experienceForExtensionId('ext_camera_club');
    final entries = {
      for (final workflow in experience.workflows)
        workflow.workflowId: cardSurfaceRegistryEntryFor(
          extensionId: experience.extensionId,
          workflow: workflow,
        ),
    };

    expect(
      entries['photo-walk-rsvp']!.rendererTarget,
      contains('CalendarTabSurface/EventRsvpDetailRenderer'),
    );
    expect(
      entries['gear-loan-request']!.rendererTarget,
      contains('MarketplaceTabSurface/MarketplaceListingDetailRenderer'),
    );
    expect(
      tabRendererContractFor(
        'workflow-status-timeline-actions',
      ).requiredAnatomy,
      contains('status timeline'),
    );
  });

  test('persona tab resolver keeps shell defaults and filters admin tabs', () {
    final experience = experienceForExtensionId('ext_mosque');

    final adminTabs = appShellTabsFor(
      experience: experience,
      personaId: 'mosque-admin',
    );
    final memberTabs = appShellTabsFor(
      experience: experience,
      personaId: 'mosque-member',
    );

    expect(adminTabs.map((tab) => tab.tabId), containsAll(['home', 'admin']));
    expect(adminTabs.last.tabId, 'messages');
    expect(memberTabs.map((tab) => tab.tabId), isNot(contains('admin')));
    expect(
      memberTabs.map((tab) => tab.tabId),
      containsAll(['home', 'messages']),
    );

    for (final tab in [...adminTabs, ...memberTabs]) {
      expect(tab.hasExplicitPinningPolicy, isTrue, reason: tab.tabId);
      if (tab.pinnedWorkflowIds.isEmpty) {
        expect(tab.pinningPolicy, startsWith('none'), reason: tab.tabId);
      } else {
        expect(
          tab.pinningPolicy,
          'pin-first-critical-surface',
          reason: tab.tabId,
        );
      }
    }
  });

  test('package app shell configuration can define custom persona tabs', () {
    final experience = experienceForExtensionId('ext_camera_club');
    final tabs = appShellTabsFor(
      experience: experience,
      personaId: 'camera-organizer',
      appShellConfiguration: {
        'tabs': [
          {
            'tabId': 'calendar',
            'label': 'Walks',
            'icon': 'calendar',
            'description': 'Photo walk schedule and RSVP detail.',
            'rendererContractId': 'calendar-agenda-event-detail',
            'sectionTitles': ['Upcoming events'],
            'cardSurfaceFamilies': ['event-rsvp'],
            'pinningPolicy': 'pin-first-critical-surface',
            'pinningPolicyRationale':
                'The next photo walk is pinned because it is the most time-sensitive item.',
            'pinnedWorkflowIds': ['photo-walk-rsvp'],
          },
          {
            'tabId': 'marketplace',
            'label': 'Gear',
            'icon': 'storefront',
            'description': 'Loan, browse, and list camera gear.',
            'rendererContractId': 'marketplace-browse-listing-detail',
            'cardSurfaceFamilies': ['equipment-loan'],
            'pinningPolicy': 'none',
            'pinningPolicyRationale':
                'Gear listings are sorted by availability instead of pinned.',
          },
        ],
        'personaTabs': {
          'camera-member': [
            {
              'tabId': 'messages',
              'label': 'Club chat',
              'icon': 'messages',
              'description': 'Member threads and invites.',
              'rendererContractId': 'messages-inbox-thread-composer',
              'pinningPolicy': 'none',
              'pinningPolicyRationale':
                  'Messages uses inbox/thread state rather than pinned cards.',
            },
          ],
        },
      },
    );

    final calendar = tabs.firstWhere((tab) => tab.tabId == 'calendar');
    final marketplace = tabs.firstWhere((tab) => tab.tabId == 'marketplace');

    expect(calendar.label, 'Walks');
    expect(calendar.rendererContract.rendererId, 'CalendarTabSurface');
    expect(calendar.pinnedWorkflowIds, ['photo-walk-rsvp']);
    expect(marketplace.label, 'Gear');
    expect(marketplace.pinningPolicy, 'none');
  });

  testWidgets('wf_app-shell-persona-tabs-customization', (tester) async {
    final target = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_mosque',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    expect(find.byKey(const ValueKey('community-bottom-tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-tab-messages')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('community-tab-admin')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('community-tab-messages')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('messages-tab-surface')), findsOneWidget);

    await selectPersona(tester, 'mosque-member');

    expect(find.byKey(const ValueKey('community-tab-admin')), findsNothing);
    expect(find.byKey(const ValueKey('community-tab-home')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('community-tab-messages')),
      findsOneWidget,
    );
  });

  testWidgets('tab-native renderer widgets render for community tabs', (
    tester,
  ) async {
    final target = loomEvidenceTargets.firstWhere(
      (target) => target.extensionId == 'ext_camera_club',
    );

    await tester.pumpWidget(const LoomCommunitiesDemoApp());
    await installEvidenceTarget(tester, target);
    await openEvidenceTarget(tester, target);

    await _tapTab(tester, 'calendar');
    expect(find.byKey(const ValueKey('calendar-tab-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-week-strip')), findsOneWidget);
    expect(
      find.textContaining('/calendar/', skipOffstage: false),
      findsOneWidget,
    );

    await _tapTab(tester, 'marketplace');
    expect(
      find.byKey(const ValueKey('marketplace-tab-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('marketplace-browse-search')),
      findsOneWidget,
    );
    expect(
      find.textContaining('/marketplace/', skipOffstage: false),
      findsOneWidget,
    );

    await _tapTab(tester, 'messages');
    expect(find.byKey(const ValueKey('messages-tab-surface')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('messages-inbox-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('messages-thread-composer-preview')),
      findsOneWidget,
    );
  });
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
