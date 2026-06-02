import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loom_api_contracts/loom_api_contracts.dart';
import 'package:loom_app_shell/loom_app_shell.dart';
import 'package:loom_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p21 AI search foundation smoke', (tester) async {
    final store = await configureDemoDependencies(persistent: false);
    addTearDown(() async {
      await store.close();
      resetAppShellDependencies();
    });

    await resolveFanVaultApi().putSearchAgentConfig(
      passportId: 'passport_demo_fan',
      provider: AiSearchProvider.anthropicClaude,
      mcpEndpoint: 'mcp://demo-agent/search',
      connected: true,
      preferCreators: true,
      externalSourcesEnabled: true,
      idempotencyKey: 'it-p21-agent',
    );
    await resolveFanVaultApi().putExternalSourceConnection(
      passportId: 'passport_demo_fan',
      sourceType: ExternalSourceType.youtube,
      connected: true,
      displayName: 'YouTube',
      idempotencyKey: 'it-p21-youtube',
    );

    final result = await resolveAiGatewayApi().runAiSearch(
      passportId: 'passport_demo_fan',
      query: 'raid',
      limit: 8,
    );

    expect(
      result.items.any((item) => item.type == AiSearchItemType.creator),
      isTrue,
    );
    expect(
      result.items.any((item) => item.type == AiSearchItemType.external),
      isTrue,
    );
    expect(result.searchReceiptId, startsWith('receipt_search_'));
  });
}
