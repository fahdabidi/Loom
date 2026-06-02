import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p19_reconfigure_propagates', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final controller = CreatorCustomizeController(
      initialCreatorId: 'creator_ember_hollow',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
      externalContentApi: resolveExternalContentSourceApi(),
    );
    await controller.load();
    final manifest = controller.catalog.singleWhere(
      (candidate) => candidate.extensionId == 'ext_hypewars',
    );
    await controller.installExtension(manifest);
    await controller.retuneExtension('ext_hypewars');

    final config = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_ember_hollow',
    );
    expect(
      config.surfaceModules
          .singleWhere((module) => module.extensionId == 'ext_hypewars')
          .config['studioPreset'],
      'retuned',
    );
  });
}
