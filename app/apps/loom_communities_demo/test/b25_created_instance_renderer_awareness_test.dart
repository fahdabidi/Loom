import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'b25_created_instance_identity.dart';

// Phase-1 honesty probes for HARNESS-the-created-instance-reader-must-be-
// renderer-aware. Each fixture mounts the widget-key namespace of a NON-list
// tab surface, snapshots the ids the CURRENT reader sees BEFORE the created
// card mounts, then requires the created instance to be identified. Calendar,
// marketplace and table fixtures MUST fail against the current
// single-namespace reader with 0 candidates; the generic-list control must
// pass. These tests are updated to the renderer-aware signature with the fix.
void main() {
  group('B25 created-instance reader renderer awareness (honesty probes)', () {
    testWidgets('calendar agenda tile is identified after creation', (
      tester,
    ) async {
      await tester.pumpWidget(const _CalendarAgendaFixture());
      final existingInstanceIds = engineNativeInstanceIdsForTab(
        tester,
        tabId: 'calendar',
        tabBoundSurfaceFamilies: const {'event-rsvp'},
      );
      expect(
        existingInstanceIds,
        {'existing-draft'},
        reason:
            'The facts- twin and the day-keyed group/date keys must not '
            'double-count the mounted tile.',
      );
      await tester.pumpWidget(const _CalendarAgendaFixture(showCreated: true));
      final instanceId = await waitForCreatedEngineNativeInstanceId(
        tester,
        workflowType: 'garden-event-rsvp',
        tabId: 'calendar',
        tabBoundSurfaceFamilies: const {'event-rsvp'},
        existingInstanceIds: existingInstanceIds,
        timeout: Duration.zero,
      );
      expect(instanceId, 'created-garden-event');
    });

    testWidgets('marketplace listing is identified after creation', (
      tester,
    ) async {
      await tester.pumpWidget(const _MarketplaceListingFixture());
      final existingInstanceIds = engineNativeInstanceIdsForTab(
        tester,
        tabId: 'marketplace',
        tabBoundSurfaceFamilies: const {'equipment-loan'},
      );
      expect(
        existingInstanceIds,
        {'existing-tool-listing'},
        reason:
            'The simultaneously-mounted -tap- twin must not double-count '
            'the listing.',
      );
      await tester.pumpWidget(
        const _MarketplaceListingFixture(showCreated: true),
      );
      final instanceId = await waitForCreatedEngineNativeInstanceId(
        tester,
        workflowType: 'garden-tool-loan',
        tabId: 'marketplace',
        tabBoundSurfaceFamilies: const {'equipment-loan'},
        existingInstanceIds: existingInstanceIds,
        timeout: Duration.zero,
      );
      expect(instanceId, 'created-tool-listing');
    });

    testWidgets('table row is identified after creation', (tester) async {
      await tester.pumpWidget(const _WorkflowTableFixture());
      final existingInstanceIds = engineNativeInstanceIdsForTab(
        tester,
        tabId: 'admin',
        tabBoundSurfaceFamilies: const {'table'},
      );
      expect(existingInstanceIds, {'existing-draft'});
      await tester.pumpWidget(const _WorkflowTableFixture(showCreated: true));
      final instanceId = await waitForCreatedEngineNativeInstanceId(
        tester,
        workflowType: 'mosque-announcement',
        tabId: 'admin',
        tabBoundSurfaceFamilies: const {'table'},
        existingInstanceIds: existingInstanceIds,
        timeout: Duration.zero,
      );
      expect(instanceId, 'created-announcement');
    });

    testWidgets('generic list row control still identified after creation', (
      tester,
    ) async {
      await tester.pumpWidget(const _GenericListFixture());
      final existingInstanceIds = engineNativeInstanceIdsForTab(
        tester,
        tabId: 'home',
        tabBoundSurfaceFamilies: const {'formEntry', 'statusTimeline'},
      );
      expect(existingInstanceIds, {'existing-offer'});
      await tester.pumpWidget(const _GenericListFixture(showCreated: true));
      final instanceId = await waitForCreatedEngineNativeInstanceId(
        tester,
        workflowType: 'plant-exchange',
        tabId: 'home',
        tabBoundSurfaceFamilies: const {'formEntry', 'statusTimeline'},
        existingInstanceIds: existingInstanceIds,
        timeout: Duration.zero,
      );
      expect(instanceId, 'created-plant-offer');
    });
  });
}

/// Calendar agenda namespace (`part28:1308`), with the `facts-` twin
/// (`part28:1336`) and the `$day`-keyed group/date keys mounted, exactly as
/// the real surface mounts them alongside every tile.
class _CalendarAgendaFixture extends StatelessWidget {
  const _CalendarAgendaFixture({this.showCreated = false});

  final bool showCreated;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(
            key: ValueKey('engine-native-calendar-agenda-group-2026-10-10'),
          ),
          const SizedBox(
            key: ValueKey('engine-native-calendar-agenda-date-2026-10-10'),
          ),
          const SizedBox(
            key: ValueKey('engine-native-calendar-agenda-existing-draft-0'),
          ),
          const SizedBox(
            key: ValueKey(
              'engine-native-calendar-agenda-facts-existing-draft-0',
            ),
          ),
          if (showCreated)
            const SizedBox(
              key: ValueKey(
                'engine-native-calendar-agenda-created-garden-event-2',
              ),
            ),
        ],
      ),
    ),
  );
}

/// Marketplace namespace (`part36:357`) with each listing's `-tap-` twin
/// (`part36:351`) mounted, exactly as the real grid mounts both at once.
class _MarketplaceListingFixture extends StatelessWidget {
  const _MarketplaceListingFixture({this.showCreated = false});

  final bool showCreated;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(
            key: ValueKey('marketplace-listing-tap-existing-tool-listing'),
          ),
          const SizedBox(
            key: ValueKey('marketplace-listing-existing-tool-listing'),
          ),
          if (showCreated) ...[
            const SizedBox(
              key: ValueKey('marketplace-listing-tap-created-tool-listing'),
            ),
            const SizedBox(
              key: ValueKey('marketplace-listing-created-tool-listing'),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Table namespace (`part32:551`) with the discoverable first-cell
/// `KeyedSubtree` keys plus the group grid/data keys carrying the group id.
class _WorkflowTableFixture extends StatelessWidget {
  const _WorkflowTableFixture({this.showCreated = false});

  final bool showCreated;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(
            key: ValueKey('engine-native-table-admin-mosque-announcement'),
          ),
          const SizedBox(
            key: ValueKey('workflow-table-data-admin-mosque-announcement'),
          ),
          const SizedBox(
            key: ValueKey(
              'workflow-table-row-admin-mosque-announcement-existing-draft-0',
            ),
          ),
          if (showCreated)
            const SizedBox(
              key: ValueKey(
                'workflow-table-row-admin-mosque-announcement-created-announcement-1',
              ),
            ),
        ],
      ),
    ),
  );
}

/// Generic list namespace control (`part32:179`) on a multi-family tab.
class _GenericListFixture extends StatelessWidget {
  const _GenericListFixture({this.showCreated = false});

  final bool showCreated;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(
            key: ValueKey('engine-native-list-item-home-existing-offer-0'),
          ),
          if (showCreated)
            const SizedBox(
              key: ValueKey(
                'engine-native-list-item-home-created-plant-offer-3',
              ),
            ),
        ],
      ),
    ),
  );
}
