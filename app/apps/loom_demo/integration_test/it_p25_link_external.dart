import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p25_link_external', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final controller = CreatorCustomizeController(
      initialCreatorId: 'creator_nova_clutch',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
      externalContentApi: resolveExternalContentSourceApi(),
    );
    await controller.load();
    await controller.linkExternalContent(
      input: 'NovaClutch VOD',
      creatorNote: 'Creator-picked companion video.',
    );

    final config = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_nova_clutch',
    );
    expect(
      config.surfaceModules.map((module) => module.kind),
      contains('external_content'),
    );
  });
}
