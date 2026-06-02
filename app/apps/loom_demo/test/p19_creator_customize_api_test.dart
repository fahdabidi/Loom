import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';
import 'package:loom_local_store/loom_local_store.dart';

void main() {
  late DemoLocalStore store;

  setUp(() async {
    resetAppShellDependencies();
    store = await configureDemoDependencies(persistent: false);
  });

  tearDown(() async {
    await store.close();
    resetAppShellDependencies();
  });

  test(
    'p19 customize console persists theme banner and module order',
    () async {
      final controller = _controller('creator_nova_clutch');
      await controller.load();

      controller.selectTheme(CreatorCustomizeController.themeOptions[1]);
      controller.selectBanner(CreatorCustomizeController.bannerOptions[1]);
      controller.moveModule('clip_arena', -1);
      expect(controller.dirty, isTrue);

      await controller.save();
      final persisted = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: 'creator_nova_clutch',
      );
      expect(persisted.theme.themeId, 'ember-lore');
      expect(persisted.bannerRef, 'seed://banners/ember-hollow');
      expect(persisted.surfaceModules.first.moduleId, 'clip_arena');
    },
  );

  test(
    'p19 install reconfigure and suspend extension writes through APIs',
    () async {
      final controller = _controller('creator_ember_hollow');
      await controller.load();
      final hypeWars = controller.catalog.singleWhere(
        (manifest) => manifest.extensionId == 'ext_hypewars',
      );

      await controller.installExtension(hypeWars);
      var persisted = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: 'creator_ember_hollow',
      );
      expect(
        persisted.installedExtensions.map((install) => install.extensionId),
        contains('ext_hypewars'),
      );
      expect(
        persisted.surfaceModules.map((module) => module.extensionId),
        contains('ext_hypewars'),
      );

      await controller.retuneExtension('ext_hypewars');
      persisted = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: 'creator_ember_hollow',
      );
      final hypeModule = persisted.surfaceModules.singleWhere(
        (module) => module.extensionId == 'ext_hypewars',
      );
      expect(hypeModule.config['studioPreset'], 'retuned');

      await controller.suspendExtension('ext_hypewars');
      persisted = await resolveCreatorExperienceApi().getExperienceConfig(
        channelId: 'creator_ember_hollow',
      );
      expect(
        persisted.installedExtensions.map((install) => install.extensionId),
        isNot(contains('ext_hypewars')),
      );
    },
  );

  test(
    'p19 gaming starter pack assembly persists five creator bundle',
    () async {
      final controller = _controller('creator_nova_clutch');
      await controller.load();

      await controller.assembleGamingStarterPack();
      final pack = await resolveStarterPackApi().getStarterPack(
        channelId: 'creator_nova_clutch',
        passportId: 'passport_demo_fan',
      );

      expect(pack.members, hasLength(5));
      expect(
        pack.members.map((member) => member.channelId),
        containsAll([
          'creator_nova_clutch',
          'creator_ember_hollow',
          'creator_frame_by_frame',
          'creator_drift_and_chill',
          'creator_iron_vael',
        ]),
      );
    },
  );
}

CreatorCustomizeController _controller(String creatorId) {
  return CreatorCustomizeController(
    initialCreatorId: creatorId,
    metadataApi: resolveCreatorMetadataApi(),
    experienceApi: resolveCreatorExperienceApi(),
    registryApi: resolveExtensionRegistryApi(),
    starterPackApi: resolveStarterPackApi(),
  );
}
