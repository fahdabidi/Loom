import 'package:feature_fan_settings/feature_fan_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p22 prefer creators persists for AI search', (tester) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });

    final controller = FanAiSearchSettingsController();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.config?.preferCreators, isTrue);

    await controller.setPreferCreators(false);
    final persisted = await resolveFanVaultApi().getSearchAgentConfig(
      'passport_demo_fan',
    );
    expect(persisted.preferCreators, isFalse);
  });
}
