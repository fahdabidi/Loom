import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p15_extensions_foundation_smoke', (tester) async {
    await tester.pumpWidget(await buildLoomDemoAppForTest());
    await tester.pumpAndSettle();

    final registry = resolveExtensionRegistryApi();
    final runtime = resolveExtensionRuntimeApi();
    final experience = resolveCreatorExperienceApi();

    final manifests = await registry.listExtensions();
    expect(manifests, hasLength(6));

    for (final creatorId in _creatorIds) {
      final config = await experience.getExperienceConfig(channelId: creatorId);
      expect(config.installedExtensions, isNotEmpty);
      final install = config.installedExtensions.first;
      final session = await runtime.createExtensionSession(
        channelId: creatorId,
        extensionId: install.extensionId,
        surface: install.surfaces.first,
        fanId: 'passport_demo_fan',
        idempotencyKey: 'it-p15-session-$creatorId-${install.extensionId}',
      );
      final event = await runtime.submitExtensionEvent(
        sessionId: session.sessionId,
        type: 'fan_interaction',
        payload: const {'source': 'integration_smoke'},
        idempotencyKey: 'it-p15-event-$creatorId-${install.extensionId}',
      );
      expect(event.sessionId, session.sessionId);
    }
  });
}

const _creatorIds = [
  'creator_nova_clutch',
  'creator_ember_hollow',
  'creator_frame_by_frame',
  'creator_drift_and_chill',
  'creator_iron_vael',
];
