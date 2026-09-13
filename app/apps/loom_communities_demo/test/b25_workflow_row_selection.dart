import 'b25_actor_audience_resolution.dart';

/// A primary action reached its persisted semantic postcondition, but B25
/// could not position the visual result frame that would verify it.
///
/// This is deliberately distinct from an unavailable action or a blocked
/// selector: the action fired, and only its visible confirmation is missing.
class B25ResultFramePositioningFailure extends StateError {
  B25ResultFramePositioningFailure(this.reason) : super(reason);

  final String reason;
}

/// The recorded, row-local result of an exception thrown while walking one
/// B25 workflow/role row.
///
/// Its reason is the original exception message. Callers must write it to the
/// evidence entry rather than replacing it with a generic failure label.
class B25RowScopedFailure {
  const B25RowScopedFailure({
    required this.rowOutcome,
    required this.actionProofStatus,
    required this.reason,
  });

  final String rowOutcome;
  final String actionProofStatus;
  final String reason;

  bool get actionSucceededButResultUnverified =>
      rowOutcome == 'action_succeeded_result_unverified';
}

/// The completed value or recorded failure from one B25 row scope.
class B25WorkflowRowScopeResult<T> {
  const B25WorkflowRowScopeResult.completed(this.value) : failure = null;

  const B25WorkflowRowScopeResult.failed(this.failure) : value = null;

  final T? value;
  final B25RowScopedFailure? failure;

  bool get completed => failure == null;
}

/// Executes all work owned by one B25 workflow/role row.
///
/// The caller defines the structural boundary: exceptions thrown inside
/// [run] are recorded as this row's outcome, while exceptions thrown before
/// or after this call remain global failures and abort the walkthrough.
Future<B25WorkflowRowScopeResult<T>> runB25WorkflowRowScope<T>(
  Future<T> Function() run,
) async {
  try {
    return B25WorkflowRowScopeResult<T>.completed(await run());
  } catch (error) {
    return B25WorkflowRowScopeResult<T>.failed(_b25RowScopedFailureFor(error));
  }
}

B25RowScopedFailure _b25RowScopedFailureFor(Object error) {
  if (error is B25ActorAudienceResolutionFailure) {
    return B25RowScopedFailure(
      rowOutcome: 'blocked_by_audience',
      actionProofStatus: 'blocked_by_audience',
      reason: error.message.toString(),
    );
  }
  if (error is B25SelectorSetupFailure) {
    return B25RowScopedFailure(
      rowOutcome: 'blocked_by_selector_setup',
      actionProofStatus: 'blocked_by_selector_setup',
      reason: error.reason,
    );
  }
  if (error is B25ResultFramePositioningFailure) {
    return B25RowScopedFailure(
      rowOutcome: 'action_succeeded_result_unverified',
      actionProofStatus: 'action_succeeded_result_unverified',
      reason: error.reason,
    );
  }
  return B25RowScopedFailure(
    rowOutcome: 'row_execution_failed',
    actionProofStatus: 'row_execution_failed',
    reason: error is StateError ? error.message.toString() : error.toString(),
  );
}

/// A selector failure B25 knows is limited to setting up one walkthrough row.
///
/// This is intentionally narrower than [StateError]. The walkthrough may
/// record and skip only failures the shipped-workflow selector explicitly
/// identifies as an inability to derive an instance, actor identity, or tab.
/// Every unrelated exception still propagates and aborts the run.
class B25SelectorSetupFailure extends StateError {
  B25SelectorSetupFailure(this.reason) : super(reason);

  static const cause =
      'selector setup could not derive an actionable instance, actorIdentity, and tab';

  final String reason;
}

/// The selector result for one B25 walkthrough row.
///
/// A blocked result is never an alternate selector or proof of completion. It
/// retains the original failure message so the recorded evidence can identify
/// the precise package or selector setup problem without rerunning B25.
class B25WorkflowRowSelection<T> {
  const B25WorkflowRowSelection.selected(this.selector)
    : rowOutcome = 'selected',
      blockedReason = null,
      blockedCause = null;

  const B25WorkflowRowSelection.blockedByAudience({
    required this.blockedReason,
    required this.blockedCause,
  }) : selector = null,
       rowOutcome = 'blocked_by_audience';

  const B25WorkflowRowSelection.blockedBySelectorSetup({
    required this.blockedReason,
    required this.blockedCause,
  }) : selector = null,
       rowOutcome = 'blocked_by_selector_setup';

  final T? selector;
  final String rowOutcome;
  final String? blockedReason;
  final String? blockedCause;

  bool get isBlockedByAudience => rowOutcome == 'blocked_by_audience';
  bool get isBlockedBySelectorSetup =>
      rowOutcome == 'blocked_by_selector_setup';
  bool get isBlocked => isBlockedByAudience || isBlockedBySelectorSetup;
}

/// Runs one B25 selector and converts only the two known row-local failures
/// into a recorded blocked result.
///
/// In particular, this must not become a general exception handler: malformed
/// data, a bad binding, or any other unexpected selector exception must still
/// abort the walkthrough loudly.
B25WorkflowRowSelection<T> selectB25WorkflowRow<T>(T Function() select) {
  try {
    return B25WorkflowRowSelection<T>.selected(select());
  } on B25ActorAudienceResolutionFailure catch (error) {
    return B25WorkflowRowSelection<T>.blockedByAudience(
      blockedReason: error.message,
      blockedCause:
          B25ActorAudienceResolutionFailure.absentActorEqualsFieldCause,
    );
  } on B25SelectorSetupFailure catch (error) {
    return B25WorkflowRowSelection<T>.blockedBySelectorSetup(
      blockedReason: error.reason,
      blockedCause: B25SelectorSetupFailure.cause,
    );
  }
}
