import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

import 'b25_created_instance_identity.dart';
import 'b25_workflow_row_selection.dart';

void main() {
  group('B25 created engine-native instance identification', () {
    testWidgets(
      'identifies one newly created row when its key renders a later frame',
      (tester) async {
        final fixtureKey = GlobalKey<_DelayedEngineNativeRowsState>();
        await tester.pumpWidget(_DelayedEngineNativeRows(key: fixtureKey));

        final existingInstanceIds = engineNativeInstanceIdsForTab(
          tester,
          tabId: 'admin',
          tabBoundSurfaceFamilies: const {'mosque-announcement-family'},
        );
        expect(existingInstanceIds, {'existing-draft'});

        await tester.tap(find.byKey(const ValueKey('create-announcement')));
        await tester.pump();
        expect(
          engineNativeInstanceIdsForTab(
            tester,
            tabId: 'admin',
            tabBoundSurfaceFamilies: const {'mosque-announcement-family'},
          ),
          {'existing-draft'},
          reason: 'The creation has succeeded before the list refresh frame.',
        );

        final instanceId = await waitForCreatedEngineNativeInstanceId(
          tester,
          workflowType: 'mosque-announcement',
          tabId: 'admin',
          tabBoundSurfaceFamilies: const {'mosque-announcement-family'},
          existingInstanceIds: existingInstanceIds,
        );

        expect(instanceId, 'created-announcement');
      },
    );

    testWidgets('keeps the specific created-but-unidentified failure loud', (
      tester,
    ) async {
      await tester.pumpWidget(const _DelayedEngineNativeRows());

      await expectLater(
        waitForCreatedEngineNativeInstanceId(
          tester,
          workflowType: 'mosque-announcement',
          tabId: 'admin',
          tabBoundSurfaceFamilies: const {'mosque-announcement-family'},
          existingInstanceIds: {'existing-draft'},
          timeout: Duration.zero,
        ),
        throwsA(
          isA<B25ResultFramePositioningFailure>().having(
            (failure) => failure.reason,
            'reason',
            allOf(
              contains('mosque-announcement creation completed'),
              contains('exactly one newly rendered engine-native identity key'),
              contains('renderer "engine-native-generic-list"'),
              contains('Actual: 0 matching candidate(s): []'),
            ),
          ),
        ),
      );
    });
  });

  group('B25 tab renderer resolution', () {
    test('single mapped family resolves its dedicated surface', () {
      expect(
        b25RendererContractIdForTabBoundFamilies(const {'event-rsvp'}),
        'calendar-agenda-event-detail',
      );
      expect(
        b25RendererContractIdForTabBoundFamilies(const {'calendar'}),
        'calendar-agenda-event-detail',
      );
      expect(
        b25RendererContractIdForTabBoundFamilies(const {'equipment-loan'}),
        'marketplace-browse-listing-detail',
      );
    });

    test('anything else falls back to the generic list', () {
      expect(
        b25RendererContractIdForTabBoundFamilies(const {}),
        b25DefaultAppShellTabRendererContractId,
      );
      expect(
        b25RendererContractIdForTabBoundFamilies(const {'table'}),
        b25DefaultAppShellTabRendererContractId,
      );
      expect(
        b25RendererContractIdForTabBoundFamilies(
          const {'event-rsvp', 'equipment-loan'},
        ),
        b25DefaultAppShellTabRendererContractId,
      );
    });

    test(
      'harness reconciliation map matches the shell archetype map exactly',
      () {
        expect(
          b25TabNativeRendererContractIdsByArchetype,
          appShellTabNativeRendererContractIdsByArchetype,
          reason:
              'The harness copy of the renderer reconciliation rule must not '
              'drift from the shell map it mirrors.',
        );
        expect(
          b25DefaultAppShellTabRendererContractId,
          defaultAppShellTabRendererContractId,
        );
      },
    );
  });
}

class _DelayedEngineNativeRows extends StatefulWidget {
  const _DelayedEngineNativeRows({super.key});

  @override
  State<_DelayedEngineNativeRows> createState() =>
      _DelayedEngineNativeRowsState();
}

class _DelayedEngineNativeRowsState extends State<_DelayedEngineNativeRows> {
  var _showCreatedRow = false;

  void create() {
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showCreatedRow = true);
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          const SizedBox(
            key: ValueKey('engine-native-list-item-admin-existing-draft-0'),
          ),
          if (_showCreatedRow)
            const SizedBox(
              key: ValueKey(
                'engine-native-list-item-admin-created-announcement-0',
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('create-announcement'),
        onPressed: create,
      ),
    ),
  );
}
