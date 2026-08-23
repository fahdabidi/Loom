import 'dart:convert';
import 'dart:io';

/// Device-side detection of native system dialogs during evidence capture.
///
/// WHY THIS EXISTS SEPARATELY FROM THE FLUTTER-SIDE TEXT GUARD -- do not
/// delete either one as redundant:
///
/// * An Android system dialog (ANR "isn't responding", "keeps stopping" crash,
///   a permission prompt, the notification shade) is a NATIVE window owned by
///   system_server or SystemUI. It lives OUTSIDE the Flutter widget tree, so it
///   can never appear in `find.byType(Text)`. The Flutter-side guard in the
///   evidence writer is structurally incapable of seeing it. THIS file is the
///   actual mechanism: it asks the device what window is on top.
/// * The Flutter-side guard is still worth keeping as a cheap secondary check:
///   it catches a dialog the app itself renders in Dart, which is invisible to
///   the device-side check because such a dialog does not take window focus
///   away from the app.
///
/// Neither check subsumes the other. Removing the device check restores the
/// defect where an ANR dialog covered every captured frame and nothing noticed.

/// The single adb command used to ask the device what is on top.
///
/// `dumpsys window displays` reports `mCurrentFocus`, `mFocusedApp` and the
/// per-display window list, and costs roughly a quarter of what a full
/// `dumpsys window` costs -- it runs twice per captured frame.
const deviceWindowStateCommand = <String>['dumpsys', 'window', 'displays'];

/// The file a capture run writes device-side findings into, per phase.
///
/// The evidence writer reads this back so a rejected frame can be reported
/// with its workflow, role and community, which only the walkthrough knows.
const deviceDialogFindingsFileName = 'device-system-dialog-findings.json';

/// Window TITLES that Android's own error dialogs carry.
///
/// MARKER SAFETY: these are matched against `dumpsys window` output only --
/// never against product copy. A window title is either a
/// `package/activity` component or a framework-assigned string; shipped UI
/// strings such as `Join waitlist` cannot appear there. Both markers also
/// carry the `Application ...:` framework prefix, so they are not substrings
/// any product string could contain. The primary rule below is stricter still
/// and needs no marker at all: it is a positive allowlist on the focused
/// window's package.
const androidSystemDialogWindowTitleMarkers = <String>[
  'Application Not Responding:',
  'Application Error:',
];

/// Focused-window titles that are NOT the app under test but still leave the
/// app fully rendered underneath, so the frame remains valid evidence.
///
/// Deliberately tiny. The soft keyboard can take input focus while the app is
/// visible and unobstructed; failing those frames would manufacture a false
/// product finding. An ANR or crash dialog never presents as `InputMethod`,
/// and the marker scan above still runs across every window on the display.
const nonBlockingFocusedWindowTitles = <String>['InputMethod'];

/// Raw result of the device-state query.
class DeviceWindowState {
  const DeviceWindowState({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get isUsable => exitCode == 0 && stdout.trim().isNotEmpty;
}

/// Injection seam: the tests stub this so the guard can be exercised without a
/// device attached.
typedef DeviceWindowStateProbe = DeviceWindowState Function();

/// Injection seam for the screenshot bytes themselves.
typedef DeviceFrameGrabber = List<int>? Function();

/// What the device reported that makes a frame invalid as evidence.
class DeviceDialogFinding {
  const DeviceDialogFinding({
    required this.kind,
    required this.detail,
    this.focusedWindow,
    this.stage = 'unknown',
  });

  /// One of `system-dialog`, `foreign-focused-window`, `no-focused-window`,
  /// `device-state-unavailable`.
  final String kind;

  /// Human-readable statement of what was actually detected.
  final String detail;

  /// The focused window title as the device reported it, when known.
  final String? focusedWindow;

  /// `before-capture` or `after-capture`.
  final String stage;

  DeviceDialogFinding atStage(String value) => DeviceDialogFinding(
    kind: kind,
    detail: detail,
    focusedWindow: focusedWindow,
    stage: value,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'kind': kind,
    'detail': detail,
    if (focusedWindow != null) 'focusedWindow': focusedWindow,
    'stage': stage,
  };

  @override
  String toString() =>
      'kind=$kind stage=$stage detail="$detail"'
      '${focusedWindow == null ? '' : ' focusedWindow="$focusedWindow"'}';
}

/// Decides, from one device-state reading, whether a frame captured at this
/// instant would be valid evidence of the app under test.
///
/// Returns `null` only when the device positively confirms the app owns the
/// focused window. An unreadable device state is a finding, not a pass: a run
/// that cannot verify what was on screen must not certify the frame.
DeviceDialogFinding? detectDeviceSystemDialog({
  required DeviceWindowState state,
  required String appPackage,
}) {
  if (!state.isUsable) {
    final stderrText = state.stderr.trim();
    return DeviceDialogFinding(
      kind: 'device-state-unavailable',
      detail:
          'the device did not answer "adb ${deviceWindowStateCommand.join(' ')}" '
          '(exitCode=${state.exitCode}'
          '${stderrText.isEmpty ? '' : ', stderr=$stderrText'}), so what was on '
          'screen could not be verified',
    );
  }

  for (final title in deviceWindowTitles(state.stdout)) {
    for (final marker in androidSystemDialogWindowTitleMarkers) {
      if (title.contains(marker)) {
        return DeviceDialogFinding(
          kind: 'system-dialog',
          detail: 'an Android system dialog window is present: "$title"',
          focusedWindow: focusedDeviceWindowTitle(state.stdout),
        );
      }
    }
  }

  final focused = focusedDeviceWindowTitle(state.stdout);
  if (focused == null || focused.isEmpty) {
    return const DeviceDialogFinding(
      kind: 'no-focused-window',
      detail:
          'the device reported no focused window, so the app under test was '
          'not on top',
    );
  }
  if (nonBlockingFocusedWindowTitles.contains(focused)) {
    return null;
  }
  final focusedPackage = focused.split('/').first;
  if (focusedPackage != appPackage) {
    return DeviceDialogFinding(
      kind: 'foreign-focused-window',
      detail:
          'the focused window belongs to "$focusedPackage", not the app under '
          'test "$appPackage"',
      focusedWindow: focused,
    );
  }
  return null;
}

/// `mCurrentFocus=Window{hash u0 TITLE}` -> `TITLE`; `null` when unfocused.
String? focusedDeviceWindowTitle(String dump) {
  final match = RegExp(
    r'mCurrentFocus=(?:Window\{\S+\s+\S+\s+([^}]*)\}|null)',
  ).firstMatch(dump);
  if (match == null) {
    return null;
  }
  return match.group(1)?.trim();
}

/// Every `Window{hash user TITLE}` title named anywhere in the dump.
List<String> deviceWindowTitles(String dump) => RegExp(
  r'Window\{\S+\s+\S+\s+([^}]*)\}',
).allMatches(dump).map((match) => match.group(1)!.trim()).toList();

/// The real probe: ask the attached device.
DeviceWindowStateProbe adbDeviceWindowStateProbe(String device) => () {
  final result = Process.runSync('adb', <String>[
    '-s',
    device,
    'shell',
    ...deviceWindowStateCommand,
  ]);
  return DeviceWindowState(
    exitCode: result.exitCode,
    stdout: result.stdout?.toString() ?? '',
    stderr: result.stderr?.toString() ?? '',
  );
};

/// Outcome of one guarded frame capture.
class GuardedFrameCapture {
  const GuardedFrameCapture({
    required this.screenshotName,
    required this.phase,
    required this.captured,
    this.path,
    this.finding,
    this.error,
  });

  final String screenshotName;
  final String phase;

  /// True only when a PNG was written. A frame the device rejected is never
  /// written, so no screenshot count anywhere can include it.
  final bool captured;
  final String? path;
  final DeviceDialogFinding? finding;
  final String? error;
}

/// Captures one Android frame, refusing to write it when the device says a
/// system dialog -- not the app under test -- owns the screen.
///
/// The device is asked twice: once before the frame is grabbed, and once after.
/// The walkthrough holds each rendered state for several seconds while the host
/// screencaps, and a dialog can arrive inside that window.
GuardedFrameCapture captureGuardedAndroidFrame({
  required Directory evidenceRoot,
  required String phase,
  required String screenshotName,
  required String appPackage,
  required DeviceWindowStateProbe probe,
  required DeviceFrameGrabber grabFrame,
}) {
  final safeToken = RegExp(r'^[A-Za-z0-9_-]+$');
  if (!safeToken.hasMatch(phase) || !safeToken.hasMatch(screenshotName)) {
    return GuardedFrameCapture(
      screenshotName: screenshotName,
      phase: phase,
      captured: false,
      error:
          'refusing unsafe screenshot target phase=$phase '
          'name=$screenshotName',
    );
  }

  final before = detectDeviceSystemDialog(
    state: probe(),
    appPackage: appPackage,
  )?.atStage('before-capture');
  if (before != null) {
    recordDeviceDialogFinding(
      evidenceRoot: evidenceRoot,
      phase: phase,
      screenshotName: screenshotName,
      finding: before,
    );
    return GuardedFrameCapture(
      screenshotName: screenshotName,
      phase: phase,
      captured: false,
      finding: before,
    );
  }

  final bytes = grabFrame();
  if (bytes == null) {
    return GuardedFrameCapture(
      screenshotName: screenshotName,
      phase: phase,
      captured: false,
      error: 'adb screencap produced no image for $phase/$screenshotName',
    );
  }

  final after = detectDeviceSystemDialog(
    state: probe(),
    appPackage: appPackage,
  )?.atStage('after-capture');
  if (after != null) {
    recordDeviceDialogFinding(
      evidenceRoot: evidenceRoot,
      phase: phase,
      screenshotName: screenshotName,
      finding: after,
    );
    return GuardedFrameCapture(
      screenshotName: screenshotName,
      phase: phase,
      captured: false,
      finding: after,
    );
  }

  final directory = Directory('${evidenceRoot.path}/$phase/screenshots')
    ..createSync(recursive: true);
  final file = File('${directory.path}/$screenshotName.png')
    ..writeAsBytesSync(bytes, flush: true);
  return GuardedFrameCapture(
    screenshotName: screenshotName,
    phase: phase,
    captured: true,
    path: file.path,
  );
}

File deviceDialogFindingsFile(Directory evidenceRoot, String phase) =>
    File('${evidenceRoot.path}/$phase/$deviceDialogFindingsFileName');

/// Drops findings left by an earlier run so a stale file can never fail -- or
/// silently pass -- the run that follows.
void clearDeviceDialogFindings({
  required Directory evidenceRoot,
  required String phase,
}) {
  final file = deviceDialogFindingsFile(evidenceRoot, phase);
  if (file.existsSync()) {
    file.deleteSync();
  }
}

void recordDeviceDialogFinding({
  required Directory evidenceRoot,
  required String phase,
  required String screenshotName,
  required DeviceDialogFinding finding,
}) {
  final file = deviceDialogFindingsFile(evidenceRoot, phase);
  Directory(file.parent.path).createSync(recursive: true);
  final findings = readDeviceDialogFindings(
    evidenceRoot: evidenceRoot,
    phase: phase,
  );
  findings[screenshotName] = finding;
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schemaVersion': 1,
      'phase': phase,
      'findings': <String, Object?>{
        for (final entry in findings.entries) entry.key: entry.value.toJson(),
      },
    }),
    flush: true,
  );
}

Map<String, DeviceDialogFinding> readDeviceDialogFindings({
  required Directory evidenceRoot,
  required String phase,
}) {
  final file = deviceDialogFindingsFile(evidenceRoot, phase);
  if (!file.existsSync()) {
    return <String, DeviceDialogFinding>{};
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    return <String, DeviceDialogFinding>{};
  }
  final findings = decoded['findings'];
  if (findings is! Map) {
    return <String, DeviceDialogFinding>{};
  }
  return <String, DeviceDialogFinding>{
    for (final entry in findings.entries)
      if (entry.value is Map)
        entry.key.toString(): DeviceDialogFinding(
          kind: (entry.value as Map)['kind']?.toString() ?? 'unknown',
          detail: (entry.value as Map)['detail']?.toString() ?? '',
          focusedWindow: (entry.value as Map)['focusedWindow']?.toString(),
          stage: (entry.value as Map)['stage']?.toString() ?? 'unknown',
        ),
  };
}
