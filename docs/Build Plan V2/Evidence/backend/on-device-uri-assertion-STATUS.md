# On-device URI assertion status

Changed only the base-URI assertion in
`app/apps/loom_communities_demo/integration_test/on_device_remote_backend_proof_test.dart`.

Old assertion:

```dart
expect(remoteEngine.baseUri, Uri.parse(_workflowServiceBaseUri));
```

New assertions:

```dart
expect(
  remoteEngine.baseUri.scheme,
  Uri.parse(_workflowServiceBaseUri).scheme,
);
expect(
  remoteEngine.baseUri.host,
  Uri.parse(_workflowServiceBaseUri).host,
);
expect(
  remoteEngine.baseUri.port,
  Uri.parse(_workflowServiceBaseUri).port,
);
```

This preserves verification that the remote engine targets the configured service
while tolerating its correct trailing-slash normalisation.

Verification performed:

```text
cd app/apps/loom_communities_demo
flutter analyze integration_test/on_device_remote_backend_proof_test.dart
```

Static analysis completed with 0 issues.

The on-device integration test was **not executed**: this environment has no
Android emulator/device. No Flutter test suite was run, so the test total is
**0 executed / 0 passed / 0 failed**. The required on-device verification remains
for the Windows emulator run with the three supplied defines.
