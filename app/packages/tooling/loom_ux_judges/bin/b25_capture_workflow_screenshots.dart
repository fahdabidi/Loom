import 'dart:convert';
import 'dart:io';

const _fullB25Phases = <String>[
  'B12',
  'B13',
  'B14',
  'B15',
  'B16',
  'B17',
  'B18',
  'B19',
  'B20',
];

void main(List<String> args) async {
  final device = _argValue(args, '--device') ?? 'emulator-5554';
  final mode = _argValue(args, '--mode') ?? 'full-b25';
  if (mode != 'full-b25' && mode != 'targeted-precheck') {
    stderr.writeln(
      'b25_capture_workflow_screenshots: --mode must be full-b25 or targeted-precheck.',
    );
    exit(64);
  }
  final phases = (_argValue(args, '--phases') ?? _fullB25Phases.join(','))
      .split(',')
      .map((phase) => phase.trim())
      .where((phase) => phase.isNotEmpty)
      .toList(growable: false);
  final fullCoverage = _samePhases(phases, _fullB25Phases);
  if (mode == 'full-b25' && !fullCoverage) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: canonical B25 evidence requires full B12-B20 coverage. '
      'Requested phases=${phases.join(',')}; expected=${_fullB25Phases.join(',')}. '
      'Use --mode targeted-precheck for remediation diagnostics that must not be committed as canonical B25 evidence.',
    );
    exit(64);
  }
  final appRoot = Directory.current;
  final repoRoot = appRoot.parent;
  final demoDir = Directory('${appRoot.path}/apps/loom_communities_demo');
  if (!demoDir.existsSync()) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: expected Demo App at ${demoDir.path}',
    );
    exit(64);
  }

  final evidenceRoot = Directory(
    _argValue(args, '--evidence-root') ??
        '${repoRoot.path}/docs/Build Plan V2/Evidence',
  ).absolute;
  await evidenceRoot.create(recursive: true);
  final captureStartedAt = DateTime.now().toUtc().subtract(
    const Duration(minutes: 1),
  );

  final logPath =
      _argValue(args, '--log') ??
      '${evidenceRoot.path}/B20/flutter-drive-workflow-ui-evidence.log';
  await Directory(File(logPath).parent.path).create(recursive: true);

  final output = StringBuffer()
    ..writeln('b25_capture_workflow_screenshots')
    ..writeln('workingDirectory=${demoDir.path}')
    ..writeln('WORKFLOW_EVIDENCE_ROOT=${evidenceRoot.path}')
    ..writeln('mode=$mode')
    ..writeln('phases=${phases.join(',')}')
    ..writeln('device=$device')
    ..writeln();

  for (final phase in phases) {
    final command = <String>[
      'drive',
      '--driver=test_driver/workflow_ui_evidence_test.dart',
      '--target=integration_test/workflow_ui_evidence_test.dart',
      '-d',
      device,
      '--dart-define=LOOM_PRELOAD_EXAMPLE_COMMUNITIES=true',
      '--dart-define=LOOM_EVIDENCE_PHASE_FILTER=$phase',
    ];

    stdout.writeln(
      'b25_capture_workflow_screenshots: [$phase] running flutter ${command.join(' ')}',
    );
    final result = await Process.run(
      'flutter',
      command,
      workingDirectory: demoDir.path,
      environment: <String, String>{
        ...Platform.environment,
        'WORKFLOW_EVIDENCE_ROOT': evidenceRoot.path,
        'WORKFLOW_EVIDENCE_COMMAND_OUTPUT': logPath,
      },
    );

    output
      ..writeln('--- $phase ---')
      ..writeln('\$ flutter ${command.join(' ')}')
      ..writeln('exitCode=${result.exitCode}')
      ..writeln()
      ..writeln('--- stdout ---')
      ..write(result.stdout)
      ..writeln()
      ..writeln('--- stderr ---')
      ..write(result.stderr)
      ..writeln();
    await File(logPath).writeAsString(output.toString(), flush: true);

    if (result.exitCode != 0) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      stderr.writeln(
        'b25_capture_workflow_screenshots: [$phase] flutter drive failed; log written to $logPath',
      );
      exit(result.exitCode);
    }

    final phaseManifest = File(
      '${evidenceRoot.path}/$phase/workflow-ui-evidence.json',
    );
    if (!phaseManifest.existsSync()) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: [$phase] missing ${phaseManifest.path}; screenshot driver did not write evidence.',
      );
      exit(65);
    }
  }

  final combinedSummary = await _writeCombinedManifest(
    evidenceRoot: evidenceRoot,
    phases: phases,
    commandOutputPath: logPath,
    captureStartedAt: captureStartedAt,
    mode: mode,
  );

  final screenshotCount = combinedSummary.screenshotCount;
  if (mode == 'full-b25' && screenshotCount < 180) {
    stderr.writeln(
      'b25_capture_workflow_screenshots: expected at least 180 screenshots, found $screenshotCount.',
    );
    exit(65);
  }

  if (mode == 'targeted-precheck') {
    stdout.writeln(
      'b25_capture_workflow_screenshots: targeted precheck captured phases=${phases.join(',')} '
      'screenshots=$screenshotCount aggregate=${combinedSummary.aggregatePath}. '
      'This artifact is not commit-eligible for B25 closeout.',
    );
    return;
  }

  stdout.writeln(
    'b25_capture_workflow_screenshots: ok fullB25Coverage=true screenshots=$screenshotCount log=$logPath',
  );
}

String? _argValue(List<String> args, String name) {
  for (var index = 0; index < args.length; index += 1) {
    final arg = args[index];
    if (arg == name && index + 1 < args.length) {
      return args[index + 1];
    }
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

bool _samePhases(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) {
    return false;
  }
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) {
      return false;
    }
  }
  return true;
}

String _slug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'targeted' : slug;
}

Future<_CombinedManifestSummary> _writeCombinedManifest({
  required Directory evidenceRoot,
  required List<String> phases,
  required String commandOutputPath,
  required DateTime captureStartedAt,
  required String mode,
}) async {
  var workflowCount = 0;
  var screenshotCount = 0;
  final manifestPaths = <String>[];

  for (final phase in phases) {
    final manifestPath =
        '${evidenceRoot.path}/$phase/workflow-ui-evidence.json';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: missing phase manifest $manifestPath',
      );
      exit(65);
    }
    final manifestModifiedAt = await manifestFile.lastModified();
    if (manifestModifiedAt.toUtc().isBefore(captureStartedAt)) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: phase $phase manifest is stale. '
        'modified=$manifestModifiedAt captureStarted=$captureStartedAt path=$manifestPath',
      );
      exit(65);
    }
    final manifest = jsonDecode(await manifestFile.readAsString());
    if (manifest is! Map<String, dynamic>) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: invalid phase manifest $manifestPath',
      );
      exit(65);
    }
    final workflows = manifest['workflows'];
    if (workflows is! List || workflows.isEmpty) {
      stderr.writeln(
        'b25_capture_workflow_screenshots: phase $phase did not record any workflows.',
      );
      exit(65);
    }
    workflowCount += workflows.length;
    for (final workflow in workflows.whereType<Map<String, dynamic>>()) {
      final paths = workflow['screenshotPaths'];
      if (paths is List) {
        screenshotCount += paths.length;
        for (final path in paths.whereType<String>()) {
          final screenshot = File(path);
          if (!screenshot.existsSync()) {
            stderr.writeln(
              'b25_capture_workflow_screenshots: missing screenshot $path',
            );
            exit(65);
          }
          final modifiedAt = await screenshot.lastModified();
          if (modifiedAt.toUtc().isBefore(captureStartedAt)) {
            stderr.writeln(
              'b25_capture_workflow_screenshots: stale screenshot $path. '
              'modified=$modifiedAt captureStarted=$captureStartedAt',
            );
            exit(65);
          }
        }
      }
    }
    manifestPaths.add(manifestPath);
  }

  final fullCoverage = _samePhases(phases, _fullB25Phases);
  final finalDirectory = mode == 'full-b25'
      ? Directory('${evidenceRoot.path}/B20')
      : Directory('${evidenceRoot.path}/B25');
  await finalDirectory.create(recursive: true);
  final aggregatePath = mode == 'full-b25'
      ? '${finalDirectory.path}/all-workflow-ui-evidence.json'
      : '${finalDirectory.path}/targeted-workflow-ui-evidence-${_slug(phases.join('-'))}.json';
  await File(aggregatePath).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'status': 'pass',
      'phases': phases,
      'expectedPhases': _fullB25Phases,
      'missingPhases': _fullB25Phases
          .where((phase) => !phases.contains(phase))
          .toList(growable: false),
      'workflowCount': workflowCount,
      'screenshotCount': screenshotCount,
      'workflowEvidenceManifestPaths': manifestPaths,
      'commandOutputPath': commandOutputPath,
      'captureMode': mode,
      'fullB25Coverage': fullCoverage,
      'commitEligible': mode == 'full-b25' && fullCoverage,
    }),
    flush: true,
  );
  return _CombinedManifestSummary(
    aggregatePath: aggregatePath,
    screenshotCount: screenshotCount,
  );
}

class _CombinedManifestSummary {
  const _CombinedManifestSummary({
    required this.aggregatePath,
    required this.screenshotCount,
  });

  final String aggregatePath;
  final int screenshotCount;
}
