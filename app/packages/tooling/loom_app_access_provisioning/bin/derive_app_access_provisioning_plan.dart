import 'dart:io';

import 'package:loom_app_access_provisioning/loom_app_access_provisioning.dart';

Future<void> main(List<String> arguments) async {
  exitCode = await runDeriveAppAccessProvisioningPlan(arguments);
}
