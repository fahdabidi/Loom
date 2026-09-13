import 'b25_actor_audience_resolution.dart';

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
