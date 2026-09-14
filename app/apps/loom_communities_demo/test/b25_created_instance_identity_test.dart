import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
        );
        expect(existingInstanceIds, {'existing-draft'});

        await tester.tap(find.byKey(const ValueKey('create-announcement')));
        await tester.pump();
        expect(
          engineNativeInstanceIdsForTab(tester, tabId: 'admin'),
          {'existing-draft'},
          reason: 'The creation has succeeded before the list refresh frame.',
        );

        final instanceId = await waitForCreatedEngineNativeInstanceId(
          tester,
          workflowType: 'mosque-announcement',
          tabId: 'admin',
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
          existingInstanceIds: {'existing-draft'},
          timeout: Duration.zero,
        ),
        throwsA(
          isA<B25ResultFramePositioningFailure>().having(
            (failure) => failure.reason,
            'reason',
            allOf(
              contains('mosque-announcement creation completed'),
              contains('exactly one newly rendered engine-native list key'),
              contains('Actual: 0 matching candidate(s): []'),
            ),
          ),
        ),
      );
    });
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
