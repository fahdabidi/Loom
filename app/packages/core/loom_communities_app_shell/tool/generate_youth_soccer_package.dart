import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _extensionId = 'ext_youth_soccer';
const _communityId = 'community_youth_soccer';
const _fixtureRelativePath =
    'docs/references/communities/'
    'Loom_Communities_Workflow_Engine_RiversideYouthSoccer_Example.jsonc';

Directory _repositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File('${directory.path}/$_fixtureRelativePath').existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not find the frozen Riverside Youth Soccer fixture.');
}

Future<void> main() async {
  final root = _repositoryRoot();
  final fixture = File('${root.path}/$_fixtureRelativePath');
  final source =
      jsonDecode(stripJsonComments(await fixture.readAsString()))
          as Map<String, dynamic>;
  // Override to match the app's preloaded demo shell's real communityId/
  // extensionId so sideload hydrates that shell (CJM.9's fix path) instead
  // of creating a separate community.
  source['extensionId'] = _extensionId;
  source['communityId'] = _communityId;

  final outputDirectory = Directory('${root.path}/.codex-logs');
  await outputDirectory.create(recursive: true);
  final initialization = File(
    '${outputDirectory.path}/$_extensionId.loom-init.zip',
  );
  final extension = File(
    '${outputDirectory.path}/$_extensionId.loom-extension.zip',
  );

  await initialization.writeAsString(jsonEncode(source));
  await extension.writeAsString(
    jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'extensionId': _extensionId,
      'displayName': source['displayName'],
      'version': '1.0.0',
      'mode': 'local-demo',
      'permissions': <String>[],
    }),
  );

  stdout.writeln('Regenerated ${extension.path}');
  stdout.writeln('Regenerated ${initialization.path}');
}
