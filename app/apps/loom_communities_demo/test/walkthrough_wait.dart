import 'dart:async';

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
    DateTime? startedAt,
  }) : timeout = timeout,
       now = now ?? _systemNow,
       _startedAt = (startedAt ?? (now ?? _systemNow)()).toUtc();

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

/// Wall-clock heartbeat watchdog that bounds the ENTIRE walkthrough body, not
/// just the individual wait-poll loops inside it.
///
/// `flutter drive` runs the whole `testWidgets` body under a single
/// `request_data` request. A single unbounded `await` anywhere in that body
/// therefore silences the whole run: finder-poll budgets that live *inside* a
/// later step never get the chance to fire. This watchdog races the body
/// against a real-timer deadline, so any stretch of the body that stops making
/// progress for [timeout] fails with [WalkthroughStallFailure] naming the last
/// completed step, the attempted step, and what was being awaited.
///
/// Call [beat] whenever the body completes a step or crosses a phase boundary
/// (a workflow starts, a screenshot is captured, a workflow completes). The
/// timer restarts on each beat, so the bound measures *a single
/// no-progress gap* rather than the total runtime of a long capture.
class WalkthroughBodyWatch {
  WalkthroughBodyWatch({
    Duration timeout = WalkthroughWaitBudget.defaultTimeout,
    DateTime Function()? now,
    Timer Function(Duration duration, void Function() callback)? createTimer,
    required String lastCompletedStep,
    required String attemptedStep,
    required String waitingFor,
  }) : timeout = timeout,
       _now = now ?? WalkthroughWaitBudget._systemNow,
       _createTimer = createTimer ?? _defaultCreateTimer,
       _lastCompletedStep = lastCompletedStep,
       _attemptedStep = attemptedStep,
       _waitingFor = waitingFor {
    _deadline = Completer<Never>();
    _beat();
  }

  static Timer _defaultCreateTimer(
    Duration duration,
    void Function() callback,
  ) {
    return Timer(duration, callback);
  }

  final Duration timeout;
  final DateTime Function() _now;
  final Timer Function(Duration duration, void Function() callback)
  _createTimer;

  String? _lastCompletedStep;
  String _attemptedStep;
  String _waitingFor;

  late final Completer<Never> _deadline;
  Timer? _timer;
  DateTime _lastBeat = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  bool _fired = false;
  bool _cancelled = false;

  /// Completes with [WalkthroughStallFailure] if the body stops progressing
  /// for [timeout]. Raced against the walkthrough body by
  /// [watchWalkthroughBodyWith].
  Future<Never> get deadline => _deadline.future;

  Duration get elapsedSinceLastBeat => _now().toUtc().difference(_lastBeat);

  /// Reports progress and restarts the deadline. All three fields are optional
  /// so a beat can update only what changed; the other fields keep their most
  /// recent diagnostic value.
  void beat({
    String? lastCompletedStep,
    String? attemptedStep,
    String? waitingFor,
  }) {
    if (lastCompletedStep != null) _lastCompletedStep = lastCompletedStep;
    if (attemptedStep != null) _attemptedStep = attemptedStep;
    if (waitingFor != null) _waitingFor = waitingFor;
    _lastBeat = _now().toUtc();
    _beat();
  }

  void _beat() {
    _timer?.cancel();
    if (_cancelled || _fired) {
      return;
    }
    _timer = _createTimer(timeout, _onExpired);
  }

  void _onExpired() {
    if (_cancelled || _fired) {
      return;
    }
    _fired = true;
    final budget = WalkthroughWaitBudget(
      timeout: timeout,
      now: _now,
      startedAt: _lastBeat,
    );
    final message = buildWalkthroughStallMessage(
      lastCompletedStep: _lastCompletedStep,
      attemptedStep: _attemptedStep,
      waitingFor: _waitingFor,
      budget: budget,
    );
    if (!_deadline.isCompleted) {
      _deadline.completeError(WalkthroughStallFailure(message));
    }
  }

  /// Stops the watchdog after the body completes. Cancelling the timer
  /// prevents an error from firing against an already-abandoned deadline once
  /// [watchWalkthroughBodyWith] has returned.
  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _timer = null;
  }
}

/// Races [body] against [watch]'s deadline and returns [body]'s result, or
/// rethrows the watchdog's [WalkthroughStallFailure] if the body stopped
/// progressing. The watchdog is always cancelled in a `finally` so a completed
/// body can never surface a late timer error.
Future<T> watchWalkthroughBodyWith<T>(
  Future<T> body,
  WalkthroughBodyWatch watch,
) async {
  try {
    return await Future.any<T>([body, watch.deadline]);
  } finally {
    watch.cancel();
  }
}
