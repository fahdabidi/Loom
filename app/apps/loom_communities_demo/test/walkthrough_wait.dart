/// Wall-clock budget for a single "wait for this thing" step during a UI
/// walkthrough.
///
/// The walkthrough runs under `IntegrationTestWidgetsFlutterBinding`, where
/// `tester.pump` and `tester.runAsync` advance REAL time on a device or
/// emulator. A bounded loop that only counts iterations therefore cannot
/// express how long a step has been stuck: software emulation without
/// `/dev/kvm` is much slower than a real device, while a runaway frame or a
/// hung platform channel can stall for tens of minutes. This budget measures
/// the same wall clock the human would: it gives every step a generous but
/// finite deadline and, when that deadline passes, explains what was being
/// waited on instead of failing silently or hanging forever.
class WalkthroughWaitBudget {
  WalkthroughWaitBudget({
    Duration timeout = const Duration(minutes: 3),
    DateTime Function()? now,
  }) : timeout = timeout,
       now = now ?? _systemNow,
       _startedAt = (now ?? _systemNow)().toUtc();

  /// Three minutes is deliberately slower than the fastest walkthroughs so a
  /// cold, non-accelerated emulator does not fail an otherwise healthy step,
  /// while still being far better than the thirty-one minutes of silence that
  /// produced this ticket. A step that has not found its target in three
  /// minutes of real time is a stall, not a slow render.
  static const Duration defaultTimeout = Duration(minutes: 3);

  final Duration timeout;
  final DateTime Function() now;
  final DateTime _startedAt;

  static DateTime _systemNow() => DateTime.now().toUtc();

  Duration get elapsed => now().toUtc().difference(_startedAt);

  bool get expired => elapsed >= timeout;
}

/// Renders a `Duration` the way a human reads a wait: `3m 0s`, `12m 40s`.
String formatWaitDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60);
  return '${minutes}m ${seconds}s';
}

/// Everything a stall message must name so the next stall diagnoses itself
/// instead of inviting an unproven root-cause story.
///
/// [lastCompletedStep] should name the most recent step that COMPLETED, for
/// example the workflow, role, phase and last captured evidence screenshot.
/// [attemptedStep] should name, in human terms, the step this wait belongs to.
/// [waitingFor] should name the actual finder/selector the loop is polling.
/// [diagnosticFrameName] is the obviously-diagnostic frame captured at the
/// moment of the stall; leave it null when no frame could be captured.
String buildWalkthroughStallMessage({
  required String? lastCompletedStep,
  required String attemptedStep,
  required String waitingFor,
  required WalkthroughWaitBudget budget,
  String? diagnosticFrameName,
}) {
  final buffer = StringBuffer()
    ..writeln(
      'Walkthrough stalled: a step could not proceed within its '
      'bounded wait (${formatWaitDuration(budget.elapsed)} elapsed, '
      'limit ${formatWaitDuration(budget.timeout)}).',
    );
  if (lastCompletedStep == null) {
    buffer.writeln(
      '  Last completed step: (none; the walkthrough had not '
      'completed a step before this wait).',
    );
  } else {
    buffer.writeln('  Last completed step: $lastCompletedStep');
  }
  buffer.writeln('  Attempted step: $attemptedStep');
  buffer.writeln('  Waiting for: $waitingFor');
  if (diagnosticFrameName != null) {
    buffer.writeln(
      '  Diagnostic frame: $diagnosticFrameName (captured at the point of failure).',
    );
  } else {
    buffer.writeln('  Diagnostic frame: (not captured).');
  }
  return buffer.toString();
}

/// Thrown when [WalkthroughWaitBudget] expires before a finder can be
/// satisfied. Keeping this a distinct exception type lets tests assert the
/// DIAGNOSTIC CONTENT rather than merely "an exception was thrown".
class WalkthroughStallFailure implements Exception {
  WalkthroughStallFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
