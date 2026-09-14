import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workflow_ui_test_harness.dart';

void main() {
  group('B25 creatable FAB preparation', () {
    testWidgets(
      'opens a collapsed speed dial when its mounted child is not hittable',
      (tester) async {
        await tester.pumpWidget(const _SpeedDialFixture());

        final createFab = find.byKey(
          const ValueKey('creatable-fab-mosque-announcement'),
        );
        final opener = find.byKey(const ValueKey('creatable-fab-speed-dial'));
        expect(createFab, findsOneWidget);
        expect(isFinderReadyForTap(tester, createFab), isFalse);
        expect(isFinderReadyForTap(tester, opener), isTrue);

        await prepareCreatableFabForTap(
          tester: tester,
          createFab: createFab,
          speedDial: opener,
          workflowType: 'mosque-announcement',
          roleId: 'masjid-admin',
        );

        expect(isFinderReadyForTap(tester, createFab), isTrue);
        expect(find.text('opened once'), findsOneWidget);
      },
    );

    testWidgets('fails by name when the speed-dial opener is not tappable', (
      tester,
    ) async {
      await tester.pumpWidget(const _SpeedDialFixture(openerEnabled: false));

      final createFab = find.byKey(
        const ValueKey('creatable-fab-mosque-announcement'),
      );
      final opener = find.byKey(const ValueKey('creatable-fab-speed-dial'));

      await expectLater(
        prepareCreatableFabForTap(
          tester: tester,
          createFab: createFab,
          speedDial: opener,
          workflowType: 'mosque-announcement',
          roleId: 'masjid-admin',
        ),
        throwsA(
          isA<TestFailure>().having(
            (failure) => failure.message,
            'message',
            allOf(
              contains('create FAB preparation failed'),
              contains('creatable-fab-speed-dial was not tappable'),
            ),
          ),
        ),
      );
      expect(find.text('opened once'), findsNothing);
    });
  });
}

class _SpeedDialFixture extends StatefulWidget {
  const _SpeedDialFixture({this.openerEnabled = true});

  final bool openerEnabled;

  @override
  State<_SpeedDialFixture> createState() => _SpeedDialFixtureState();
}

class _SpeedDialFixtureState extends State<_SpeedDialFixture> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text(_open ? 'opened once' : 'collapsed')),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IgnorePointer(
              ignoring: !_open,
              child: Opacity(
                opacity: _open ? 1 : 0,
                child: FloatingActionButton(
                  key: const ValueKey('creatable-fab-mosque-announcement'),
                  onPressed: () {},
                  child: const Icon(Icons.campaign),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !widget.openerEnabled,
              child: FloatingActionButton(
                key: const ValueKey('creatable-fab-speed-dial'),
                onPressed: () => setState(() => _open = true),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
