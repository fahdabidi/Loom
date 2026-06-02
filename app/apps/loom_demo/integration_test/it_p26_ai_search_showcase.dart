import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('it_p26_ai_search_showcase', (tester) async {
    resetAppShellDependencies();
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(store.close);

    await _connectAiSearch();
    final result = await resolveAiGatewayApi().runAiSearch(
      passportId: 'passport_demo_fan',
      query: 'raid',
      limit: 10,
    );
    final external = result.items.firstWhere(
      (item) => item.type == AiSearchItemType.external,
    );
    expect(result.neutralityLabel, contains('No ads'));
    expect(external.embedDescriptor?.kind, EmbedKind.youtubeIframe);
    expect(external.sourceAttribution, 'YouTube');
  });
}

Future<void> _connectAiSearch() async {
  final vault = resolveFanVaultApi();
  await vault.putSearchAgentConfig(
    passportId: 'passport_demo_fan',
    provider: AiSearchProvider.anthropicClaude,
    mcpEndpoint: 'mcp://demo-agent/search',
    connected: true,
    preferCreators: true,
    externalSourcesEnabled: true,
    idempotencyKey: 'it-p26-ai-search-connect',
  );
  await vault.putExternalSourceConnection(
    passportId: 'passport_demo_fan',
    sourceType: ExternalSourceType.youtube,
    connected: true,
    displayName: 'YouTube',
    idempotencyKey: 'it-p26-ai-search-youtube',
  );
}
