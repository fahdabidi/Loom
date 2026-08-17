import 'dart:io';

import 'package:loom_ux_judges/community_remote_migration.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runCommunityRemoteMigration(arguments);
}
