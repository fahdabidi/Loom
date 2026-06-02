import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p26_full_regression', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    final starterPack = await resolveStarterPackApi().getStarterPack(
      channelId: 'creator_nova_clutch',
      passportId: 'passport_demo_fan',
    );
    expect(starterPack.members, isNotEmpty);

    final config = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_iron_vael',
    );
    expect(
      config.surfaceModules.map((module) => module.kind),
      contains('external_content'),
    );

    await store.resetDemo();
    final resetConfig = await resolveCreatorExperienceApi().getExperienceConfig(
      channelId: 'creator_iron_vael',
    );
    expect(
      resetConfig.surfaceModules.map((module) => module.kind),
      contains('external_content'),
    );
  });
}
