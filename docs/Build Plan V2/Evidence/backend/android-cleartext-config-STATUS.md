# Android debug cleartext configuration — status

**Status:** complete — 2026-08-26

## Change

The existing debug-only manifest at
`app/apps/loom_communities_demo/android/app/src/debug/AndroidManifest.xml`
now merges this application attribute:

```xml
android:networkSecurityConfig="@xml/network_security_config"
```

The configuration resource is
`app/apps/loom_communities_demo/android/app/src/main/res/xml/network_security_config.xml`.
It permits cleartext for exactly **4/4** requested development destinations:

- `192.168.56.10`
- `10.0.2.2`
- `localhost`
- `127.0.0.1`

There is no `<base-config>` permit and no
`android:usesCleartextTraffic="true"`. Consequently, destinations outside that
allowlist retain the platform cleartext default (denied on the API-36 / modern
target-SDK path); the XML grants an exception only to those four hosts.
The generated debug and release manifests both declare
`android:targetSdkVersion="36"`.

The project already had a debug-specific manifest, so none was created. The
main and release manifests were not changed; the configuration is activated
only by the debug manifest merge.

## Android build and manifest verification

The following debug APK build succeeded with all three required defines:

```sh
GRADLE_USER_HOME=/tmp/loom-cleartext-gradle.TXiVK3 \
GRADLE_OPTS=-Dorg.gradle.daemon=false \
flutter build apk --debug \
  --dart-define=LOOM_AUTH_TOKEN_ENDPOINT=http://192.168.56.10:30082/realms/loom/protocol/openid-connect/token \
  --dart-define=LOOM_AUTH_CLIENT_ID=loom-test-client \
  --dart-define=LOOM_WORKFLOW_SERVICE_BASE_URI=http://192.168.56.10:30083
```

Result:

```text
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

The generated debug merged manifest, not merely the source manifest, contains
the following line at
`build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml:47`:

```xml
android:networkSecurityConfig="@xml/network_security_config" >
```

The packaged debug resource at
`build/app/intermediates/packaged_res/debug/packageDebugResources/xml/network_security_config.xml`
contains all **4/4** allowlisted destinations above and no other destination.

For the release check, I ran:

```sh
GRADLE_USER_HOME=/tmp/loom-cleartext-gradle.TXiVK3 \
GRADLE_OPTS=-Dorg.gradle.daemon=false \
./gradlew :app:processReleaseMainManifest
```

That task completed successfully. I then inspected the generated
`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`.
It contains no `networkSecurityConfig`, `usesCleartextTraffic`, or
`network_security_config` reference. The release manifest therefore retains
the platform default and carries no cleartext exemption.

The sandbox mounts the normal Gradle user directory read-only, so the build
used the temporary Gradle cache named in the commands above. Before the final
successful build, I removed only seven pre-existing, zero-byte generated CMake
`configure_fingerprint.bin` files: three from the demo build output and four
from the `jni` pub-cache build output. Those files were dated 2026-08-24, were
not source files, and Gradle regenerated them.

## Regression verification

All requested suites passed. No total moved down from the ticket baseline.

| Suite | Command | Result |
| --- | --- | --- |
| App shell | `cd app/packages/core/loom_communities_app_shell && flutter test` | **274/274 passed** |
| UX judges | `cd app/packages/tooling/loom_ux_judges && flutter test` | **432/432 passed** |
| Workflow engine | `cd app/packages/core/loom_workflow_engine && flutter test` | **287/287 passed; 4 skipped** |
| Workflow service | `cd app/packages/core/loom_workflow_service && flutter test` | **54/54 passed; 5 skipped** |
| App Access provisioning | `cd app/packages/tooling/loom_app_access_provisioning && flutter test` | **15/15 passed** |
| Communities demo | `cd app/apps/loom_communities_demo && flutter test` | **160/160 passed** |

The engine's four skips require optional live PostgreSQL or deployed-workflow
environment variables. The workflow service's five skips require the optional
live PostgreSQL/App Access port-forward credentials. These match the expected
`+4 skipped` and `+5` totals respectively; no test was modified, skipped, or
weakened for this change.

## GA blocker

This is a development-loop exemption for a host-only network and forwarded
ports, not a production transport decision. The backend must serve real TLS
before GA, and this cleartext exception must be removed at that point. In
particular, the Keycloak token endpoint is among these development hosts, so a
JWT crosses this plaintext development link; it must not be normalized into a
GA configuration.
