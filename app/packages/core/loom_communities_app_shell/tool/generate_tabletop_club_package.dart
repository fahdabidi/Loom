import 'dart:convert';
import 'dart:io';

import 'package:loom_ux_judges/src/validator/jsonc.dart';

const _extensionId = 'ext_verify_tabletop_club';
const tabletopClubFixtureRelativePath =
    'docs/references/communities/'
    'Loom_Communities_Workflow_Engine_Phase1_TabletopClub_Example.jsonc';

Directory findTabletopClubRepositoryRoot() {
  var directory = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (File(
      '${directory.path}/$tabletopClubFixtureRelativePath',
    ).existsSync()) {
      return directory;
    }
    directory = directory.parent;
  }
  throw StateError('Could not find the frozen Tabletop fixture.');
}

Future<({File extensionPackage, File initializationPackage})>
generateTabletopClubPackagePair({
  required Directory outputDirectory,
  Directory? repositoryRoot,
}) async {
  final root = repositoryRoot ?? findTabletopClubRepositoryRoot();
  final fixture = File('${root.path}/$tabletopClubFixtureRelativePath');
  final source =
      jsonDecode(stripJsonComments(await fixture.readAsString()))
          as Map<String, dynamic>;
  source['extensionId'] = _extensionId;

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
      'specVersion': 4,
      'extensionId': _extensionId,
      'displayName': source['displayName'],
      'version': '1.0.0',
      'mode': 'local-demo',
      'permissions': <String>[],
    }),
  );

  return (extensionPackage: extension, initializationPackage: initialization);
}

Future<void> main() async {
  final root = findTabletopClubRepositoryRoot();
  final generated = await generateTabletopClubPackagePair(
    outputDirectory: Directory('${root.path}/.codex-logs'),
    repositoryRoot: root,
  );

  stdout.writeln('Regenerated ${generated.extensionPackage.path}');
  stdout.writeln('Regenerated ${generated.initializationPackage.path}');
}
