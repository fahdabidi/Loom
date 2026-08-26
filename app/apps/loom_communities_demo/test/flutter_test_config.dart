import 'dart:async';

import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

/// Runs before every test in this package.
///
/// The demo's widget tests drive the app's own `main()`, which configures the
/// default service environment — the real backend, since 2026-08-26. In a test
/// process that has two consequences: the test tries to reach a cluster that
/// is not there, and the configuration it installs persists in module state
/// for every test after it. The second is the nastier one; it makes a test
/// pass alone and fail in the suite, which is a slow thing to diagnose.
///
/// `LOOM_ENV` is compile-time, so a test cannot opt out through it. This is the
/// runtime equivalent, set before any test can call `main()`.
///
/// Tests that want the real backend do not belong here: they belong in
/// `integration_test/`, gated on the service defines and run against a live
/// cluster on a device.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugForceLoomLocalBackend = true;
  await testMain();
}
