import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p21 reset restores AI search defaults', (tester) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });

    await resolveFanVaultApi().putSearchAgentConfig(
      passportId: 'passport_demo_fan',
      provider: AiSearchProvider.openAi,
      mcpEndpoint: 'mcp://changed',
      connected: true,
      preferCreators: false,
      externalSourcesEnabled: true,
      idempotencyKey: 'it-p21-reset-change',
    );

    await resolveMigrationExportApi().resetDemo(idempotencyKey: 'it-p21-reset');

    final config = await resolveFanVaultApi().getSearchAgentConfig(
      'passport_demo_fan',
    );
    expect(config.connected, isFalse);
    expect(config.preferCreators, isTrue);

    final external = await resolveExternalContentSourceApi()
        .searchExternalContent(
          passportId: 'passport_demo_fan',
          query: 'clutch',
          sourceTypes: const [ExternalSourceType.youtube],
        );
    expect(external, isNotEmpty);
  });
}
