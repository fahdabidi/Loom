import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'b25_workflow_row_selection.dart';
import 'walkthrough_wait.dart';

/// Reads the identity exposed by an engine-native list row.
///
/// `EngineNativeListSurface` owns this key shape.  The binding index is the
/// final component, so instance IDs are allowed to contain dashes.
Set<String> engineNativeInstanceIdsForTab(
  WidgetTester tester, {
  required String tabId,
}) {
  final prefix = 'engine-native-list-item-$tabId-';
  final ids = <String>{};
  for (final element in find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  }, description: 'engine-native list item for tab $tabId').evaluate()) {
    final key = element.widget.key! as ValueKey<String>;
    final encodedIdentity = key.value.substring(prefix.length);
    final bindingIndexSeparator = encodedIdentity.lastIndexOf('-');
    if (bindingIndexSeparator <= 0 ||
        int.tryParse(encodedIdentity.substring(bindingIndexSeparator + 1)) ==
            null) {
      continue;
    }
    ids.add(encodedIdentity.substring(0, bindingIndexSeparator));
  }
  return ids;
}

/// Waits for the engine-native list key produced by a successful creation.
///
/// The instance ID is not inferred from rendered title text.  Instead, this
/// compares the actual engine-native row keys before and after submission and
/// accepts exactly one new identity.  Zero or multiple candidates remain loud
/// result-verification failures because the creation call has already
/// returned successfully by the time this function is used.
Future<String> waitForCreatedEngineNativeInstanceId(
  WidgetTester tester, {
  required String workflowType,
  required String tabId,
  required Set<String> existingInstanceIds,
  Duration? timeout,
  DateTime Function()? now,
}) async {
  final budget = WalkthroughWaitBudget(
    timeout: timeout ?? WalkthroughWaitBudget.defaultInnerWaitTimeout,
    now: now,
  );
  Set<String> candidateIds = const <String>{};

  do {
    candidateIds = engineNativeInstanceIdsForTab(
      tester,
      tabId: tabId,
    ).difference(existingInstanceIds);
    if (candidateIds.length == 1) {
      return candidateIds.single;
    }
    if (budget.expired) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  } while (!budget.expired);

  final orderedCandidateIds = candidateIds.toList()..sort();
  throw B25ResultFramePositioningFailure(
    'The shipped $workflowType creation completed, but the created instance '
    'did not expose its engine-native identity key.\n'
    'Expected: exactly one newly rendered engine-native list key on tab '
    '"$tabId" that was absent before creation.\n'
    'Actual: ${orderedCandidateIds.length} matching candidate(s): '
    '$orderedCandidateIds.',
  );
}
