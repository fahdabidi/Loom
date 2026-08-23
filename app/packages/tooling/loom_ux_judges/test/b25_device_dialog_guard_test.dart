import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/b25_device_dialog_guard.dart';
import 'package:test/test.dart';

const _appPackage = 'com.example.loom_communities_demo';

/// Shaped like the real `adb shell dumpsys window displays` output on the
/// capture emulator (API 36, 1080x2400).
String _dump({
  required String focused,
  List<String> extraWindows = const <String>[],
}) {
  final windows = <String>[
    'Window{f8c5ca u0 StatusBar}',
    'Window{d6bd141 u0 Taskbar}',
    'Window{f4a32fc u0 InputMethod}',
    'Window{35cd99c u0 $_appPackage/$_appPackage.MainActivity}',
    ...extraWindows,
  ];
  return <String>[
    'WINDOW MANAGER DISPLAY CONTENTS (dumpsys window displays)',
    '  Display: mDisplayId=0 rootDpi=420',
    for (final window in windows) '    mWindow=$window',
    '  mCurrentFocus=$focused',
    '  mFocusedApp=ActivityRecord{250227762 u0 $_appPackage/.MainActivity t6}',
  ].join('\n');
}

String get _cleanDump =>
    _dump(focused: 'Window{35cd99c u0 $_appPackage/$_appPackage.MainActivity}');

/// The exact shape of an ANR: system_server owns a native window titled
/// `Application Not Responding: <package>` and holds input focus.
String get _anrDump => _dump(
  focused: 'Window{7c31a90 u0 Application Not Responding: '
      'com.google.android.gms}',
  extraWindows: <String>[
    'Window{7c31a90 u0 Application Not Responding: com.google.android.gms}',
  ],
);

DeviceWindowState _ok(String stdout) =>
    DeviceWindowState(exitCode: 0, stdout: stdout, stderr: '');

/// A probe that answers with a different dump on each successive call, so a
/// test can put a dialog on screen only after the frame was grabbed.
DeviceWindowStateProbe _scriptedProbe(List<DeviceWindowState> answers) {
  var index = 0;
  return () => answers[index++ < answers.length ? index - 1 : answers.length - 1];
}

void main() {
  group('detectDeviceSystemDialog', () {
    test('passes when the app under test owns the focused window', () {
      expect(
        detectDeviceSystemDialog(
          state: _ok(_cleanDump),
          appPackage: _appPackage,
        ),
        isNull,
      );
    });

    test('fails when an ANR dialog window is present', () {
      final finding = detectDeviceSystemDialog(
        state: _ok(_anrDump),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'system-dialog');
      expect(finding.detail, contains('Application Not Responding'));
      expect(finding.detail, contains('com.google.android.gms'));
    });

    test('fails when a crash dialog window is present', () {
      final finding = detectDeviceSystemDialog(
        state: _ok(
          _dump(
            focused: 'Window{aa11 u0 Application Error: com.android.bluetooth}',
            extraWindows: <String>[
              'Window{aa11 u0 Application Error: com.android.bluetooth}',
            ],
          ),
        ),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'system-dialog');
      expect(finding.detail, contains('Application Error'));
    });

    test('fails when another app owns the focused window', () {
      final finding = detectDeviceSystemDialog(
        state: _ok(
          _dump(
            focused: 'Window{35cd99c u0 com.google.android.apps.nexuslauncher/'
                'com.google.android.apps.nexuslauncher.NexusLauncherActivity}',
          ),
        ),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'foreign-focused-window');
      expect(finding.detail, contains('com.google.android.apps.nexuslauncher'));
    });

    test('fails when SystemUI chrome such as the shade owns focus', () {
      final finding = detectDeviceSystemDialog(
        state: _ok(_dump(focused: 'Window{4cd6ec3 u0 NotificationShade}')),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'foreign-focused-window');
    });

    test('fails when nothing holds focus', () {
      final finding = detectDeviceSystemDialog(
        state: _ok(_dump(focused: 'null')),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'no-focused-window');
    });

    test('an unreadable device state is a failure, never a quiet pass', () {
      final finding = detectDeviceSystemDialog(
        state: const DeviceWindowState(
          exitCode: 1,
          stdout: '',
          stderr: 'error: device offline',
        ),
        appPackage: _appPackage,
      );
      expect(finding, isNotNull);
      expect(finding!.kind, 'device-state-unavailable');
      expect(finding.detail, contains('device offline'));
    });

    test('the soft keyboard taking focus does not fail a frame', () {
      expect(
        detectDeviceSystemDialog(
          state: _ok(_dump(focused: 'Window{f4a32fc u0 InputMethod}')),
          appPackage: _appPackage,
        ),
        isNull,
      );
    });
  });

  group('marker safety', () {
    // The Flutter-side guard once matched 'wait' as a substring and ate
    // `Join waitlist`. Device-side markers are matched against dumpsys window
    // titles rather than product copy, and this pins that they could not
    // collide with shipped strings even if they were.
    const shippedProductStrings = <String>[
      'Join waitlist',
      'Waitlist joined',
      'Close',
      'Wait for approval',
      'Application submitted',
      'Report an error',
      'System status',
      'Respond to request',
      'Not responding yet',
    ];

    test('no shipped product string contains a device-side marker', () {
      for (final marker in androidSystemDialogWindowTitleMarkers) {
        for (final product in shippedProductStrings) {
          expect(
            product.toLowerCase().contains(marker.toLowerCase()),
            isFalse,
            reason: 'marker "$marker" would match product string "$product"',
          );
        }
      }
    });

    test('markers are framework window titles, not bare words', () {
      for (final marker in androidSystemDialogWindowTitleMarkers) {
        expect(marker, startsWith('Application '));
        expect(marker, endsWith(':'));
      }
    });

    test('a product string in the app window title does not fail a frame', () {
      final dump = _dump(
        focused: 'Window{35cd99c u0 $_appPackage/$_appPackage.MainActivity}',
        extraWindows: <String>[
          'Window{99 u0 $_appPackage/$_appPackage.JoinWaitlistActivity}',
        ],
      );
      expect(
        detectDeviceSystemDialog(state: _ok(dump), appPackage: _appPackage),
        isNull,
      );
    });
  });

  group('captureGuardedAndroidFrame', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('loom-device-dialog-guard-');
    });

    tearDown(() async {
      await root.delete(recursive: true);
    });

    File _png() => File('${root.path}/B13/screenshots/B13_row.png');

    test('a clean device response captures the frame', () {
      var grabbed = 0;
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[_ok(_cleanDump)]),
        grabFrame: () {
          grabbed += 1;
          return <int>[0x89, 0x50, 0x4e, 0x47];
        },
      );

      expect(capture.captured, isTrue);
      expect(capture.finding, isNull);
      expect(grabbed, 1);
      expect(_png().existsSync(), isTrue);
      expect(
        readDeviceDialogFindings(evidenceRoot: root, phase: 'B13'),
        isEmpty,
      );
    });

    test('a dialog present before the grab fails the capture', () {
      var grabbed = 0;
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[_ok(_anrDump)]),
        grabFrame: () {
          grabbed += 1;
          return <int>[0x89, 0x50, 0x4e, 0x47];
        },
      );

      expect(capture.captured, isFalse);
      expect(capture.finding, isNotNull);
      expect(capture.finding!.kind, 'system-dialog');
      expect(capture.finding!.stage, 'before-capture');
      expect(grabbed, 0, reason: 'no frame should be grabbed at all');
      expect(
        _png().existsSync(),
        isFalse,
        reason: 'a rejected frame must never reach disk',
      );

      final recorded = readDeviceDialogFindings(
        evidenceRoot: root,
        phase: 'B13',
      );
      expect(recorded.keys, <String>['B13_row']);
      expect(recorded['B13_row']!.detail, contains('Application Not '
          'Responding'));
    });

    test('a dialog that arrives after the grab still fails the capture', () {
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[
          _ok(_cleanDump),
          _ok(_anrDump),
        ]),
        grabFrame: () => <int>[0x89, 0x50, 0x4e, 0x47],
      );

      expect(capture.captured, isFalse);
      expect(capture.finding!.stage, 'after-capture');
      expect(_png().existsSync(), isFalse);
    });

    test('an unavailable device fails the capture', () {
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[
          const DeviceWindowState(
            exitCode: 255,
            stdout: '',
            stderr: 'error: no devices/emulators found',
          ),
        ]),
        grabFrame: () => <int>[0x89, 0x50, 0x4e, 0x47],
      );

      expect(capture.captured, isFalse);
      expect(capture.finding!.kind, 'device-state-unavailable');
      expect(_png().existsSync(), isFalse);
    });

    test('a failed screencap does not write a frame', () {
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[_ok(_cleanDump)]),
        grabFrame: () => null,
      );

      expect(capture.captured, isFalse);
      expect(capture.error, contains('screencap'));
      expect(_png().existsSync(), isFalse);
    });

    test('findings from an earlier run are cleared before the next', () {
      captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: 'B13_row',
        appPackage: _appPackage,
        probe: _scriptedProbe(<DeviceWindowState>[_ok(_anrDump)]),
        grabFrame: () => <int>[1],
      );
      expect(
        readDeviceDialogFindings(evidenceRoot: root, phase: 'B13'),
        isNotEmpty,
      );

      clearDeviceDialogFindings(evidenceRoot: root, phase: 'B13');

      expect(
        readDeviceDialogFindings(evidenceRoot: root, phase: 'B13'),
        isEmpty,
      );
      expect(deviceDialogFindingsFile(root, 'B13').existsSync(), isFalse);
    });

    test('several rejected frames in a phase all survive to the report', () {
      for (final name in <String>['B13_one', 'B13_two']) {
        captureGuardedAndroidFrame(
          evidenceRoot: root,
          phase: 'B13',
          screenshotName: name,
          appPackage: _appPackage,
          probe: _scriptedProbe(<DeviceWindowState>[_ok(_anrDump)]),
          grabFrame: () => <int>[1],
        );
      }
      final recorded = readDeviceDialogFindings(
        evidenceRoot: root,
        phase: 'B13',
      );
      expect(recorded.keys.toSet(), <String>{'B13_one', 'B13_two'});

      final raw =
          jsonDecode(deviceDialogFindingsFile(root, 'B13').readAsStringSync())
              as Map<String, dynamic>;
      expect(raw['phase'], 'B13');
      expect((raw['findings'] as Map).length, 2);
    });

    test('an unsafe frame name is refused without touching the device', () {
      var probed = 0;
      final capture = captureGuardedAndroidFrame(
        evidenceRoot: root,
        phase: 'B13',
        screenshotName: '../../escape',
        appPackage: _appPackage,
        probe: () {
          probed += 1;
          return _ok(_cleanDump);
        },
        grabFrame: () => <int>[1],
      );

      expect(capture.captured, isFalse);
      expect(capture.error, contains('unsafe'));
      expect(probed, 0);
    });
  });
}
