import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final mode = _argValue(args, '--mode') ?? 'local-demo';
  final manifestFile = File(_defaultPrereqManifestPath());
  final manifest = _readJsonObject(manifestFile);
  final tools = manifest['tools'];
  if (tools is! List<Object?>) {
    _fail('skill_prereq_check: tools must be a list');
  }

  final requiredTools = <String>[];
  for (final item in tools) {
    if (item is! Map<String, Object?>) {
      _fail('skill_prereq_check: each tool must be an object');
    }
    final id = item['id'];
    final requiredFor = item['requiredFor'];
    if (id is! String || requiredFor is! List<Object?>) {
      _fail('skill_prereq_check: tool id and requiredFor are required');
    }
    if (requiredFor.contains(mode)) {
      requiredTools.add(id);
    }
  }

  if (requiredTools.isEmpty) {
    _fail('skill_prereq_check: no tools registered for mode $mode');
  }

  stdout.writeln(
    'skill_prereq_check: ok mode=$mode requiredTools=${requiredTools.join(',')}',
  );
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

String _defaultPrereqManifestPath() {
  final appRelative = File(
    '../docs/Build Plan V2/Skill/setup/prereq-manifest.json',
  );
  if (appRelative.existsSync()) {
    return appRelative.path;
  }
  return 'docs/Build Plan V2/Skill/setup/prereq-manifest.json';
}

Map<String, Object?> _readJsonObject(File file) {
  if (!file.existsSync()) {
    _fail('skill_prereq_check: JSON file missing: ${file.path}');
  }
  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    _fail('skill_prereq_check: ${file.path} must contain a JSON object');
  }
  return decoded;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
