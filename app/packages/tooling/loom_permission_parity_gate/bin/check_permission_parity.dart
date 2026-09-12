import 'dart:io';

import 'package:loom_permission_parity_gate/loom_permission_parity_gate.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runPermissionParityGate(arguments);
}
