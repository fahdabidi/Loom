import 'dart:async';

import 'package:loom_communities_app_shell/loom_communities_app_shell.dart';

/// Runs before every test in this package.
///
/// The production engine factory now throws unless the process has declared
/// itself local (see `part25_engine_native_community_store.dart`). This
/// package's tests install engine-native experiences directly, without
/// calling an app's `main()`, so without this they would hit that throw on
/// every test that resolves an engine. This is the declared local opt-in,
/// set before any test in this package runs.
///
/// A test that wants to prove the gate fires for a non-local process must
/// flip this back to `false` for its own body and restore it with
/// `addTearDown`, so the opt-in still holds for every test after it.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugForceLoomLocalBackend = true;
  await testMain();
}
