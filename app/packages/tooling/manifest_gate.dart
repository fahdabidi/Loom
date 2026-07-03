import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final manifestPath = _argValue(args, '--manifest') ?? _defaultManifestPath();
  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    _fail('manifest not found: $manifestPath');
  }

  final manifest = _readJsonObject(manifestFile);
  final components = _requiredList(manifest, 'components');
  final tests = _requiredList(manifest, 'tests');
  final errors = <String>[];
  final componentIds = <String>{};

  for (var index = 0; index < components.length; index += 1) {
    final component = _asObjectMap(components[index], 'components[$index]');
    final id = _requiredString(component, 'id', 'components[$index]', errors);
    _requiredString(component, 'layer', 'components[$index]', errors);
    _requiredString(component, 'phase', 'components[$index]', errors);
    _requiredString(component, 'contract', 'components[$index]', errors);
    _requiredString(component, 'version', 'components[$index]', errors);
    if (component['fakePresent'] is! bool) {
      errors.add('components[$index].fakePresent must be a boolean');
    }
    if (id != null) {
      componentIds.add(id);
    }
  }

  final statusCounts = <String, int>{};
  final allowedStatuses = <String>{
    'planned',
    'pending-counterpart',
    'pending',
    'pass',
    'fail',
    'stale',
    'skipped',
  };
  final allowedTypes = <String>{'validation', 'contract', 'workflow'};

  for (var index = 0; index < tests.length; index += 1) {
    final test = _asObjectMap(tests[index], 'tests[$index]');
    final testId = _requiredString(test, 'testId', 'tests[$index]', errors);
    final type = _requiredString(test, 'type', 'tests[$index]', errors);
    final phase = _requiredString(test, 'phase', 'tests[$index]', errors);
    final status = _requiredString(test, 'status', 'tests[$index]', errors);
    _requiredString(test, 'testHash', 'tests[$index]', errors);
    final covers = _requiredStringList(
      test,
      'coversComponents',
      'tests[$index]',
      errors,
    );
    _requiredStringList(test, 'dependents', 'tests[$index]', errors);

    if (testId != null && testId.trim().isEmpty) {
      errors.add('tests[$index].testId must not be empty');
    }
    if (type != null && !allowedTypes.contains(type)) {
      errors.add('tests[$index].type has unsupported value: $type');
    }
    if (phase != null && phase.trim().isEmpty) {
      errors.add('tests[$index].phase must not be empty');
    }
    if (status != null) {
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      if (!allowedStatuses.contains(status)) {
        errors.add('tests[$index].status has unsupported value: $status');
      }
    }

    final owningComponent = test['owningComponent'];
    if (type == 'workflow') {
      if (owningComponent != null && owningComponent is! String) {
        errors.add('tests[$index].owningComponent must be null or a string');
      }
    } else if (owningComponent is! String || owningComponent.trim().isEmpty) {
      errors.add('tests[$index].owningComponent is required for $type tests');
    } else if (!componentIds.contains(owningComponent)) {
      errors.add(
        'tests[$index].owningComponent references unknown component: '
        '$owningComponent',
      );
    }

    for (final coveredComponent in covers) {
      if (!componentIds.contains(coveredComponent)) {
        errors.add(
          'tests[$index].coversComponents references unknown component: '
          '$coveredComponent',
        );
      }
    }

    if (test['lastRunComponentVersions'] is! Map<String, Object?>) {
      errors.add('tests[$index].lastRunComponentVersions must be an object');
    }
  }

  if (errors.isNotEmpty) {
    _fail(errors.join('\n'));
  }

  stdout.writeln(
    'manifest_gate: ok components=${components.length} tests=${tests.length} '
    'statuses=$statusCounts',
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

Map<String, Object?> _readJsonObject(File file) {
  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    _fail('${file.path} must contain a JSON object');
  }
  return decoded;
}

List<Object?> _requiredList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! List<Object?>) {
    _fail('$key must be a list');
  }
  return value;
}

Map<String, Object?> _asObjectMap(Object? value, String context) {
  if (value is! Map<String, Object?>) {
    _fail('$context must be an object');
  }
  return value;
}

String? _requiredString(
  Map<String, Object?> map,
  String key,
  String context,
  List<String> errors,
) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    errors.add('$context.$key must be a non-empty string');
    return null;
  }
  return value;
}

List<String> _requiredStringList(
  Map<String, Object?> map,
  String key,
  String context,
  List<String> errors,
) {
  final value = map[key];
  if (value is! List<Object?>) {
    errors.add('$context.$key must be a list');
    return const <String>[];
  }
  final result = <String>[];
  for (var index = 0; index < value.length; index += 1) {
    final item = value[index];
    if (item is! String || item.trim().isEmpty) {
      errors.add('$context.$key[$index] must be a non-empty string');
    } else {
      result.add(item);
    }
  }
  return result;
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
