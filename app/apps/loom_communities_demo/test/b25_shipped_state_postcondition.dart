import 'walkthrough_wait.dart';

/// The result of polling one shipped workflow instance for its documented
/// target state.
///
/// This describes the observation only. It deliberately does not infer that
/// a tap reached the handler, that the engine accepted it, or that an engine
/// call completed successfully.
class B25ShippedStatePostcondition {
  const B25ShippedStatePostcondition({
    required this.targetState,
    required this.lastObservedState,
    required this.waited,
    required this.readAttempts,
  });

  final String targetState;
  final String? lastObservedState;
  final Duration waited;
  final int readAttempts;

  bool get targetStateObserved => lastObservedState == targetState;

  String failureReason({
    required String workflowType,
    required String transitionId,
    required String instanceId,
  }) =>
      'After the walkthrough attempted $transitionId for $workflowType '
      'instance $instanceId, the state check did not observe target state '
      '$targetState; the last observed state was '
      '${lastObservedState ?? 'instance not found'}. '
      'Waited ${formatWaitDuration(waited)}. '
      'Transition dispatch and successful completion were not verified.';
}

/// Polls until the target state is observed, rather than stopping merely
/// because the instance can be found. [maximumAttempts] is intentionally
/// supplied by the walkthrough so its existing wait budget remains unchanged.
Future<B25ShippedStatePostcondition> waitForB25ShippedTargetState({
  required String targetState,
  required Future<String?> Function() readCurrentState,
  required Future<void> Function() waitForRetry,
  required Duration Function() elapsed,
  required int maximumAttempts,
}) async {
  if (maximumAttempts <= 0) {
    throw ArgumentError.value(
      maximumAttempts,
      'maximumAttempts',
      'must be greater than zero',
    );
  }

  String? lastObservedState;
  for (var attempt = 0; attempt < maximumAttempts; attempt += 1) {
    lastObservedState = await readCurrentState();
    if (lastObservedState == targetState) {
      return B25ShippedStatePostcondition(
        targetState: targetState,
        lastObservedState: lastObservedState,
        waited: elapsed(),
        readAttempts: attempt + 1,
      );
    }
    if (attempt + 1 < maximumAttempts) {
      await waitForRetry();
    }
  }
  return B25ShippedStatePostcondition(
    targetState: targetState,
    lastObservedState: lastObservedState,
    waited: elapsed(),
    readAttempts: maximumAttempts,
  );
}
