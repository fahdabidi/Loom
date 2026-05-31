import 'dart:io';

void main() {
  final root = Directory.current;
  final violations = <String>[];

  final dartFiles = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.contains('/.dart_tool/'))
      .where((file) => !file.path.contains('/build/'));

  for (final file in dartFiles) {
    final normalized = file.path.replaceAll('\\', '/');
    final imports = _packageImports(file.readAsStringSync());

    if (normalized.contains('/packages/features/')) {
      for (final imported in imports) {
        final allowed =
            imported == 'flutter' ||
            imported == 'loom_api_contracts' ||
            imported == 'loom_design_system' ||
            imported == 'loom_app_shell';
        if (!allowed) {
          violations.add('$normalized imports package:$imported');
        }
      }
    }

    if (normalized.contains('/packages/core/loom_design_system/')) {
      for (final imported in imports) {
        final forbidden =
            imported.startsWith('feature_') ||
            imported == 'loom_api_contracts' ||
            imported == 'loom_app_shell' ||
            imported == 'loom_fake_backend' ||
            imported == 'loom_local_store' ||
            imported == 'loom_seed_data';
        if (forbidden) {
          violations.add('$normalized imports package:$imported');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Boundary violations:');
    for (final violation in violations) {
      stderr.writeln('- $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln('Boundary checks passed.');
}

List<String> _packageImports(String source) {
  final pattern = RegExp(r'''import\s+['"]package:([^/'"]+)\/''');
  return pattern.allMatches(source).map((match) => match.group(1)!).toList();
}
