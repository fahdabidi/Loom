import 'package:feature_creator_customize/feature_creator_customize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p20_starter_pack_onramp', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final controller = CreatorCustomizeController(
      initialCreatorId: 'creator_nova_clutch',
      metadataApi: resolveCreatorMetadataApi(),
      experienceApi: resolveCreatorExperienceApi(),
      registryApi: resolveExtensionRegistryApi(),
      starterPackApi: resolveStarterPackApi(),
    );
    await controller.load();
    await controller.assembleGamingStarterPack();

    final result = await resolveStarterPackApi().bulkFollow(
      channelId: 'creator_nova_clutch',
      passportId: 'passport_demo_fan',
      channelIds: controller.starterPack!.members
          .map((member) => member.channelId)
          .toList(growable: false),
      followVisibility: 'public',
      idempotencyKey: 'p20-starter-pack-follow',
    );
    expect(result.feedReady, isTrue);
  });
}
