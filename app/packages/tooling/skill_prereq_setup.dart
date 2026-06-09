import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final target = _argValue(args, '--target') ?? 'codex';
  final mode = _argValue(args, '--mode') ?? 'local-demo';
  final manifestFile = File(_defaultPrereqManifestPath());
  final manifest = _readJsonObject(manifestFile);
  final supportedTargets = _stringList(manifest['supportedExecutionTargets']);
  if (!supportedTargets.contains(target)) {
    _fail('skill_prereq_setup: unsupported target $target');
  }

  final installPlan = _buildInstallPlan(manifest, mode);
  if (installPlan.isEmpty) {
    _fail('skill_prereq_setup: no install plan entries for mode $mode');
  }

  stdout.writeln(
    'skill_prereq_setup: ok target=$target mode=$mode '
    'installPlanItems=${installPlan.length}',
  );
  for (final entry in installPlan) {
    stdout.writeln('- ${entry.id}: ${entry.install}');
  }
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _defaultPrereqManifestPath() {
  final appRelative = File('../docs/Build Plan V2/Skill/setup/prereq-manifest.json');
  if (appRelative.existsSync()) {
    return appRelative.path;
  }
  return 'docs/Build Plan V2/Skill/setup/prereq-manifest.json';
}

Map<String, Object?> _readJsonObject(File file) {
  if (!file.existsSync()) {
    _fail('skill_prereq_setup: JSON file missing: ${file.path}');
  }
  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    _fail('skill_prereq_setup: ${file.path} must contain a JSON object');
  }
  return decoded;
}

List<_InstallPlanEntry> _buildInstallPlan(
  Map<String, Object?> manifest,
  String mode,
) {
  final tools = manifest['tools'];
  if (tools is! List<Object?>) {
    _fail('skill_prereq_setup: tools must be a list');
  }
  final entries = <_InstallPlanEntry>[];
  for (final item in tools) {
    if (item is! Map<String, Object?>) {
      _fail('skill_prereq_setup: each tool must be an object');
    }
    final id = item['id'];
    final requiredFor = _stringList(item['requiredFor']);
    final install = item['install'];
    final verify = item['verify'];
    if (id is! String || install is! String || verify is! String) {
      _fail('skill_prereq_setup: each tool requires id, install, and verify');
    }
    if (requiredFor.contains(mode)) {
      entries.add(
        _InstallPlanEntry(
          id: id,
          install: install,
          verify: verify,
        ),
      );
    }
  }
  return entries;
}

List<String> _stringList(Object? value) {
  if (value is! List<Object?>) {
    _fail('skill_prereq_setup: expected a string list');
  }
  final result = <String>[];
  for (final item in value) {
    if (item is! String) {
      _fail('skill_prereq_setup: expected a string list');
    }
    result.add(item);
  }
  return result;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

class _InstallPlanEntry {
  const _InstallPlanEntry({
    required this.id,
    required this.install,
    required this.verify,
  });

  final String id;
  final String install;
  final String verify;
}
