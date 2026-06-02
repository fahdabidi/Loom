import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p19_two_creators_diverge', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final nova = CreatorCustomizeController(
      initialCreatorId: 'creator_nova_clutch',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
      externalContentApi: resolveExternalContentSourceApi(),
    );
    await nova.load();
    nova.selectTheme(CreatorCustomizeController.themeOptions[0]);
    await nova.save();

    final ember = CreatorCustomizeController(
      initialCreatorId: 'creator_ember_hollow',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
      externalContentApi: resolveExternalContentSourceApi(),
    );
    await ember.load();
    ember.selectTheme(CreatorCustomizeController.themeOptions[2]);
    await ember.save();

    final novaConfig = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_nova_clutch',
    );
    final emberConfig = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_ember_hollow',
    );
    expect(novaConfig.theme.themeId, isNot(emberConfig.theme.themeId));
  });
}
