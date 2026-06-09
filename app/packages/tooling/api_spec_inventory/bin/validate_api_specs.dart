import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final manifestPath = _argValue(args, '--manifest') ??
      '../docs/Build Plan V2/test-manifest.json';
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    _fail('manifest not found: $manifestPath');
  }
  final manifest = jsonDecode(manifestFile.readAsStringSync());
  if (manifest is! Map<String, Object?>) {
    _fail('manifest must be a JSON object');
  }
  final components = manifest['components'];
  final tests = manifest['tests'];
  if (components is! List || tests is! List) {
    _fail('manifest must include components and tests arrays');
  }

  final errors = <String>[];
  final componentIds = <String>{};
  for (final item in components) {
    if (item is! Map<String, Object?>) {
      errors.add('component entry is not an object');
      continue;
    }
    final id = item['id'];
    final contract = item['contract'];
    final phase = item['phase'];
    final fakePresent = item['fakePresent'];
    if (id is! String || id.isEmpty) {
      errors.add('component missing id');
      continue;
    }
    componentIds.add(id);
    if (contract is! String || contract.isEmpty || contract == 'TBD') {
      errors.add('$id missing API/local contract name');
    }
    if (phase is! String || phase.isEmpty || phase == 'TBD') {
      errors.add('$id missing first implementation phase');
    }
    if (fakePresent != true) {
      errors.add('$id missing local fake/backend contract');
    }
  }

  for (final item in tests) {
    if (item is! Map<String, Object?>) {
      errors.add('test entry is not an object');
      continue;
    }
    final testId = item['testId'];
    final type = item['type'];
    final covers = item['coversComponents'];
    if (testId is! String || testId.isEmpty) {
      errors.add('test missing id');
    }
    if (type == 'workflow' &&
        item['executionTarget'] != 'demo-loom-communities-app-local-backend') {
      errors.add('$testId missing local Demo App execution target');
    }
    if (covers is! List || covers.isEmpty) {
      errors.add('$testId missing covered components');
      continue;
    }
    for (final covered in covers) {
      if (covered is! String || !componentIds.contains(covered)) {
        errors.add('$testId covers unknown component: $covered');
      }
    }
  }

  if (errors.isNotEmpty) {
    _fail(errors.join('\n'));
  }
  stdout.writeln(
    'vt_api_specs_complete: ok components=${componentIds.length} tests=${tests.length}',
  );
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
