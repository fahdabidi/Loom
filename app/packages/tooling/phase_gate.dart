import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final phase = _argValue(args, '--phase') ?? '0';
  final manifestPath = _argValue(args, '--manifest') ?? _defaultManifestPath();
  final checkEnv = args.contains('--check-env');
  final manifest = _readJsonObject(File(manifestPath));
  final tests = _requiredList(manifest, 'tests');
  final phaseTests = tests
      .where((Object? value) {
        if (value is! Map<String, Object?>) {
          return false;
        }
        return value['phase'] == phase;
      })
      .toList(growable: false);

  if (phaseTests.isEmpty) {
    _fail('phase_gate: no manifest tests registered for phase $phase');
  }

  final repoRoot = _repoRoot();
  final requiredFiles = <String>[
    'docs/Build Plan V2/Rules.md',
    'docs/Build Plan V2/Build Tracker.md',
    'docs/Build Plan V2/Test Manifest.md',
    'docs/Build Plan V2/Skill/SKILL.md',
    'docs/Build Plan V2/Skill/using-loom-to-build-an-extension.md',
  ];

  for (final relativePath in requiredFiles) {
    final file = File('${repoRoot.path}/$relativePath');
    if (!file.existsSync()) {
      _fail('phase_gate: required file missing: $relativePath');
    }
  }

  if (checkEnv) {
    _validateWslUbuntu();
    _validatePrereqFiles(repoRoot);
  }

  stdout.writeln(
    'phase_gate: ok phase=$phase registeredTests=${phaseTests.length} '
    'checkEnv=$checkEnv',
  );
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _defaultManifestPath() {
  final appRelative = File('../docs/Build Plan V2/test-manifest.json');
  if (appRelative.existsSync()) {
    return appRelative.path;
  }
  return 'docs/Build Plan V2/test-manifest.json';
}

Directory _repoRoot() {
  final fromApp = Directory.current.parent;
  if (File(
    '${fromApp.path}/docs/Build Plan V2/test-manifest.json',
  ).existsSync()) {
    return fromApp;
  }
  return Directory.current;
}

Map<String, Object?> _readJsonObject(File file) {
  if (!file.existsSync()) {
    _fail('phase_gate: JSON file missing: ${file.path}');
  }
  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    _fail('phase_gate: ${file.path} must contain a JSON object');
  }
  return decoded;
}

List<Object?> _requiredList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List<Object?>) {
    _fail('phase_gate: $key must be a list');
  }
  return value;
}

void _validatePrereqFiles(Directory repoRoot) {
  final setupDir = '${repoRoot.path}/docs/Build Plan V2/Skill/setup';
  final prereq = _readJsonObject(File('$setupDir/prereq-manifest.json'));
  final lock = _readJsonObject(
    File('$setupDir/validation-environment.lock.json'),
  );
  if (prereq['schemaVersion'] != 1) {
    _fail('phase_gate: prereq manifest schemaVersion must be 1');
  }
  if (lock['schemaVersion'] != 1) {
    _fail('phase_gate: validation environment lock schemaVersion must be 1');
  }
}

void _validateWslUbuntu() {
  final procVersion = File('/proc/version');
  final osRelease = File('/etc/os-release');
  if (!procVersion.existsSync() || !osRelease.existsSync()) {
    _fail('phase_gate: WSL Ubuntu check must run inside Ubuntu');
  }

  final kernel = procVersion.readAsStringSync().toLowerCase();
  final os = osRelease.readAsStringSync().toLowerCase();
  final isWsl = kernel.contains('microsoft') || kernel.contains('wsl');
  final isUbuntu = os.contains('id=ubuntu') || os.contains('name="ubuntu"');
  if (!isWsl || !isUbuntu) {
    _fail('phase_gate: tooling must run inside WSL Ubuntu');
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
