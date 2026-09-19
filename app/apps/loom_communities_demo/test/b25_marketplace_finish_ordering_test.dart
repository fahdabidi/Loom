// Regression coverage for the `return` vs `return await` cleanup race fixed
// in `_runB25ShippedWorkflowWalkthrough` (integration_test/workflow_ui_evidence_test.dart).
// That function is private to its file and cannot be called from here, so
// this reproduces the exact shape -- a try/finally whose finally does
// guarded cleanup work while the try's return expression is a pending,
// unawaited Future that does its own guarded polling -- using the real,
// shared marketplace harness helpers the fixed code depends on.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'workflow_ui_test_harness.dart';

const _instanceId = 'ordering-repro-item';

class _MarketplaceRowFixture extends StatelessWidget {
  const _MarketplaceRowFixture();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(
        key: const ValueKey('marketplace-detail-test-surface'),
        child: Builder(
          builder: (context) => InkWell(
            key: const ValueKey('marketplace-listing-tap-$_instanceId'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => Dialog(
                key: const ValueKey('marketplace-detail-dialog-$_instanceId'),
                child: SizedBox(
                  height: 200,
                  width: 200,
                  child: Column(
                    children: [
                      // Never becomes enabled: the "finish" stand-in below
                      // polls for it until its own short timeout expires,
                      // exactly like a real alternate-action wait that finds
                      // nothing.
                      const FilledButton(
                        key: ValueKey('alternate-action-never-ready'),
                        onPressed: null,
                        child: Text('Alternate'),
                      ),
                      TextButton(
                        key: const ValueKey(
                          'marketplace-detail-close-$_instanceId',
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: const SizedBox(height: 40, child: Text('Listing')),
          ),
        ),
      ),
    );
  }
}

/// Stands in for `_finishB25WalkthroughAfterPrimary`: guarded polling that
/// must complete, and be read, before the dialog it polls is torn down.
Future<String> _finishAfterPrimaryLike({
  required WidgetTester tester,
  required MarketplaceActionSurfacePreparation preparation,
  required List<String> events,
}) async {
  events.add('finish-start');
  await waitForPrimaryActionAvailability(
    tester: tester,
    timeout: const Duration(milliseconds: 200),
    candidates: [
      PrimaryActionCandidate(
        value: 'alternate',
        finder: find.descendant(
          of: preparation.actionSurface,
          matching: find.byKey(const ValueKey('alternate-action-never-ready')),
        ),
        description: 'Alternate',
      ),
    ],
  );
  final dialogStillOpen = marketplaceDetailDialogFinder(
    _instanceId,
  ).evaluate().isNotEmpty;
  events.add('finish-end dialogPresent=$dialogStillOpen');
  return 'finished';
}

Future<MarketplaceActionSurfacePreparation> _openDetail(
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    const MaterialApp(home: _MarketplaceRowFixture()),
  );
  return prepareMarketplaceActionSurfaceForActionPolling(
    tester: tester,
    surface: find.byKey(const ValueKey('marketplace-detail-test-surface')),
    tabId: 'marketplace',
    instanceId: _instanceId,
  );
}

void main() {
  testWidgets(
    'an unawaited finish lets cleanup start before the finish work reads '
    'the still-open dialog (the return-without-await defect)',
    (tester) async {
      final preparation = await _openDetail(tester);
      final events = <String>[];

      try {
        // BUG shape: evaluating the return expression starts the finish
        // work, but nothing awaits it before `finally` begins its own
        // guarded cleanup.
        _finishAfterPrimaryLike(
          tester: tester,
          preparation: preparation,
          events: events,
        );
      } finally {
        events.add('finally-start');
        await closeMarketplaceActionSurfaceAfterActionPolling(
          tester: tester,
          preparation: preparation,
          expectedSurface: find.byKey(
            const ValueKey('marketplace-detail-test-surface'),
          ),
        );
        events.add('finally-end');
      }
      // Let the orphaned finish() future run to completion so it cannot
      // report an error after this test has already finished.
      await tester.pump(const Duration(milliseconds: 500));

      final finallyStarted = events.indexOf('finally-start');
      final finishEnded = events.indexWhere(
        (event) => event.startsWith('finish-end'),
      );
      expect(
        finallyStarted,
        lessThan(finishEnded),
        reason:
            'Without an await, dialog cleanup started while the finish '
            'work was still reading the dialog it was about to close -- '
            'the exact race the return-await fix removes.',
      );
    },
  );

  testWidgets(
    'return await keeps the finish work strictly before cleanup, and '
    'raises no framework error',
    (tester) async {
      final preparation = await _openDetail(tester);
      final events = <String>[];
      final frameworkErrors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = frameworkErrors.add;

      Future<String> run() async {
        try {
          // FIX shape: the return expression is awaited before `finally`
          // begins, so the two guarded chains never run concurrently.
          return await _finishAfterPrimaryLike(
            tester: tester,
            preparation: preparation,
            events: events,
          );
        } finally {
          events.add('finally-start');
          await closeMarketplaceActionSurfaceAfterActionPolling(
            tester: tester,
            preparation: preparation,
            expectedSurface: find.byKey(
              const ValueKey('marketplace-detail-test-surface'),
            ),
          );
          events.add('finally-end');
        }
      }

      String? result;
      try {
        result = await run();
      } finally {
        FlutterError.onError = originalOnError;
      }

      expect(result, 'finished');
      expect(events, [
        'finish-start',
        'finish-end dialogPresent=true',
        'finally-start',
        'finally-end',
      ]);
      expect(
        frameworkErrors,
        isEmpty,
        reason:
            'The awaited ordering must not raise any guarded-call conflict.',
      );
    },
  );
}
