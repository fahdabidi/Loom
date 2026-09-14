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

/// A receiver row whose named prerequisite row did not produce the persisted
/// object it needs to observe or act on.
///
/// This is not a successful no-op and not a selector problem: recording it
/// separately preserves the dependency edge in the evidence rather than
/// making the receiver appear to have attempted an opaque interaction.
class B25DependentReceiverBlockedFailure extends StateError {
  B25DependentReceiverBlockedFailure(this.reason) : super(reason);

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

/// Whether a dedicated B25 community setup may run for this dispatch.
///
/// Package reads and role/selector derivation belong behind this predicate.
/// In particular, an excluded community must not be validated merely because
/// a different selected community has a B17-B20 work item.
bool isB25DedicatedCommunitySelected({
  required Set<String> selectedExtensionIds,
  required String extensionId,
  required Iterable<String> phases,
  required bool Function(String phase) includesPhase,
}) => selectedExtensionIds.contains(extensionId) && phases.any(includesPhase);

/// The recorded result of work that belongs to one B25 community traversal.
///
/// A community boundary is deliberately wider than a row boundary: opening a
/// community and returning from it are owned by that community, while setup
/// for the whole walkthrough remains outside this scope and still aborts.
class B25CommunityScopedFailure {
  const B25CommunityScopedFailure(this.reason);

  final String reason;
}

/// The completed value or recorded failure from one B25 community scope.
class B25CommunityScopeResult<T> {
  const B25CommunityScopeResult.completed(this.value) : failure = null;

  const B25CommunityScopeResult.failed(this.failure) : value = null;

  final T? value;
  final B25CommunityScopedFailure? failure;

  bool get completed => failure == null;
}

/// A durable record of whether one community was fully traversed.
///
/// Rows write their own evidence before the community teardown runs. This
/// separate record therefore makes an incomplete teardown visible without
/// deleting or reclassifying the rows that were already proven.
class B25CommunityTraversalRecord {
  const B25CommunityTraversalRecord._({
    required this.phase,
    required this.communityId,
    required this.communityName,
    required this.extensionId,
    required this.traversalStatus,
    required this.lastRowWalked,
    this.reason,
  });

  static B25CommunityTraversalRecord fromScope<T>({
    required B25CommunityScopeResult<T> scope,
    required String phase,
    required String communityId,
    required String communityName,
    required String extensionId,
    required String? lastRowWalked,
  }) {
    return B25CommunityTraversalRecord._(
      phase: phase,
      communityId: communityId,
      communityName: communityName,
      extensionId: extensionId,
      traversalStatus: scope.completed
          ? 'completely_traversed'
          : 'incompletely_traversed',
      lastRowWalked: lastRowWalked,
      reason: scope.failure?.reason,
    );
  }

  final String phase;
  final String communityId;
  final String communityName;
  final String extensionId;
  final String traversalStatus;
  final String? lastRowWalked;
  final String? reason;

  bool get isIncomplete => traversalStatus == 'incompletely_traversed';

  /// Replaces a completed traversal with the final, owned cleanup failure.
  ///
  /// Report finalisation is deliberately outside that cleanup operation, so a
  /// failure to return to the community list remains attributable to the last
  /// traversal without preventing the evidence report from being written.
  B25CommunityTraversalRecord withFinalCleanupFailure(String failureReason) =>
      B25CommunityTraversalRecord._(
        phase: phase,
        communityId: communityId,
        communityName: communityName,
        extensionId: extensionId,
        traversalStatus: 'incompletely_traversed',
        lastRowWalked: lastRowWalked,
        reason: failureReason,
      );

  Map<String, Object?> toReportData() => <String, Object?>{
    'phase': phase,
    'communityId': communityId,
    'communityName': communityName,
    'extensionId': extensionId,
    'traversalStatus': traversalStatus,
    'lastRowWalked': lastRowWalked,
    if (reason != null) 'reason': reason,
  };
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

/// Executes all work owned by one B25 community traversal.
///
/// The caller defines the structural boundary: failures thrown while opening,
/// walking, or tearing down one community are recorded for that community;
/// failures outside this call remain global and abort the walkthrough.
Future<B25CommunityScopeResult<T>> runB25CommunityScope<T>(
  Future<T> Function() run,
) async {
  try {
    return B25CommunityScopeResult<T>.completed(await run());
  } catch (error) {
    return B25CommunityScopeResult<T>.failed(
      B25CommunityScopedFailure(
        error is StateError ? error.message.toString() : error.toString(),
      ),
    );
  }
}

/// Builds the teardown diagnostic that identifies the missing control and the
/// current surface instead of exposing Flutter's generic empty-finder text.
String buildB25CommunityTeardownFailureMessage({
  required String communityName,
  required String extensionId,
  required String? lastRowWalked,
  required String observedSurface,
  String? detail,
}) {
  return 'B25 community teardown failed for community $communityName '
      '($extensionId).\n'
      'Last row walked: ${lastRowWalked ?? '(none)'}.\n'
      'Sought control: a Back tooltip.\n'
      'Observed surface: $observedSurface.'
      '${detail == null ? '' : '\n$detail'}';
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
  if (error is B25DependentReceiverBlockedFailure) {
    return B25RowScopedFailure(
      rowOutcome: 'blocked_by_prerequisite',
      actionProofStatus: 'blocked_by_prerequisite',
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
